# Google Cloud Logging Setup

This file provides instructions for enabling Google Cloud Logging in production.

## Prerequisites

1. Google Cloud Project with Cloud Logging API enabled
2. Service account with Cloud Logging Writer permissions
3. Service account key file or other authentication method

## Configuration Steps

### 1. Enable Cloud Logging API

```bash
gcloud services enable logging.googleapis.com
```

### 2. Create Service Account

```bash
gcloud iam service-accounts create shelter-partner-logger \
    --description="Service account for ShelterPartner logging" \
    --display-name="ShelterPartner Logger"
```

### 3. Grant Permissions

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:shelter-partner-logger@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
```

### 4. Create and Download Key

```bash
gcloud iam service-accounts keys create shelter-partner-logger-key.json \
    --iam-account=shelter-partner-logger@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 5. Update Firebase Providers

Replace the TODO section in `lib/providers/firebase_providers.dart`:

```dart
final loggerServiceProvider = Provider<LoggerService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  
  if (environment.isProduction) {
    try {
      // Configure authentication
      final credentials = ServiceAccountCredentials.fromJson({
        // Your service account key JSON here
        // Or use Application Default Credentials
      });
      
      final authClient = await clientViaServiceAccount(
        credentials,
        [LoggingApi.cloudPlatformScope],
      );
      
      final logging = Logging(authClient, projectId: 'YOUR_PROJECT_ID');
      return CloudLoggerService(
        logging: logging,
        logName: 'shelter-partner-app',
      );
    } catch (e) {
      // Fallback to console if cloud logging fails to initialize
      return ConsoleLoggerService(minimumLevel: LogLevel.warning);
    }
  } else {
    return ConsoleLoggerService(minimumLevel: LogLevel.debug);
  }
});
```

### 6. Environment Variables (Alternative)

For deployments, you can use environment variables:

```dart
final projectId = const String.fromEnvironment('GOOGLE_CLOUD_PROJECT_ID');
final serviceAccountKey = const String.fromEnvironment('GOOGLE_CLOUD_SERVICE_ACCOUNT_KEY');

if (projectId.isNotEmpty && serviceAccountKey.isNotEmpty) {
  // Initialize cloud logging
}
```

### 7. Web Deployment

For Flutter web, you may need to use the REST API instead of the gRPC client:

```dart
// Use HTTP client for web deployments
final httpClient = http.Client();
final logging = LoggingApi(httpClient);
```

## Testing Cloud Logging

To test cloud logging in development:

```dart
// Override the environment provider in your test setup
final container = ProviderContainer(
  overrides: [
    appEnvironmentProvider.overrideWithValue(AppEnvironment.production()),
    // ... other overrides
  ],
);
```

## Viewing Logs

1. **Google Cloud Console**: Navigate to "Logging" → "Log Explorer"
2. **Filter by resource**: `resource.type="global"` or your specific resource
3. **Filter by log name**: `logName="projects/YOUR_PROJECT_ID/logs/shelter-partner-app"`
4. **gcloud CLI**: `gcloud logging read "logName:shelter-partner-app"`

## Log Retention

Default retention is 30 days. To configure longer retention:

1. Create a log sink to Cloud Storage or BigQuery
2. Configure retention policies in Cloud Storage
3. Or upgrade to longer retention in Cloud Logging

## Monitoring and Alerting

Set up alerts for error logs:

1. Go to "Monitoring" → "Alerting"
2. Create policy based on log-based metrics
3. Alert on error-level logs or specific error patterns

## Costs

Cloud Logging pricing (as of 2024):
- First 50 GiB per month: Free
- Additional ingestion: $0.50 per GiB
- Retention beyond 30 days: Additional charges

Monitor usage in the Cloud Console to stay within budget.