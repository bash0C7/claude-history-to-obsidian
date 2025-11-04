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

### ⚠️ Critical Rule: Test-First Enforcement

**NEVER modify production code or configuration files before writing tests.**

### Phase 0: Test Baseline Verification (先制条件)

**BEFORE starting ANY TDD cycle, ALWAYS verify that all tests are GREEN.**

This ensures:
- ✅ You start from a known-good state
- ✅ NEW test failures are from YOUR code, not pre-existing issues
- ✅ RED phase is unambiguous (new test you wrote, not old breakage)
- ✅ Development momentum isn't lost on debugging unrelated failures

**Verification Process**:
```bash
# Run all tests
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
```

**Results**:
- ✅ **All tests PASS** → Continue to TDD cycle
- ❌ **Any test FAILS** → STOP, report to user, fix issues first

**Correct Cycle**:
1. **Verify Baseline** → Run all tests (Phase 0)
2. **Plan** → Understand the requirement
3. **Write Test** → Express the plan as test code (改修計画 = テストコード)
4. **Run Test (RED)** → Confirm test fails intentionally
5. **Write Code** → Modify production code/config files
6. **Run Test (GREEN)** → Confirm test passes
7. **Refactor** → Improve code structure

**Wrong Cycle (Test-Last Development)**:
1. ❌ Plan → Modify production code/config → Run test → Fail → Fix
2. ❌ This is NOT TDD, this is Test-After Development

**Examples**:

❌ **Wrong**:
```
1. Edit lib/foo.rb to add new feature
2. Run tests
3. Notice test failure
4. Fix test
```

✅ **Correct**:
```
1. Write test_foo.rb with test for new feature
2. Run test → RED (fails as expected)
3. Edit lib/foo.rb to implement feature
4. Run test → GREEN (passes)
5. Refactor
```

**Key Insight**: If you discover a failure AFTER implementation, you're doing Test-Last, not Test-First.

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

## 🌳 Git Worktree Session Management for Parallel Development

### Overview

Git worktrees enable multiple Claude Code sessions to run in parallel without interference. Each worktree is an isolated working directory with its own branch, allowing safe concurrent development on different features.

### Why Use Worktrees?

**Traditional Sequential Workflow** (problems):
```
Session 1: Work on feature A
  → Finish and merge
  → Create new branch for feature B
  → Wait for previous work to complete

Session 2: Meanwhile... can't start until Session 1 is done
```

**Worktree Parallel Workflow** (benefits):
```
Session 1: feature-a     (worktree 1)  ← Independent
Session 2: feature-b     (worktree 2)  ← Independent
Session 3: bugfix-c      (worktree 3)  ← Independent

All progress in parallel, merge when each is done
```

### Worktree Lifecycle

```
┌─ Start: @worktree-session feature-name
├─ Setup: bundle install, environment configuration
├─ Work:  Claude Code session in worktree
├─ Merge: git merge feature-name → main
├─ Resolve: Handle conflicts if any
└─ Cleanup: git worktree remove (automatic)
```

### Storage Location

Worktrees are stored in `~/.cache/claude-worktrees/{project}/{branch}/`:

- **Why cache?**: One-time use per branch, survives restarts but cleanable
- **Not in project**: Keeps main repo clean
- **Isolated environment**: Each worktree has independent `vendor/bundle/`, logs, etc.

### Session Initialization

Using the global `worktree-session` subagent:

```bash
# Start new worktree session
@worktree-session my-feature-name

# The subagent automatically:
# 1. Creates worktree at ~/.cache/claude-worktrees/...
# 2. Runs bundle install
# 3. Sets up environment variables (isolated log paths, etc.)
# 4. Shows you the path and next steps
# 5. Guides you to open Claude Code in the new worktree
```

### Parallel Session Management

**Concurrent Sessions**:
```bash
# Terminal 1 - Main project analysis
cd /Users/bash/src/claude-history-to-obsidian
@worktree-session feature-web-import

# Terminal 2 - Separate feature work
cd /Users/bash/src/another-project
@worktree-session fix-json-parsing

# Each session is completely isolated
# No merge conflicts, no interference
```

**Session Ordering**: Merge in any order—completions are independent.

### Session Completion & Merge

When your Claude Code work in the worktree is done:

```bash
# In the original main repository terminal
@worktree-session --merge feature-web-import
```

