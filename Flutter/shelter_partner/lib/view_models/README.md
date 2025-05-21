# ViewModels

The `view_models` directory contains classes that serve as an intermediary between the `views` (UI components) and the `models` (data and business logic). This pattern helps in creating a clear separation of concerns.

## Key Responsibilities:

-   **Data Preparation**: ViewModels fetch data from models or repositories and transform/format it for easy consumption by the views. They hold and manage the UI state.
-   **User Interaction Handling**: They process user actions received from the views and update their internal state. Changes to this state are then observed by Flutter's reactive UI system, which rebuilds the relevant parts of the user interface to reflect the new state. ViewModels also interact with models or services to perform business logic (e.g., API calls, data persistence).
-   **Decoupling**: They decouple views from the underlying data sources and business logic, making views simpler (focused on presentation) and models independent of the UI.

Each class in this directory usually corresponds to a specific screen or a significant reusable UI component, managing its state and the logic that drives its part of the user interface.
