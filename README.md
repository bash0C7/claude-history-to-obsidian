# claude-history-to-obsidian

> Automatically save Claude Code and Claude Web conversation transcripts to your Obsidian vault

A lightweight Ruby CLI tool that captures your Claude Code and Claude Web sessions and stores them in your Obsidian vault via Hook integration. Works seamlessly with both Claude Code Hook system and Claude Web—no manual steps required.

## Features

- ✅ **Dual Support**: Saves transcripts from both Claude Code and Claude Web
- 📝 **Markdown**: Converts transcripts to beautifully formatted Markdown files
- 🏠 **Organized**: Groups sessions by project name in separate vault folders:
  - `Claude Code/{project}/` for Claude Code sessions
  - `claude.ai/{project}/` for Claude Web sessions
- 📦 **Bulk Import**: Import past Claude Code sessions from JSONL history
- 🐚 **Non-blocking**: Runs as a Hook with zero impact on Claude Code workflow
- 📋 **Minimal**: Pure Ruby with stdlib only (no heavy dependencies)

## Prerequisites

- **macOS** (requires iCloud Drive for Obsidian vault sync)
- **Ruby 3.4.7** (managed by rbenv)
- **Bundler** (for gem management)
- **Obsidian** installed with vault at: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/`

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
        "command": "cd ~/src/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
```

**Note**: Update the path to match your actual project directory.

## Quick Start

### Automatic Usage (Recommended)

Works with both Claude Code and Claude Web:

**Claude Code**:
1. Configure the Hook in `.claude/settings.local.json` with `"source": "code"`
2. Work with Claude Code as usual
3. When you end the session (Stop button), the transcript automatically saves
4. Check your vault under `Claude Code/{project-name}/`

**Claude Web**:
1. Configure your application to send Hook JSON with `"source": "web"`
2. Use Claude Web as usual
3. When saving a session, it sends the Hook to this script
4. Check your vault under `claude.ai/{project-name}/`

### Manual Testing

Test the script before deploying to your workflow:

```bash
# Create test data (Claude Code)
cat > /tmp/test-input.json <<'EOF'
{
  "session_id": "test123456789",
  "transcript_path": "/tmp/test-transcript.json",
  "cwd": "~/src/test-project",
  "project": "test-project",
  "source": "code",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/test-transcript.json <<'EOF'
{
  "session_id": "test123456789",
  "cwd": "~/src/test-project",
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
1. Session ends (Claude Code Stop event or Claude Web export)
2. Hook sends JSON via stdin with:
   - `source: "code"` → Saves to `Claude Code/{project}/`
   - `source: "web"` → Saves to `claude.ai/{project}/`
3. Script reads transcript (from file in Hook mode, or embedded in JSON)
4. Converts to Markdown with User/Claude sections
5. Saves to appropriate Obsidian vault with auto-generated filename
6. Script exits (Hook requirement: always exit 0)

**File Naming**: `{YYYYMMDD-HHMMSS}_{session-name}_{session-id-first-8}.md`

Example: `20251103-143022_implementing-feature_abc12345.md`

**Important Fields**:
- `source`: Either `"code"` (Claude Code) or `"web"` (Claude Web). Default: `"code"`
- `project`: Project name (optional, extracted from `cwd` if not provided)
- `transcript_path`: Path to transcript file (Hook mode)
- `transcript`: Embedded transcript object (Bulk Import mode)

### Bulk Import Previous Sessions

Import Claude Code or Claude Web sessions from your history:

```bash
# Import Claude Code sessions from ~/.claude/projects/
rake code:bulk_import

# Import Claude Web conversations from conversations.json
CONVERSATIONS_JSON=~/Downloads/conversations.json rake web:bulk_import
```

Progress is printed every 10 sessions. Files are created with timestamps from the original session start (idempotency guaranteed).

### View Transcripts in Obsidian

Your saved transcripts are organized by source and project:

**Claude Code** (`source: "code"`):
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

**Claude Web** (`source: "web"`):
```
claude.ai/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── (your-project-name)/
    └── ...
```

**Test Mode** (when `CLAUDE_VAULT_MODE=test`):
```
Claude Code [test]/
├── picoruby-recipes/
│   └── 20251102-143022_implementing-feature_abc12345.md
└── another-project/
    └── ...

claude.ai [test]/
├── picoruby-recipes/
│   └── 20251102-143022_implementing-feature_abc12345.md
└── another-project/
    └── ...
```

Each file contains the full conversation with:
- **Metadata**: Project name, path, session ID, date, source (Code or Web)
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
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
```

Make sure your Obsidian vault is set to this location (or update CLAUDE.md specifications if needed).

### Environment Variables

You can customize the vault and log paths using environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `CLAUDE_VAULT_PATH` | `~/Library/.../ObsidianVault/Claude Code` | Claude Code vault directory |
| `CLAUDE_WEB_VAULT_PATH` | `~/Library/.../ObsidianVault/claude.ai` | Claude Web vault directory |
| `CLAUDE_LOG_PATH` | `~/.local/var/log/claude-history-to-obsidian.log` | Log file path |
| `CLAUDE_VAULT_MODE` | empty (normal mode) | Set to `test` to add `[test]` suffix to vault folders for isolation |

**Examples**:

```bash
# Use custom Claude Code vault path
CLAUDE_VAULT_PATH=/custom/vault bundle exec ruby bin/claude-history-to-obsidian

# Use custom Claude Web vault path
CLAUDE_WEB_VAULT_PATH=/custom/web-vault bundle exec ruby bin/claude-history-to-obsidian

# Use custom log path
CLAUDE_LOG_PATH=/tmp/custom.log bundle exec ruby bin/claude-history-to-obsidian

# Enable test mode (adds [test] suffix to vault folders)
CLAUDE_VAULT_MODE=test bundle exec ruby bin/claude-history-to-obsidian

# All together
CLAUDE_VAULT_PATH=/tmp/code CLAUDE_WEB_VAULT_PATH=/tmp/web CLAUDE_VAULT_MODE=test CLAUDE_LOG_PATH=/tmp/app.log \
  bundle exec ruby bin/claude-history-to-obsidian
```

This is useful for:
- **Testing**: Isolate test data with `CLAUDE_VAULT_MODE=test` to separate from production data
- **Alternative vaults**: Use different Obsidian vaults for different sources
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

## License

MIT
