import functions_framework
import imaplib
import email
import os
import base64
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import pubsub_v1

# Initialize Firebase
firebase_admin.initialize_app()
firestore_client = firestore.client()

# Initialize Pub/Sub client
publisher = pubsub_v1.PublisherClient()
project_id = "development-e5282"

@functions_framework.http
def shelter_email_publisher(request):
    """
    Cloud Function to process emails and publish messages based on shelter IDs.
    """
    # Retrieve email credentials from environment variables
    username = os.environ.get('EMAIL_ADDRESS')
    password = os.environ.get('EMAIL_PASSWORD')

    try:
        # Connect to Gmail IMAP server
        mail = imaplib.IMAP4_SSL("imap.gmail.com")
        mail.login(username, password)
        mail.select('"[Gmail]/All Mail"')  # or use 'INBOX'

        # Calculate timestamp for 2 hours ago
        two_hours_ago = (datetime.utcnow() - timedelta(hours=2)).strftime('%d-%b-%Y')
        
        # Search for emails within the last 2 hours
        result, data = mail.uid('search', None, f'(SINCE {two_hours_ago})')
        
        if result == 'OK':
            email_ids = data[0].split()
            print(f'Found {len(email_ids)} emails in the last 2 hours.')

            # Fetch all shelters from Firestore
            shelters_ref = firestore_client.collection('shelters')
            shelters = shelters_ref.stream()
            shelter_docs = {doc.id: doc.to_dict() for doc in shelters}
            
            print(f'Fetched {len(shelter_docs)} shelters.')

            # Process each email
            for email_uid in email_ids:
                # Fetch the email
                result, email_data = mail.uid('fetch', email_uid, '(BODY[])')
                raw_email = email_data[0][1]
                email_message = email.message_from_bytes(raw_email)

                # Extract subject
                subject = ''
                for header in email_message.get_all('subject', []):
                    decoded_header = email.header.decode_header(header)
                    subject = decoded_header[0][0]
                    if isinstance(subject, bytes):
                        subject = subject.decode()
                
                print(f'Processing email with subject: {subject}')

                # Check if subject matches any shelter document ID
                if subject in shelter_docs:
                    shelter_id = subject
                    shelter_data = shelter_docs[shelter_id]
                    management_software = shelter_data.get('managementSoftware')
                    
                    if not management_software:
                        print(f'No management software for shelter {shelter_id}')
                        continue
                    
                    # Determine topic and data based on management software
                    topic_name = None
                    data = None
                    
                    if management_software == 'ShelterLuv':
                        api_key = shelter_data.get('shelterSettings', {}).get('apiKey')
                        if not api_key:
                            print(f'No API key for ShelterLuv shelter {shelter_id}')
                            continue
                        topic_name = 'ingest-shelterluv-email'
                        data = {
                            'apiKey': api_key,
                            'shelterId': shelter_id
                        }
                    

                    
                    elif management_software == 'Animals First':
                        api_key = shelter_data.get('shelterSettings', {}).get('apiKey')
                        if not api_key:
                            print(f'No API key for Animals First shelter {shelter_id}')
                            continue
                        
                        topic_name = 'animals-first-topic'
                        data = {
                            'apiKey': api_key,
                            'shelterId': shelter_id
                        }
                    
                    else:
                        print(f'Unknown management software for shelter {shelter_id}: {management_software}')
                        continue
                    
                    # Publish message to Pub/Sub
                    if topic_name and data:
                        try:
                            topic_path = publisher.topic_path(project_id, topic_name)
                            data_str = str(data).encode('utf-8')
                            future = publisher.publish(topic_path, data_str)
                            print(f'Published message for shelter {shelter_id}: {future.result()}')
                        except Exception as e:
                            print(f'Error publishing message for shelter {shelter_id}: {e}')

        # Close the IMAP connection
        mail.close()
        mail.logout()
        
        return 'Email processing completed successfully', 200
    
    except Exception as e:
        print(f'Error in email processing: {e}')
        return f'Error processing emails: {e}', 500