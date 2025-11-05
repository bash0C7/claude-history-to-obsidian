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
        "command": "cd /Users/bash/src/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
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
  "transcript_path": "/Users/bash/.claude/sessions/session-20251102-143022.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
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
  "transcript_path": "/Users/bash/.claude/sessions/session-20251102-143022.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
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
    "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
    "messages": [
      {"role": "user", "content": "...", "timestamp": "2025-11-02T14:30:22.000Z"},
      {"role": "assistant", "content": "...", "timestamp": "2025-11-02T14:30:25.000Z"}
    ],
    "_first_message_timestamp": "20251102-143022"
  },
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
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
/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
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
/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai/
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
**Path**: /Users/bash/src/Arduino/picoruby-recipes
**Session ID**: abc123456789...
**Date**: 2025-11-02 14:30:22
```

**Claude Web** (`source: "web"`):
```markdown
# Claude Web Session

**Project**: project-name
**Path**: /Users/bash/src/Arduino/picoruby-recipes
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
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
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

## 📦 JSON Nesting & Content Handling

### Content Type Detection

The `build_markdown` method handles content in multiple formats by detecting the type and processing accordingly:

#### Pattern 1: Array Content (Confirmed JSON Structure)

**Condition**: `content.is_a?(Array)`

**Structure**: Typically from Claude Code API responses
```ruby
content = [
  {'type' => 'thinking', 'thinking' => '複数行\nの思考'},
  {'type' => 'text', 'text' => '回答\nテキスト'},
  {'type' => 'signature', 'text' => 'signature data'}  # Filtered out
]
```

**Processing**:
- `format_content_blocks` method processes each block individually
- Block types: `'thinking'`, `'text'`, `'input'`
- Signature blocks are skipped (type filter in block_map)
- Escaped `\n` in content is converted to actual newlines

#### Pattern 2: String Content (Text Message)

**Condition**: `content.is_a?(String)`

**Structure**: Plain text message from user or assistant
```ruby
content = "Hello\nWorld\nMultiple lines"
```

**Processing**:
- Escaped newlines `\n` (backslash-n) are converted to actual newlines via `gsub('\\n', "\n")`
- Content is included as-is in markdown output

#### Pattern 3: Unknown/Other Types

**Condition**: Any other type (rare, defensive coding)

**Processing**:
- Convert to string via `to_s`
- Apply same `\n` conversion logic

### Signature Filtering

Signatures are filtered at two levels to prevent trace data from appearing in Obsidian output:

#### Level 1: Message-Level Signature (Line 157)
```ruby
next if msg['signature']  # Skip entire message if signature field exists
```

This skips messages that contain a top-level `signature` field (tracing data).

#### Level 2: Block-Level Signature (Line 202-208)
```ruby
block_config = block_map[block_type]
next if block_config.nil?  # Skips blocks with type not in block_map
```

The `block_map` only includes `'thinking'`, `'text'`, and `'input'` types, so `'signature'` blocks are automatically filtered out.

### Newline Conversion

Escaped newlines (`\n` as two characters: backslash + n) are converted to actual newlines:

**Line 164**:
```ruby
content = content.gsub('\\n', "\n") if content.is_a?(String)
```

**Line 212**:
```ruby
content_text = content_text.gsub('\\n', "\n") if content_text.is_a?(String)
```

This ensures that:
- Multi-line content displays correctly in Obsidian
- Philosophy: `\n` in JSON becomes actual newlines in markdown output
- Applies to both top-level message content and block content

### Test Coverage

See `test/test_claude_history_to_obsidian.rb` for comprehensive test cases:

- `test_build_markdown_with_content_array_blocks` - Array content with multiple block types
- `test_build_markdown_filters_out_signature_blocks` - Signature filtering
- `test_build_markdown_handles_input_blocks` - Input block type handling
- `test_build_markdown_with_array_content` - Array content format

---

## 📦 Large File Handling

### conversations.json File Size

The `conversations.json` file exported from Claude Web can be **extremely large (100+ MB)** and contains the entire conversation history in a **single line** of JSON.

**Important Considerations**:

1. **File Structure**:
   - Single-line JSON array containing all conversations
   - No pretty-printing or formatting
   - ~97-100MB is common for years of conversations

2. **Production Code** (`rake web:bulk_import`):
   - ✅ Handles large files correctly via streaming JSON parsing
   - `File.read()` with encoding specified reads the entire file but processes it efficiently
   - `JSON.parse()` works on the complete JSON string
   - No memory issues in production

3. **Investigation and Debugging**:
   - ❌ **DO NOT** attempt to view the entire file with tools like `cat` or text editors
   - Use sampling for safe inspection

### Safe Exploration Commands

**Check file size**:
```bash
# Get file size in bytes
ls -lh conversations.json

# Get size in MB
du -m conversations.json

# Example output:
# 97M conversations.json
```

**Safe sampling - first 50KB**:
```bash
# Read first 50000 bytes (safe, instant)
head -c 50000 conversations.json

# Pretty-print sampled JSON (if jq available)
head -c 50000 conversations.json | jq . | head -50
```

