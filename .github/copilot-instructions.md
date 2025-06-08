# ShelterPartner Copilot Instructions

This is a Flutter-based application for animal shelter management built with Firebase backend services. The core application is located in `Flutter/shelter_partner/` and uses MVVM architecture with Riverpod for state management. Please follow these guidelines when contributing:

## Code Standards

### Required Before Each Commit
- Run `dart fix --apply` before formatting to apply automatic fixes
- Run `dart format .` in both `Flutter/shelter_partner/` and `Website/` directories to ensure proper code formatting
- Ensure all tests pass with `flutter test` from the project directory
- Verify code analysis passes without blocking errors using `flutter analyze`

### Development Flow
- **Setup**: `cd Flutter/shelter_partner && flutter pub get` to install dependencies
- **Build**: `flutter build web` (primary target platform)
- **Test**: `flutter test` (all tests must pass)
- **Analyze**: `flutter analyze` (warnings are acceptable, errors are not)
- **Format**: `dart format .` (required by CI)

## Repository Structure
- `Flutter/shelter_partner/`: Main Flutter application
  - `lib/models/`: Data models with Firestore integration and `fromFirestore()`, `toMap()`, `copyWith()` methods
  - `lib/repositories/`: Data access layer that interfaces with Firebase services
  - `lib/view_models/`: Business logic layer using Riverpod providers
  - `lib/views/`: UI components (pages and reusable components)
  - `lib/providers/`: Riverpod provider definitions
  - `test/`: Test files mirroring the lib structure with `_test.dart` suffix
- `Website/`: Flutter web application
- `Cloud Functions/`: Firebase Cloud Functions
- `Documentation/`: Project documentation and user guides
- `.github/workflows/`: CI/CD configuration

## Architecture & Key Patterns

### MVVM with Riverpod
- **Models**: Immutable data classes with Firebase integration (`fromFirestore()`, `toMap()`, `copyWith()`)
- **Repositories**: Handle all Firebase operations (Firestore, Auth, Storage)
- **ViewModels**: Business logic using Riverpod providers and notifiers
- **Views**: UI components that consume providers via `Consumer` or `ref.watch()`

### Testing Strategy
- Use `ProviderScope.overrides` with `FirebaseTestOverrides.overrides` for dependency injection
- Test files mirror `lib/` structure in `test/` directory
- **Critical**: Always verify tests can fail by temporarily breaking functionality
- Group related tests with `group()` and use descriptive test names
- Use `testWidgets()` for UI tests and `test()` for pure logic

### Firebase Integration
- Firestore for data persistence with strongly-typed models
- Firebase Auth for user management
- Firebase Storage for file uploads
- Cloud Functions for server-side logic

## Key Guidelines

1. **Follow Flutter best practices** and Material Design principles
2. **Maintain MVVM separation**: Views should only consume providers, not call repositories directly
3. **Use Riverpod patterns**: Leverage providers for state management and dependency injection
4. **Write effective tests**: Ensure tests actually validate behavior and can fail when code breaks
5. **Handle async operations**: Use proper error handling and loading states in ViewModels
6. **Maintain immutability**: Use `copyWith()` methods for model updates
7. **Firebase best practices**: Use batch operations for multiple writes, implement proper error handling

## Common Commands

```bash
# Initial setup
cd Flutter/shelter_partner
flutter doctor
flutter pub get

# Development
flutter run -d chrome                    # Run on web (primary platform)
flutter test                            # Run all tests
flutter analyze                         # Static analysis
dart format .                           # Format code

# Build
flutter build web                       # Build for web deployment

# Troubleshooting
flutter clean && flutter pub get        # Reset dependencies
flutter doctor                          # Check Flutter setup
```

## Development Notes

- **Primary platform**: Web (other platforms disabled due to `dart:html` usage)
- **Flutter version**: 3.32.0 (locked in CI)
- **State management**: Riverpod 2.5.1+ with code generation
- **Backend**: Firebase (Firestore, Auth, Storage, Functions)
- **Testing**: Mock Firebase services using `fake_cloud_firestore` and `firebase_auth_mocks`

## Specific to This Codebase

- Models include Firestore integration patterns and should follow existing patterns
- Use existing `FirebaseTestOverrides.overrides` for test setup
- Follow the established directory structure when adding new features
- Print statements are discouraged (causes linting warnings) - use proper logging instead
- Maintain consistency with existing naming conventions and patterns
- When adding new providers, follow the established Riverpod patterns in the codebase