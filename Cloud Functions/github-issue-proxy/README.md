# GitHub Issue Proxy Cloud Function

This Cloud Function acts as a secure proxy for creating GitHub issues from the ShelterPartner Flutter app. It enables users to submit feedback, bug reports, and feature requests without exposing GitHub authentication tokens in the client app.

## Features

- **Secure GitHub API Integration**: Uses server-side GitHub token for authenticated requests
- **CORS Support**: Handles preflight requests and allows cross-origin requests from the Flutter web app
- **Input Validation**: Validates required fields and request format
- **Error Handling**: Comprehensive error handling with appropriate HTTP status codes
- **Logging**: Uses Google Cloud Logging for monitoring and debugging

## Deployment

### Prerequisites

1. GitHub Personal Access Token with `repo` scope for the `Shelter-Partner/ShelterPartner` repository
2. Google Cloud Project with Cloud Functions API enabled

### Deploy Function

```bash
# Navigate to the function directory
cd "Cloud Functions/github-issue-proxy"

# Deploy the function
gcloud functions deploy create_github_issue \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars GITHUB_TOKEN=your_github_token_here \
  --region us-central1
```

### Environment Variables

- `GITHUB_TOKEN`: GitHub Personal Access Token with `repo` permissions

## API Usage

### Endpoint

```
POST https://us-central1-shelterpartner-42b4c.cloudfunctions.net/create_github_issue
```

### Request Format

```json
{
  "title": "Issue title",
  "body": "Issue description and details",
  "labels": ["user feedback", "bug"]  // Optional, defaults to ["user feedback"]
}
```

### Response Format

**Success (201):**
```json
{
  "number": 123,
  "html_url": "https://github.com/Shelter-Partner/ShelterPartner/issues/123",
  "title": "Issue title"
}
```

**Error (4xx/5xx):**
```json
{
  "error": "Error description",
  "details": "Additional error details"  // Optional
}
```

## Security

- GitHub token is stored as an environment variable, not in code
- Function validates all inputs before making GitHub API calls
- CORS headers restrict usage to appropriate origins
- Comprehensive logging for security monitoring

## Testing

The function can be tested locally using the Functions Framework:

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variable
export GITHUB_TOKEN=your_token_here

# Run locally
functions-framework --target=create_github_issue --debug
```

Then make a POST request to `http://localhost:8080` with the required JSON payload.