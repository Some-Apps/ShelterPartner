import functions_framework
import requests
from google.cloud import firestore
from google.cloud import storage
from datetime import datetime
import uuid
import re
import base64
import json
import xml.etree.ElementTree as ET

# Initialize Firestore and Storage clients outside the function for efficiency
db = firestore.Client()
storage_client = storage.Client()

@functions_framework.http
def main(request):
    print("Received a request.")
    # Parse JSON payload from the request
    request_json = request.get_json(silent=True)
    if not request_json:
        print('Invalid request: No JSON payload found')
        return 'Invalid request: No JSON payload found', 400
    print(f"Request JSON: {request_json}")

    # Check for 'message' and 'data' fields (Pub/Sub message format)
    message = request_json.get('message')
    if not message or 'data' not in message:
        print('Invalid request: Missing message or data field.')
        return 'Invalid request: Missing message or data field.', 400
    print(f"Message: {message}")

    # Decode the base64 data
    data_base64 = message['data']
    try:
        data_decoded = base64.b64decode(data_base64).decode('utf-8')
        print(f"Decoded data: {data_decoded}")
    except Exception as e:
        print(f'Invalid data encoding: {e}')
        return f'Invalid data encoding: {e}', 400

    # Parse the JSON data
    try:
        data_json = json.loads(data_decoded)
        print(f"Parsed JSON data: {data_json}")
    except Exception as e:
        print(f'Invalid JSON data: {e}')
        return f'Invalid JSON data: {e}', 400

    # Extract username, password, account, and shelterId from the data
    username = data_json.get('username')
    password = data_json.get('password')
    account = data_json.get('account')
    shelterId = data_json.get('shelterId')
    print(f"Username: {username}, Shelter ID: {shelterId}")

    if not username or not password or not account or not shelterId:
        print('Invalid request: username, password, account, and shelterId are required')
        return 'Invalid request: username, password, account, and shelterId are required', 400

    # Initialize Firestore document references using the shelterId
    print("Initializing Firestore references...")
    shelter_doc_ref = db.collection('shelters').document(shelterId)
    cats_ref = shelter_doc_ref.collection('cats')
    dogs_ref = shelter_doc_ref.collection('dogs')
    other_ref = shelter_doc_ref.collection('other')
    print("Firestore references initialized.")

    # Fetch and process animals
    print("Fetching all animals...")
    animals = fetch_all_animals(username, password, account)
    if animals is None:
        print("No animals fetched due to invalid credentials or an error.")
        return 'No animals fetched due to invalid credentials or an error.', 200
    print(f"Fetched {len(animals)} animals.")
    print("Updating Firestore...")
    update_firestore_optimized(animals, shelter_doc_ref, cats_ref, dogs_ref, other_ref, shelterId)
    print("Firestore update completed.")

    # Update the shelter document with the last sync times
    update_data = {
        "lastSync": firestore.SERVER_TIMESTAMP,
        "lastCatSync": firestore.SERVER_TIMESTAMP,
        "lastDogSync": firestore.SERVER_TIMESTAMP
    }
    try:
        shelter_doc_ref.update(update_data)
        print("Shelter document updated with last sync times.")
    except Exception as e:
        # Create the document if it doesn't exist
        shelter_doc_ref.set(update_data)
        print("Shelter document did not exist. Created new document with last sync times.")

    print("Finished updating shelter.")
    return 'Finished updating shelter', 200

def fetch_all_animals(username, password, account):
    print("Fetching all animals from sheltermanager API...")
    url = "https://service.sheltermanager.com/asmservice"
    params = {
        'account': account,
        'method': 'xml_shelter_animals',
        'username': username,
        'password': password
    }
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
    except Exception as e:
        print(f"Error fetching animals: {e}")
        print("Invalid credentials or other error occurred. Ending function gracefully.")
        return None  # Return None to indicate failure

    xml_data = response.text  # XML data as string

    # Parse the XML data
    animals = parse_animals_from_xml(xml_data, account)
    if animals is None:
        print("Failed to parse XML data. Ending function gracefully.")
        return None

    print(f"Total animals fetched: {len(animals)}")
    return animals

def parse_animals_from_xml(xml_data, account):
    """Parse animals data from an XML string using the detailed parse_animal function for each animal."""
    all_animals = []

    try:
        root = ET.fromstring(xml_data)  # Parse the XML string
    except ET.ParseError as e:
        print(f"XML parsing error: {e}")
        return None  # Return None to indicate failure

    # Find all <row> elements, each <row> represents an animal
    rows = root.findall('.//row')
    if not rows:
        print("No animals found in the XML data.")
        return []

    for row in rows:
        animal_data = {}
        for element in row:  # Iterate through each child element in <row>
            animal_data[element.tag] = element.text
        animal_data['account'] = account  # Add account to animal_data

        parsed_animal = parse_animal(animal_data)
        if parsed_animal:
            all_animals.append(parsed_animal)  # Add the parsed animal data to the list

    return all_animals

