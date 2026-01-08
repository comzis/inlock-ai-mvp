# Script Unit Testing Plan

## Overview

This document outlines the plan for adding unit tests to critical scripts in the INLOCK infrastructure project.

**Status:** Planning Phase  
**Last Updated:** January 3, 2026

---

## Testing Framework

### Recommended: Bats (Bash Automated Testing System)

**Why Bats:**
- Native bash testing
- Simple syntax
- Good documentation
- Active maintenance

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install bats

# Or via npm
npm install -g bats

# Or from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Alternative: shellspec

**Why shellspec:**
- More advanced features
- Better reporting
- Mock support

**Installation:**
```bash
curl -fsSL https://git.io/shellspec | sh
```

---

## Testing Strategy

### Phase 1: Critical Scripts (High Priority)

**Backup Scripts:**
- `scripts/backup/automated-backup-system.sh`
- `scripts/backup/backup-databases.sh`
- `scripts/backup/backup-volumes.sh`
- `scripts/backup/monitor-backup-success-rate.sh`

**Security Scripts:**
- `scripts/security/fix-ssh-firewall-access.sh`
- `scripts/security/enable-ufw-complete.sh`
- `scripts/security/verify-ssh-restrictions.sh`

### Phase 2: Infrastructure Scripts (Medium Priority)

- `scripts/infrastructure/configure-firewall.sh`
- `scripts/infrastructure/manage-firewall.sh`
- `scripts/utilities/check-backup-readiness.sh`

### Phase 3: Utility Scripts (Low Priority)

- `scripts/utilities/check-cursor-compliance.sh`
- `scripts/utilities/cleanup-project.sh`

---

## Test Structure

### Directory Layout

```
scripts/
├── backup/
│   ├── automated-backup-system.sh
│   └── tests/
│       └── test-automated-backup-system.bats
├── security/
│   ├── fix-ssh-firewall-access.sh
│   └── tests/
│       └── test-fix-ssh-firewall-access.bats
└── utilities/
    ├── check-backup-readiness.sh
    └── tests/
        └── test-check-backup-readiness.bats
```

### Example Test File (Bats)

```bash
#!/usr/bin/env bats

# Test file: scripts/backup/tests/test-backup-databases.bats

load test_helper

@test "backup-databases.sh requires GPG" {
    # Test that script fails without GPG
    run ./scripts/backup/backup-databases.sh
    [ "$status" -eq 1 ]
    [ "$output" =~ "GPG is required" ]
}

@test "backup-databases.sh validates GPG recipient" {
    # Test GPG recipient validation
    export GPG_RECIPIENT=""
    run ./scripts/backup/backup-databases.sh
    [ "$status" -eq 1 ]
    [ "$output" =~ "GPG_RECIPIENT" ]
}

@test "backup-databases.sh creates backup directory" {
    # Test directory creation
    export BACKUP_DIR="/tmp/test-backup"
    run ./scripts/backup/backup-databases.sh
    [ -d "$BACKUP_DIR" ]
    [ -d "$BACKUP_DIR/encrypted" ]
}
```

---

## Test Coverage Goals

### Path Resolution Tests
- ✅ Absolute path resolution
- ✅ Relative path handling
- ✅ Missing directory handling

### Error Handling Tests
- ✅ Fail-fast on critical errors
- ✅ Proper exit codes
- ✅ Error message clarity

### Environment Variable Tests
- ✅ Default values
- ✅ Custom values
- ✅ Missing required variables

### Integration Tests
- ✅ Script interactions
- ✅ File system operations
- ✅ Docker operations (mocked)

---

## Implementation Steps

### Step 1: Setup Testing Infrastructure

1. Install Bats or shellspec
2. Create test directory structure
3. Create test helper functions
4. Add test runner script

### Step 2: Write Tests for Critical Scripts

1. Start with backup scripts
2. Add security script tests
3. Expand to infrastructure scripts

### Step 3: Integrate with CI/CD

1. Add test runner to CI pipeline
2. Require tests to pass before merge
3. Generate test coverage reports

### Step 4: Documentation

1. Document test structure
2. Add testing guidelines
3. Create test examples

---

## Test Helper Functions

Create `scripts/tests/test_helper.bash`:

```bash
# Test helper functions for Bats tests

setup() {
    # Setup test environment
    export TEST_DIR="/tmp/inlock-test-$$"
    mkdir -p "$TEST_DIR"
}

teardown() {
    # Cleanup test environment
    rm -rf "$TEST_DIR"
}

# Mock functions
mock_docker() {
    # Mock docker command
}

mock_gpg() {
    # Mock gpg command
}
```

---

## Running Tests

### Run All Tests

```bash
./scripts/tests/run-all-tests.sh
```

### Run Specific Test Suite

```bash
bats scripts/backup/tests/
```

### Run Single Test

```bash
bats scripts/backup/tests/test-backup-databases.bats
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Script Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats
      - name: Run Tests
        run: |
          ./scripts/tests/run-all-tests.sh
```

---

## Success Criteria

- ✅ All critical scripts have unit tests
- ✅ Test coverage > 80% for critical paths
- ✅ Tests run in CI/CD pipeline
- ✅ Tests are documented and maintainable

---

## Timeline

- **Q1 2026:** Setup testing infrastructure, write tests for backup scripts
- **Q2 2026:** Expand to security and infrastructure scripts
- **Q3 2026:** Full test coverage, CI/CD integration

---

## Resources

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [shellspec Documentation](https://shellspec.info/)
- [Bash Testing Best Practices](https://github.com/bats-core/bats-core)

---

**Next Steps:**
1. Install Bats testing framework
2. Create test directory structure
3. Write first test for `backup-databases.sh`
4. Integrate with CI/CD pipeline


