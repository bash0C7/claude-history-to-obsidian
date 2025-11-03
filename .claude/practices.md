# Practices & Methodologies

## 🧪 Test-Driven Development (t-wada Style)

### TDD Philosophy

Test-Driven Development (TDD) is "a tips collection for developer testing" (Kent Beck). It is not a revolutionary technique, but rather a practical approach designed by Kent Beck to make developer testing accessible and effective. TDD overcomes the uncertainty of software development by providing immediate feedback and enables continuous design evolution through small cycles of unit testing and refactoring.

**The Core Problem TDD Solves**: Working on code without immediate feedback on whether it works as expected. TDD provides instant verification instead of discovering problems months later.

### RED-GREEN-REFACTOR Cycle

TDD revolves around three simple laws (Robert C. Martin's formalization of Kent Beck's approach):

1. **Don't write production code** until you have a failing unit test
2. **Don't write more of a unit test** than is sufficient to fail (not compiling counts as failing)
3. **Don't write more production code** than is sufficient to pass the current failing test

### 7-Step TDD Process

1. **Conceptualize next goal** (from Test List)
2. **Write test demonstrating that goal**
3. **Execute test to ensure it fails** (RED)
4. **Write code to achieve objective**
5. **Execute test to confirm success** (GREEN)
6. **Refactor while tests remain passing** (REFACTOR)
7. **Repeat cycle**

### Test List (TODO List)

The Test List is a comprehensive enumeration of all desired functionality broken down into small, actionable items:

- List all desired functionality before starting
- Break down large requirements into small pieces
- Work on **ONE test at a time**
- Order by: 1) Test ease, 2) Importance
- Accept that "initial plans are typically flawed" - embrace iterative refinement
- Update list as new requirements emerge

### Three Implementation Strategies

1. **Fake It (仮実装)**:
   - Return hardcoded values first
   - Use when uncertain about implementation
   - Gradually generalize through additional tests
   - Example: `return 4` for `add(2, 2)`

2. **Obvious Implementation (明白な実装)**:
   - Directly implement straightforward solutions
   - Use when confident about implementation
   - Example: `a + b` for addition

3. **Triangulation (三角測量)**:
   - Use multiple test cases to drive generic code
   - Use when uncertain about implementation
   - Helps discover patterns from multiple examples

### Fake-Red Validation

Before implementing, validate that your test actually works:

1. Write a test that should fail
2. Intentionally change the assertion to an obviously wrong value
3. Verify the test fails (Fake-Red)
4. Fix the assertion back to correct value
5. Now implement with confidence that test will detect problems

### Step Size (Baby Steps)

Adjust stride between Fake It and Obvious Implementation:

- **Smaller steps**: When uncertain, use Fake It and Triangulation
- **Larger steps**: When confident, use Obvious Implementation
- Each decision should be nearly obvious
- Effort required should be "stupidly small"
- If stuck, reduce step size

### Testability Components

Design for testability with three key components:

- **Observability**: Can test verify the behavior?
  - Return values, state changes, side effects visible to tests

- **Controllability**: Can test operate/control the target?
  - Inputs controllable, dependencies injectable

- **Smallness**: Is target narrowly scoped?
  - Single responsibility, minimal dependencies

### Learning TDD

- **Theory vs. Practice**: Start with imitation, not theory. "Hands-on learning is most effective"
- **Code Transcription (写経)**: Copy and practice working examples to internalize patterns
- **Pair Programming**: Work with experienced TDD practitioners
- **Watch Others**: Learn by observing skilled developers through videos

### Core Philosophy

- "Limited minds can't pursue correct behavior AND correct structure simultaneously"
- RED-GREEN-REFACTOR separates these concerns:
  - RED-GREEN: Make it work (correct behavior)
  - REFACTOR: Make it right (correct structure)
- Software development IS continuous refactoring
- Refactoring requires supporting tests
- TDD enables "usable" design, not just "buildable" design

### Continuous Design Evolution

- Refactor constantly while tests remain green
- Each small refactoring improves structure
- Tests provide safety net for change
- Design emerges from tests (testability drives good design)

### Default Development Approach

**Important**: All feature development in this project uses t-wada style TDD by default.

