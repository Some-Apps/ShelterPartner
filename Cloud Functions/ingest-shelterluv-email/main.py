import base64
import json
import functions_framework
import imaplib
import email
import os
import re
from google.cloud import firestore
from google.api_core import exceptions
import requests
from datetime import datetime, timedelta
from pytz import timezone
import pandas as pd
import ast

# Initialize Firestore client
db = firestore.Client()

@functions_framework.cloud_event
def shelterluv_sync(cloud_event):
    """
    Triggered by a Pub/Sub message containing ShelterLuv credentials.
    """
    shelter_id = None  # Initialize shelter_id at the start
    
    try:
        # Get the Pub/Sub message and properly decode it
        pubsub_message = cloud_event.data["message"]
        message_data = base64.b64decode(pubsub_message["data"]).decode()
        
        # Try multiple approaches to parse the message data
        try:
            # First attempt: direct JSON parsing
            message = json.loads(message_data)
        except json.JSONDecodeError:
            try:
                # Second attempt: evaluate as string literal and convert to JSON-friendly format
                message = ast.literal_eval(message_data)
            except (ValueError, SyntaxError):
                try:
                    # Third attempt: replace single quotes with double quotes
                    message_data = message_data.replace("'", '"')
                    message = json.loads(message_data)
                except json.JSONDecodeError as e:
                    print(f"Failed to parse message data: {message_data}")
                    print(f"Error: {str(e)}")
                    return

        shelter_id = message.get('shelterId')
        api_key = message.get('apiKey')
        
        if not all([shelter_id, api_key]):
            print(f"Missing required credentials in message. Message content: {message}")
            return

        print(f"Processing ShelterLuv sync for shelter: {shelter_id}")

        # Email setup
        username = os.environ.get("EMAIL_ADDRESS")
        password = os.environ.get("EMAIL_PASSWORD")
        
        mail = imaplib.IMAP4_SSL("imap.gmail.com")
        mail.login(username, password)
        mail.select('"[Gmail]/All Mail"')
        
        # Calculate date range for email search
        server_tz = timezone('US/Central')
        server_date = datetime.now(server_tz)
        current_date_str = server_date.strftime("%m/%d/%Y")
        
        # Search for ShelterLuv emails with the shelter ID
        subject_search = shelter_id
        result, data = mail.uid('search', None, f'(SUBJECT "{subject_search}")')
        
        if result != 'OK':
            print(f"Failed to search emails for shelter {shelter_id}")
            return
            
        email_ids = data[0].split()
        if not email_ids:
            print(f"No emails found for shelter {shelter_id}")
            return
            
        # Process the latest email
        latest_email_uid = email_ids[-1]
        result, email_data = mail.uid('fetch', latest_email_uid, '(BODY[])')
        raw_email = email_data[0][1]
        email_message = email.message_from_bytes(raw_email)
        
        # Process email and extract links
        if email_message.is_multipart():
            for part in email_message.walk():
                if part.get_content_type() == "text/plain":
                    text_content = part.get_payload(decode=True).decode()
                    links = re.findall(r"(?<=paste this into your browser: \r\n)http://track.shelterluv.com.*?(?=\r)", text_content)
                    if not links:
                        print("Regex didn't work")
                    for link in links:
                        try:
                            download_file_from_link(links[-1], '/tmp/downloaded_file.xlsx')
                            print(f"Downloaded file from {link}")
                        except Exception as e:
                            print(f"Error downloading file: {e}")
                        break
        else:
            text_content = email_message.get_payload(decode=True).decode()
            links = re.findall(r"(?<=paste this into your browser: \r\n)http://track.shelterluv.com.*?(?=\r)", text_content)
            for link in links:
                try:
                    download_file_from_link(links[-1], '/tmp/downloaded_file.xlsx')
                    print(f"Downloaded file from {link}")
                except Exception as e:
                    print(f"Error downloading file: {e}")

        # Read and process the Excel file
        df = pd.read_excel('/tmp/downloaded_file.xlsx')
        
        # Process the data
        shelter_ref = db.collection('shelters').document(shelter_id)
        cats_ref = shelter_ref.collection('Cats')
        dogs_ref = shelter_ref.collection('Dogs')
        
        sync_df_to_firestore(df, cats_ref, dogs_ref)

        # Update Firestore timestamps
        try:
            update_data = {
                "lastSync": firestore.SERVER_TIMESTAMP,
                "lastCatSync": firestore.SERVER_TIMESTAMP,
                "lastDogSync": firestore.SERVER_TIMESTAMP
            }
            shelter_ref.update(update_data)
        except exceptions.NotFound:
            shelter_ref.set({
                "lastSync": firestore.SERVER_TIMESTAMP,
                "lastCatSync": firestore.SERVER_TIMESTAMP,
                "lastDogSync": firestore.SERVER_TIMESTAMP
            })
        
        print(f"Successfully processed ShelterLuv sync for shelter: {shelter_id}")
        
    except Exception as e:
        error_message = f"Error processing ShelterLuv sync"
        if shelter_id:
            error_message += f" for shelter {shelter_id}"
        error_message += f": {str(e)}"
        print(error_message)
        raise e
    finally:
        # Close email connection if it exists
        if 'mail' in locals():
            try:
                mail.close()
                mail.logout()
            except:
                pass

