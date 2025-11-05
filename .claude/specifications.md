# Technical Specifications

## 🔌 Hook Integration

### Critical Rules

The Hook system is the primary integration point. Adhere strictly to these rules:

- **ALWAYS exit 0** (even on errors) - Prevents blocking Claude Code
- **Read JSON from stdin** (not command arguments)
- **Write errors to stderr** for immediate user feedback
- **Log detailed information** to `~/.local/var/log/claude-history-to-obsidian.log`
- **Never hang or block** on I/O operations

### Hook Configuration

Set up the Stop event hook in `.claude/settings.local.json`:

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

**Trigger**: When Claude Code session ends (Stop event)

### Hook JSON Input Structure

The script handles both Hook mode and Bulk Import mode:

#### Hook Mode (Claude Code or Claude Web)

**Claude Code Example**:
```json
{
  "session_id": "abc123456789...",
  "transcript_path": "~/.claude/sessions/session-20251102-143022.json",
  "cwd": "~/src/Arduino/picoruby-recipes",
  "project": "picoruby-recipes",
  "source": "code",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

**Claude Web Example**:
```json
{
  "session_id": "abc123456789...",
  "transcript_path": "~/.claude/sessions/session-20251102-143022.json",
  "cwd": "~/src/Arduino/picoruby-recipes",
  "project": "picoruby-recipes",
  "source": "web",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

**Required Fields**:
- `session_id`: Session identifier (first 8 chars used in filename)
- `transcript_path`: Path to transcript JSON file (read from here)
- `cwd`: Current working directory (used as fallback for project name)

**Optional Fields**:
- `project`: Project name (if not provided, extracted from `cwd` basename)
- `source`: Either `"code"` (Claude Code) or `"web"` (Claude Web). Default: `"code"`
  - `"code"` → Saves to `Claude Code/{project}/`
  - `"web"` → Saves to `claude.ai/{project}/`

#### Bulk Import Mode

```json
{
  "session_id": "abc123456789...",
  "transcript": {
    "session_id": "abc123456789...",
    "cwd": "~/src/Arduino/picoruby-recipes",
    "messages": [
      {"role": "user", "content": "...", "timestamp": "2025-11-02T14:30:22.000Z"},
      {"role": "assistant", "content": "...", "timestamp": "2025-11-02T14:30:25.000Z"}
    ],
    "_first_message_timestamp": "20251102-143022"
  },
  "cwd": "~/src/Arduino/picoruby-recipes",
  "project": "picoruby-recipes",
  "source": "code",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

**Processing Logic**:
- If `transcript` field exists → use directly (Bulk Import)
- If `transcript_path` field exists → read from file (Hook Mode)
- If `source` field exists → use for vault destination routing (default: `"code"`)

### Environment Variable Configuration

The application supports customizing paths via environment variables. This is particularly useful for testing and alternative deployments.

**Supported Variables**:

| Variable | Format | Default | Use Case |
|---|---|---|---|
| `CLAUDE_VAULT_PATH` | File path | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code` | Claude Code vault directory |
| `CLAUDE_WEB_VAULT_PATH` | File path | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai` | Claude Web vault directory |
| `CLAUDE_LOG_PATH` | File path | `~/.local/var/log/claude-history-to-obsidian.log` | Custom log file location |
| `CLAUDE_VAULT_MODE` | `test` or empty | empty (normal mode) | Adds `[test]` suffix to vault folders for test isolation |

**Implementation**:

The constants are initialized via `ENV.fetch()` at class load time:

```ruby
CLAUDE_CODE_VAULT_PATH = ENV.fetch(
  'CLAUDE_VAULT_PATH',
  File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code')
)

CLAUDE_WEB_VAULT_PATH = ENV.fetch(
  'CLAUDE_WEB_VAULT_PATH',
  File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai')
)

LOG_FILE_PATH = ENV.fetch(
  'CLAUDE_LOG_PATH',
  File.expand_path('~/.local/var/log/claude-history-to-obsidian.log')
)
```

**Usage Examples**:

```bash
# Use custom vault path
CLAUDE_VAULT_PATH=/tmp/test-vault bundle exec ruby bin/claude-history-to-obsidian

# Use custom log path
CLAUDE_LOG_PATH=/tmp/app.log bundle exec ruby bin/claude-history-to-obsidian

# Use test mode (adds [test] suffix to vault folders)
CLAUDE_VAULT_MODE=test bundle exec ruby bin/claude-history-to-obsidian
# Files saved to: Claude Code [test]/{project}/, claude.ai [test]/{project}/

# Use all together (Hook configuration example)
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "CLAUDE_VAULT_PATH=/custom/vault CLAUDE_VAULT_MODE=test CLAUDE_LOG_PATH=/custom/app.log cd /path/to/project && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
```

**Testing**:

Test suite sets these variables at startup (`test/test_claude_history_to_obsidian.rb`):

```ruby
ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault'
ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'
```

This ensures tests use isolated temporary directories rather than the actual iCloud Drive vault.

---

## 📝 Output Specifications

### Obsidian Vault Directory Structure

Vault location is determined by the `source` field:

**Claude Code** (`source: "code"`):
```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── (project-name)/
    └── ...
```

**Claude Web** (`source: "web"`):
```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── (project-name)/
    └── ...
```

**Directory Selection Logic**:
```ruby
vault_base = source == 'web' ? CLAUDE_WEB_VAULT_PATH : CLAUDE_CODE_VAULT_PATH
project_name = hook_input['project'] || File.basename(hook_input['cwd'])
project_dir = File.join(vault_base, project_name)
```

### File Naming Format

```
{YYYYMMDD-HHMMSS}_{session-name}_{session-id-first-8}.md
```

**Example**: `20251103-143022_implementing-feature_abc12345.md`

**Components**:

| Component | Format | Source | Example |
|---|---|---|---|
| Date/Time | `YYYYMMDD-HHMMSS` | `Time.now.strftime('%Y%m%d-%H%M%S')` | `20251103-143022` |
| Session Name | Slug (30 chars max) | First user message | `implementing-feature` |
| Session ID | First 8 characters | `session_id` field | `abc12345` |

### Session Name Extraction Logic

Extract readable name from first user message:

1. Find first message with `{"role": "user", ...}`
2. Get first line of `content`
3. Take first 30 characters
4. Lowercase
5. Replace non-alphanumeric with `-`
6. Remove consecutive `-` (collapse to single)
7. Strip leading/trailing `-`
8. Default to `session` if empty

**Ruby Implementation**:

```ruby
def extract_session_name(messages)
  first_user_msg = messages.find { |m| m['role'] == 'user' }
  return 'session' unless first_user_msg && first_user_msg['content']

  text = first_user_msg['content']
  first_line = text.split("\n")[0]
  name = first_line[0..29]  # First 30 chars

  name
    .downcase
    .gsub(/[^a-z0-9]+/, '-')
    .sub(/^-+/, '')
    .sub(/-+$/, '')
    .presence || 'session'
end
```

### Markdown Output Format

The header differs based on `source`:

**Claude Code** (`source: "code"`):
```markdown
# Claude Code Session

**Project**: project-name
**Path**: ~/src/Arduino/picoruby-recipes
**Session ID**: abc123456789...
**Date**: 2025-11-02 14:30:22
```

**Claude Web** (`source: "web"`):
```markdown
# Claude Web Session

**Project**: project-name
**Path**: ~/src/Arduino/picoruby-recipes
**Session ID**: abc123456789...
**Date**: 2025-11-02 14:30:22
```

**Rest of Format** (identical for both):

```markdown
---

## 👤 User

{user message content as-is}

---

## 🤖 Claude

{assistant message content as-is}

---

## 👤 User

{next user message}

---

(repeat for all messages)
```

**Important Notes**:
- Messages already contain markdown formatting (code blocks, etc.)
- Paste content as-is, no escaping needed
- Process messages in order from the transcript
- Preserve all formatting exactly

---

## 📊 Transcript JSON Input Format

The `transcript_path` (Hook mode) or `transcript.messages` (Bulk Import) points to file with structure:

```json
{
  "session_id": "abc123456789...",
  "cwd": "~/src/Arduino/picoruby-recipes",
  "messages": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."},
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

**Message Processing**:
- Process messages in array order
- Use `role` field to determine section heading (User vs Claude)
- Use `content` field as markdown body (already formatted)

---

## 🐛 Error Handling

### Philosophy

Non-blocking, informative error handling:

- **ALWAYS exit 0** (hook requirement, even on failures)
- **Detailed stderr messages** for immediate user feedback
- **Comprehensive logs** to `~/.local/var/log/claude-history-to-obsidian.log`
- **Graceful degradation** on failures (skip, don't crash)

### Log File Implementation

```ruby
def log(message)
  log_dir = File.expand_path('~/.local/var/log')
  FileUtils.mkdir_p(log_dir)

  log_file = File.join(log_dir, 'claude-history-to-obsidian.log')
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  File.open(log_file, 'a') do |f|
    f.puts "[#{timestamp}] #{message}"
  end
end
```

### Common Error Scenarios

| Scenario | Action | Exit Code |
|---|---|---|
| Missing transcript file | Log warning, skip processing | 0 |
| Invalid JSON | Log error with details | 0 |
| Vault write failure | Log error with path info | 0 |
| iCloud sync delay | Log info only (expected) | 0 |
| JSON parse errors | Log and continue | 0 |
| Permission denied | Log error, skip file | 0 |

---

## 📌 Important Notes

### stdin Input

- Hook passes JSON via stdin (pipe)
- NOT as command-line arguments
- Read from `$stdin` until EOF

### Project Name Detection

- Extract from `cwd` parameter via `File.basename(cwd)`
- Create project directory under Obsidian vault base
- Each project has its own folder for organization

### Session ID Handling

- Full `session_id` stored in markdown header
- First 8 characters used in filename
- Enables cross-reference between file and session

### iCloud Drive Behavior

- File creation is immediate
- Obsidian may detect files before sync completes
- Write operation should NOT block on sync
- Sync status visible in macOS System Settings

### Minimal Dependencies Philosophy

- Ruby stdlib for core functionality (JSON, FileUtils, Time)
- Optional `terminal-notifier` gem for macOS notifications
- No heavy frameworks (no Rails, no ActiveSupport)
- Keep it lightweight for hook performance

### Testing Best Practices

- Always use `/tmp/` for test data
- Test with various message types and lengths
- Verify file naming format matches specification
- Check markdown output in Obsidian for formatting
- Review logs for error details

---

## 🏗️ Implementation Class Structure

### Main Class: `ClaudeHistoryToObsidian`

Located in `lib/claude_history_to_obsidian.rb`:

| Method | Purpose | Mode |
|---|---|---|
| `run` | Entry point - processes Hook JSON from stdin | Hook mode |
| `process_transcript` | Direct processing (called from Rakefile) | Bulk Import |
| `load_hook_input` | Parse stdin Hook JSON | Hook mode |
| `load_transcript` | Read transcript JSON from file | Hook mode |
| `extract_session_name` | Generate session name from first user message | Both |
| `extract_session_timestamp` | Parse timestamp for idempotency | Both |
| `generate_filename` | Create filename using session timestamp | Both |
| `build_markdown` | Convert messages to markdown | Both |
| `ensure_directories` | Create vault directory structure | Both |
| `save_to_vault` | Write markdown to Obsidian vault | Both |
| `notify` | Send optional system notification | Both |
| `log` | Write to log file for debugging | Both |

### Bulk Import (Rakefile)

The `rake bulk_import` task uses these functions:

| Function | Purpose |
|---|---|
| `parse_and_group_jsonl(path)` | Parse JSONL file and group messages by sessionId |
| `process_session(session_id, session_data)` | Call `ClaudeHistoryToObsidian.process_transcript` |
| `extract_first_message_timestamp(messages)` | Extract ISO timestamp and format to YYYYMMDD-HHMMSS |

**JSONL Processing**:
- Handles both string and array content formats (Claude Code format)
- Returns: `{ session_id => { messages: [...], cwd: '...' } }`

### Legacy: ClaudeHistoryImporter

Located in `lib/claude_history_importer.rb`:

- **Status**: No longer used in default flow
- **Reason**: Superseded by direct Rakefile JSONL processing
- **Kept for**: Reference and alternative workflows

---

## 📦 Implementation Details & Large File Handling

See these references for detailed implementation information:

- **@.claude/references/implementation-details.md** - JSON Nesting, Content Handling, Signature Filtering, Newline Conversion
- **@.claude/references/large-file-handling.md** - conversations.json processing, safe exploration, test validation

---

## 🔗 Related Documentation

- **@.claude/development.md** - Development setup and commands
- **@.claude/practices.md** - TDD methodology and operations
- **@CLAUDE.md** - Claude Code project overview
