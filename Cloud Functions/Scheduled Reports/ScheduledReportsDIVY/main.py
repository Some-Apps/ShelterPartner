import functions_framework
from google.cloud import firestore
from google.cloud import pubsub_v1
import datetime
import os
import json

# Initialize Firestore DB
db = firestore.Client()

# Initialize Pub/Sub Publisher
publisher = pubsub_v1.PublisherClient()
project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
if not project_id:
    raise Exception("GOOGLE_CLOUD_PROJECT environment variable is not set.")
topic_path = publisher.topic_path(project_id, 'send-scheduled-report')

DAYS_MAP = {
    "Monday": 0, "Tuesday": 1, "Wednesday": 2,
    "Thursday": 3, "Friday": 4, "Saturday": 5,
    "Sunday": 6, "Never": None
}

@functions_framework.http
def process_documents(request):
    societies_ref = db.collection('Societies')
    societies = societies_ref.stream()
    today = datetime.date.today()
    today_weekday = today.weekday()

    for society in societies:
        society_id = society.id
        society_data = society.to_dict()
        
        scheduled_reports_day = society_data.get('reportsDay')
        scheduled_reports_email = society_data.get('reportsEmail')

        if not scheduled_reports_day or not scheduled_reports_email:
            continue

        scheduled_reports_day_number = DAYS_MAP.get(scheduled_reports_day)

        if scheduled_reports_day_number is not None and today_weekday == scheduled_reports_day_number:
            print(f"Triggering report for society: {society_id}")
            message_data = {
                "society_id": society_id,
                "email": scheduled_reports_email
            }
            print(f"Publishing message: {message_data}")  # Log the message data
            try:
                future = publisher.publish(topic_path, data=json.dumps(message_data).encode("utf-8"))
                print(f"Published message ID: {future.result()}")
            except Exception as e:
                print(f"Error publishing message: {e}")

    return "Documents processed successfully", 200
