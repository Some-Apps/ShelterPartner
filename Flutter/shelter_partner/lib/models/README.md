# Data Models

This directory contains the data model classes for the application. These classes define the structure, and in some cases, the behavior of the data entities used throughout the ShelterPartner app.

## Key Characteristics in this Project:

-   **Data Structuring**: Models in this directory define the properties for core entities. They establish a clear, strongly-typed schema for the application's data.

-   **Firestore Interaction**:
    -   Models are designed to work directly with Firestore data. They typically include factory constructors (commonly named `fromFirestore()` or `fromDocument()`) to parse Firestore documents or Maps into Dart objects.
    -   Many models also provide `toMap()` methods to serialize the Dart object back into a format suitable for writing to Firestore, though some may be primarily read or updated field by field.

-   **Immutability and Copying**: A common pattern is the implementation of a `copyWith()` method. This allows for creating modified copies of model instances, which is a best practice for state management in Flutter, ensuring that data objects are treated as immutable.

-   **Helper Logic & Derived Data**: Some models include getters or methods to provide derived or formatted data. For instance, a model might have a getter to process a raw string field into a more usable list or to compute a value based on other properties.

-   **Nested Structures**: Models frequently contain instances of other models, creating nested data structures (e.g., a primary model might contain a list of related sub-model objects).

## Purpose:

-   Provide a reliable and consistent way to represent and manage data from Firestore and within the application.
-   Ensure type safety and reduce runtime errors by working with well-defined objects.
-   Facilitate interaction between `repositories` (which fetch/store data) and `view_models` (which prepare data for the UI).

These models are fundamental to how data is handled, stored, and manipulated within the application.