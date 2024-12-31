import firebase_admin
import json
from firebase_admin import auth, firestore
from flask import jsonify, request

# Initialize the Firebase app
firebase_admin.initialize_app()

def delete_volunteer(request):
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Authorization, Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return '', 204, headers

    # Check for the Authorization header to verify the Firebase ID token
    id_token = request.headers.get('Authorization')
    if not id_token or not id_token.startswith("Bearer "):
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return jsonify({'success': False, 'message': 'Unauthorized. No valid token provided.'}), 401, headers

    # Remove "Bearer " prefix
    id_token = id_token[len("Bearer "):]

    try:
        # Verify the Firebase ID token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']  # Get the user ID from the token
        print(f"User authenticated: {uid}")

    except Exception as e:
        print(f"Token verification failed: {str(e)}")
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return jsonify({"status": "error", "message": "Unauthorized"}), 401, headers

    # Get volunteer ID and shelterID from the query parameters
    id = request.args.get('id')
    shelter_id = request.args.get('shelterID')

    if not id or not shelter_id:
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return jsonify({'success': False, 'message': 'Volunteer ID and shelterID are required.'}), 400, headers

    try:
        # Initialize Firestore client
        db = firestore.client()

        # Delete the user from Firebase Auth
        auth.delete_user(id)
        
        # Delete the user from Firestore users collection
        db.collection('users').document(id).delete()

        # Remove the user from the volunteers array in the shelter document
        shelter_ref = db.collection('shelters').document(shelter_id)
        shelter_doc = shelter_ref.get()

        if shelter_doc.exists:
            volunteers = shelter_doc.to_dict().get('volunteers', [])
            
            # Filter out the volunteer with the specified ID
            updated_volunteers = [volunteer for volunteer in volunteers if volunteer.get('id') != id]
            
            # Update the shelter document with the new volunteers array
            shelter_ref.update({'volunteers': updated_volunteers})
        else:
            headers = {
                'Access-Control-Allow-Origin': '*'
            }
            return jsonify({'success': False, 'message': 'Shelter not found.'}), 404, headers

        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return jsonify({'success': True, 'message': 'Volunteer deleted successfully from Auth, Firestore, and shelter.'}), 200, headers

    except Exception as e:
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return jsonify({'success': False, 'message': str(e)}), 400, headers
