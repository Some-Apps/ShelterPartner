# Testing Standards for ShelterPartner Flutter App

## 1. Test File Organization
- Place all test files in the `test/` directory, mirroring the structure of the `lib/` directory.
- For each Dart file in `lib/`, create a corresponding test file in `test/` (e.g., `lib/views/auth/login_page.dart` → `test/views/auth/login_page_test.dart`).
- Place golden (screenshot) tests in `test/golden/` directory.

## 2. Test Naming Conventions
- Name test files with a `_test.dart` suffix.
- Use descriptive test names that explain the behavior being tested.
- For golden tests, use a `_golden_test.dart` suffix.

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
- Run all tests with `flutter test --exclude-tags golden` from the project root.
- Run only golden tests with `./run_golden_tests.sh` from the project root (requires Docker and bash).
- **Before submitting code**: Ensure all tests pass AND verify that critical tests can fail when the code they test is broken.

## 8. Golden Tests (Screenshot Tests)
Golden tests verify the visual appearance of UI components by comparing screenshots against reference images.

**📖 For complete golden test documentation, see [GOLDEN_TESTS.md](../GOLDEN_TESTS.md)**

### Quick Start
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh
```

### Key Requirements
- **Docker is required** for consistent rendering across different environments
- **Windows users**: Use Git Bash or WSL to run the bash script (not PowerShell)
- Tag all golden tests with `tags: ['golden']`
- Set consistent viewport sizes for reproducible screenshots
- Handle async operations properly before taking screenshots

### Example
```dart
testWidgets('login page appears correctly', (WidgetTester tester) async {
  // Set consistent viewport
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  
  await tester.pumpWidget(widget);
  
  // Wait for async operations
  await tester.pump();
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('login_page.png'),
  );
}, tags: ['golden']);
```

### Updating Golden Images
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh --update-goldens
```

**Important:** Always review updated golden images before committing them.

---

For more details, see the [Flutter testing documentation](https://docs.flutter.dev/testing) and [Riverpod documentation](https://riverpod.dev/).
