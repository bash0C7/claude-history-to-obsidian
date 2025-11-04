---
name: tdd
description: Apply Test-Driven Development methodology following t-wada principles and Kent Beck's practices. Guide development through RED-GREEN-REFACTOR cycles with test lists, baby steps, and continuous refactoring.
---

# Test-Driven Development (t-wada Style)

Authentic Test-Driven Development following t-wada (和田卓人) principles and Kent Beck's "Test-Driven Development By Example." Guide development through RED-GREEN-REFACTOR cycles with test lists, small steps, and continuous refactoring.

## When to Use This Skill

Use this skill when:
- Starting new feature implementation
- Fixing bugs with test reproduction
- Refactoring existing code
- Learning new libraries/APIs (learning tests)
- Uncertain about implementation approach
- Need to decompose complex problems
- Want to ensure continuous test coverage
- Need guidance on step size and test strategy

## TDD Workflow

### Phase 0: Test Initialization Verification ⚠️ (MANDATORY)

**BEFORE starting TDD, ALWAYS verify current test status.**

This step guarantees that you're starting from a GREEN state (not RED).

#### Initialization Checklist

1. **Run ALL tests**:
   ```bash
   bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
   ```

2. **Verify Results**:
   - ✅ **All tests PASS**: Proceed to Phase 1 (Test List Creation)
   - ❌ **Any test FAILS**: STOP and return to user
     - There's a pre-existing issue in the codebase
     - Must be resolved BEFORE starting TDD
     - Report failure details to user

3. **Document Initial State**:
   - Note total test count
   - Note overall pass rate
   - This becomes your baseline

#### Why This Phase Exists

**Philosophy**: RED-GREEN-REFACTOR assumes you start from GREEN.

- If tests are already RED, you can't distinguish:
  - Tests failing due to your new code? (Normal)
  - Tests failing due to pre-existing issue? (Problem)
- RED phase becomes ambiguous
- New test failure is indistinguishable from existing failures

#### Implementation Notes

- Use subagent to run tests automatically
- Stop immediately if any test is RED
- Inform user of pre-existing issues
- Do NOT proceed with TDD until state is GREEN

---

### Phase 1: Test List Creation

#### Step 1: Create Test List (TODO List)

1. **Brainstorm all desired functionality**:
   - List everything you need to implement
   - Don't worry about order yet
   - Include edge cases and variants

2. **Break down into small, actionable items**:
   - Each item should be testable in isolation
   - Each item should take 15-30 minutes max
   - Be specific about inputs and outputs

3. **Order the list**:
   - **First by test ease**: Easier tests first (builds momentum)
   - **Then by importance**: High-value features before low-value ones
   - Dependencies before dependents

4. **Accept imperfection**:
   - "Initial plans are typically flawed" (t-wada)
   - List will evolve as you learn
   - Add new items as they emerge

#### Example Test List

```
Initial requirement: "Parse and validate user registration data"

Test List:
- [ ] Parse email from input
  - [ ] Extract valid email address
  - [ ] Reject empty email
  - [ ] Reject malformed email
- [ ] Parse name from input
  - [ ] Extract full name
  - [ ] Handle missing name
- [ ] Validate password strength
  - [ ] Require minimum 8 characters
  - [ ] Require mixed case
  - [ ] Require numbers
- [ ] Combine parsed data into user object
- [ ] Return validation errors for invalid data
```

#### Step 2: Progressive Decomposition

As you discover complexity, break items further:

```
Original: "Validate password strength"

Refined:
- [ ] Check minimum length (8 chars)
- [ ] Check for uppercase letters
- [ ] Check for lowercase letters
- [ ] Check for numbers
- [ ] Combine all checks into strength validator
```

#### Step 3: Discovery of Prerequisites

When blocked, add learning items:

```
If implementing "Database query for user search":
- [ ] LEARN: How to connect to test database
- [ ] LEARN: Ruby MySQL adapter syntax
- [ ] Simple query: SELECT by ID
- [ ] Query with WHERE clause
- [ ] Query with joins
```

### Phase 2: RED-GREEN-REFACTOR Cycle

For **EACH item** in test list:

#### RED Phase (失敗 - Make it fail)

1. **Select ONE item** from test list
2. **Write ONLY the test code**:
   ```ruby
   # Example: Testing addition
   def test_addition_of_two_positive_numbers
     assert_equal 5, add(2, 3)
   end
   ```

3. **Run the test** and confirm it **FAILS**:
   ```bash
   bundle exec ruby -I lib:test test/test_*.rb -v
   ```

