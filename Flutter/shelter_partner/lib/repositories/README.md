# Repositories

This directory houses repository classes that abstract the data sources of the application. Repositories act as a bridge between the application's business logic (often in `view_models`) and the actual data persistence or retrieval mechanisms, primarily Firebase Firestore and Firebase Authentication in this project.

## Key Characteristics & Responsibilities in this Project:

-   **Data Source Interaction**: Repositories are the primary interface to Firebase services. They encapsulate all Firestore queries, data writes (creations, updates, deletions), and Firebase Authentication calls.

-   **Variety of Scopes**:
    -   Some repositories, like those handling authentication, manage broad concerns such as user sign-up/sign-in, user document creation, and even initial data seeding for new accounts (e.g., populating animal data from CSV files).
    -   Other repositories are more granular, focusing on specific operations for a particular data entity (e.g., updating an animal's details or modifying a specific field like an animal's log entries).

-   **Model Interaction**:
    -   Repositories use the data `models` (from the `lib/models/` directory) extensively. They utilize factory constructors on models (e.g., `ModelName.fromDocument()` or `ModelName.fromFirestore()`) to convert Firestore data into strongly-typed Dart objects.
    -   They call `toMap()` methods on model instances to serialize Dart objects into a Map format suitable for writing to Firestore.

-   **CRUD Operations & Beyond**: While providing standard Create, Read, Update, Delete (CRUD) operations, repositories in this project also handle more complex tasks like:
    -   Batch operations for initial data setup.
    -   Targeted field updates within documents (e.g., removing an item from a list within a Firestore document).
    -   Re-authentication and account deletion processes.

-   **Error Handling**: Repositories may include try-catch blocks to handle potential errors during data operations, though detailed error propagation to the UI is typically managed by `ViewModels`.

-   **Dependency Provision**: They are often made available to the rest of the application (especially `ViewModels`) through a dependency injection mechanism like Riverpod.

## Purpose:

-   To provide a clean, abstracted API for all data operations, shielding the rest of the application from the direct complexities of Firebase SDKs.
-   To centralize data access logic, making it easier to manage, test (by mocking repositories), and modify data sources or strategies in the future.
-   To ensure that `ViewModels` can request or send data without needing to know the specifics of how or where that data is stored or retrieved.