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
from datetime import datetime
from pytz import timezone
import pandas as pd
import ast

# Initialize Firestore client
print("[DEBUG] Initializing Firestore client...")
db = firestore.Client()
print("[DEBUG] Firestore client initialized successfully.")

print("[DEBUG] Firestore project id:", db.project)

@functions_framework.cloud_event
def shelterluv_sync(cloud_event):
    """
    Triggered by a Pub/Sub message containing ShelterLuv credentials.
    We now use the shortUUID from the shelter doc's shelterSettings map
    to search for matching emails, rather than the shelter ID.
    """
    print("[DEBUG] shelterluv_sync function triggered by CloudEvent.")
    print(f"[DEBUG] Full CloudEvent data: {cloud_event.data}")
    
    shelter_id = None  # Initialize shelter_id at the start
    print("[DEBUG] shelter_id variable initialized to None.")

    try:
        print("[DEBUG] Attempting to retrieve pubsub_message from cloud_event data...")
        pubsub_message = cloud_event.data["message"]
        print(f"[DEBUG] pubsub_message retrieved: {pubsub_message}")

        print("[DEBUG] Attempting to retrieve 'data' field from pubsub_message...")
        raw_data = pubsub_message.get("data")
        print(f"[DEBUG] raw_data retrieved: {raw_data}")

        if not raw_data:
            print("[DEBUG] raw_data is empty or None. Exiting function.")
            return
        
        print("[DEBUG] Decoding the base64-encoded raw_data...")
        message_data = base64.b64decode(raw_data).decode()
        print(f"[DEBUG] message_data after base64 decode: '{message_data}'")

        if not message_data:
            print("[DEBUG] Decoded message_data is empty or None. Exiting function.")
            return

        # ---------------------------
        # Parsing the message_data
        # ---------------------------
        print("[DEBUG] Attempting first parse attempt with json.loads...")
        try:
            message = json.loads(message_data)
            print("[DEBUG] First parse attempt with json.loads() succeeded.")
        except json.JSONDecodeError as e_json:
            print(f"[DEBUG] json.loads() failed with error: {e_json}")
            print("[DEBUG] Attempting second parse attempt with ast.literal_eval...")
            try:
                message = ast.literal_eval(message_data)
                print("[DEBUG] ast.literal_eval() succeeded.")
            except (ValueError, SyntaxError) as e_ast:
                print(f"[DEBUG] ast.literal_eval() also failed with error: {e_ast}")
                print("[DEBUG] Attempting final fallback: replace single quotes with double quotes.")
                
                if message_data is None:
                    print("[DEBUG] message_data is None before replace(). Exiting function.")
                    return
                
                try:
                    print("[DEBUG] Replacing single quotes in message_data with double quotes.")
                    message_data = message_data.replace("'", '"')
                    print(f"[DEBUG] message_data after replace(): '{message_data}'")
                    message = json.loads(message_data)
                    print("[DEBUG] Final parse attempt with json.loads() succeeded after replace().")
                except json.JSONDecodeError as e_final:
                    print(f"[DEBUG] Final parse attempt failed with error: {e_final}")
                    print("[DEBUG] Exiting function after failed parsing.")
                    return

        print("[DEBUG] Checking for 'shelterId' and 'apiKey' in the parsed message...")
        shelter_id = message.get('shelterId')
        api_key = message.get('apiKey')
        print(f"[DEBUG] shelter_id = {shelter_id}")
        print(f"[DEBUG] api_key = {api_key}")

        if not all([shelter_id, api_key]):
            print("[DEBUG] Either 'shelterId' or 'apiKey' is missing. Exiting function.")
            print(f"[DEBUG] Current message content: {message}")
            return

        print(f"[DEBUG] Starting ShelterLuv sync for shelter: {shelter_id}")

        # ------------------------------------------------------
        # Instead of subject = shelter_id, we retrieve shortUUID
        # ------------------------------------------------------
        print(f"[DEBUG] Fetching shelter doc from Firestore for ID: {shelter_id}")
        shelter_ref = db.collection('shelters').document(shelter_id)
        shelter_snapshot = shelter_ref.get()

        if email_date:
            print("[DEBUG] Storing email sync date in Firestore...")
            try:
                shelter_ref.update({"lastEmailSync": email_date})
                print("[DEBUG] Last sync date stored successfully in Firestore.")
            except exceptions.GoogleCloudError as e_firestore:
                print(f"[DEBUG] Error updating Firestore with lastSync date: {e_firestore}")

        
        if not shelter_snapshot.exists:
            print(f"[DEBUG] Shelter doc '{shelter_id}' not found in Firestore. Exiting.")
            return
        
        shelter_data = shelter_snapshot.to_dict()
        print(f"[DEBUG] Shelter doc data retrieved: {shelter_data}")
        
        # Get shortUUID from shelterSettings
        short_uuid = shelter_data.get('shelterSettings', {}).get('shortUUID')
        print(f"[DEBUG] shortUUID found: {short_uuid}")
        
        if not short_uuid:
            print("[DEBUG] This shelter doc does not have a shortUUID in shelterSettings. Exiting.")
            return

        # ---------------------------
        # Email setup
        # ---------------------------
        print("[DEBUG] Retrieving EMAIL_ADDRESS and EMAIL_PASSWORD from environment variables...")
        username = os.environ.get("EMAIL_ADDRESS")
        password = os.environ.get("EMAIL_PASSWORD")
        print(f"[DEBUG] Retrieved username: {username}")
        # IMPORTANT: Avoid printing actual passwords in real environments, but shown here for thoroughness:
        print(f"[DEBUG] Retrieved password: {password}")

        print("[DEBUG] Attempting to create IMAP4_SSL connection to Gmail...")
        mail = imaplib.IMAP4_SSL("imap.gmail.com")
        print("[DEBUG] IMAP4_SSL connection created successfully.")

        print("[DEBUG] Attempting to log in to Gmail account...")
        mail.login(username, password)
        print("[DEBUG] Logged in successfully.")

        print('[DEBUG] Selecting the mailbox: "[Gmail]/All Mail"...')
        mail.select('"[Gmail]/All Mail"')
        print("[DEBUG] Mailbox selected successfully.")

        # ---------------------------
        # Date/time for logging
        # ---------------------------
        print("[DEBUG] Calculating current time in US/Central timezone for logging...")
        server_tz = timezone('US/Central')
        server_date = datetime.now(server_tz)
        current_date_str = server_date.strftime("%m/%d/%Y")
        print(f"[DEBUG] Current date/time in US/Central: {server_date} (formatted: {current_date_str})")

        # ---------------------------
        # Searching emails
        # ---------------------------
        print(f"[DEBUG] We will now search for emails with subject containing '{short_uuid}'.")
        subject_search = short_uuid
        print(f"[DEBUG] Executing mail.uid search with subject_search: {subject_search}")
        result, data = mail.uid('search', None, f'(SUBJECT "{subject_search}")')
        print(f"[DEBUG] search result: {result}, raw data: {data}")

        if result != 'OK':
            print(f"[DEBUG] Mail search failed (result != 'OK'). Exiting function.")
            return

        print("[DEBUG] Splitting email_ids from data.")
        email_ids = data[0].split()
        print(f"[DEBUG] Found {len(email_ids)} matching email(s). email_ids: {email_ids}")

        if not email_ids:
            print(f"[DEBUG] No emails found using shortUUID '{short_uuid}'. Exiting function.")
            return
        
        # ---------------------------
        # Processing the latest email
        # ---------------------------
        latest_email_uid = email_ids[-1]
        print(f"[DEBUG] Latest email UID is: {latest_email_uid}")
        print("[DEBUG] Fetching the latest email data...")
        result, email_data = mail.uid('fetch', latest_email_uid, '(BODY[])')

        raw_email = email_data[0][1]
        print("[DEBUG] Constructing email_message from raw bytes...")
        email_message = email.message_from_bytes(raw_email)
        print("[DEBUG] email_message created successfully.")

        # Extract the email date
        email_date_str = email_message["Date"]
        print(f"[DEBUG] Extracted email date string: {email_date_str}")

        # Convert to a datetime object
        try:
            email_date = email.utils.parsedate_to_datetime(email_date_str)
            print(f"[DEBUG] Parsed email date: {email_date}")
        except Exception as e_date:
            print(f"[DEBUG] Error parsing email date: {e_date}")
            email_date = None

        print(f"[DEBUG] Fetch result: {result}")

        raw_email = email_data[0][1]
        print("[DEBUG] Constructing email_message from raw bytes...")
        email_message = email.message_from_bytes(raw_email)
        print("[DEBUG] email_message created successfully.")

        # ---------------------------
        # Extract links from email
        # ---------------------------
        print("[DEBUG] Checking if email_message is multipart...")
        if email_message.is_multipart():
            print("[DEBUG] Email is multipart. Walking through its parts...")
            for part in email_message.walk():
                content_type = part.get_content_type()
                print(f"[DEBUG] Found part with content_type = {content_type}")
                if content_type == "text/plain":
                    print("[DEBUG] This part is text/plain, attempting to decode...")
                    text_content = part.get_payload(decode=True).decode()
                    print(f"[DEBUG] text_content length: {len(text_content)} characters")
                    print("[DEBUG] Attempting to find links using regex: r'(?<=instead: )https://new\\.shelterluv\\.com[^\\s]+'")
                    links = re.findall(r"(?<=instead: )https://new\.shelterluv\.com[^\s]+", text_content)
                    print(f"[DEBUG] Found {len(links)} link(s) in text_content: {links}")
                    
                    if not links:
                        print("[DEBUG] Regex didn't find any links matching the pattern in this part.")
                    else:
                        last_link = links[-1]
                        print(f"[DEBUG] Attempting to download file from the last link found: {last_link}")
                        try:
                            download_file_from_link(last_link, '/tmp/downloaded_file.xlsx')
                            print(f"[DEBUG] File downloaded successfully from {last_link}")
                        except Exception as e_dl:
                            print(f"[DEBUG] Exception during file download: {e_dl}")
                    print("[DEBUG] Stopping after first text/plain part.")
                    break
        else:
            print("[DEBUG] Email is not multipart, attempting to decode the payload...")
            text_content = email_message.get_payload(decode=True).decode()
            print(f"[DEBUG] text_content length: {len(text_content)} characters")
            print("[DEBUG] Attempting regex search for ShelterLuv links...")
            links = re.findall(r"(?<=instead: )https://new\.shelterluv\.com[^\s]+", text_content)
            print(f"[DEBUG] Found {len(links)} link(s) in text_content: {links}")
            
            if not links:
                print("[DEBUG] Regex didn't find any links in non-multipart email.")
            else:
                last_link = links[-1]
                print(f"[DEBUG] Attempting to download file from the last link found: {last_link}")
                try:
                    download_file_from_link(last_link, '/tmp/downloaded_file.xlsx')
                    print(f"[DEBUG] File downloaded successfully from {last_link}")
                except Exception as e_dl:
                    print(f"[DEBUG] Exception during file download: {e_dl}")

        # ---------------------------
        # Reading the downloaded Excel file
        # ---------------------------
        print("[DEBUG] Attempting to read Excel file from /tmp/downloaded_file.xlsx")
        df = pd.read_excel('/tmp/downloaded_file.xlsx')
        print(f"[DEBUG] Excel file read successfully, shape of DataFrame: {df.shape}")

        # ---------------------------
        # Firestore refs (already got shelter_ref above)
        # ---------------------------
        print("[DEBUG] Getting Firestore sub-collections: Cats, Dogs...")
        cats_ref = shelter_ref.collection('cats')
        dogs_ref = shelter_ref.collection('dogs')

        print("[DEBUG] Starting sync_df_to_firestore...")
        sync_df_to_firestore(df, cats_ref, dogs_ref, shelter_id)
        print("[DEBUG] sync_df_to_firestore completed.")

        # ---------------------------
        # Updating Firestore timestamps
        # ---------------------------
        print("[DEBUG] Attempting to update Firestore document timestamps...")
        try:
            update_data = {
                "lastSync": firestore.SERVER_TIMESTAMP,
                "lastCatSync": firestore.SERVER_TIMESTAMP,
                "lastDogSync": firestore.SERVER_TIMESTAMP
            }
            shelter_ref.update(update_data)
            print("[DEBUG] shelter_ref.update() completed successfully.")
        except exceptions.NotFound:
            print("[DEBUG] Document not found; attempting to create it with initial timestamps.")
            shelter_ref.set({
                "lastSync": firestore.SERVER_TIMESTAMP,
                "lastCatSync": firestore.SERVER_TIMESTAMP,
                "lastDogSync": firestore.SERVER_TIMESTAMP
            })
            print("[DEBUG] shelter_ref.set() completed successfully.")

        print(f"[DEBUG] Successfully processed ShelterLuv sync for shelter: {shelter_id}, shortUUID='{short_uuid}'")

    except Exception as e:
        error_message = f"Error processing ShelterLuv sync"

        if shelter_id:
            error_message += f" for shelter {shelter_id}"
        error_message += f": {str(e)}"
        print(f"[DEBUG] {error_message}")
        raise e
    finally:
        # Attempting to close email connection if it exists
        if 'mail' in locals():
            print("[DEBUG] Attempting to close IMAP connection...")
            try:
                mail.close()
                mail.logout()
                print("[DEBUG] IMAP connection closed and logged out successfully.")
            except Exception as e_mail:
                print(f"[DEBUG] Exception while closing/logging out of mail: {e_mail}")