4. **Verify failure reason** (Fake-Red Validation):
   - Change assertion to wrong value: `assert_equal 999, add(2, 3)`
   - Confirm it still fails for right reason
   - Fix assertion back to correct value

5. **Stop here** - resist writing implementation code

#### GREEN Phase (成功 - Make it pass)

1. **Write MINIMUM production code** to pass test:
   - No more, no less than needed
   - Hardcoding is OK (Fake It strategy)

2. **Choose implementation strategy**:

   **Strategy A: Fake It** (仮実装):
   ```ruby
   def add(a, b)
     5  # Hardcoded - when you're uncertain
   end
   ```
   - Use when: Uncertain about implementation
   - Then: Add more tests to force generalization

   **Strategy B: Obvious Implementation** (明白な実装):
   ```ruby
   def add(a, b)
     a + b  # Direct implementation - when confident
   end
   ```
   - Use when: Implementation is straightforward
   - Use when: You're very confident

   **Strategy C: Triangulation** (三角測量):
   ```ruby
   # Write test 1: assert_equal 5, add(2, 3)
   # Implementation: return 5

   # Write test 2: assert_equal 7, add(3, 4)
   # Implementation: return a + b  # Pattern emerges!
   ```
   - Use when: Uncertain but multiple examples help
   - Use when: Want extra safety

3. **Run test** and confirm **PASSES**:
   ```bash
   bundle exec ruby -I lib:test test/test_*.rb -v
   ```

4. **Ensure ALL tests pass**:
   - New test passes
   - Previous tests still pass
   - No regressions

#### REFACTOR Phase (改善 - Make it clean)

1. **Improve code structure** while keeping all tests green:
   - Remove duplication
   - Extract helper methods
   - Improve naming
   - Apply design patterns

2. **Refactor BOTH test code AND production code**:
   ```ruby
   # Before
   def test_add_two_positives
     assert_equal 5, add(2, 3)
   end

   def test_add_with_zero
     assert_equal 2, add(2, 0)
   end

   # Refactor: Extract common test helper
   def test_addition(a, b, expected)
     assert_equal expected, add(a, b)
   end

   def test_add_two_positives
     test_addition(2, 3, 5)
   end
   ```

3. **Run tests after EACH refactoring step**:
   - Refactor small piece
   - Run tests
   - Make sure tests pass
   - If any fail, revert immediately

4. **When to stop refactoring**:
   - Code is clean and understandable
   - No obvious duplication remains
   - Tests still pass
   - Move to next item

### Phase 3: Repeat Until Done

1. **Mark item as completed** on test list
2. **Review test list**:
   - Did you discover new items? Add them
   - Did priorities change? Reorder
   - Are any items now clearer/simpler? Update them

3. **Select next item** from list
4. **Return to Phase 2** (RED-GREEN-REFACTOR)
5. **Repeat until test list is empty**

## Step Size (Baby Steps) Guidance

### When to Take Smaller Steps

Use smaller steps when:
- **Implementation approach unclear**
- **Problem domain unfamiliar**
- **Learning new technology**
- **Bug is hard to reproduce**
- **Team is new to TDD**

Small step strategies:
- Use "Fake It" strategy
- Add more tests before generalizing
- Use Triangulation to discover patterns
- Break test into even smaller pieces

### When to Take Larger Steps

Use larger steps when:
- **Implementation obvious to you**
- **Problem domain very familiar**
- **Working in well-known patterns**
- **Team is experienced with TDD**
- **Bug is easy to reproduce and fix**

Larger step strategies:
- Use "Obvious Implementation" strategy
- Write more comprehensive tests
- Trust your experience and intuition

### Step Size Indicators

✅ Good step size:
- Each decision is nearly obvious
- Effort required is "stupidly small" (5-10 minutes)
- You finish before overthinking
- Tests pass immediately

❌ Too large step:
- You get stuck mid-implementation
- You need more than 30 minutes
- You're uncertain about approach
- You write multiple features at once

❌ Too small step:
- Each cycle takes < 1 minute
- You're making no visible progress
- You're testing trivial things
- Consider combining steps

## The Three Laws of TDD

Follow strictly for authentic TDD:

**Law 1: Don't write production code until you have a failing unit test**
- ALWAYS write test first
- Production code ONLY in response to test failure
- No "just implementing" without tests

**Law 2: Don't write more of a unit test than is sufficient to fail**
- Test should fail for good reason (not just missing method)
- Not compiling = failing (counts!)
- One assert is enough to start