The subagent:
1. **Checks out main branch**
2. **Attempts fast-forward merge** first (if no conflicts)
3. **Handles conflicts** (with your help if needed)
   - Shows conflict markers
   - Guides resolution
   - Offers to abort and retry
4. **Deletes worktree** after successful merge
5. **Cleans up branch** with `git branch -d`

### Conflict Resolution

**Automated handling**:
```bash
# Most merges succeed automatically (fast-forward or clean merge)
# Subagent handles these without intervention
```

**Manual intervention when needed**:
```bash
# If conflicts detected:
# 1. Subagent shows: "Merge conflict detected in X files"
# 2. Subagent lists conflicted files
# 3. You resolve manually in editor (<<<< >>>> markers)
# 4. Subagent verifies and completes merge

# Or abort and retry:
git merge --abort
git branch -d <branch>  (if needed)
git worktree remove ~/.cache/...
```

### Environment Isolation

Each worktree maintains independent:

| Item | Storage | Isolation |
|------|---------|-----------|
| Gems | `vendor/bundle/` | Per-worktree (bundle install) |
| Logs | `~/.local/var/log/` | Configurable env var per session |
| Temp | `~/.cache/worktree-tmp/` | Per-worktree subdirectory |
| Env vars | Per-terminal | Claude Code session specific |

**Example**: Log path separation
```bash
# Session 1
export CLAUDE_LOG_PATH=~/.local/var/log/claude-wt-feature.log

# Session 2 (different terminal)
export CLAUDE_LOG_PATH=~/.local/var/log/claude-wt-fix.log

# Each logs independently, no interference
```

### Best Practices

1. **Branch Naming Convention**
   ```
   feature/<description>     - New feature
   fix/<description>        - Bug fix
   refactor/<description>   - Code refactoring
   test/<description>       - Test additions
   docs/<description>       - Documentation
   ```

2. **Session Focus**
   - One feature/fix per worktree
   - Keep work scope limited
   - Merge frequently to avoid large conflicts

3. **Dependency Management**
   - First `bundle install` slower (downloads gems)
   - Subsequent worktrees reuse cache
   - Expect 10-30 seconds setup per new worktree

4. **Log Monitoring**
   ```bash
   # Monitor one session's logs
   tail -f ~/.local/var/log/claude-wt-feature.log

   # Keep different logs for different sessions
   ```

5. **Cleanup Policy**
   - Automatic after merge completion
   - Manual cleanup if needed:
     ```bash
     git worktree list                    # See all
     git worktree remove --force ~/.c...  # Force remove
     ```

### Common Patterns

**Pattern 1: Sequential Features** (one at a time)
```bash
Session 1: @worktree-session feature-a → merge → cleanup
Session 2: @worktree-session feature-b → merge → cleanup
```

**Pattern 2: Parallel Experimentation** (try multiple approaches)
```bash
Session 1: @worktree-session approach-option-1
Session 2: @worktree-session approach-option-2
Session 3: @worktree-session approach-option-3
# Compare results, merge best, delete others
```

**Pattern 3: Long-running + Quick Fixes** (main work + interruptions)
```bash
Session 1: Main project (main branch)
  └─ Interrupted by bug

Session 2: @worktree-session emergency-fix
  └─ Merge → unblock main work

Session 1: Continue with latest code
```

### Troubleshooting

**Worktree creation fails**
```bash
git worktree list  # See existing worktrees
# If orphaned, remove with --force
git worktree remove --force ~/.cache/...
```

**Merge conflicts overwhelming**
```bash
git merge --abort              # Cancel merge
git branch -d <branch>         # Clean up (if safe)
git worktree remove --force $PATH  # Force remove worktree
# Then start fresh
```

**Environment issues in worktree**
```bash
cd $WORKTREE_PATH
bundle config set --local path vendor/bundle  # Reconfigure
bundle install --force                         # Reinstall
```

**Slow gem installation**
```bash
# First-time setup is slow; reuse cache:
bundle config list
# Verify path is set correctly
```

### Integration with TDD Workflow

Worktrees complement TDD perfectly:

```
RED Phase:      Write failing tests in worktree
GREEN Phase:    Implement to pass (all in same worktree)
REFACTOR Phase: Improve structure (still in worktree)

COMPLETE:       Merge worktree when RED-GREEN-REFACTOR done
```

Each worktree = one complete RED-GREEN-REFACTOR cycle.

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
