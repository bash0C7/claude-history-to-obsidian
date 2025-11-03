# claude-history-to-obsidian

Ruby CLI tool that automatically saves Claude Code conversation transcripts to Obsidian vault via Hook integration.

<output_tone>
**日本語で出力すること**:
- **絶対に日本語で応答・プラン提示すること**
- 通常時: 語尾に「ピョン。」をつけて可愛く
- 盛り上がってきたら:「チェケラッチョ！！」と叫ぶ
- コード内コメント: 日本語、体言止め
- ドキュメント(.md): 英語で記述
- Git commit: 英語、命令形
</output_tone>

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
- **Runtime**: Ruby stdlib only (JSON, FileUtils, Time, Tempfile)
- **Optional**: terminal-notifier gem for macOS notifications
- **Development**: test-unit gem for unit testing (Test::Unit framework)

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

Unit tests use Test::Unit gem:
```bash
# Run unit tests
bundle exec ruby -I lib:test test/test_claude_history_importer.rb -v

# All tests
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
```

Manual testing with Hook JSON:
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

# Create test transcript (with timestamp in messages)
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

Bulk import past Claude Code sessions:
```bash
# Run bulk import task (processes JSONL directly, no intermediate formats)
rake bulk_import
```

The `rake bulk_import` task:
- Scans all JSONL files in `~/.claude/projects/`
- Parses sessionId-grouped messages
- Extracts message.content from both text and array formats
- Generates Markdown files with session start timestamp (idempotency)
- Progress: prints every 10 sessions imported

## 📁 Project Structure

```
claude-history-to-obsidian/
├── bin/
│   ├── claude-history-to-obsidian    # Hook entry point (bundle exec ruby)
│   └── claude-history-import         # Bulk import entry point (processes JSONL)
├── lib/
│   ├── claude_history_to_obsidian.rb # Hook processing & Obsidian output
│   └── claude_history_importer.rb    # JSONL parsing & session grouping
├── test/
│   └── test_claude_history_importer.rb # Unit tests (Test::Unit)
├── vendor/
│   └── bundle/                        # Vendored gems (gitignored)
├── .ruby-version                      # 3.4.7
├── Gemfile
├── Gemfile.lock                       # Version controlled
├── Rakefile                           # Bulk import task
├── .gitignore
├── CLAUDE.md
└── README.md
```

**Entry Points**:
- `bin/claude-history-to-obsidian`: Hook event processing
- `bin/claude-history-import`: JSONL to Hook JSON conversion

**Core Logic**:
- `lib/claude_history_to_obsidian.rb`: Transcript → Markdown → Obsidian
- `lib/claude_history_importer.rb`: JSONL → session grouping → Hook JSON

**Testing**:
- `test/test_claude_history_importer.rb`: Unit tests with Test::Unit

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

Two formats depending on source:

**Hook Mode** (Claude Code Hook triggers):
```json
{
  "session_id": "abc123456789...",
  "transcript_path": "/Users/bash/.claude/sessions/session-20251102-143022.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

**Bulk Import Mode** (claude-history-import):
```json
{
  "session_id": "abc123456789...",
  "transcript": {
    "session_id": "abc123456789...",
    "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
    "messages": [
      {"role": "user", "content": "...", "timestamp": "2025-11-02T14:30:22.000Z"},
      {"role": "assistant", "content": "...", "timestamp": "2025-11-02T14:30:25.000Z"}
    ],
    "_first_message_timestamp": "20251102-143022"
  },
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

The script handles both formats:
- `transcript` field (present in Bulk Import) → use directly
- `transcript_path` field (present in Hook) → read from file

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

**Main class `ClaudeHistoryToObsidian`** (lib/claude_history_to_obsidian.rb):
- `run`: Entry point - processes Hook JSON from stdin (Hook mode)
- `process_transcript`: Direct method for Bulk Import (called from Rakefile)
- `load_hook_input`: Parse stdin Hook JSON (Hook mode)
- `load_transcript`: Read transcript JSON from file
- `extract_session_name`: Generate session name from first user message
- `extract_session_timestamp`: Parse timestamp from transcript messages (idempotency)
- `generate_filename`: Create filename using session timestamp (not execution time)
- `build_markdown`: Convert messages to markdown with User/Claude sections
- `ensure_directories`: Create vault directory structure
- `save_to_vault`: Write markdown to Obsidian vault
- `notify`: Optional system notification (terminal-notifier)
- `log`: Write to log file for debugging

**Bulk Import (Rakefile)**:
- `parse_and_group_jsonl(path)`: Parse JSONL file and group messages by sessionId
  - Handles both string and array content formats (Claude Code format)
  - Returns: `{ session_id => { messages: [...], cwd: '...' } }`
- `process_session(session_id, session_data)`: Call ClaudeHistoryToObsidian.process_transcript
- `extract_first_message_timestamp(messages)`: Extract ISO timestamp and format to YYYYMMDD-HHMMSS

**Legacy: ClaudeHistoryImporter** (lib/claude_history_importer.rb):
- No longer used in default flow (kept for reference/alternative workflows)

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
