import functions_framework
import json
import os
import requests
from flask import jsonify, request
from google.cloud import logging

# Initialize Google Cloud Logging
logging_client = logging.Client()
logging_client.setup_logging()

# GitHub API configuration
GITHUB_API_URL = "https://api.github.com"
REPO_OWNER = "Shelter-Partner"
REPO_NAME = "ShelterPartner"

@functions_framework.http
def create_github_issue(request):
    """
    Cloud Function that acts as a proxy for creating GitHub issues.
    Accepts POST requests with issue data and creates issues using a secure GitHub token.
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
        github_token = os.environ.get('GITHUB_TOKEN')
        if not github_token:
            logging.error("GitHub token not configured")
            return jsonify({'error': 'Server configuration error'}), 500, headers
        
        # Parse request JSON
        request_json = request.get_json()
        if not request_json:
            return jsonify({'error': 'Invalid JSON payload'}), 400, headers
        
        # Validate required fields
        title = request_json.get('title')
        body = request_json.get('body')
        labels = request_json.get('labels', ['user feedback'])
        
        if not title or not body:
            return jsonify({'error': 'Title and body are required'}), 400, headers
        
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
            
            # Return the same format expected by Flutter app
            result = {
                'number': github_data['number'],
                'html_url': github_data['html_url'],
                'title': github_data['title']
            }
            
            logging.info(f"Successfully created GitHub issue #{github_data['number']}")
            return jsonify(result), 201, headers
        else:
            logging.error(f"GitHub API error: {response.status_code} - {response.text}")
            return jsonify({
                'error': 'Failed to create GitHub issue',
                'details': response.text
            }), response.status_code, headers
            
    except requests.exceptions.RequestException as e:
        logging.error(f"Request error: {str(e)}")
        return jsonify({'error': 'Network error occurred'}), 500, headers
    except json.JSONDecodeError:
        return jsonify({'error': 'Invalid JSON payload'}), 400, headers
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500, headers