# Development Guide

## 🔧 Development Environment

### Ruby Setup

This project uses Ruby 3.4.7 (CRuby), managed by rbenv:

- **Version Manager**: rbenv with `.ruby-version`
- **Fixed at**: 3.4.7
- **Install**: `rbenv install 3.4.7`
- **Verify**: `ruby --version` should show `3.4.7`

### Bundler Configuration

**Critical**: Gems MUST be vendored in `vendor/bundle` to avoid polluting the global gem path.

```bash
# Initial setup (one time)
bundle config set --local path vendor/bundle
bundle install
```

**Rule**: Always use `bundle exec ruby ...` (never bare `ruby`)

### Dependencies

**Runtime**:
- Ruby stdlib only (JSON, FileUtils, Time, Tempfile)

**Optional**:
- `terminal-notifier` gem for macOS desktop notifications

**Development**:
- `test-unit` gem for unit testing (Test::Unit framework)

---

## 📋 Commands

### Initial Setup

```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/claude-history-to-obsidian.git
cd claude-history-to-obsidian

# Install dependencies (into vendor/bundle)
bundle config set --local path vendor/bundle
bundle install
```

### Run Application

```bash
# From project root
bundle exec ruby bin/claude-history-to-obsidian

# With test input from stdin
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

### Testing

Unit tests use Test::Unit gem:

```bash
# Run specific test file
bundle exec ruby -I lib:test test/test_claude_history_importer.rb -v

# Run all tests
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
```

### Manual Testing with Hook JSON

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
    {"role": "user", "content": "Implementing the feature for button handling", "timestamp": "2025-11-03T10:00:00.000Z"},
    {"role": "assistant", "content": "I'll help you implement the button handling feature...", "timestamp": "2025-11-03T10:00:05.000Z"}
  ]
}
EOF

# Execute test
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian

# Verify output
ls -la ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code/test-project/
```

### Bulk Import

```bash
# Run bulk import task (processes JSONL files directly)
rake bulk_import
```

The `rake bulk_import` task:
- Scans all JSONL files in `~/.claude/projects/`
- Parses sessionId-grouped messages
- Extracts message.content from both text and array formats
- Generates Markdown files with session start timestamp (idempotency)
- Progress: prints every 10 sessions imported

---

## 📁 Project Structure

```
claude-history-to-obsidian/
├── bin/
│   ├── claude-history-to-obsidian    # Hook entry point (bundle exec ruby)
│   └── claude-history-import         # Bulk import entry point
├── lib/
│   ├── claude_history_to_obsidian.rb # Hook processing & Obsidian output
│   └── claude_history_importer.rb    # JSONL parsing & session grouping
├── test/
│   └── test_claude_history_importer.rb # Unit tests (Test::Unit)
├── vendor/
│   └── bundle/                        # Vendored gems (gitignored)
├── .claude/
│   ├── development.md                # Development guide (this file)
│   ├── specifications.md             # Technical specifications
│   └── practices.md                  # TDD & operational practices
├── .ruby-version                      # 3.4.7
├── Gemfile
├── Gemfile.lock                       # Version controlled
├── Rakefile                           # Bulk import task
├── .gitignore
├── CLAUDE.md                          # Claude Code instructions
├── CLAUDE_TODO.md                     # Implementation checklist
└── README.md                          # User documentation
```

### Entry Points

- `bin/claude-history-to-obsidian`: Hook event processing
- `bin/claude-history-import`: JSONL to Hook JSON conversion (legacy)

### Core Logic

- `lib/claude_history_to_obsidian.rb`: Transcript → Markdown → Obsidian
- `lib/claude_history_importer.rb`: JSONL → session grouping → Hook JSON

### Testing

- `test/test_claude_history_importer.rb`: Unit tests with Test::Unit

---

## 🎨 Code Style

Follow Ruby community style (no Rails conventions):

- **Methods & Variables**: `snake_case`
- **Classes & Modules**: `PascalCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Indentation**: 2 spaces (standard Ruby)
- **Dependencies**: Minimal (prefer stdlib)
- **Method Names**: Clear, descriptive, action-oriented
- **Comments**: Only for complex logic

---

## 🚦 File Boundaries

### Safe to Modify

- `/bin/` - Executable scripts
- `/lib/` - Application logic
- `CLAUDE.md` - Claude Code instructions
- `README.md` - User documentation
- `Gemfile` - Gem dependencies
- `CLAUDE_TODO.md` - Task tracking

### NEVER Touch

- `/vendor/` - Bundler-managed gems (gitignored)
- `/.git/` - Git internals
- `Gemfile.lock` - Only Bundler modifies this
- `.ruby-version` - Fixed at 3.4.7

### System Paths (Write-Only)

- **Obsidian vault**: `/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/`
- **Logs**: `~/.local/var/log/claude-history-to-obsidian.log`

---

## 🚫 Critical Rules

### Bundler Only

```bash
# Always use:
bundle config set --local path vendor/bundle
bundle exec ruby ...
bundle add gem_name

# Never:
gem install ...                    # Global gems forbidden
ruby bin/...                       # Without bundle exec
bundle install --system            # System gems forbidden
```

### Ruby Version

- Fixed at 3.4.7
- Never modify `.ruby-version`
- Let rbenv manage the version

### Exit Codes

- **Always exit 0** (even on errors) - Required by Claude Code hooks
- Never exit with non-zero code (blocks hook execution)

### Git & Files

- Never modify `.git/` directory
- Never touch `/vendor/bundle/` (Bundler-managed)
- Never modify `Gemfile.lock` directly
- Never block on iCloud Drive operations

---

## 💡 Development Best Practices

### Setup Environment

When starting development on a new machine:

```bash
# 1. Install rbenv if not present
# 2. Install Ruby 3.4.7
rbenv install 3.4.7

# 3. Configure bundler (local path)
bundle config set --local path vendor/bundle

# 4. Install gems
bundle install

# 5. Verify
bundle exec ruby --version
ls -la vendor/bundle/
```

### Run Tests During Development

Keep tests running while developing:

```bash
# Run tests after making changes
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb

# Watch mode (requires external tool like entr or fs_event)
bundle install
```

### Debug with Logs

Monitor logs in real-time:

```bash
# View logs
tail -20 ~/.local/var/log/claude-history-to-obsidian.log

# Monitor live
tail -f ~/.local/var/log/claude-history-to-obsidian.log
```

### Test with Hook Simulator

Use test JSON files for quick feedback:

```bash
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

---

## 🔗 Related Documentation

- **@.claude/specifications.md** - Technical specifications (Hook, JSON, output formats)
- **@.claude/practices.md** - TDD methodology and Git Subtree management
- **@CLAUDE.md** - Claude Code instructions and project overview
