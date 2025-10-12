---
title: Test-Driven Development Workflow
last_updated: 2025-10-12
author: team
category: testing
tags: [tdd, testing, red-green-refactor, unit-tests]
applies_to: [all]
iron_law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"
when_to_use:
  - writing new features
  - fixing bugs
  - refactoring existing code
  - adding new functions or methods
---

# Test-Driven Development Workflow

## Purpose
To ensure code quality, maintainability, and correctness by writing tests before production code following the RED-GREEN-REFACTOR cycle.

## When to Use
- Writing new features
- Fixing bugs
- Refactoring existing code
- Adding new functions or methods

## Iron Law
**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**

## How to Use

### RED-GREEN-REFACTOR Cycle

1. **RED**: Write a failing test that defines the desired behavior
2. **GREEN**: Write the minimal production code to make the test pass
3. **REFACTOR**: Improve the code while keeping tests green

### Step-by-Step Process

1. **Understand Requirements**: Clearly define what the code should do
2. **Write Test First**: Create a test that fails because the functionality doesn't exist yet
3. **Run Test**: Confirm it fails (RED)
4. **Write Minimal Code**: Implement just enough to make the test pass
5. **Run Test**: Confirm it passes (GREEN)
6. **Refactor**: Clean up and improve the code
7. **Run Test**: Confirm it still passes after refactoring
8. **Repeat**: Continue with next piece of functionality

## Examples

### Example 1: Simple Function

**RED - Write failing test:**
```python
def test_calculate_area():
    result = calculate_area(5, 10)
    assert result == 50
```

**GREEN - Write minimal code:**
```python
def calculate_area(width, height):
    return width * height
```

**REFACTOR - Improve if needed:**
```python
def calculate_area(width, height):
    if width < 0 or height < 0:
        raise ValueError("Dimensions must be positive")
    return width * height
```

### Example 2: Class with Method

**RED - Write failing test:**
```python
def test_user_creation():
    user = User("john@example.com", "John Doe")
    assert user.email == "john@example.com"
    assert user.name == "John Doe"
    assert user.is_active == True
```

**GREEN - Write minimal code:**
```python
class User:
    def __init__(self, email, name):
        self.email = email
        self.name = name
        self.is_active = True
```

**REFACTOR - Add validation:**
```python
class User:
    def __init__(self, email, name):
        if not email or "@" not in email:
            raise ValueError("Invalid email format")
        if not name or len(name.strip()) == 0:
            raise ValueError("Name cannot be empty")
        
        self.email = email
        self.name = name.strip()
        self.is_active = True
```

## Common Mistakes

1. **Writing tests after code**: This defeats the purpose of TDD
2. **Writing too much code in GREEN phase**: Only write minimal code to pass the test
3. **Skipping REFACTOR phase**: Code quality degrades over time
4. **Writing tests that are too broad**: Tests should be specific and focused
5. **Not running tests frequently**: Run tests after each small change
6. **Writing integration tests instead of unit tests first**: Start with unit tests

## Testing This Skill

### Pressure Scenario 1: Urgent Bug Fix
**Situation**: Critical bug in production needs immediate fixing
**TDD Response**: Still write a failing test that reproduces the bug, then fix it
**Verification**: Bug is fixed and regression test exists

### Pressure Scenario 2: Complex Feature
**Situation**: Large, complex feature with many edge cases
**TDD Response**: Break into small pieces, write one test at a time
**Verification**: Each piece is tested and working before moving to next

### Pressure Scenario 3: Legacy Code
**Situation**: Need to modify untested legacy code
**TDD Response**: Write characterization tests first, then modify
**Verification**: Existing behavior is preserved, new functionality is tested

## Related Skills

- [Unit Testing](../testing/unit-testing/SKILL.md)
- [Test Coverage](../testing/test-coverage/SKILL.md)
- [Refactoring](../development/refactoring/SKILL.md)
- [Code Review](../workflow/code-review/SKILL.md)