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
    # Parse JSON payload from the request
    request_json = request.get_json(silent=True)
    if not request_json:
        return 'Invalid request: No JSON payload found', 400

    # Check for 'message' and 'data' fields (Pub/Sub message format)
    message = request_json.get('message')
    if not message or 'data' not in message:
        return 'Invalid request: Missing `message` or `data` field.', 400

    # Decode the base64 data
    data_base64 = message['data']
    try:
        data_decoded = base64.b64decode(data_base64).decode('utf-8')
    except Exception as e:
        return f'Invalid data encoding: {e}', 400

    # Parse the JSON data
    try:
        data_json = json.loads(data_decoded)
    except Exception as e:
        return f'Invalid JSON data: {e}', 400

    # Extract apiKey and shelterId from the data
    api_key = data_json.get('apiKey')
    shelterId = data_json.get('shelterId')

    if not api_key or not shelterId:
        return 'Invalid request: apiKey and shelterId are required', 400

    # Initialize Firestore document references using the shelterId
    shelter_doc_ref = db.collection('shelters').document(shelterId)
    cats_ref = shelter_doc_ref.collection('cats')
    dogs_ref = shelter_doc_ref.collection('dogs')
    other_ref = shelter_doc_ref.collection('other')

    # Fetch shelter settings to determine photo filtering behavior
    try:
        shelter_doc = shelter_doc_ref.get()
        shelter_settings = shelter_doc.to_dict().get('shelterSettings', {}) if shelter_doc.exists else {}
        only_include_primary_photo = shelter_settings.get('onlyIncludePrimaryPhotoFromShelterLuv', True)
    except Exception as e:
        print(f"Error fetching shelter settings: {e}")
        only_include_primary_photo = True  # Default to true if error

    # Fetch and process animals
    try:
        animals, original_animals = fetch_all_animals(api_key)
        processed_animals = [parse_animal(animal, only_include_primary_photo) for animal in animals]
        update_firestore_optimized(processed_animals, shelter_doc_ref, cats_ref, dogs_ref, other_ref, shelterId)
    except requests.exceptions.HTTPError as e:
        # Check if the error indicates a revoked/invalid API key
        if e.response.status_code in [401, 403]:
            print(f"API key revoked or invalid for shelter {shelterId}. Clearing API key.")
            try:
                # Clear the API key by setting it to an empty string
                shelter_doc_ref.update({'shelterSettings.apiKey': ''})
                print(f"Successfully cleared API key for shelter {shelterId}")
                return f'API key revoked for shelter {shelterId}. Key has been cleared.', 200
            except Exception as clear_error:
                print(f"Error clearing API key for shelter {shelterId}: {clear_error}")
                return f'API key revoked but failed to clear: {clear_error}', 500
        else:
            # Re-raise the exception if it's not related to API key issues
            print(f"HTTP error {e.response.status_code} for shelter {shelterId}: {e}")
            raise
    except Exception as e:
        # Handle other types of exceptions
        print(f"Unexpected error fetching animals for shelter {shelterId}: {e}")
        raise

    # Update the shelter document with the last sync times
    try:
        update_data = {
            "lastSync": firestore.SERVER_TIMESTAMP,
            "lastCatSync": firestore.SERVER_TIMESTAMP,
            "lastDogSync": firestore.SERVER_TIMESTAMP
        }
        shelter_doc_ref.update(update_data)
    except Exception as e:
        # Create the document if it doesn't exist
        shelter_doc_ref.set(update_data)

    return 'Finished updating shelter', 200

def update_firestore_optimized(animals, shelter_doc_ref, cats_ref, dogs_ref, other_ref, shelterId):
    batch = db.batch()
    operations_count = 0
    max_batch_size = 499  # Firestore's limit per batch

    # Function to commit the batch and reset the counter
    def commit_batch():
        nonlocal batch, operations_count
        if operations_count > 0:
            batch.commit()
            batch = db.batch()  # Start a new batch
            operations_count = 0

    added_animals = []
    updated_animals = []
    removed_animals = []

    # Fetch existing Firestore animals
    firestore_animals = fetch_firestore_animals(cats_ref, dogs_ref, other_ref)
    firestore_animals_set = set(firestore_animals)

    for animal in animals:
        if not animal['id']:
            continue

        if animal['species'] == 'cat':
            collection_ref = cats_ref
        elif animal['species'] == 'dog':
            collection_ref = dogs_ref
        else:
            collection_ref = other_ref
        animal_doc_ref = collection_ref.document(animal['id'])
        doc_snapshot = animal_doc_ref.get()
        
        # Get deleted photos for this animal
        deleted_photos_ref = animal_doc_ref.collection('deleted_photos')
        deleted_photos = [doc.to_dict()['url'] for doc in deleted_photos_ref.stream()]

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
            
            # Filter out deleted photos from the update 
            if 'photos' in animal:
                # Keep manually added photos from existing data
                existing_photos = existing_data.get('photos', [])
                manually_added_photos = [p for p in existing_photos if p.get('source') == 'manual']
                
                # Filter out deleted photos from new ShelterLuv photos 
                new_shelterluv_photos = [p for p in animal['photos'] if p['url'] not in deleted_photos]
                
                # Combine manually added photos with new ShelterLuv photos
                # This automatically replaces all previous ShelterLuv photos with the new filtered set
                update_data['photos'] = manually_added_photos + new_shelterluv_photos

            # Check if any of the update fields have actually changed
            needs_update = False
            for key, new_value in update_data.items():
                existing_value = existing_data.get(key)
                if existing_value != new_value:
                    needs_update = True
                    break

            if needs_update:  # Only update if there's actually a change
                batch.update(animal_doc_ref, update_data)
                updated_animals.append(animal['id'])
        else:
            # For new animals, filter out any photos that were previously deleted
            if 'photos' in animal:
                animal['photos'] = [p for p in animal['photos'] if p['url'] not in deleted_photos]
                
            batch.set(animal_doc_ref, animal)  # Set the document if it does not exist
            added_animals.append(animal['id'])

        operations_count += 1
        if operations_count >= max_batch_size:
            commit_batch()

    commit_batch()
    # Mark removed animals as inactive instead of deleting them
    animals_to_mark_inactive = firestore_animals_set - {animal['id'] for animal in animals if animal['id']}
    for animal_id in animals_to_mark_inactive:
        mark_animal_as_inactive_if_exists(animal_id, cats_ref, dogs_ref, other_ref, shelterId)
        removed_animals.append(animal_id)
        operations_count += 1
        if operations_count >= max_batch_size:
            commit_batch()

    commit_batch()

    # Store the last sync changes
    shelter_doc_ref.update({
        "lastSync": firestore.SERVER_TIMESTAMP,
        "lastSyncChanges": {
            "added": added_animals,
            "updated": updated_animals,
            "removed": removed_animals  # These are actually marked inactive, not removed
        }
    })

