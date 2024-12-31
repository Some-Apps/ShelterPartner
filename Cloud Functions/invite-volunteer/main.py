import functions_framework
import firebase_admin
from firebase_admin import auth
from firebase_admin import credentials
from google.cloud import firestore
import os
import json
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize Firebase Admin SDK
cred = credentials.ApplicationDefault()
firebase_admin.initialize_app(cred)
db = firestore.Client()

@functions_framework.http
def create_user(request):
    """HTTP Cloud Function with CORS support."""
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Authorization, Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return '', 204, headers

    # Get the ID token from the Authorization header
    id_token = request.headers.get('Authorization')
    if not id_token or not id_token.startswith("Bearer "):
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return json.dumps({"status": "error", "message": "Missing or invalid ID token"}), 401, headers

    id_token = id_token.split("Bearer ")[1]

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
        return json.dumps({"status": "error", "message": "Unauthorized"}), 401, headers

    # Parse the request body
    request_json = request.get_json(silent=True)
    if not request_json:
        print("Invalid request: No JSON payload received")
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return "Invalid request", 400, headers

    print(f"Received request: {request_json}")

    data = request_json.get('data', request_json)
    email = data.get('email')
    firstName = data.get('firstName')
    lastName = data.get('lastName')
    password = data.get('password')
    shelterID = data.get('shelterID')

    if not email or not firstName or not password or not shelterID:
        print("Missing parameters")
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return "Missing parameters", 400, headers

    try:
        # Create user in Firebase Authentication
        user = auth.create_user(
            email=email,
            password=password
        )

        # Add user details to Firestore
        doc_ref = db.collection('users').document(user.uid)
        doc_ref.set({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'shelterID': shelterID,
            'type': 'volunteer',
            'lastActivity': firestore.SERVER_TIMESTAMP,
            'averageLogDuration': 0,
            'totalTimeLogged': 0
        })

        # Add a reference to the user document in the shelter's 'volunteers' array
        user_ref = db.collection('users').document(user.uid)
        shelter_ref = db.collection('shelters').document(shelterID)
        shelter_ref.update({
            'volunteers': firestore.ArrayUnion([user_ref])
        })


        # Send invitation email
        subject = "Welcome To ShelterPartner"
        body = f"""
        <p>Hi {firstName},</p>
        <p>You've been invited to use <a href='https://apps.apple.com/us/app/pawpartner-shelter-app/id6449749673'>ShelterPartner</a>. Here are your credentials:</p>
        <p>Email: {email}<br>Password: {password}</p>
        <p>Thank you!</p>
        """

        if send_email(email, subject, body):
            headers = {
                'Access-Control-Allow-Origin': '*'
            }
            return json.dumps({"status": "success", "message": f"Invite sent to {email}"}), 200, headers
        else:
            headers = {
                'Access-Control-Allow-Origin': '*'
            }
            return json.dumps({"status": "error", "message": f"Failed to send invite to {email}"}), 500, headers

    except Exception as e:
        print(f"Error: {str(e)}")
        headers = {
            'Access-Control-Allow-Origin': '*'
        }
        return json.dumps({"status": "error", "message": str(e)}), 500, headers

def send_email(to_email, subject, body):
    try:
        msg = MIMEMultipart()
        msg['From'] = os.getenv("emailAddress")
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'html'))

        username = os.getenv("emailAddress")
        password = os.getenv("emailPassword")

        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(username, password)
            server.send_message(msg)

        print(f"Invite sent to {to_email}")
        return True
    except Exception as e:
        print(f"Failed to send invite to {to_email}: {str(e)}")
        return False