**Law 3: Don't write more production code than is sufficient to pass**
- MINIMUM code to make test pass
- Hardcoding is acceptable
- Generalization comes through more tests

These laws ensure tight coupling between test and code, small steps, and continuous feedback.

## Testability Guidelines

Design code with three testability components in mind:

### Observability (観測可能性)

**Definition**: Can test code verify the behavior?

**Questions**:
- Can I see what happened?
- Can I capture return values?
- Can I inspect state changes?
- Can I verify side effects?

**Examples**:
```ruby
# Good observability - can verify behavior
def calculate_total(items)
  items.sum(&:price)  # Returns value, observable
end

# Poor observability - no return value, no state change
def calculate_total(items)
  items.each { |item| puts item.price }  # Can't test!
end
```

### Controllability (制御可能性)

**Definition**: Can test code operate and control the target?

**Questions**:
- Can I set up inputs?
- Can I inject dependencies?
- Can I control external services?
- Can I isolate the unit?

**Examples**:
```ruby
# Good controllability - can inject dependencies
class UserValidator
  def initialize(email_service)
    @email_service = email_service
  end

  def valid?(user)
    @email_service.exists?(user.email)
  end
end

# Poor controllability - hardcoded dependency
class UserValidator
  def valid?(user)
    EmailService.exists?(user.email)  # Can't control!
  end
end
```

### Smallness (小ささ)

**Definition**: Is the target narrowly scoped?

**Questions**:
- Does it have one responsibility?
- Does it have minimal dependencies?
- Is it isolated from other concerns?
- Can I test it in isolation?

**Examples**:
```ruby
# Good smallness - focused responsibility
def validate_email(email)
  email.include?('@')
end

# Poor smallness - too many responsibilities
def validate_user(user)
  # Email validation, password strength, age checking,
  # database lookup, sending verification email, etc.
  # Can't test one thing in isolation!
end
```

## Common TDD Patterns

### Learning Test Pattern

When learning a new library or API:

```ruby
def test_http_client_basic_get
  # Before implementing feature, write test to understand library
  client = HttpClient.new
  response = client.get("https://api.example.com/data")

  assert_equal 200, response.status_code
  assert_includes response.body, "expected_data"
end
```

1. Write test exploring the API
2. Make it pass to understand the library
3. Document your understanding through tests
4. Now implement your feature with confidence

### Characterization Test Pattern

When refactoring legacy code without tests:

```ruby
def test_calculate_discount_current_behavior
  # Test captures CURRENT behavior (even if wrong)
  # Allows safe refactoring
  assert_equal 15, calculate_discount(100, 0.15)
end
```