def mark_animal_as_inactive_if_exists(animal_id, cats_ref, dogs_ref, other_ref, shelterId):
    """Mark an animal as inactive instead of deleting it, but still delete photos to save storage costs."""
    cat_doc_ref = cats_ref.document(animal_id)
    dog_doc_ref = dogs_ref.document(animal_id)
    other_doc_ref = other_ref.document(animal_id)

    if cat_doc_ref.get().exists:
        cat_doc_ref.update({'isActive': False})
        delete_images_for_animal(animal_id, shelterId)
    elif dog_doc_ref.get().exists:
        dog_doc_ref.update({'isActive': False})
        delete_images_for_animal(animal_id, shelterId)
    elif other_doc_ref.get().exists:
        other_doc_ref.update({'isActive': False})
        delete_images_for_animal(animal_id, shelterId)

def delete_images_for_animal(animal_id, shelterId):
    """Deletes all images for a given animal from Firebase Storage based on the animal's ID."""
    bucket = storage_client.get_bucket('production-10b3e.firebasestorage.app')
    images_prefix = f'{shelterId}/{animal_id}/'

    blobs = bucket.list_blobs(prefix=images_prefix)
    for blob in blobs:
        blob.delete()

def fetch_firestore_animals(cats_ref, dogs_ref, other_ref):
    """Fetches IDs of all active animals in Firestore for cats, dogs, and other animals"""
    firestore_animals = []
    # Only fetch active animals for comparison
    for doc in cats_ref.where('isActive', '==', True).stream():
        firestore_animals.append(doc.id)
    for doc in dogs_ref.where('isActive', '==', True).stream():
        firestore_animals.append(doc.id)
    for doc in other_ref.where('isActive', '==', True).stream():
        firestore_animals.append(doc.id)
    return firestore_animals

def fetch_all_animals(api_key):
    url = "https://www.shelterluv.com/api/v1/animals?status_type=in custody"
    headers = {"X-Api-Key": api_key}
    params = {"limit": 100, "offset": 0}
    all_original_animals = []
    all_animals = []

    while True:
        response = requests.get(url, headers=headers, params=params)
        try:
            response.raise_for_status()
        except Exception as e:
            raise
        data = response.json()

        animals = data.get('animals')
        if not animals:  # Break the loop if no animals are returned
            break

        all_animals.extend(animals)  # Keep raw animals
        all_original_animals.extend(animals)
        params["offset"] += params["limit"]

    return all_animals, all_original_animals

def parse_animal(animal, only_include_primary_photo=True):
    timestamp = datetime.now()
    name_without_parentheses = re.sub(r"\([^)]*\)", "", animal.get('Name', '')).strip()
    current_location = animal.get('CurrentLocation')
    currentLocation = 'Unknown'

    if isinstance(current_location, dict):
        tiers = ['Tier1', 'Tier2', 'Tier3', 'Tier4', 'Tier5']
        location_parts = [current_location.get(tier, '') for tier in tiers if tier in current_location]
        currentLocation = ' '.join(filter(None, location_parts)) or "Unknown"

    photos = []
    if animal.get('Photos'):
        photo_urls = animal.get('Photos')
        # If only_include_primary_photo is True, only take the first photo (CoverPhoto)
        # Otherwise, take all photos
        if only_include_primary_photo and photo_urls:
            photo_urls = [photo_urls[0]]  # Only the first photo (primary/cover photo)
            
        for photo_url in photo_urls:
            photo_id = str(uuid.uuid4())
            photos.append({
                'id': photo_id,
                'url': photo_url,
                'timestamp': timestamp,
                'author': 'Shelter Partner',
                'authorID': 'shelterluv_api',
                'source': 'shelterluv'
            })

    full_location = '>'.join(current_location.values()) if current_location else "Unknown"

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
        'isActive': True,  # All animals from ShelterLuv are active by default
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
    return animal_data
