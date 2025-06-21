# Golden Tests Documentation

Golden tests (also known as screenshot tests or visual regression tests) verify the visual appearance of UI components by comparing screenshots against reference images. This ensures that UI changes are intentional and helps catch unintended visual regressions.

## Prerequisites

### Docker Installation
Golden tests **require Docker** to ensure consistent rendering across different operating systems, fonts, and environments.

**Install Docker:**
- **Windows/Mac**: Download Docker Desktop from [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
- **Linux**: Follow the installation guide for your distribution at [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

**Verify Docker Installation:**
```bash
docker --version
docker info
```

If `docker info` fails, ensure Docker Desktop is running.

### Shell Requirements (Windows Users)
The golden test script (`run_golden_tests.sh`) is a bash script. **Windows users** need to use one of the following:

- **Git Bash** (recommended) - Comes with Git for Windows: [https://git-scm.com/download/win](https://git-scm.com/download/win)
- **Windows Subsystem for Linux (WSL)** - [https://docs.microsoft.com/en-us/windows/wsl/install](https://docs.microsoft.com/en-us/windows/wsl/install)
- **PowerShell with bash** - If you have bash available in your PATH

**Windows users should run commands in Git Bash, not PowerShell or Command Prompt.**

## Running Golden Tests

### Quick Commands

**Windows users**: Use Git Bash, WSL, or another bash-compatible shell for these commands.

**Run all golden tests:**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh
```

**Update golden images after UI changes:**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh --update-goldens
```

**Run specific golden test:**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh --name "login page appears correctly"
```

### Alternative Methods

**Using the Docker script directly:**
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh
```

**Manual Docker command:**
```bash
cd Flutter/shelter_partner
docker build -t flutter-golden-tests -f Dockerfile.golden .
docker run --rm -v "$(pwd)/test:/app/test" -v "$(pwd)/assets:/app/assets" flutter-golden-tests
```

**To update golden images manually:**
```bash
cd Flutter/shelter_partner
docker build -t flutter-golden-tests -f Dockerfile.golden .
CONTAINER_NAME="golden-tests-$(date +%s)"
docker run --name "$CONTAINER_NAME" -v "$(pwd)/test:/app/test" -v "$(pwd)/assets:/app/assets" flutter-golden-tests --update-goldens
docker cp "$CONTAINER_NAME:/app/test/golden/" "./test/"
docker rm "$CONTAINER_NAME"
```

## Writing Golden Tests

### Basic Structure

1. **Location**: Place golden tests in `test/golden/` directory
2. **Naming**: Use `_golden_test.dart` suffix (e.g., `login_page_golden_test.dart`)
3. **Tagging**: Add `@Tags(['golden'])` at the top of the file and, to avoid IDE warnings, add a `library` directive immediately after, e.g.:
   ```dart
   @Tags(['golden'])
   library my_widget_golden_test;
   ```
4. **Viewport**: Set consistent viewport size for reproducible screenshots

### Example Golden Test

```dart
@Tags(['golden'])
library my_widget_golden_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shelter_partner/views/my_widget.dart';
import '../helpers/firebase_test_overrides.dart';

void main() {
  group('MyWidget Golden Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    Future<Widget> createTestWidget() async {
      return ProviderScope(
        overrides: FirebaseTestOverrides.overrides,
        child: const MaterialApp(
          home: MyWidget(),
        ),
      );
    }

    void setupTestViewport(WidgetTester tester) {
      // Set consistent viewport size
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('my widget appears correctly', (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);
      final widget = await createTestWidget();

      // Act
      await tester.pumpWidget(widget);
      
      // Wait for async operations to complete
      await tester.pump();
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('my_widget.png'),
      );
    });
  });
}
```

### Best Practices

1. **Consistent Viewport**: Always set the same viewport size for reproducible results
2. **Handle Async Operations**: Use `pump()` with delays to ensure loading states complete
3. **Avoid Random Data**: Use fixed test data to ensure consistent screenshots
4. **Minimal Dependencies**: Only override necessary providers for the test
5. **Descriptive Names**: Use clear, descriptive test and file names

## Updating Golden Images

When you make intentional UI changes, golden tests will fail. To update the reference images:

1. **Run tests with update flag:**
   ```bash
   ./run_golden_tests.sh --update-goldens
   ```
   
   This will:
   - Run the golden tests in Docker
   - Update any mismatched golden images with the new screenshots inside the container
   - Copy the updated images from the container back to your local `test/golden/` directory
   - Clean up the temporary container

2. **Review the changes:**
   - Check the updated PNG files in `test/golden/`
   - Ensure changes match your expectations
   - Verify no unintended visual regressions

3. **Commit the updated images:**
   ```bash
   git add test/golden/*.png
   git commit -m "Update golden test images after UI changes"
   ```

**Note**: When using `--update-goldens`, the script runs the tests in a named Docker container, then copies the updated golden images from the container to your local filesystem. This ensures that updated images are available regardless of Docker volume mounting issues.

## Troubleshooting

### Common Issues

**Docker not found:**
```
Error: Docker is required but is not installed
```
- Install Docker from [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)

**Docker not running:**
```
Error: Docker is installed but not running
```
- Start Docker Desktop application

**Script won't run (Windows):**
```
bash: ./run_golden_tests.sh: No such file or directory
```
- Use Git Bash instead of PowerShell or Command Prompt
- Or install WSL: [https://docs.microsoft.com/en-us/windows/wsl/install](https://docs.microsoft.com/en-us/windows/wsl/install)

**Tests timeout:**
- Increase wait time between `pump()` calls
- Ensure all async operations complete before taking screenshot

**Inconsistent results:**
- Always use Docker for golden tests
- Ensure viewport size is set consistently
- Check for animations or time-dependent content

**Large golden files:**
- Consider reducing viewport size
- Optimize images if necessary

### Getting Help

- Check existing golden tests in `test/golden/` for examples
- Review `test/TESTING_STANDARDS.md` for general testing guidelines
- Ask questions in GitHub issues or discussions

## CI/CD Integration

Golden tests run automatically in GitHub Actions:

- **Location**: `.github/workflows/flutter_golden_tests.yml`
- **Environment**: Ubuntu with Docker for consistency
- **Failure Handling**: Screenshots of failures are uploaded as artifacts
- **Exclusion**: Regular tests exclude golden tests using `--exclude-tags golden`

### Viewing CI Failures

If golden tests fail in CI:

1. Go to the failed GitHub Actions run
2. Download the "golden-test-failures" artifact
3. Review the failure images to understand the differences
4. Update golden images locally if changes are intended

## File Structure

```
test/golden/
├── README.md                     # Quick reference
├── login_page_golden_test.dart   # Test file
├── login_page.png               # Reference image
└── ...                          # Other golden tests
```

## Advanced Usage

### Running Specific Tests

```bash
# Run tests matching a pattern
./run_golden_tests.sh --name "login"

# Run all golden tests in a specific file
./run_golden_tests.sh test/golden/login_page_golden_test.dart
```

### Custom Docker Arguments

```bash
# Pass additional arguments to Flutter test
./run_golden_tests.sh --verbose --reporter=expanded
```

### Debugging Failed Tests

```bash
# Run with verbose output
./run_golden_tests.sh --verbose

# Update specific test only
./run_golden_tests.sh --update-goldens --name "specific test name"
```

---

For more information about testing in general, see `test/TESTING_STANDARDS.md`.