def parse_animal(animal_data):
    timestamp = datetime.now()
    animal_id = animal_data.get('ID') or animal_data.get('id')
    if not animal_id:
        print("Animal data missing ID, skipping.")
        return None

    name = animal_data.get('Name', '').strip() or animal_data.get('animalname', '').strip()
    # Remove parentheses from name
    name_without_parentheses = re.sub(r"\([^)]*\)", "", name).strip()

    animal_type = animal_data.get('Type', '').lower() or animal_data.get('petfinderspecies', '').lower()
    description = animal_data.get('Description', '') or ''
    sex = animal_data.get('sexname', '').lower()
    # age = animal_data.get('animalage')
    age = 20
    breed = animal_data.get('breedname', '')

    # For location
    location_unit = animal_data.get('shelterlocationunit', '') or ''
    location = animal_data.get('shelterlocation', '') or ''
    currentLocation = (location_unit + ' ' + location).strip() if location_unit or location else 'Unknown'
    full_location = currentLocation

    # Photos
    photos = []
    numberOfPhotos = animal_data.get('websiteimagecount')
    if numberOfPhotos:
        try:
            numberOfPhotos = int(numberOfPhotos)
        except ValueError:
            numberOfPhotos = 0
    else:
        numberOfPhotos = 0

    account = animal_data.get('account', '')
    animal_id_in_url = animal_id

    for photoNumber in range(1, numberOfPhotos + 1):
        photoString = str(photoNumber)
        photo_url = f'https://service.sheltermanager.com/asmservice?account={account}&method=animal_image&animalid={animal_id_in_url}&seq={photoString}'
        photo_id = str(uuid.uuid4())
        photos.append({
            'id': photo_id,
            'url': photo_url,
            'timestamp': timestamp,
            'source': 'asm'
        })

    # Intake date
    intake_date_text = animal_data.get('IntakeDate')
    if intake_date_text:
        # Parse the date, assuming a certain format
        try:
            # Assuming format 'YYYY-MM-DD'
            intake_date = datetime.strptime(intake_date_text, '%Y-%m-%d')
        except ValueError:
            intake_date = timestamp
    else:
        intake_date = timestamp

    # Map animal type to 'cat', 'dog', or 'other'
    if animal_type in ['cat', 'feline']:
        species = 'cat'
    elif animal_type in ['dog', 'canine']:
        species = 'dog'
    else:
        species = 'other'

    animal_data_dict = {
        'id': animal_id,
        'species': species,
        'name': name_without_parentheses,
        'takeOutAlert': '',
        'putBackAlert': '',
        'inKennel': True,
        'location': currentLocation,
        'fullLocation': full_location,
        'intakeDate': intake_date,
        'notes': [{
            'id': str(uuid.uuid4()),
            'timestamp': timestamp,
            'note': 'Added animal to the app',
            'author': "ShelterPartner"
        }],
        'logs': [{
            'id': str(uuid.uuid4()),
            'startTime': timestamp,
            'endTime': timestamp,
            'type': "Initial Log",
            'author': "ShelterPartner",
            'earlyReason': ''
        }],
        'photos': photos,
        'description': description,
        'sex': sex,
        'monthsOld': age,
        'breed': breed
    }
    print(f"Parsed animal data for ID {animal_id}")
    return animal_data_dict

