import functions_framework
import json
import os
import requests
import base64
import tempfile
import mimetypes
import time
import uuid
from flask import jsonify, request


# GitHub API configuration
GITHUB_API_URL = "https://api.github.com"
REPO_OWNER = "Shelter-Partner"
REPO_NAME = "ShelterPartner"

def upload_image_to_github(github_token, image_base64, image_name):
    """
    Upload an image to GitHub repository as a file and return the URL.
    Returns the URL if successful, None otherwise.
    """
    try:
        # Decode base64 image
        image_data = base64.b64decode(image_base64)
        
        # Check size limit (GitHub has a 100MB file size limit, but let's be more conservative)
        max_size = 25 * 1024 * 1024  # 25MB
        if len(image_data) > max_size:
            return None, "Image too large (maximum 25MB)"
        
        # Generate a unique filename with timestamp
        import time
        import uuid
        timestamp = int(time.time())
        unique_id = str(uuid.uuid4())[:8]
        
        # Detect image format and ensure proper extension
        image_format = 'png'  # default
        extension = '.png'
        if image_name:
            if image_name.lower().endswith(('.jpg', '.jpeg')):
                image_format = 'jpeg'
                extension = '.jpg'
            elif image_name.lower().endswith('.gif'):
                image_format = 'gif'
                extension = '.gif'
            elif image_name.lower().endswith('.webp'):
                image_format = 'webp'
                extension = '.webp'
        
        # Create file path in the repository
        filename = f"feedback-{timestamp}-{unique_id}{extension}"
        file_path = f"Assets/user-feedback/{filename}"
        
        # Upload file to GitHub repository using Contents API
        github_headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
            'User-Agent': 'ShelterPartner-CloudFunction'
        }
        
        upload_payload = {
            'message': f'Add user feedback image: {filename}',
            'content': image_base64,
            'path': file_path
        }
        
        upload_url = f"{GITHUB_API_URL}/repos/{REPO_OWNER}/{REPO_NAME}/contents/{file_path}"
        upload_response = requests.put(
            upload_url,
            headers=github_headers,
            json=upload_payload,
            timeout=30
        )
        
        if upload_response.status_code == 201:
            # File uploaded successfully, return the raw GitHub URL
            upload_data = upload_response.json()
            # Use the download_url from the response for direct access
            if 'content' in upload_data and 'download_url' in upload_data['content']:
                return upload_data['content']['download_url'], None
            else:
                # Fallback to constructing the raw URL
                raw_url = f"https://raw.githubusercontent.com/{REPO_OWNER}/{REPO_NAME}/main/{file_path}"
                return raw_url, None
        else:
            return None, f"Failed to upload to GitHub: {upload_response.status_code} - {upload_response.text}"
        
    except Exception as e:
        return None, f"Image upload failed: {str(e)}"

@functions_framework.http
def create_github_issue(request):
    """
    Cloud Function that acts as a proxy for creating GitHub issues.
    Accepts POST requests with issue data and creates issues using a secure GitHub token.
    Now supports image uploads.
    """
    # Set CORS headers for all responses
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '3600'
    }
    
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return ('', 204, headers)
    
    # Only allow POST requests
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        # Get GitHub token from environment variable
        github_token = os.environ.get('github')
        if not github_token:
            return jsonify({'error': 'Server configuration error'}), 500, headers
        
        # Parse request JSON
        request_json = request.get_json()
        if not request_json:
            return jsonify({'error': 'Invalid JSON payload'}), 400, headers
        
        # Validate required fields
        title = request_json.get('title')
        body = request_json.get('body')
        labels = request_json.get('labels', ['user feedback'])
        image_base64 = request_json.get('imageBase64')
        image_name = request_json.get('imageName')
        
        if not title or not body:
            return jsonify({'error': 'Title and body are required'}), 400, headers
        
        # Handle image upload if provided
        image_uploaded = False
        image_upload_error = None
        
        if image_base64:
            image_url, error = upload_image_to_github(github_token, image_base64, image_name)
            if image_url:
                # Add image to the issue body
                body += f"\n\n## Screenshot\n\n![Screenshot]({image_url})"
                image_uploaded = True
            else:
                image_upload_error = error
                # Add a note that image upload failed
                body += f"\n\n**Note:** User attempted to include a screenshot but upload failed: {error}"
        
        # Prepare GitHub API request
        github_headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
            'User-Agent': 'ShelterPartner-CloudFunction'
        }
        
        github_payload = {
            'title': title,
            'body': body,
            'labels': labels
        }
        
        # Make request to GitHub API
        github_url = f"{GITHUB_API_URL}/repos/{REPO_OWNER}/{REPO_NAME}/issues"
        response = requests.post(
            github_url,
            headers=github_headers,
            json=github_payload,
            timeout=30
        )
        
        # Handle GitHub API response
        if response.status_code == 201:
            github_data = response.json()
            
            # Return the same format expected by Flutter app, including image upload status
            result = {
                'number': github_data['number'],
                'html_url': github_data['html_url'],
                'title': github_data['title'],
                'imageUploaded': image_uploaded,
                'imageUploadError': image_upload_error
            }
            
            return jsonify(result), 201, headers
        else:
            return jsonify({
                'error': 'Failed to create GitHub issue',
                'details': response.text
            }), response.status_code, headers
            
    except requests.exceptions.RequestException as e:
        return jsonify({'error': 'Network error occurred'}), 500, headers
    except json.JSONDecodeError:
        return jsonify({'error': 'Invalid JSON payload'}), 400, headers
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500, headers