import functions_framework
from google.cloud import firestore
from flask import abort, jsonify, request
from datetime import datetime, timedelta

db = firestore.Client()

# Default rate limit values
DEFAULT_RATE_LIMIT = 1000
TIME_WINDOW = timedelta(days=30)  # 1 month

def to_datetime(firestore_timestamp):
    return datetime.fromtimestamp(firestore_timestamp.timestamp())

def check_and_update_rate_limit(shelterId):
    now = datetime.utcnow()
    shelterRef = db.collection('shelters').document(shelterId)
    shelterDoc = shelterRef.get()
    
    if not shelterDoc.exists:
        return False, 'Shelter not found'
    
    shelterData = shelterDoc.to_dict()
    
    # Accessing shelterSettings map
    shelterSettings = shelterData.get('shelterSettings', {})
    if not shelterSettings:
        return False, 'shelterSettings not found'

    requestCount = shelterSettings.get('requestCount', 0)
    lastReset = shelterSettings.get('lastReset')
    requestLimit = shelterSettings.get('requestLimit', DEFAULT_RATE_LIMIT)

    if lastReset:
        lastReset = to_datetime(lastReset)  # Convert Firestore timestamp to standard datetime
    else:
        lastReset = now

    # Check if we need to reset the count (new month)
    if now - lastReset >= TIME_WINDOW:
        requestCount = 0
        lastReset = now

    # Check if the request count exceeds the rate limit
    if requestCount >= requestLimit:
        return False, 'Rate limit exceeded'

    # Update the request count and last reset timestamp only if they exist
    shelterRef.update({
        'shelterSettings.requestCount': requestCount + 1,
        'shelterSettings.lastReset': lastReset
    })

    if 'requestLimit' not in shelterSettings:
        # Add rate limit field only if it doesn't exist
        shelterRef.update({
            'shelterSettings.requestLimit': DEFAULT_RATE_LIMIT
        })

    return True, None

@functions_framework.http
def validate_api_key_and_fetch_data(request):
    shelterId = request.args.get('shelterId')
    api_key = request.args.get('apiKey')
    species = request.args.get('species')

    if not shelterId or not api_key or not species:
        return abort(400, 'Missing shelterId, apiKey, or species')

    if species not in ['dogs', 'cats']:
        return abort(400, 'Invalid species. Must be "dogs" or "cats"')

    # Check and update rate limit
    rate_limit_ok, error_message = check_and_update_rate_limit(shelterId)
    if not rate_limit_ok:
        return abort(429, error_message)

    try:
        shelterRef = db.collection('shelters').document(shelterId)
        shelterDoc = shelterRef.get()
        if not shelterDoc.exists:
            return abort(404, 'Shelter not found')

        # Access shelterSettings to validate API key
        shelterData = shelterDoc.to_dict()
        shelterSettings = shelterData.get('shelterSettings', {})
        
        if not shelterSettings:
            return abort(404, 'shelterSettings not found')

        # Access the keys within shelterSettings
        apiKeys = shelterSettings.get('apiKeys', [])
        is_valid_api_key = any(key_obj['key'] == api_key for key_obj in apiKeys)

        if not is_valid_api_key:
            return abort(403, 'Invalid API Key')

        # Fetch the data from the specified subcollection (Dogs or Cats)
        animals_ref = shelterRef.collection(species)
        animals = [doc.to_dict() for doc in animals_ref.stream()]

        return jsonify(animals)

    except Exception as e:
        print(f'Error validating API key or fetching data: {e}')
        return abort(500, 'Internal Server Error')
