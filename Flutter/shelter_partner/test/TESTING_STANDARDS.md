# Testing Standards for ShelterPartner Flutter App

## 1. Test File Organization
- Place all test files in the `test/` directory, mirroring the structure of the `lib/` directory.
- For each Dart file in `lib/`, create a corresponding test file in `test/` (e.g., `lib/views/auth/login_page.dart` → `test/views/auth/login_page_test.dart`).

## 2. Test Naming Conventions
- Name test files with a `_test.dart` suffix.
- Use descriptive test names that explain the behavior being tested.

## 3. Writing Tests
- Use the `flutter_test` package for widget and unit tests.
- Group related tests using the `group()` function.
- Use `setUp()` and `tearDown()` for test initialization and cleanup.
- Prefer `testWidgets()` for widget tests and `test()` for pure Dart logic.

## 4. Dependency Injection & Mocking Strategy
- **Use Riverpod's `ProviderScope.overrides` to inject test dependencies.**
  - Override providers in your test setup to supply fake or mock implementations as needed.
  - This makes dependencies explicit and test setup clear.
  - Example:
    ```dart
    final widget = ProviderScope(
      overrides: [
        ...FirebaseTestOverrides.overrides,
      ],
      child: MaterialApp(
        home: LoginPage(key: key),
      ),
    );
    ```

*See existing test files for full usage patterns.*

## 5. Test Effectiveness Validation
**CRITICAL: Always verify that your tests can fail when the code they're testing is broken.**

This is essential to ensure your tests are actually testing the intended behavior and will catch regressions.

### Validation Process
After writing a test that passes, temporarily break the functionality and verify the test fails:

1. **For UI tests**: Change the text, remove UI elements, or modify widget properties
2. **For behavior tests**: Remove callbacks, change method calls, or alter logic
3. **For integration tests**: Break the data flow or remove key functionality

### Why This Matters
- **Prevents false security**: Tests that never fail provide false confidence
- **Catches test bugs**: Ensures your test setup and assertions are correct
- **Validates test scope**: Confirms you're testing the right behavior
- **Improves reliability**: Helps identify flaky or ineffective tests

## 7. Running Tests
- Run all tests with `flutter test` from the project root.
- **Before submitting code**: Ensure all tests pass AND verify that critical tests can fail when the code they test is broken.

---

For more details, see the [Flutter testing documentation](https://docs.flutter.dev/testing) and [Riverpod documentation](https://riverpod.dev/).
