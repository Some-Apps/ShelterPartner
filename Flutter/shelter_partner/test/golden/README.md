# Golden Tests (Screenshot Tests)

This directory contains golden tests that verify the visual appearance of UI components by comparing screenshots against reference images.

## Quick Start

**📖 For complete documentation, see [GOLDEN_TESTS.md](../../GOLDEN_TESTS.md)**

### Prerequisites
- **Docker is required** - Install from [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
- **Windows users** - Use Git Bash, WSL, or bash-compatible shell (not PowerShell)

### Running Golden Tests
**Windows users**: Use Git Bash or WSL, not PowerShell.

```bash
cd Flutter/shelter_partner
./run_golden_tests.sh
```

### Updating Golden Images
When UI changes are intentional and golden tests fail:
```bash
cd Flutter/shelter_partner
./run_golden_tests.sh --update-goldens
```


**📖 For complete documentation including troubleshooting, advanced usage, and best practices, see [GOLDEN_TESTS.md](../../GOLDEN_TESTS.md)**