def download_file_from_link(link, destination_path):
    """Download a file from the provided link to the specified destination path."""
    response = requests.get(link)
    if response.status_code == 200:
        with open(destination_path, 'wb') as file:
            file.write(response.content)
    else:
        raise Exception(f"Failed to download file: Status code {response.status_code}")

def sync_df_to_firestore(df, cats_ref, dogs_ref):
    """Sync DataFrame data to Firestore collections."""
    existing_cats = {doc.id for doc in cats_ref.stream()}
    existing_dogs = {doc.id for doc in dogs_ref.stream()}

    batch = db.batch()

    for _, row in df.iterrows():
        animal_id = row['Animal ID'].split('-')[-1]
        color = row['Volunteer Category']
        symbol = 'pawprint.fill'
        adoptionGroup = row['Adoption Category']
        behaviorGroup = row['Behavior Category']
        medicalGroup = row['Medical Category']

        # Set default color to black if the cell is empty
        if pd.isna(color) or color.strip() == "":
            color = "clear"
            colorGroup = "​Unknown Group"

        # Define colorGroup based on color value
        if 'staff only' in color.lower():
            color = 'red'
            colorGroup = 'Staff Only'
            symbol = "exclamationmark.octagon.fill"
        elif 'red' in color.lower():
            color = 'red'
            colorGroup = 'Red'
        elif 'blue' in color.lower():
            color = 'blue'
            colorGroup = 'Blue'
        elif 'green' in color.lower():
            color = 'green'
            colorGroup = 'Green'
        elif 'silver' in color.lower():
            color = 'gray'
            colorGroup = 'Gray'
        elif 'black' in color.lower():
            color = 'black'
            colorGroup = 'Black'
        elif 'orange' in color.lower():
            color = 'orange'
            colorGroup = 'Orange'
        elif 'pink' in color.lower():
            color = 'pink'
            colorGroup = 'Pink'
        elif 'purple' in color.lower():
            color = 'purple'
            colorGroup = 'Purple'
        elif 'yellow' in color.lower():
            color = 'yellow'
            colorGroup = 'Yellow'
        elif 'brown' in color.lower():
            color = 'brown'
            colorGroup = 'Brown'
        else:
            colorGroup = "​Unknown Group"

        # Check if the animal exists in either the Cats or Dogs collection
        if animal_id in existing_cats:
            doc_ref = cats_ref.document(animal_id)
        elif animal_id in existing_dogs:
            doc_ref = dogs_ref.document(animal_id)
        else:
            # Skip the animal if it does not exist in either collection
            continue

        # Update or set data in the Firestore document
        data = {
            'symbol': symbol,
            'symbolColor': color,
        }

        if pd.isna(behaviorGroup) or behaviorGroup.strip() == "":
            data['behaviorGroup'] = firestore.DELETE_FIELD
        else:
            data['behaviorGroup'] = behaviorGroup

        if pd.isna(adoptionGroup) or adoptionGroup.strip() == "":
            data['adoptionGroup'] = firestore.DELETE_FIELD
        else:
            data['adoptionGroup'] = adoptionGroup

        if pd.isna(medicalGroup) or medicalGroup.strip() == "":
            data['medicalGroup'] = firestore.DELETE_FIELD
        else:
            data['medicalGroup'] = medicalGroup

        batch.update(doc_ref, data)

    batch.commit()