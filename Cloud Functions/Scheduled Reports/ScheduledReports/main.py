import functions_framework
import datetime
import os
import json
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from google.cloud import firestore
from google.cloud import pubsub_v1
import base64
import csv
import io
import pytz


# Initialize Firestore DB
db = firestore.Client()

# Timezone for Chicago
chicago_tz = pytz.timezone('America/Chicago')

# Get current date in Chicago timezone
today = datetime.datetime.now(chicago_tz).date() - datetime.timedelta(days=1)
last_week = today - datetime.timedelta(days=6)
today_str, last_week_str = today.strftime("%B %-d"), last_week.strftime("%B %-d")

def fetch_all_data_for_animals(animals, species):
    result_list = []
    for animal_id, animal in animals.items():
        filtered_photos = []
        relevant_notes = []
        filtered_logs = []

        if 'photos' in animal:
            for photo in animal['photos']:
                photo_timestamp = datetime.datetime.fromtimestamp(photo['timestamp'], chicago_tz).date()
                if last_week <= photo_timestamp <= today:
                    filtered_photos.append(photo['url'])

        if 'notes' in animal:
            for note in animal['notes']:
                note_date = datetime.datetime.fromtimestamp(note['date'], chicago_tz).date()
                if last_week <= note_date <= today and note['note'].strip() and note['note'] != 'Added animal to the app':
                    notes_user = note['user']
                    note_string = note['note']
                    relevant_notes.append({
                        "note": note_string,
                        "date": note_date.strftime("%Y-%m-%d"),
                        "user": notes_user
                    })

        if 'logs' in animal:
            for log in animal['logs']:
                start_time = datetime.datetime.fromtimestamp(log['startTime'], chicago_tz)
                end_time = datetime.datetime.fromtimestamp(log['endTime'], chicago_tz)
                log_user = log.get('user', '')
                log_short_reason = log.get('shortReason', '')
                if last_week <= start_time.date() <= today:
                    filtered_logs.append({
                        "start": start_time.strftime("%Y-%m-%d %H:%M:%S"),
                        "end": end_time.strftime("%Y-%m-%d %H:%M:%S"),
                        "user": log_user,
                        "shortReason": log_short_reason
                    })

        if filtered_photos or relevant_notes or filtered_logs:
            result_list.append({
                "id": animal_id,
                "name": animal['name'],
                "species": species,
                "notes": relevant_notes,
                "photos": filtered_photos,
                "logs": filtered_logs
            })

    return result_list

def format_data_to_csv(data):
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['ID', 'Name', 'Species', 'Note', 'Note Date', 'Note Person', 'Log Start', 'Log End', 'Log Duration (minutes)', 'Log Person', 'Short Log Reason', 'Log Type'])

    for item in data:
        first_row = True
        max_rows = max(len(item['notes']), len(item['logs']), 1)
        for i in range(max_rows):
            row = []
            if first_row:
                row.append(item['id'])
                row.append(item['name'])
                row.append(item['species'])
                first_row = False
            else:
                row.extend(['', '', ''])

            if i < len(item['notes']):
                note = item['notes'][i]
                row.append(note['note'])
                row.append(note['date'])
                row.append(note['user'])
            else:
                row.extend(['', '', ''])

            if i < len(item['logs']):
                log = item['logs'][i]
                start_time = datetime.datetime.strptime(log['start'], "%Y-%m-%d %H:%M:%S")
                end_time = datetime.datetime.strptime(log['end'], "%Y-%m-%d %H:%M:%S")
                duration_minutes = (end_time - start_time).total_seconds() / 60
                row.append(log['start'])
                row.append(log['end'])
                row.append(f"{duration_minutes:.2f}")
                row.append(log.get('user', ''))
                row.append(log.get('shortReason', ''))
                row.append(log.get('letOutType', ''))
            else:
                row.extend(['', '', '', '', ''])

            writer.writerow(row)

    return output.getvalue()


