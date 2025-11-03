# claude-history-to-obsidian

Ruby CLI tool that automatically saves Claude Code conversation transcripts to Obsidian vault via Hook integration.

## 🎯 Project Context

- **Language**: Ruby 3.4.7 (CRuby)
- **Type**: CLI application (NOT Rails, pure Ruby)
- **Package Manager**: Bundler with vendor/bundle (NO global gems)
- **Version Manager**: rbenv with .ruby-version
- **Platform**: macOS only (iCloud Drive dependency)
- **Integration**: Claude Code Hook system (Stop event)

## 🔧 Development Environment

**Ruby Setup**:
- rbenv manages Ruby version via .ruby-version
- Fixed at 3.4.7
- Install: `rbenv install 3.4.7`

**Bundler Configuration**:
- Gems MUST be in vendor/bundle
- NEVER pollute global gem path
- Config: `bundle config set --local path vendor/bundle`
- Always use: `bundle exec ruby ...`

**Dependencies**:
- Minimal: Ruby stdlib only (JSON, FileUtils, Time)
- Optional: terminal-notifier gem for macOS notifications

## 📋 Commands

**Initial Setup**:
```bash
bundle config set --local path vendor/bundle
bundle install
```

**Run Application**:
```bash
# From project root
bundle exec ruby bin/claude-history-to-obsidian

# With test input
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

**Testing**:
```bash
# Create test hook input
cat > /tmp/hook-input.json <<'EOF'
{
  "session_id": "test123456789",
  "transcript_path": "/tmp/test-transcript.json",
  "cwd": "/Users/bash/src/test-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

# Create test transcript
cat > /tmp/test-transcript.json <<'EOF'
{
  "session_id": "test123456789",
  "cwd": "/Users/bash/src/test-project",
  "messages": [
    {"role": "user", "content": "Implementing the feature for button handling"},
    {"role": "assistant", "content": "I'll help you implement the button handling feature..."}
  ]
}
EOF

# Execute test
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian

# Verify output
ls -la ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code/test-project/
```

## 📁 Project Structure

```
claude-history-to-obsidian/
├── bin/
│   └── claude-history-to-obsidian    # Entry point (bundle exec ruby)
├── lib/
│   └── claude_history_to_obsidian.rb # Core logic class
├── vendor/
│   └── bundle/                        # Vendored gems (gitignored)
├── .ruby-version                      # 3.4.7
├── Gemfile
├── Gemfile.lock                       # Version controlled
├── .gitignore
├── CLAUDE.md
└── README.md
```

**Entry Point**: `bin/claude-history-to-obsidian`
**Core Logic**: `lib/claude_history_to_obsidian.rb`

## 🎨 Code Style

- Follow Ruby community style (no Rails)
- snake_case for methods and variables
- PascalCase for classes and modules
- SCREAMING_SNAKE_CASE for constants
- 2-space indentation (standard Ruby)
- Minimal dependencies (prefer stdlib)
- Clear, descriptive method names describing actions
- Comments only for complex logic

## 🚦 File Boundaries

**Safe to Modify**:
- `/bin/` - Executable script
- `/lib/` - Application logic
- `README.md` - Usage documentation
- `Gemfile` - Dependency definitions
- `CLAUDE.md` - This file (version control)

**NEVER Touch**:
- `/vendor/` - Bundler-managed gems (gitignored)
- `/.git/` - Git internals
- `Gemfile.lock` - Only bundler modifies this
- `.ruby-version` - Fixed at 3.4.7

**System Paths** (write-only, no modifications):
- Obsidian vault: `/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/`
- Logs: `~/.local/var/log/claude-history-to-obsidian.log`

## 🔌 Hook Integration

**Critical Rules**:
- ALWAYS exit 0 (even on errors) - Prevents blocking Claude Code
- Read JSON from stdin (not command arguments)
- Write errors to stderr for immediate feedback
- Log detailed information to ~/.local/var/log/claude-history-to-obsidian.log
- Never hang or block on I/O operations

**Hook Configuration** (`.claude/settings.local.json`):
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

**Hook JSON Input Structure** (via stdin):
```json
{
  "session_id": "abc123456789...",
  "transcript_path": "/Users/bash/.claude/sessions/session-20251102-143022.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

## 📝 Output Specifications

**Obsidian Vault Directory Structure**:
```
/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── (project-name as per cwd basename)/
    └── ...
```

**File Naming Format**: `{YYYYMMDD-HHMMSS}_{session-name}_{session-id-first-8}.md`
- Example: `20251103-143022_implementing-feature_abc12345.md`
- Date/Time: `Time.now.strftime('%Y%m%d-%H%M%S')`
- Session Name: Extracted from first user message (see logic below)
- Session ID: First 8 characters of session_id field

**Session Name Extraction Logic**:
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

**Markdown Output Format**:
```markdown
# Claude Code Session

**Project**: project-name
**Path**: /Users/bash/src/Arduino/picoruby-recipes
**Session ID**: abc123456789...
**Date**: 2025-11-02 14:30:22

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

**Important**: Messages already contain markdown formatting (code blocks etc) - paste content as-is, no escaping needed.

## 📊 Transcript JSON Input Format

`transcript_path` points to file with structure:
```json
{
  "session_id": "abc123456789...",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "messages": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."},
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

Process messages in order, converting each to markdown based on role (User vs Claude).

## 🐛 Error Handling

**Philosophy**: Non-blocking, informative
- ALWAYS exit 0 (hook requirement, even on failures)
- Detailed stderr messages for immediate user feedback
- Comprehensive logs to ~/.local/var/log/claude-history-to-obsidian.log
- Graceful degradation on failures

**Log File**:
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

**Common Error Scenarios**:
- Missing transcript file → Log warning, skip processing, exit 0
- Invalid JSON → Log error with details, exit 0
- Vault write failure → Log error with path info, exit 0
- iCloud sync delay → Expected behavior, log info only
- JSON parse errors → Log and continue, exit 0

## 🚫 Do Not Touch

**NEVER**:
- Install gems globally (ALWAYS use `bundle exec`)
- Skip `bundle exec` prefix for any Ruby execution
- Modify .ruby-version file (fixed at 3.4.7)
- Change Obsidian vault base path (user-specific path)
- Exit with non-zero code (blocks Claude Code hooks)
- Modify git or .git/ directory
- Touch /vendor/bundle/ (bundler-managed)
- Block on iCloud Drive operations

**Bundler Commands Only**:
- Always use: `bundle config set --local path vendor/bundle`
- Always use: `bundle exec ruby ...` (never bare ruby)
- Always use: `bundle add gem_name` (not gem install)

## 📌 Important Notes

**stdin Input**:
- Hook passes JSON via stdin (pipe)
- NOT as command-line arguments
- Read from $stdin until EOF

**Project Name Detection**:
- Extract from `cwd` parameter via `File.basename(cwd)`
- Create project directory under Obsidian vault base
- Each project has its own folder for organization

**Session ID Handling**:
- Full `session_id` stored in markdown frontmatter
- First 8 characters used in filename
- Enables cross-reference between file and session

**iCloud Drive Behavior**:
- File creation is immediate
- Obsidian may detect files before sync completes
- Write operation should not block on sync
- Sync status visible in macOS System Settings

**Minimal Dependencies Philosophy**:
- Ruby stdlib for core functionality (JSON, FileUtils, Time)
- Optional terminal-notifier for macOS desktop notifications
- No heavy frameworks (no Rails, no ActiveSupport)
- Keep it lightweight for hook performance

**Testing Best Practices**:
- Always use /tmp/ for test data
- Test with various message types and lengths
- Verify file naming format matches specification
- Check markdown output in Obsidian for formatting
- Review logs for error details

## 🏗️ Implementation Class Structure

Main class `ClaudeHistoryToObsidian`:
- `run`: Main entry point (orchestrates workflow)
- `load_hook_input`: Parse stdin JSON
- `load_transcript`: Read transcript JSON from file
- `extract_session_name`: Generate session name from content
- `build_markdown`: Convert JSON to markdown format
- `ensure_directories`: Create vault directory structure
- `save_to_vault`: Write markdown to Obsidian vault
- `notify`: Optional system notification (terminal-notifier)
- `log`: Write to log file for debugging

All private methods except `run` (which is called by bin script).