**Check JSON structure at start**:
```bash
# Verify it starts with [
head -c 1 conversations.json
# Output: [

# Get first conversation object structure (first ~1000 bytes)
head -c 1000 conversations.json | sed 's/^.//' | jq . 2>/dev/null || echo "Sample extraction failed"
```

**Count conversations safely**:
```bash
# Method 1: Count 'uuid' field occurrences (fast, ~1-2 seconds)
grep -o '"uuid"' conversations.json | wc -l

# Method 2: Read and parse (slower, ~30 seconds for 100MB)
ruby -e "require 'json'; data = JSON.parse(File.read('conversations.json')); puts data.length"
```

**Verify JSON validity**:
```bash
# Parse and validate entire file (safe, proper error reporting)
ruby -e "
  require 'json'
  file_content = File.read('conversations.json', encoding: 'UTF-8')
  file_content = file_content.encode('UTF-8', invalid: :replace)
  JSON.parse(file_content)
  puts 'JSON is valid ✓'
rescue JSON::ParserError => e
  puts \"JSON parse error: #{e.message}\"
  exit 1
"
```

**Extract specific conversation**:
```bash
# Get first conversation UUID
ruby -e "
  require 'json'
  data = JSON.parse(File.read('conversations.json'))
  puts data.first['uuid']
"

# Get specific conversation by UUID
ruby -e "
  require 'json'
  uuid = ARGV[0]
  data = JSON.parse(File.read('conversations.json'))
  conv = data.find { |c| c['uuid'] == uuid }
  puts JSON.pretty_generate(conv) if conv
" <uuid-here>
```

### Ruby Production Code Pattern

**From Rakefile - Web bulk import processing** (lines 92-126):

```ruby
def process_web_conversation(conversation)
  # conversations.json のオブジェクトから必要な情報を抽出
  session_id = conversation['uuid']
  conversation_name = conversation['name'] || 'conversation'
  chat_messages = conversation['chat_messages'] || []

  # 空の会話はスキップ
  return if chat_messages.empty?

  # chat_messages を transcript 形式に変換
  # Note: Claude Web uses 'sender' field instead of 'role', and 'human' instead of 'user'
  messages = chat_messages.map do |msg|
    {
      'role' => msg['sender'] == 'human' ? 'user' : msg['sender'],
      'content' => msg['content'],
      'timestamp' => msg['created_at']
    }
  end

  # トランスクリプトを生成
  timestamp = extract_first_message_timestamp(messages)
  transcript = {
    'session_id' => session_id,
    'cwd' => Dir.pwd,
    'messages' => messages,
    '_first_message_timestamp' => timestamp
  }.compact

  # conversation_name をスラッグ化して project_name として使用
  project_name = slugify_name(conversation_name)

  processor = ClaudeHistoryToObsidian.new
  relative_path = processor.process_transcript(
    project_name: project_name,
    cwd: Dir.pwd,
    session_id: session_id,
    transcript: transcript,
    messages: messages,
    source: 'web'
  )

  relative_path
end
```

**Key implementation details**:

```ruby
# 1. UTF-8 encoding handling with invalid byte replacement
file_content = File.read('conversations.json', encoding: 'UTF-8')
file_content = file_content.encode('UTF-8', invalid: :replace)
conversations = JSON.parse(file_content)

# 2. Field mapping: 'sender' → 'role', 'human' → 'user'
'role' => msg['sender'] == 'human' ? 'user' : msg['sender']

# 3. Handling array content format (type blocks)
content = msg['content']  # Already array format from Web
# Process as-is, no string conversion needed

# 4. Error handling: Non-blocking, continue on failure
conversations.each do |conversation|
  begin
    relative_path = process_web_conversation(conversation)
    puts relative_path
    count += 1
  rescue StandardError => e
    warn "WARNING: Failed to process conversation: #{e.message}"
    # Continue processing next conversation
  end
end
```

### Test Code Pattern - Strict Validation

**From test/test_rake_web_import.rb - Test-data synchronized validation** (lines 25-83):

```ruby
def test_web_import_saves_to_yyyy_mm_directory
  # Step 1: Define expected values (source of truth)
  expected_user_message = 'Hello Claude Web'
  expected_assistant_message = 'Hello! How can I help?'
  expected_project_name = 'test-project'

  # Step 2: Generate test data using expected values
  conversations_json = create_test_conversations_json_with(
    user_message: expected_user_message,
    assistant_message: expected_assistant_message,
    project_name: expected_project_name
  )

  # Step 3: Run the import
  output = run_web_import(conversations_json)

  # Step 4: Verify directory structure using actual timestamp
  year_month_dir = File.join(@vault_web_dir, '202511')
  assert(
    Dir.exist?(year_month_dir),
    "Web vault yyyymm directory should exist: #{year_month_dir}"
  )

  # Step 5: Verify file exists with correct naming format
  markdown_files = Dir.glob(File.join(year_month_dir, '*.md'))
  assert(
    markdown_files.length > 0,
    "Markdown file should exist in web vault yyyymm dir"
  )

  # Step 6: Verify filename format (no session_id for web)
  filename = File.basename(markdown_files.first)
  assert_match(/^\\d{8}-\\d{6}_test-project_.*\\.md$/, filename,
               "Filename should be {timestamp}_{project-name}_{session-name}.md format")

  # Step 7: STRICT VALIDATION - Read content and verify it matches expected values
  content = File.read(markdown_files.first)

  # Verify headers
  assert_include(content, '# Claude Web Session', 'Should have Claude Web Session header')
  assert content.include?('User'), 'User section header should exist'
  assert content.include?('Claude'), 'Claude section header should exist'

  # CRITICAL: Verify actual content matches test data exactly
  assert_include(content, expected_user_message,
    "Expected user message '#{expected_user_message}' should appear in file")
  assert_include(content, expected_assistant_message,
    "Expected assistant message '#{expected_assistant_message}' should appear in file")

  # Verify Code vault was NOT used for web import
  code_year_month_dir = File.join(@vault_code_dir, '202511')
  assert(
    !Dir.exist?(code_year_month_dir),
    "Code vault yyyymm directory should NOT exist for web import"
  )
end
```