@functions_framework.cloud_event
def send_scheduled_report(cloud_event):
    pubsub_message = cloud_event.data.get('message', {})
     # Acknowledge the Pub/Sub message
    ack_id = pubsub_message.get('ackId')
    if ack_id:
        print(ack_id)
        acknowledge_message(ack_id)
    if 'data' in pubsub_message:
        message_data = base64.b64decode(pubsub_message['data']).decode('utf-8')
        message = json.loads(message_data)
        print(f"Received message: {message}")
    else:
        print("No data in the Pub/Sub message")
        return

    society_id = message.get('society_id')
    scheduled_reports_email = message.get('email')

    if not society_id or not scheduled_reports_email:
        print("society_id or email missing in the message")
        return

    print(f"Function invoked for society_id: {society_id}, email: {scheduled_reports_email}")
    
    societies_ref = db.collection('Societies')
    society_doc_ref = societies_ref.document(society_id)
    society_doc = society_doc_ref.get()

    if not society_doc.exists:
        print(f"Society {society_id} does not exist")
        return

    society_data = society_doc.to_dict()
    report_type = society_data.get('reportType', 'default')

    cats_ref = society_doc_ref.collection('Cats')
    dogs_ref = society_doc_ref.collection('Dogs')
    cats = {doc.id: doc.to_dict() for doc in cats_ref.stream()}
    dogs = {doc.id: doc.to_dict() for doc in dogs_ref.stream()}

    cats_data = fetch_all_data_for_animals(cats, 'Cat')
    dogs_data = fetch_all_data_for_animals(dogs, 'Dog')
    email_body = generate_html_email_body(cats_data, dogs_data)
    csv_data = format_data_to_csv(cats_data + dogs_data)

    send_email_with_csv(scheduled_reports_email, email_body, csv_data)

def generate_html_email_body(cats_data, dogs_data):
    has_content = any([cats_data, dogs_data])

    email_body = """
    <html>
    <head>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f9f9f9;
                padding: 2%;
                color: #444;
            }
            .header {
                background-color: #4CAF50;
                padding: 10px;
                text-align: center;
                color: white;
                font-size: 24px;
            }
            .animal-type {
                font-size: 22px;
                font-weight: bolder;
                margin-top: 20px;
                color: #333;
            }
            .animal-section {
                margin-bottom: 20px;
            }
            .animal-name {
                font-size: 15px;
                text-decoration: underline;
                margin-bottom: 5px;
                color: #444;
            }
            ul {
                margin-top: 0;
                padding-left: 20px;
            }
            li {
                color: #555;
                margin-bottom: 5px;
            }
            a:link, a:visited {
                color: #007bff;
            }
        </style>
    </head>
    <body>
    """
    if has_content:
        email_body += "<p>See the attached spreadsheet for a more detailed report</p>"
        for animal_type, data in [('Cats', cats_data), ('Dogs', dogs_data)]:
            data_with_notes = [item for item in data if item.get('notes')]
            if data_with_notes:
                email_body += f"<div class='animal-type'>{animal_type}:</div>"
                for item in data_with_notes:
                    email_body += f"""
                    <div class='animal-section'>
                        <p class='animal-name'>{item['name']}</p>
                        <ul>
                    """
                    for note in item.get('notes', []):
                        email_body += f"<li>{note['note']}</li>"
                    for photo_url in item.get('photos', []):
                        email_body += f'<li><a href="{photo_url}" target="_blank">Photo</a></li>'
                    email_body += """
                        </ul>
                    </div>
                    """
    else:
        email_body += "<p>No activity from the past week.</p>"

    email_body += "</body></html>"

    return email_body



def send_email_with_csv(to, body, csv_data):
    msg = MIMEMultipart()
    msg['From'] = 'reports@pawpartner.app'
    msg['To'] = to
    msg['Subject'] = f'{last_week_str} - {today_str} Animal Activity Report'
    msg.attach(MIMEText(body, 'html'))
    
    # Attach CSV
    part = MIMEBase('application', 'octet-stream')
    part.set_payload(csv_data.encode('utf-8'))
    encoders.encode_base64(part)
    part.add_header('Content-Disposition', 'attachment; filename="animal_activity_report.csv"')
    msg.attach(part)
    
    username = os.getenv("emailAddress")
    password = os.getenv("emailPassword")
    with smtplib.SMTP('smtp.gmail.com: 587') as server:
        server.starttls()
        server.login(username, password)
        server.send_message(msg)

    print(f"Report sent to {to}")

def acknowledge_message(ack_id):
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = "projects/humanesociety-21855/subscriptions/eventarc-us-central1-trigger-r6xhyzgh-sub-172"
    subscriber.acknowledge(subscription_path, [ack_id])
    print(f"Message with ack_id {ack_id} acknowledged.")