1. Write test capturing current behavior
2. Make it pass (may be wrong, but that's OK)
3. Refactor with safety net
4. Now add tests for correct behavior

## Fake-Red Validation Example

```ruby
# Step 1: Write failing test
def test_string_reversal
  assert_equal "dlrow", reverse("world")
end

# Run: FAILS ✓ (method doesn't exist)

# Step 2: Fake-Red validation (OPTIONAL but recommended)
def test_string_reversal
  assert_equal "WRONG", reverse("world")  # Wrong expectation
end

# Run: FAILS ✓ (confirms test logic works)

# Step 3: Fix test back to correct assertion
def test_string_reversal
  assert_equal "dlrow", reverse("world")
end

# Step 4: Implement (Fake It - hardcoded)
def reverse(str)
  "dlrow"  # Hardcoded - when uncertain
end

# Run: PASSES ✓

# Step 5: Add test to force generalization
def test_reverse_another_word
  assert_equal "oof", reverse("foo")
end

# Run: FAILS (expected "oof", got "dlrow")

# Step 6: Generalize implementation
def reverse(str)
  str.reverse  # Now works for all cases
end

# Run: PASSES ✓

# Step 7: Refactor
def reverse(str)
  str.reverse  # No duplication, clear intent
end

# Run: PASSES ✓
```

## Anti-Patterns to Avoid

❌ **Multiple tests at once**
- Write ONE test, make it pass, before next test
- Violates Law 2

❌ **Writing tests AFTER code**
- That's unit testing, not TDD
- Misses the design benefits
- Less effective at catching bugs

❌ **Modifying production code/config before writing tests**
- Plan → Code → Test is Test-Last Development
- You MUST write test BEFORE touching production code
- You MUST write test BEFORE modifying config files
- If you discover failure after implementation, you're doing it wrong
- **改修計画 = テストコード** (Implementation plan = Test code)

**Correct workflow**:
1. Plan the change (understand requirement)
2. Write test expressing the plan
3. Run test to see RED
4. Modify production code or config files
5. Run test to see GREEN
6. Refactor

**Wrong workflow**:
1. ❌ Modify production code/config
2. ❌ Run test
3. ❌ Discover failure
4. ❌ Fix test or code

❌ **Skipping RED phase**
- Always run tests and see them fail first
- Ensures tests work correctly
- Validates Fake-Red

❌ **Over-engineering in GREEN**
- Don't build perfect solution on first try
- Use Fake It to get to green quickly
- Generalization comes through more tests

❌ **Skipping REFACTOR**
- Refactoring is where design improves
- Without it, code degrades over time
- Tests provide safety for refactoring

❌ **Large steps**
- Try to do too much at once
- Gets stuck, loses momentum
- Reduces feedback frequency

❌ **Not running tests frequently**
- Run after every change
- Run after every refactoring step
- Immediate feedback is the value

❌ **Treating TDD as dogma**
- "Must have 100% coverage"
- "Every test must be written first"
- TDD is a practical tool, not religion
- Adapt to context, but keep core principles

## Success Indicators

✅ You're doing TDD well when:

- Tests written BEFORE production code
- Test list guides your development
- Each cycle takes 5-15 minutes
- All tests remain green after each change
- Code structure improves over time (refactoring works)
- You're confident making changes (tests provide safety)
- New features fail existing tests first, then pass
- Design emerges from tests (testability drives architecture)
- Small, focused classes with single responsibility
- Minimal dependencies between components
- Tests read like documentation
- No "TODO" comments in code (tests list them!)

## Error Recovery

### Stuck in RED (Test won't fail)

**Symptom**: Test passes without code change

**Solutions**:
1. Verify test is actually different from previous version
2. Check test is testing new behavior, not existing
3. Ensure you're running the right test file
4. Try: `bundle exec ruby -I lib:test test/test_*.rb -v`

### Stuck in GREEN (Can't make test pass)

**Symptom**: Test fails but can't figure out implementation

**Solutions**:
1. **Reduce step size**: Break test into smaller pieces
2. **Use Fake It**: Return hardcoded value
3. **Add more context**: What are you uncertain about?
4. **Try Triangulation**: Add another test case first
5. **Take a break**: Sometimes fresh eyes help

### Stuck in REFACTOR (Risk of breaking tests)

**Symptom**: Want to refactor but scared of breaking tests

**Solutions**:
1. **Take smaller refactoring steps**: Change one thing
2. **Run tests after each step**: Instant feedback
3. **If test breaks, revert immediately**: `git checkout file`
4. **Skip refactoring for now**: Mark as TODO
5. **Trust your tests**: They catch regressions!

## Output Format When Guiding TDD

When you guide someone through TDD:

### 1. Show Test List

```
📋 Test List:
- [x] Parse email address
- [ ] Validate email format      ← Current focus
  - [ ] Reject empty email
  - [ ] Reject malformed email
- [ ] Generate validation message
- [ ] Return validation result
```

### 2. Announce Phase

```
🔴 RED Phase: Writing test for "Validate email format"
🟢 GREEN Phase: Implementing code to pass test
🔵 REFACTOR Phase: Improving structure
```

### 3. Explain Strategy

```
Using "Fake It" strategy (implementation uncertain)
Using "Obvious Implementation" strategy (straightforward)
Using "Triangulation" strategy (multiple examples)
```

### 4. Show Test Code

```ruby
# RED: Write the test
def test_email_validation_rejects_empty
  assert_equal false, valid_email?("")
end
```

### 5. Show Implementation

```ruby
# GREEN: Minimum code to pass
def valid_email?(email)
  email.include?("@")
end

# REFACTOR: Better version
def valid_email?(email)
  !email.empty? && email.include?("@")
end
```

### 6. Update Progress

```
📋 Test List:
- [x] Parse email address
- [x] Validate email format
  - [x] Reject empty email
  - [ ] Reject malformed email   ← Next
- [ ] Generate validation message
```

## Core TDD Philosophy Reminders

> "TDD is a tips collection for developer testing" - Kent Beck

> "Limited minds can't pursue correct behavior AND correct structure simultaneously" - Kent Beck

**What this means**:
- You can't think about two things at once
- RED-GREEN-REFACTOR separates concerns
- RED-GREEN: Focus on making it work
- REFACTOR: Focus on making it clean

> "Initial plans are typically flawed" - t-wada

**What this means**:
- Your test list will evolve
- Embrace feedback and changes
- Iterative refinement is the process
- Perfection comes through repetition

> "Hands-on learning is most effective" - t-wada

**What this means**:
- Watch experienced developers
- Copy and practice patterns (写経)
- Pair programming accelerates learning
- Don't memorize rules, feel the rhythm

## TDD in Practice (Ruby with Test::Unit)

### Setup

```bash
# Install test-unit
bundle add test-unit --group development

# Create test file
mkdir -p test
touch test/test_calculator.rb
```

### Test File Structure

```ruby
require 'test/unit'
require_relative '../lib/calculator'

class TestCalculator < Test::Unit::TestCase
  def test_addition
    calc = Calculator.new
    assert_equal 5, calc.add(2, 3)
  end

  def test_subtraction
    calc = Calculator.new
    assert_equal -1, calc.subtract(2, 3)
  end
end
```

### Run Tests

```bash
# Run specific test file
bundle exec ruby -I lib:test test/test_calculator.rb

# Run all tests with verbose output
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb -v

# Run with color output
bundle exec ruby -I lib:test test/test_calculator.rb -v --color
```

### Common Test::Unit Assertions

```ruby
assert(condition)                    # condition must be true
assert_equal(expected, actual)       # values must be equal
assert_not_equal(unexpected, actual) # values must differ
assert_nil(value)                    # value must be nil
assert_not_nil(value)                # value must not be nil
assert_raises(Exception) { code }    # code must raise exception
assert_includes(array, item)         # array must include item
assert_empty(collection)             # collection must be empty
assert_true(value)                   # value must be true
assert_false(value)                  # value must be false
```

## Getting Started with TDD in This Project

1. **Review CLAUDE.md TDD Section** for philosophy and principles
2. **Read Kent Beck's "Test-Driven Development By Example"** Part I (Money Example)
3. **Watch t-wada presentations** on YouTube for practical examples
4. **Practice with small kata**: Project Euler problems or Code Wars
5. **Pair program** with experienced TDD practitioner
6. **Start applying to real features** in this project

Remember: TDD is a skill that improves with practice. Start small, be patient with yourself, and embrace the rhythm of RED-GREEN-REFACTOR.

---

## 🚀 Implementation: Automatic Test Verification

### When TDD Skill is Invoked

**Automatic Process**:

1. **Phase 0 Execution** (Mandatory):
   ```
   1. Run: bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
   2. Parse output for pass/fail status
   3. If PASS → Continue to Phase 1
   4. If FAIL → Stop and report to user
   ```

2. **Report Baseline State**:
   ```
   ✅ Current Test Status:
   - Total Tests: N
   - Assertions: N
   - Pass Rate: 100%

   ✔️ GREEN baseline established. Ready for TDD.
   ```

3. **If Tests FAIL**:
   ```
   ❌ Pre-existing Test Failure Detected:

   [Show failing test details]

   🛑 STOP: Cannot start TDD with RED tests.

   Action Required:
   - Fix failing tests first
   - Re-run to establish GREEN baseline
   - Then contact me to continue TDD
   ```

### TodoWrite Integration

Phase 0 results feed into TodoWrite:

```
1. ✅ [Verify test baseline is GREEN]
2. [ ] [RED: Write failing test for feature]
   (This only becomes active if Phase 0 passes)
3. [ ] [GREEN: Implement code]
4. [ ] [REFACTOR: Improve structure]
```

If Phase 0 fails:
```
⚠️ Pre-requisite Issue: Test baseline is RED
- Task list creation BLOCKED
- User intervention needed
```

### User Communication

**Success Case**:
```
✔️ Phase 0: Test Initialization Verification PASSED

Baseline Status:
- 9 tests, 24 assertions
- 100% pass rate

Now proceeding to Phase 1: Test List Creation...
```

**Failure Case**:
```
❌ Phase 0: Test Initialization Verification FAILED

Pre-existing failures detected:
- test_claude_history_importer.rb: 2 failures
- test_claude_history_to_obsidian.rb: 1 failure

🛑 Cannot start TDD with RED tests.

Next Steps:
1. Review error details above
2. Fix failing tests
3. Run tests again: bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
4. Once all tests pass, contact me to continue TDD
```

---

## Critical Rule: GREEN Before RED

**Never skip Phase 0**. This rule prevents:
- ❌ Confusing pre-existing failures with new failures
- ❌ Writing RED tests for already-broken code
- ❌ Misalignment between test and code changes
- ❌ Loss of development momentum

**Always**:
1. Verify GREEN baseline
2. Write RED test (one at a time)
3. Write GREEN implementation
4. REFACTOR while green

**If Phase 0 fails**: Stop immediately, report to user, fix issues first.
