# claude-history-to-obsidian

> Automatically save Claude Code conversation transcripts to your Obsidian vault

A lightweight Ruby CLI tool that captures your Claude Code sessions and stores them in your Obsidian vault via Hook integration. Works seamlessly with the Claude Code Hook system—no manual steps required.

## Features

- ✅ **Automatic**: Saves transcripts automatically when you end a Claude Code session
- 📝 **Markdown**: Converts transcripts to beautifully formatted Markdown files
- 🏠 **Organized**: Groups sessions by project name for easy browsing
- 📦 **Bulk Import**: Import past Claude Code sessions from JSONL history
- 🐚 **Non-blocking**: Runs as a Hook with zero impact on Claude Code workflow
- 📋 **Minimal**: Pure Ruby with stdlib only (no heavy dependencies)

## Prerequisites

- **macOS** (requires iCloud Drive for Obsidian vault sync)
- **Ruby 3.4.7** (managed by rbenv)
- **Bundler** (for gem management)
- **Obsidian** installed with vault at: `/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/`

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git
cd claude-history-to-obsidian
```

### 2. Install Dependencies

```bash
# Configure bundler to use vendor/bundle (local isolation)
bundle config set --local path vendor/bundle

# Install gems
bundle install
```

Verify the setup:

```bash
ruby --version     # Should show 3.4.7
bundle --version
ls -la vendor/bundle/  # Gems should be here, not globally installed
```

### 3. Configure Claude Code Hook

Add this hook to your `.claude/settings.local.json` or `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "cd /Users/bash/src/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
```

**Note**: Update the path to match your actual project directory.

## Quick Start

### Automatic Usage (Recommended)

1. Configure the Hook (see above)
2. Work with Claude Code as usual
3. When you end the session (Stop button), the transcript automatically saves to your Obsidian vault
4. Check your vault under `Claude Code/{project-name}/` to view the session

### Manual Testing

Test the script before deploying to your workflow:

```bash
# Create test data
cat > /tmp/test-input.json <<'EOF'
{
  "session_id": "test123456789",
  "transcript_path": "/tmp/test-transcript.json",
  "cwd": "/Users/bash/src/test-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/test-transcript.json <<'EOF'
{
  "session_id": "test123456789",
  "cwd": "/Users/bash/src/test-project",
  "messages": [
    {"role": "user", "content": "Implementing the feature for button handling", "timestamp": "2025-11-03T10:00:00.000Z"},
    {"role": "assistant", "content": "I'll help you implement the button handling feature...", "timestamp": "2025-11-03T10:00:05.000Z"}
  ]
}
EOF

# Run the script
cat /tmp/test-input.json | bundle exec ruby bin/claude-history-to-obsidian

# Verify output was created
ls -la ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code/test-project/
```

## Usage

### How It Works

**Hook Mode** (Automatic - Recommended):
1. Claude Code session ends (Stop event triggered)
2. Hook sends session data to this script via stdin
3. Script reads transcript from file
4. Converts to Markdown with User/Claude sections
5. Saves to Obsidian vault with auto-generated filename
6. Script exits (Hook requirement: always exit 0)

**File Naming**: `{YYYYMMDD-HHMMSS}_{session-name}_{session-id-first-8}.md`

Example: `20251103-143022_implementing-feature_abc12345.md`

### Bulk Import Previous Sessions

Import Claude Code sessions from your history:

```bash
# Import all JSONL files from ~/.claude/projects/
rake bulk_import
```

Progress is printed every 10 sessions. Files are created with timestamps from the original session start (idempotency guaranteed).

### View Transcripts in Obsidian

Your saved transcripts are organized by project:

```
Claude Code/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── (your-project-name)/
    └── ...
```

Each file contains the full conversation with:
- **Metadata**: Project name, path, session ID, date
- **Conversation**: User messages and Claude responses, in order
- **Formatting**: Markdown preserved as-is (code blocks, formatting, etc.)

## Configuration

### Hook Configuration

The Hook endpoint in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "cd /path/to/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
```

**Required parameters**:
- `command`: Full path to the script directory + `bundle exec ruby bin/claude-history-to-obsidian`

### Obsidian Vault Path

The script writes to a hardcoded path (macOS iCloud Drive):
```
/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
```

Make sure your Obsidian vault is set to this location (or update CLAUDE.md specifications if needed).

### Environment Variables

You can customize the vault and log paths using environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `CLAUDE_VAULT_PATH` | iCloud Drive default | Custom Obsidian vault location |
| `CLAUDE_LOG_PATH` | `~/.local/var/log/claude-history-to-obsidian.log` | Custom log file path |

**Examples**:

```bash
# Use custom vault path
CLAUDE_VAULT_PATH=/custom/vault bundle exec ruby bin/claude-history-to-obsidian

# Use custom log path
CLAUDE_LOG_PATH=/tmp/custom.log bundle exec ruby bin/claude-history-to-obsidian

# Both together
CLAUDE_VAULT_PATH=/tmp/vault CLAUDE_LOG_PATH=/tmp/app.log \
  bundle exec ruby bin/claude-history-to-obsidian
```

This is useful for:
- **Testing**: Isolate tests with temporary directories
- **Alternative vaults**: Use different Obsidian vaults for different projects
- **Custom logging**: Direct logs to different locations

### Optional: Desktop Notifications

Install the optional `terminal-notifier` gem for macOS desktop notifications:

```bash
bundle add terminal-notifier
```

## Troubleshooting

### Hook isn't running

**Problem**: Transcripts aren't being saved.

**Solutions**:
1. Check Hook configuration in `.claude/settings.local.json`
2. Verify the command path is correct
3. Review logs: `tail -20 ~/.local/var/log/claude-history-to-obsidian.log`

### Transcripts not appearing in Obsidian

**Problem**: Files are created but don't show in Obsidian.

**Solutions**:
1. Check iCloud Drive sync status (macOS System Settings > iCloud Drive)
2. Verify Obsidian vault path in settings
3. Manually refresh Obsidian (Cmd+R)

### Ruby version mismatch

**Problem**: Script fails with Ruby version error.

**Solutions**:
```bash
# Install the required Ruby version
rbenv install 3.4.7

# Verify it's used
ruby --version  # Should show 3.4.7
```

### Permission denied errors

**Problem**: "Permission denied" when writing to vault.

**Solutions**:
1. Check directory permissions: `ls -la ~/Library/Mobile\ Documents/iCloud*/`
2. Ensure iCloud Drive is enabled in System Preferences
3. Verify sufficient disk space in iCloud Drive

### View logs for debugging

```bash
# Recent errors
tail -50 ~/.local/var/log/claude-history-to-obsidian.log

# Monitor in real-time
tail -f ~/.local/var/log/claude-history-to-obsidian.log
```

## How to Development

### For Contributors & Maintainers

This project uses **t-wada style Test-Driven Development** by default. For development tasks:

**Setup**:
1. Follow Installation steps above
2. Read the development documentation:
   - `CLAUDE.md` - Project overview and structure
   - `.claude/development.md` - Dev environment and setup
   - `.claude/specifications.md` - Technical specs
   - `.claude/practices.md` - TDD methodology

**Development Workflow**:
1. Run tests: `bundle exec ruby -I lib:test -rtest/unit test/**/*.rb`
2. Write failing test first (RED)
3. Implement code to pass test (GREEN)
4. Refactor while tests stay green (REFACTOR)
5. Repeat

**Key Rules**:
- Always use `bundle exec ruby ...`
- Never install gems globally
- Use `/tmp/` for test data
- Always exit 0 (even on errors)
- Log errors to stderr and `~/.local/var/log/claude-history-to-obsidian.log`

For detailed development guidance, see:
- `@.claude/development.md` - Environment & commands
- `@.claude/specifications.md` - Technical specs
- `@.claude/practices.md` - TDD & best practices
- `CLAUDE_TODO.md` - Implementation checklist

## Contributing

Contributions welcome! For development:

```bash
# Fork and clone
git clone https://github.com/YOUR_FORK/claude-history-to-obsidian.git

# Create feature branch
git checkout -b feature/your-feature

# Follow TDD workflow
# Write tests, implement, refactor

# Push and create PR
git push origin feature/your-feature
```

## License

MIT

---

## Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/YOUR_USERNAME/claude-history-to-obsidian/issues)
- **Documentation**: See `CLAUDE.md` for full technical documentation
- **Logs**: Check `~/.local/var/log/claude-history-to-obsidian.log` for debugging