def download_file_from_link(link, destination_path):
    """Download a file from the provided link to the specified destination path."""
    print(f"[DEBUG] download_file_from_link called with link='{link}', destination_path='{destination_path}'")
    response = requests.get(link)
    print(f"[DEBUG] HTTP GET request completed with status_code={response.status_code}")
    if response.status_code == 200:
        with open(destination_path, 'wb') as file:
            file.write(response.content)
        print(f"[DEBUG] File written to {destination_path} successfully.")
    else:
        error_msg = f"Failed to download file: Status code {response.status_code}"
        print(f"[DEBUG] {error_msg}")
        raise Exception(error_msg)

def sync_df_to_firestore(df, cats_ref, dogs_ref, shelter_id):
    """Sync DataFrame data to Firestore collections."""
    print("[DEBUG] Entering sync_df_to_firestore.")
    print("[DEBUG] Streaming existing documents in Cats collection to create a set of IDs.")
    existing_cats = {doc.id for doc in cats_ref.stream()}
    print(f"[DEBUG] existing_cats: {existing_cats}")

    print("[DEBUG] Streaming existing documents in Dogs collection to create a set of IDs.")
    existing_dogs = {doc.id for doc in dogs_ref.stream()}
    print(f"[DEBUG] existing_dogs: {existing_dogs}")

    print("[DEBUG] Creating Firestore batch for updates.")
    batch = db.batch()

    print("[DEBUG] Iterating through DataFrame rows...")
    for index, row in df.iterrows():
        print(f"[DEBUG] Processing row {index}: {row.to_dict()}")
        # Safely get the Animal ID
        if pd.isna(row['Animal ID']):
            print("[DEBUG] Animal ID is NaN or missing; skipping this row.")
            continue
        # Retrieve the full animal id from the DataFrame row
        animal_id_str = str(row['Animal ID'])
        print(f"[DEBUG] Raw Animal ID: {animal_id_str}")

        # For this specific shelter, extract only the last part of the ID
        # Retrieve the full animal id from the DataFrame row
        animal_id_str = str(row['Animal ID'])
        print(f"[DEBUG] Raw Animal ID: {animal_id_str}")

        if shelter_id == "abd439bd-8bcf-4ede-8fbb-f86030ea4d24":
            # Split and take the last part for this shelter
            animal_id_parts = animal_id_str.split('-')
            animal_id = animal_id_parts[-1] if animal_id_parts else animal_id_str
            print(f"[DEBUG] Extracted animal_id (last part): {animal_id}")
        elif shelter_id == "7udgg4q8-pzq5-0qgw-dhd0-0e61uioz25mb":
            # Split and take the last part for this shelter
            animal_id_parts = animal_id_str.split('-')
            animal_id = animal_id_parts[-1] if animal_id_parts else animal_id_str
            print(f"[DEBUG] Extracted animal_id (last part): {animal_id}")
        else:
            animal_id = animal_id_str
            print(f"[DEBUG] Using full animal_id: {animal_id}")

        if not animal_id:
            print("[DEBUG] animal_id is empty after split; skipping this row.")
            continue

        color = row.get('Volunteer Category', None)
        volunteerCategory = color

        if shelter_id == "7udgg4q8-pzq5-0qgw-dhd0-0e61uioz25mb":
            color = row.get('Attributes', None)
            # if raw_attributes:
            #     # Use regex to extract the value after "Collar Color:" and before the first comma
            #     match = re.search(r'Collar Color:\s*([^,]+)', raw_attributes, re.IGNORECASE)
            #     if match:
            #         color = match.group(1).strip()
            #     else:
            #         color = raw_attributes  # Fallback if pattern isn’t found
            # else:
            #     color = None
        adoptionCategory = row.get('Adoption Category', None)
        behaviorCategory = row.get('Behavior Category', None)
        medicalCategory = row.get('Medical Category', None)

        print(f"[DEBUG] color from row: {color}")
        print(f"[DEBUG] volunteerCategory: {volunteerCategory}")
        print(f"[DEBUG] adoptionCategory: {adoptionCategory}")
        print(f"[DEBUG] behaviorCategory: {behaviorCategory}")
        print(f"[DEBUG] medicalCategory: {medicalCategory}")

        symbol = 'pets'

        # Handle color
        if not color or pd.isna(color) or color.strip() == "":
            print("[DEBUG] Color is empty or NaN; defaulting to 'clear' and 'Unknown Group'")
            color = "clear"
            colorGroup = "Unknown Group"
        else:
            print(f"[DEBUG] Converting color to lowercase: {color}")
            color = color.lower()
            if 'staff only' in color:
                color = 'red'
                colorGroup = 'Staff Only'
                # symbol = "exclamationmark.octagon.fill"
            elif 'red' in color:
                color = 'red'
                colorGroup = 'Red'
            elif 'blue' in color:
                color = 'blue'
                colorGroup = 'Blue'
            elif 'green' in color:
                color = 'green'
                colorGroup = 'Green'
            elif 'silver' in color:
                color = 'gray'
                colorGroup = 'Gray'
            elif 'black' in color:
                color = 'black'
                colorGroup = 'Black'
            elif 'orange' in color:
                color = 'orange'
                colorGroup = 'Orange'
            elif 'pink' in color:
                color = 'pink'
                colorGroup = 'Pink'
            elif 'purple' in color:
                color = 'purple'
                colorGroup = 'Purple'
            elif 'yellow' in color:
                color = 'yellow'
                colorGroup = 'Yellow'
            elif 'brown' in color:
                color = 'brown'
                colorGroup = 'Brown'
            else:
                print("[DEBUG] Color does not match any known category; defaulting to 'clear' and 'Unknown Group'")
                color = "clear"
                colorGroup = "Unknown Group"

        # Determine if the animal exists in Cats or Dogs
        if animal_id in existing_cats:
            doc_ref = cats_ref.document(animal_id)
            print(f"[DEBUG] Found animal {animal_id} in cats collection.")
        elif animal_id in existing_dogs:
            doc_ref = dogs_ref.document(animal_id)
            print(f"[DEBUG] Found animal {animal_id} in dogs collection.")
        else:
            print(f"[DEBUG] Animal {animal_id} not found in either cats or dogs. Skipping.")
            continue

        # Prepare Firestore data
        data = {
            'symbol': symbol,
            'symbolColor': color,
        }
        print(f"[DEBUG] Initial data for update: {data}")

        if not behaviorCategory or pd.isna(behaviorCategory) or behaviorCategory.strip() in ["", "—"]:
            print("[DEBUG] behaviorCategory was blank or '-' so setting it to an empty string in Firestore.")
            data['behaviorCategory'] = ""
        else:
            data['behaviorCategory'] = behaviorCategory

        if not volunteerCategory or pd.isna(volunteerCategory) or volunteerCategory.strip() in ["", "—"]:
            print("[DEBUG] volunteerCategory was blank or '-' so setting it to an empty string in Firestore.")
            data['volunteerCategory'] = ""
        else:
            data['volunteerCategory'] = volunteerCategory

        if not adoptionCategory or pd.isna(adoptionCategory) or adoptionCategory.strip() in ["", "—"]:
            print("[DEBUG] adoptionCategory was blank or '-' so setting it to an empty string in Firestore.")
            data['adoptionCategory'] = ""
        else:
            data['adoptionCategory'] = adoptionCategory

        if not medicalCategory or pd.isna(medicalCategory) or medicalCategory.strip() in ["", "—"]:
            print("[DEBUG] medicalCategory was blank or '-' so setting it to an empty string in Firestore.")
            data['medicalCategory'] = ""
        else:
            data['medicalCategory'] = medicalCategory

        print(f"[DEBUG] Final data to batch update: {data}")
        batch.update(doc_ref, data)
    print("[DEBUG] Committing Firestore batch updates now...")
    batch.commit()
    print("[DEBUG] Firestore batch commit complete.")
