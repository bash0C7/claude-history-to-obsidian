# Git Subtree Management Skill

**Purpose**: Manage git subtree operations for embedding and syncing this project with other repositories.

**Scope**: Subtree initialization, pulling updates, pushing changes, and best practices for multi-repo management.

## When to Use This Skill

Use this skill when:
- Adding `claude-history-to-obsidian` to another repository as a subtree
- Updating subtree from upstream changes
- Pushing local modifications back to upstream
- Troubleshooting subtree merge conflicts
- Managing multiple subtree remotes

Do NOT use if:
- This is standalone (not embedded in another repo)
- Using git submodules instead of subtrees
- Repository has no upstream connection

## Key Operations

### 1. Initial Subtree Setup

**Task**: Add this project as a subtree to another repository.

**Command Pattern**:
```bash
git subtree add --prefix {path} {repo-url} {branch}
```

**Example**:
```bash
cd /Users/bash/src/dotfiles
git subtree add --prefix tools/claude-history-to-obsidian \
  https://github.com/user/claude-history-to-obsidian.git main
```

**Verification**:
- Check directory exists: `ls -la tools/claude-history-to-obsidian/`
- Verify git history: `git log --graph --oneline | head -10`

### 2. Pulling Updates from Upstream

**Task**: Sync local subtree with upstream changes.

**Command Pattern**:
```bash
git subtree pull --prefix {path} {repo-url} {branch}
```

**With Remote**:
```bash
# If remote already configured
git subtree pull --prefix tools/claude-history-to-obsidian origin main
```

**Conflict Resolution**:
```bash
# If merge conflicts occur
git status  # See conflicted files
# Resolve conflicts manually in editor
git add .
git commit -m "Resolve subtree merge conflicts"
```

### 3. Pushing Local Changes Upstream

**Task**: Send local subtree modifications back to upstream repository.

**Prerequisite**: Must have commit rights to upstream repo.

**Command Pattern**:
```bash
git subtree push --prefix {path} {repo-url} {branch}
```

**With Remote**:
```bash
git subtree push --prefix tools/claude-history-to-obsidian origin main
```

**Before Pushing**:
1. Ensure local changes are committed: `git status`
2. Pull latest upstream: `git subtree pull ...`
3. Resolve any conflicts
4. Then push: `git subtree push ...`

### 4. Setting Up Subtree Remote

**Task**: Configure a permanent remote to simplify commands.

```bash
# Add remote
git remote add claude-history https://github.com/user/claude-history-to-obsidian.git

# Verify
git remote -v | grep claude-history

# Now use in commands
git subtree pull --prefix tools/claude-history-to-obsidian claude-history main
git subtree push --prefix tools/claude-history-to-obsidian claude-history main
```

### 5. Viewing Subtree History

**Task**: Check commits affecting the subtree.

```bash
# See all commits touching subtree
git log --follow --oneline tools/claude-history-to-obsidian/ | head -20

# See subtree-specific commits
git log --grep="subtree" --oneline

# View one-line graph
git log --graph --oneline --all tools/claude-history-to-obsidian/
```

### 6. Removing Subtree (if needed)

**Task**: Completely remove subtree from repository.

```bash
# Option 1: Simple removal (keeps history)
git rm -r tools/claude-history-to-obsidian
git commit -m "Remove claude-history-to-obsidian subtree"

# Option 2: Clean history (advanced, caution recommended)
git filter-branch --tree-filter 'rm -rf tools/claude-history-to-obsidian' HEAD
```

## Best Practices

### Isolation Strategy

Keep subtree changes isolated:
```bash
# Good: Subtree change in its own commit
git commit -m "Update claude-history-to-obsidian subtree to v1.2.0"

# Avoid: Mixing subtree with unrelated changes
git commit -m "Update subtree AND fix bug in main project"
```

### Workflow for Updates

Recommended sequence:
```bash
# 1. Ensure clean working tree
git status

# 2. Pull latest from subtree upstream
git subtree pull --prefix tools/claude-history-to-obsidian origin main

# 3. Test/verify if needed
# ... run tests, check functionality ...

# 4. Commit if updating
git commit -m "Update claude-history-to-obsidian subtree"

# 5. Push to main repo
git push origin main
```

### Commit Message Conventions

Use clear commit messages:
```
# Reference upstream version
Update claude-history-to-obsidian subtree to v1.2.0

# Document changes if significant
Subtree pull from upstream:
- Fix: Handle special characters in session names
- Feature: Add support for iCloud sync errors
- Docs: Improve error handling guide
```

### Avoid Common Pitfalls

| Mistake | Issue | Solution |
|---------|-------|----------|
| Modifying subtree locally | Upstream changes conflict | Prefer upstream changes, contribute back |
| Pushing without pulling | Lost upstream changes | Always `pull` before `push` |
| Wrong prefix path | Subtree in wrong location | Verify path before adding |
| Missing remote config | Verbose commands needed | Set up remote once |
| Large subtree history | Repo bloat | Consider using git filter for clean history |

## Troubleshooting

### Merge Conflicts

```bash
# When pulling causes conflicts
git status  # List conflicted files

# Edit files, resolve conflicts
vim tools/claude-history-to-obsidian/CLAUDE.md

# Stage and commit
git add tools/claude-history-to-obsidian/
git commit -m "Resolve subtree merge conflicts"
```

### Wrong Prefix Path

```bash
# If subtree added with wrong prefix, remove and re-add
git rm -r wrong/path/to/subtree
git commit -m "Remove incorrectly placed subtree"

git subtree add --prefix correct/path https://github.com/... main
```

### Push Rejected (No Rights)

```bash
# Error: "You do not have permission"
# Solution: Ensure you have push rights to upstream repo

# Verify remote
git remote -v

# Check GitHub/GitLab permissions
# Then retry push
```

### Split History Too Large

```bash
# If subtree operations are slow
# Consider creating a squashed branch first

git subtree split --prefix tools/claude-history-to-obsidian -b claude-history-squashed
git subtree push --prefix tools/claude-history-to-obsidian origin claude-history-squashed
```

## Integration with Claude Code

When using this skill with Claude Code in this project:

1. **Test subtree ops locally first**: Use a test repo to validate
2. **Use non-blocking hooks**: Ensure subtree pulls don't hang hook execution
3. **Monitor git operations**: Check logs if subtree sync takes long
4. **Version tracking**: Document subtree version in project docs

Example for Claude Code project using subtree:
```bash
# Quick check of subtree status
git subtree split --prefix tools/claude-history-to-obsidian -b claude-history-check
git log --oneline claude-history-check | head -1
git branch -d claude-history-check
```

## Related Documentation

- CLAUDE.md: Git Subtree Management section
- Git subtree official docs: `git help subtree`
- Git subtree vs submodules comparison: understand when to use each