- **When implementing features**: Use TDD automatically
- **When writing tests**: Apply RED-GREEN-REFACTOR cycle without asking
- **When refactoring**: Use TDD cycle and test list
- **Test list creation**: Always start with test list planning before coding
- **No need to ask**: TDD is the standard, not optional

**Exception**: Only if you explicitly say **"t-wadaには内緒でTDDしないでくれ"** (don't TDD, keep it secret from t-wada), will TDD be skipped for that specific task.

This ensures authentic TDD practice becomes the natural workflow in all development.

---

## 🌳 Git Subtree Management

This project can be embedded in other repositories using `git subtree` for multi-repo management and synchronization.

### Use Cases

1. **Embed in dotfiles repo**: Include this tool in your dotfiles for centralized management
2. **Shared team setup**: Distribute to team members via their own repos
3. **Monorepo integration**: Include as a component in larger project structure

### Initial Setup (Adding as Subtree)

```bash
# In your target repository
git subtree add --prefix tools/claude-history-to-obsidian \
  https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git main

# Verify
ls -la tools/claude-history-to-obsidian/
```

### Updating Subtree

```bash
# Pull latest changes from upstream
git subtree pull --prefix tools/claude-history-to-obsidian \
  https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git main

# Or use shorthand if remote exists
git subtree pull --prefix tools/claude-history-to-obsidian origin main
```

### Pushing Changes Back

```bash
# Commit changes locally first
git add .
git commit -m "Update claude-history-to-obsidian subtree"

# Push changes to subtree upstream
git subtree push --prefix tools/claude-history-to-obsidian \
  https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git main
```

### Add Remote for Easier Commands

```bash
# Add subtree remote
git remote add claude-history https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git

# Now use simpler commands
git subtree pull --prefix tools/claude-history-to-obsidian claude-history main
git subtree push --prefix tools/claude-history-to-obsidian claude-history main
```

### Best Practices

- **Isolate subtree changes**: Keep subtree commits separate from main repo changes
- **Pull before push**: Always pull latest before pushing subtree changes
- **Document subtree path**: Document where subtree is embedded in your project
- **Version tracking**: Reference upstream releases in commit messages
- **Avoid modifying**: Prefer upstream changes over local modifications

### Removing Subtree

```bash
# If needed, remove the subtree directory
git rm -r tools/claude-history-to-obsidian
git commit -m "Remove claude-history-to-obsidian subtree"

# Clean up history (optional, advanced)
git filter-branch --tree-filter 'rm -rf tools/claude-history-to-obsidian' HEAD
```

---

## 🤖 Claude Code Integration Best Practices

### Multi-Project Usage

When using this tool across multiple projects:

1. **Centralized Installation**: Install once in dotfiles or global tools directory
2. **Hook Configuration**: Each project's `.claude/settings.local.json` references the same binary
3. **Log Centralization**: All projects log to `~/.local/var/log/claude-history-to-obsidian.log`

Example hook configuration for multi-project:

```json
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "bash -c '~/.local/bin/claude-history-to-obsidian'"
      }]
    }
  }
}
```

### Using with Claude Code Projects

When using Claude Code in this project itself:

1. **Test with hook simulator**: Use `/tmp/hook-input.json` for local testing
2. **Monitor logs in real-time**: `tail -f ~/.local/var/log/claude-history-to-obsidian.log`
3. **Verify Obsidian sync**: Check `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/`
4. **Version control hooks**: Check in `.claude/settings.local.json` for reproducibility

### Performance Considerations

- **Hook execution time**: Typically < 100ms for transcript processing
- **iCloud sync**: Happens asynchronously, don't block on it
- **File I/O**: Bundle operations (reads transcript, writes output) efficiently
- **Memory footprint**: Minimal for reasonable transcript sizes (< 100MB)

### Debugging with Claude Code

Use these commands during Claude Code sessions:

```bash
# View recent logs
tail -20 ~/.local/var/log/claude-history-to-obsidian.log

# Monitor hook execution
tail -f ~/.local/var/log/claude-history-to-obsidian.log

# Test script directly
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

---

## 🔗 Related Documentation

- **@.claude/development.md** - Development environment and commands
- **@.claude/specifications.md** - Technical specifications
- **@CLAUDE.md** - Claude Code project overview