**Test data generator pattern** (lines 191-227):

```ruby
def create_test_conversations_json_with(user_message:, assistant_message:, project_name:)
  # Generate test data with embedded expected values
  conversations = [
    {
      'uuid' => 'uuid-12345678',
      'name' => project_name,
      'chat_messages' => [
        {
          'sender' => 'human',  # Production structure (not 'role')
          'content' => [
            {
              'type' => 'text',
              'text' => user_message  # Embed expected value
            }
          ],
          'created_at' => '2025-11-03T10:00:00Z'
        },
        {
          'sender' => 'assistant',
          'content' => [
            {
              'type' => 'text',
              'text' => assistant_message  # Embed expected value
            }
          ],
          'created_at' => '2025-11-03T10:00:05Z'
        }
      ]
    }
  ]

  conversations_json = File.join(@test_dir, 'conversations.json')
  File.write(conversations_json, JSON.generate(conversations))
  conversations_json
end
```

**Key validation principles**:

1. **Define once, use everywhere**:
   ```ruby
   expected_value = 'Hello Claude Web'
   # Pass to test data generator
   # Assert against same variable
   ```

2. **No re-execution for verification**:
   - Read output file ONCE
   - Validate all assertions in single test
   - Use shell exit codes to check pass/fail

3. **Strict content matching**:
   ```ruby
   # ✅ CORRECT: Direct assertion against expected value
   assert_include(content, expected_user_message)

   # ❌ WRONG: Hardcoded string different from test data
   assert_include(content, 'Different message')
   ```

4. **Production-realistic test data**:
   - Use `'sender'` field, not `'role'`
   - Use array content format with type blocks
   - Use ISO timestamp format `'created_at'`
   - Match actual conversations.json structure exactly

### Development Best Practices

**File exploration workflow**:

```bash
# 1. Check file size first
ls -lh conversations.json

# 2. Sample safely
head -c 50000 conversations.json | jq . | head -20

# 3. Validate JSON
ruby -e "require 'json'; JSON.parse(File.read('conversations.json')); puts 'Valid ✓'"

# 4. Count records
grep -o '"uuid"' conversations.json | wc -l

# 5. Run tests (NOT manual inspection)
bundle exec ruby -I lib:test -rtest/unit test/test_rake_web_import.rb
```

**When working with large files**:

- ❌ Never use `cat`, `less`, or text editors
- ❌ Never attempt to load full file for inspection
- ❌ Never run multiple test iterations to debug
- ✅ Use safe sampling with `head -c N`
- ✅ Use `jq` for structured inspection
- ✅ Trust test assertions (exit code tells you if tests pass)
- ✅ Review logs for detailed error information

**Test validation approach**:

- Define expected values at test start
- Generate test data from those values
- Run test once, check exit code
- If exit code 0 → all assertions passed
- If exit code 1 → read assertion failure message
- Never re-run just to inspect output

### Critical Rule: Single Execution + Exit Code

**Testing Principle** (非妥協的ルール):

```bash
# ✅ CORRECT: Single execution, check exit code, review output if needed
bundle exec ruby -I lib:test test/test_web_import.rb 2>&1
echo "Exit code: $?"

# ❌ WRONG: Multiple executions wasting time and resources
bundle exec ruby -I lib:test test/test_web_import.rb | tail -5
# ... then ...
bundle exec ruby -I lib:test test/test_web_import.rb 2>&1  # Redundant!
```

**Workflow**:
1. Run test once, capture complete output
2. Check exit code immediately
3. Exit code 0? → Test passes, done
4. Exit code non-zero? → Review captured output for failure details
5. Fix issue based on failure message
6. Run once more to verify fix
7. Never run multiple times for inspection

**Why**:
- Respects developer time (no redundant execution)
- Exit code is authoritative (no guessing)
- Full logs available for investigation
- Follows principle: "Trust test assertions, use exit codes"

---

## 🔗 Related Documentation

- **@.claude/development.md** - Development setup and commands
- **@.claude/practices.md** - TDD methodology and operations
- **@CLAUDE.md** - Claude Code project overview
