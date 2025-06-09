# Golden Tests (Screenshot Tests)

This directory contains golden tests that verify the visual appearance of UI components by comparing screenshots against reference images.

## Quick Start

### Running Golden Tests

**Option 1: Local (Simple)**
```bash
cd Flutter/shelter_partner
./run_golden_tests_local.sh
```

**Option 2: Docker (Consistent Environment)**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh
```

### Updating Golden Images

When UI changes are intentional and golden tests fail:

**Local:**
```bash
cd Flutter/shelter_partner
./run_golden_tests_local.sh --update-goldens
```

**Docker:**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh --update-goldens
```

## Writing Golden Tests

1. Create test files in this directory with `_golden_test.dart` suffix
2. Tag all golden tests with `tags: ['golden']`
3. Use consistent viewport sizes
4. Handle async operations properly

Example:
```dart
testWidgets('my component appears correctly', (WidgetTester tester) async {
  // Set consistent viewport
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  
  // Build your widget
  await tester.pumpWidget(myWidget);
  
  // Wait for async operations
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  
  // Compare against golden image
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('my_component.png'),
  );
}, tags: ['golden']);
```

## CI/CD Integration

- Golden tests run automatically in GitHub Actions in a Docker container
- Regular tests exclude golden tests using `--exclude-tags golden`
- If golden tests fail in CI, failure images are uploaded as artifacts

## Important Notes

- Golden images are stored alongside test files (e.g., `login_page.png`)
- Always review updated golden images before committing
- Use Docker for consistent results across different machines
- Golden tests are excluded from regular test runs to keep them fast

For more details, see `../TESTING_STANDARDS.md`.