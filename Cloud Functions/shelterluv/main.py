import functions_framework
import requests
from google.cloud import firestore
from google.cloud import storage
from datetime import datetime, timedelta
import uuid
import re
import base64
import json  # Import json module for parsing

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
        print('Invalid request: Missing `message` or `data` field.')
        return 'Invalid request: Missing `message` or `data` field.', 400
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

    # Extract apiKey and shelterId from the data
    api_key = data_json.get('apiKey')
    shelterId = data_json.get('shelterId')
    print(f"API Key: {api_key}, Shelter ID: {shelterId}")

    if not api_key or not shelterId:
        print('Invalid request: apiKey and shelterId are required')
        return 'Invalid request: apiKey and shelterId are required', 400

    # Initialize Firestore document references using the shelterId
    print("Initializing Firestore references...")
    shelter_doc_ref = db.collection('shelters').document(shelterId)
    cats_ref = shelter_doc_ref.collection('cats')
    dogs_ref = shelter_doc_ref.collection('dogs')
    other_ref = shelter_doc_ref.collection('other')
    print("Firestore references initialized.")

    # Fetch and process animals
    print("Fetching all animals...")
    animals, original_animals = fetch_all_animals(api_key)
    print(f"Fetched {len(animals)} animals.")
    print("Updating Firestore...")
    update_firestore_optimized(animals, shelter_doc_ref, cats_ref, dogs_ref, other_ref, shelterId)
    print("Firestore update completed.")

    # Update the shelter document with the last sync times
    try:
        update_data = {
            "lastSync": firestore.SERVER_TIMESTAMP,
            "lastCatSync": firestore.SERVER_TIMESTAMP,
            "lastDogSync": firestore.SERVER_TIMESTAMP
        }
        shelter_doc_ref.update(update_data)
        print("Shelter document updated with last sync times.")
    except Exception as e:
        # Create the document if it doesn't exist
        shelter_doc_ref.set(update_data)
        print("Shelter document did not exist. Created new document with last sync times.")

    print("Finished updating shelter.")
    return 'Finished updating shelter', 200

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

        if doc_snapshot.exists:
            # Fetching the existing data to compare if update is necessary
            existing_data = doc_snapshot.to_dict()
            update_data = {key: animal[key] for key in [
                'name', 'location', 'fullLocation', 'description',
                'sex', 'monthsOld', 'breed'
            ] if key in animal}
            # Conditionally update 'photos' if specific criteria are met
            if 'photos' not in existing_data or len(existing_data['photos']) < 1:
                update_data['photos'] = animal.get('photos', [])
            batch.update(animal_doc_ref, update_data)
            print(f"Updated animal with ID {animal['id']}")
        else:
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
    bucket = storage_client.get_bucket('development-e5282.appspot.com')
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

def fetch_all_animals(api_key):
    print("Fetching all animals from external API...")
    url = "https://www.shelterluv.com/api/v1/animals?status_type=in custody"
    headers = {"X-Api-Key": api_key}
    params = {"limit": 100, "offset": 0}
    all_original_animals = []
    all_animals = []

    while True:
        print(f"Fetching animals with offset {params['offset']}")
        response = requests.get(url, headers=headers, params=params)
        try:
            response.raise_for_status()
        except Exception as e:
            print(f"Error fetching animals: {e}")
            raise
        data = response.json()

        animals = data.get('animals')
        if not animals:  # Break the loop if no animals are returned
            print("No more animals returned from API.")
            break

        print(f"Fetched {len(animals)} animals from API.")
        all_animals.extend([parse_animal(animal) for animal in animals])
        all_original_animals.extend(animals)
        params["offset"] += params["limit"]

    print(f"Total animals fetched: {len(all_animals)}")
    return all_animals, all_original_animals

def parse_animal(animal):
    timestamp = datetime.now()
    name_without_parentheses = re.sub(r"\([^)]*\)", "", animal.get('Name', '')).strip()
    current_location = animal.get('CurrentLocation')
    currentLocation = 'Unknown'

    if isinstance(current_location, dict):
        tiers = ['Tier1', 'Tier2', 'Tier3', 'Tier4', 'Tier5']
        location_parts = [current_location.get(tier, '') for tier in tiers if tier in current_location]
        currentLocation = ' '.join(filter(None, location_parts))

    photos = []
    if animal.get('Photos'):
        for photo_url in animal.get('Photos'):
            photo_id = str(uuid.uuid4())
            photos.append({
                'id': photo_id,
                'url': photo_url,
                'timestamp': timestamp
            })

    full_location = ' '.join(current_location.values()) if current_location else "Unknown"

    intake_timestamp = animal.get('LastIntakeUnixTime')
    if intake_timestamp is not None:
        intake_date = datetime.fromtimestamp(int(intake_timestamp))
    else:
        intake_date = timestamp

    animal_data = {
        'id': animal.get('ID'),
        'species': animal.get('Type').lower(),
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
        'description': animal.get('Description'),
        'sex': animal.get('Sex', '').lower(),
        'monthsOld': animal.get('Age'),
        'breed': animal.get('Breed')
    }
    print(f"Parsed animal data for ID {animal.get('ID')}")
    return animal_data
