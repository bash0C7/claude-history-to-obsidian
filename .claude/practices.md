# Practices & Methodologies


## 📝 Test-Driven Development

Use **@tdd** skill for detailed TDD methodology including:

- RED-GREEN-REFACTOR cycle
- Phase 0: GREEN baseline verification
- Phase 0.5: Plan revision using actual code
- Test lists and baby steps
- Implementation strategies (Fake It, Obvious Implementation, Triangulation)
- Plan examination and gap analysis

---

## 🌳 Git Subtree Management

**Note**: This project does not currently use Git Subtree. This section is retained for reference if Git Subtree is adopted in the future.

For detailed Git Subtree workflows, see **@.claude/skills/git-subtree-management/SKILL.md** (external reference)

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
cd ~/src/claude-history-to-obsidian
@worktree-session feature-web-import

# Terminal 2 - Separate feature work
cd ~/src/another-project
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