def update_firestore_optimized(animals, shelter_doc_ref, cats_ref, dogs_ref, other_ref, shelterId):
    print("Starting Firestore update...")
    batch = db.batch()
    operations_count = 0
    max_batch_size = 499  # Firestore's limit per batch

    # Function to commit the batch and reset the counter
    def commit_batch():
        nonlocal batch, operations_count
        if operations_count > 0:
            print(f"Committing batch with {operations_count} operations.")
            batch.commit()
            batch = db.batch()  # Start a new batch
            operations_count = 0

    for animal in animals:
        if not animal['id']:
            print("Skipping animal with no ID.")
            continue

        if animal['species'] == 'cat':
            collection_ref = cats_ref
        elif animal['species'] == 'dog':
            collection_ref = dogs_ref
        else:
            collection_ref = other_ref
        animal_doc_ref = collection_ref.document(animal['id'])
        doc_snapshot = animal_doc_ref.get()
        
        # Get deleted phots for this animal
        deleted_photos_ref = animal_doc_ref = animal_doc_ref.collection('deleted_photos')
        deleted_photos = [doc.to_dict()['url'] for doc in deleted_photos_ref.stream()]

        if doc_snapshot.exists:
            # Fetching the existing data to compare if update is necessary
            existing_data = doc_snapshot.to_dict()
            update_data = {key: animal[key] for key in [
                'name', 'location', 'fullLocation', 'description',
                'sex', 'monthsOld', 'breed'
            ] if key in animal}
            
            # Filter out deleted photos from the update 
            if 'photos' in animal:
                # Kepp manually added photos from exisiting data
                existing_photos = existing_data.get('photos' , [])
                manually_added_photos = [p for p in existing_photos if p.get('source') == 'manual']
                
                # Filter out dellted photos form new photos
                new_photos = [p for p in animal['photos'] if p['url'] not in deleted_photos] 
                
                # Combine manually added phots with non deleted photos
                update_data['photos'] = manually_added_photos + new_photos
                
            batch.update(animal_doc_ref, update_data)
            print(f"Updated animal with ID {animal['id']}")
        else:
            # For new animals, filter out any photos that were previously deleted
            if 'photos' in animal:
                animal['photos'] = [p for p in animal['photos'] if p['url'] not in deleted_photos] 
                
            batch.set(animal_doc_ref, animal)  # Set the document if it does not exist
            print(f"Added new animal with ID {animal['id']}")

        operations_count += 1
        if operations_count >= max_batch_size:
            commit_batch()

    commit_batch()  # Commit any remaining operations
    print("All animals updated. Now checking for animals to delete.")

    # Now handle deletions with batch operations as well
    firestore_animals = fetch_firestore_animals(cats_ref, dogs_ref, other_ref)
    print(f"Firestore has {len(firestore_animals)} animals.")
    animals_to_delete = set(firestore_animals) - {animal['id'] for animal in animals if animal['id']}
    print(f"Found {len(animals_to_delete)} animals to delete.")

    for animal_id in animals_to_delete:
        print(f"Deleting animal with ID {animal_id}")
        delete_animal_if_exists(animal_id, cats_ref, dogs_ref, other_ref, shelterId)
        operations_count += 1
        if operations_count >= max_batch_size:
            commit_batch()

    commit_batch()  # Final commit if there are any operations left
    print("Firestore update optimized completed.")

def delete_animal_if_exists(animal_id, cats_ref, dogs_ref, other_ref, shelterId):
    cat_doc_ref = cats_ref.document(animal_id)
    dog_doc_ref = dogs_ref.document(animal_id)
    other_doc_ref = other_ref.document(animal_id)

    if cat_doc_ref.get().exists:
        cat_doc_ref.delete()
        delete_images_for_animal(animal_id, shelterId)
        print(f"Deleted cat with ID {animal_id}")
    elif dog_doc_ref.get().exists:
        dog_doc_ref.delete()
        delete_images_for_animal(animal_id, shelterId)
        print(f"Deleted dog with ID {animal_id}")
    elif other_doc_ref.get().exists:
        other_doc_ref.delete()
        delete_images_for_animal(animal_id, shelterId)
        print(f"Deleted other animal with ID {animal_id}")
    else:
        print(f"No animal with ID {animal_id} found to delete.")

def delete_images_for_animal(animal_id, shelterId):
    """Deletes all images for a given animal from Firebase Storage based on the animal's ID."""
    print(f"Deleting images for animal ID {animal_id}")
    bucket = storage_client.get_bucket('development-e5282')  # Replace with your actual bucket name
    images_prefix = f'{shelterId}/{animal_id}/'

    blobs = bucket.list_blobs(prefix=images_prefix)
    for blob in blobs:
        blob.delete()
        print(f"Deleted blob {blob.name}")
    print(f"All images for animal ID {animal_id} deleted.")

def fetch_firestore_animals(cats_ref, dogs_ref, other_ref):
    """Fetches IDs of all animals in Firestore for cats, dogs, and other animals"""
    print("Fetching animal IDs from Firestore...")
    firestore_animals = []
    for doc in cats_ref.stream():
        firestore_animals.append(doc.id)
    for doc in dogs_ref.stream():
        firestore_animals.append(doc.id)
    for doc in other_ref.stream():
        firestore_animals.append(doc.id)
    print(f"Fetched {len(firestore_animals)} animal IDs from Firestore.")
    return firestore_animals
