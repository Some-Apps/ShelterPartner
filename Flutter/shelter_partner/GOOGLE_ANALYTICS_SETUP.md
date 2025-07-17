# Google Analytics Setup

This document outlines how to set up Google Analytics for the ShelterPartner Flutter web application.

## Overview

The ShelterPartner app now includes Google Analytics integration to track:

- **Device information** and **active users** (automatic tracking)
- **App versions** (automatic tracking through user properties)
- **Custom events**:
  - `note_added` - When a note is added to an animal
  - `photo_added` - When a photo is added to an animal  
  - `tag_added` - When a tag is added to an animal
  - `log_completed` - When an animal is taken out and put back (logged)

## Firebase Console Setup

### 1. Enable Analytics

1. Go to your Firebase project console
2. Navigate to **Analytics** in the left sidebar
3. Click **Get started** if Analytics is not already enabled
4. Follow the setup wizard to create a Google Analytics property
5. Link your Firebase project to the Analytics property

### 2. Configure Analytics

1. In the Firebase console, go to **Project Settings** (gear icon)
2. Select the **Analytics** tab
3. Note your **Analytics Property ID** (you may need this for advanced configuration)

### 3. Update Firebase Configuration (if needed)

The app automatically initializes Analytics when Firebase is initialized. No additional configuration should be needed in most cases.

## Web-specific Setup

For Flutter web apps, Google Analytics automatically tracks:

- Page views and navigation
- User sessions and engagement
- Device type, browser, and operating system
- Geographic location (if enabled)
- Custom events (as implemented in the app)

## Events Tracked

### Automatic Events

- `page_view` - When users navigate between pages
- `session_start` - When users start a session
- `first_visit` - When users visit for the first time
- User demographics and device information

### Custom Events

- `note_added`
  - Parameters: `animal_id`, `animal_species`
- `photo_added`
  - Parameters: `animal_id`, `animal_species`, `photo_source`
- `tag_added`
  - Parameters: `animal_id`, `animal_species`, `tag_name`
- `log_completed`
  - Parameters: `animal_id`, `animal_species`, `log_type`

### User Properties

- `app_version` - Set automatically from package.json version

## Viewing Analytics Data

### Firebase Analytics Dashboard

1. Go to your Firebase project console
2. Click **Analytics** in the left sidebar
3. Explore the **Dashboard**, **Events**, and **Audiences** sections

### Google Analytics Dashboard

1. Go to [analytics.google.com](https://analytics.google.com)
2. Select your property
3. View detailed reports in the **Reports** section

### Key Reports to Monitor

- **Realtime** → Overview (see current active users)
- **Audience** → Overview (user demographics and devices)
- **Acquisition** → All Traffic (how users find your app)
- **Behavior** → Events (custom events like note_added, photo_added)
- **Technology** → Browser & OS (device information)

## Privacy Considerations

- Analytics data is automatically anonymized
- No personally identifiable information (PII) is tracked
- Animal IDs in custom events are internal identifiers, not sensitive data
- Users can opt out of Analytics in their browser settings

## Testing Analytics

During development, you can test Analytics events:

1. Open your browser's Developer Tools
2. Go to the **Network** tab
3. Filter for requests to `google-analytics.com` or `analytics.google.com`
4. Perform actions in the app (add notes, photos, tags, logs)
5. Verify that Analytics events are being sent

### Debug Mode

For detailed testing, you can enable Analytics debug mode:

1. Install the [Google Analytics Debugger](https://chrome.google.com/webstore/detail/google-analytics-debugger/jnkmfdileelhofjcijamephohjechhna) Chrome extension
2. Enable it and check the browser console for detailed Analytics logs

## Troubleshooting

### Analytics Not Working

1. **Check Firebase setup**: Ensure Analytics is enabled in your Firebase project
2. **Verify web app registration**: Make sure your web app is registered in Firebase
3. **Check console errors**: Look for JavaScript errors in the browser console
4. **Test network requests**: Verify Analytics requests are being sent (see Testing section)

### Events Not Appearing

1. **Real-time reports**: Check Firebase Analytics real-time reports for immediate feedback
2. **Processing delay**: Standard reports may take 24-48 hours to update
3. **Event parameters**: Ensure event parameters meet [Google Analytics requirements](https://support.google.com/analytics/answer/9267735)

### Data Discrepancies

1. **Ad blockers**: Some users may have ad blockers that prevent Analytics
2. **Privacy settings**: Browser privacy settings may block tracking
3. **Development vs Production**: Make sure you're looking at the correct environment

## Implementation Details

The Analytics implementation includes:

- **Service abstraction** (`AnalyticsService`) for easy testing and mocking
- **Error handling** - Analytics failures won't break the app
- **Test coverage** - Mock implementation for unit and integration tests
- **Minimal impact** - Analytics code is non-blocking and lightweight

For technical details, see:
- `lib/services/analytics_service.dart` - Main implementation
- `test/services/analytics_service_test.dart` - Unit tests
- `test/repositories/*_analytics_test.dart` - Integration tests