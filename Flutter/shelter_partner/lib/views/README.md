# Views (UI Components and Pages)

This directory contains all the UI elements of the Flutter application, primarily composed of Flutter widgets that define the user interface and experience.

## Organization:

-   **`auth/`**: Contains UI widgets and screens specifically dedicated to user authentication flows (e.g., login, sign-up, password reset).
-   **`components/`**: Holds smaller, reusable UI widgets (e.g., custom buttons, list items, dialogs) that are used across various pages and auth screens to maintain a consistent look and feel.
-   **`pages/`**: Contains widgets that represent the primary screens or distinct sections of the application that users interact with after authentication (e.g., main dashboards, detail views, settings areas).
-   **Embedded Components**: Complex pages and auth screens in this project define highly specific sub-components (widgets) directly within their own files. This is typically done when these components are not intended for broader reuse, co-locating UI logic tightly coupled to that specific page or screen.

## Key Characteristics & Responsibilities in this Project:

-   **State Management (Riverpod)**: Views are deeply integrated with Riverpod. They are typically `ConsumerWidget` or `StatelessWidget` using `Consumer` builders to:
    -   `watch` providers to subscribe to state changes from `ViewModels` and other application state providers.
    -   `read` providers (often the `.notifier` of a `StateNotifierProvider`) to call methods on `ViewModels` to trigger business logic or state updates.

-   **Data Display & Formatting**: Views are responsible for rendering data obtained from `ViewModels` and applying any necessary UI-specific formatting (e.g., formatting dates, calculating displayable age from months).

-   **User Interaction**: They capture user inputs (taps, gestures, form submissions) and delegate the handling of these interactions to the appropriate `ViewModels`.

-   **Conditional Rendering**: The UI presented by views is often dynamic, changing based on various states such as:
    -   Authentication status (loading, authenticated, unauthenticated, error).
    -   User roles and permissions (e.g., admin-specific UI elements or modes).
    -   Loading/error states of data fetched by `ViewModels`.
    -   Specific conditions like geofencing status for certain user types.

-   **Navigation**: Page navigation and the management of navigation structures (like bottom navigation bars with nested routes) are handled using the `go_router` package.

-   **Asynchronous UI**: Views manage the UI representation of asynchronous operations, typically by showing loading indicators while data is being fetched or operations are in progress, and displaying error messages when issues occur.

-   **Local UI State & Logic**: Views manage their own internal UI-specific state that doesn't belong in a `ViewModel`. This includes `ScrollController`s, `PageController`s (e.g., for image galleries), `FocusNode`s, and other Flutter-specific UI controllers.

-   **Provider Scope**: Core application state and service providers (like those for authentication or shared user data) are generally defined globally for broad accessibility. For `ViewModels` that require parameters (e.g., an ID to fetch specific data), views utilize `StateNotifierProvider.family`. Additionally, providers very tightly coupled to a specific view's functionality are sometimes defined directly within the view file itself.

Views in this project aim to be primarily focused on presentation and user interaction, delegating business logic and complex state management to `ViewModels` and services, facilitated by Riverpod.