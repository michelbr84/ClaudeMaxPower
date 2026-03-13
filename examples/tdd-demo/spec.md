# Feature Specification: Calculator

## Overview

Build a `Calculator` class in Python that supports basic arithmetic operations with full error handling.

## Requirements

### Core Operations

1. **Addition**: `add(a, b)` — returns `a + b`
2. **Subtraction**: `subtract(a, b)` — returns `a - b`
3. **Multiplication**: `multiply(a, b)` — returns `a * b`
4. **Division**: `divide(a, b)` — returns `a / b`

### Input Types

- All operations must accept `int` and `float` inputs
- All operations must return `float`

### Error Handling

- `divide(a, 0)` must raise `ZeroDivisionError` with message: `"Cannot divide by zero"`
- All operations with non-numeric inputs must raise `TypeError` with message: `"Operands must be numeric"`

### History

- The calculator must maintain a history of all operations performed
- `get_history()` returns a list of strings in the format: `"add(2, 3) = 5.0"`
- `clear_history()` clears the history and returns `None`

### Additional Operations

- `square_root(a)` — returns `math.sqrt(a)`
  - Raises `ValueError` with message `"Cannot take square root of negative number"` if `a < 0`
- `power(base, exp)` — returns `base ** exp`

## Example Usage

```python
calc = Calculator()
result = calc.add(2, 3)       # 5.0
result = calc.divide(10, 4)   # 2.5
calc.divide(1, 0)             # raises ZeroDivisionError
history = calc.get_history()  # ["add(2, 3) = 5.0", "divide(10, 4) = 2.5"]
calc.clear_history()
```

## Out of Scope

- No UI or CLI interface required
- No persistence (history lives only in memory)
- No support for complex numbers
