# Large File Handling

## conversations.json File Size

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

## Safe Exploration Commands

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

## Ruby Production Code Pattern

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

## Test Code Pattern - Strict Validation

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

## Development Best Practices

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

## Critical Rule: Single Execution + Exit Code

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
