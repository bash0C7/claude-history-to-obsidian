---
name: ruby-cli-debugging
description: "🐛 Debug Ruby CLI errors, analyze logs, trace execution flow, inspect variables. Use when you see 'error', 'failed', 'exception', 'logs show', or 'not working'. Use PROACTIVELY when tests fail unexpectedly or behavior is incorrect."
---

# Ruby CLI Debugging Skill

Debug and troubleshoot the claude-history-to-obsidian Ruby CLI application.

## View Application Logs

Check the application log file for debugging information:

```bash
#!/bin/bash
# ログファイル閲覧

LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log

echo "=== Application Logs ==="
echo "Location: $LOG_FILE"
echo ""

if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found (will be created on first run)"
  exit 1
fi

echo "File size: $(stat -f%z "$LOG_FILE") bytes"
echo "Last modified: $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$LOG_FILE")"
echo ""

echo "=== Recent Logs (last 50 lines) ==="
tail -50 "$LOG_FILE"

echo ""
echo "=== All Logs ==="
wc -l "$LOG_FILE"
```

## Tail Logs in Real-Time

Monitor logs as scripts execute:

```bash
#!/bin/bash
# リアルタイムログ監視

LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log

# ログファイルが存在しなければ作成
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

echo "Watching logs (press Ctrl+C to stop):"
echo "File: $LOG_FILE"
echo "---"

tail -f "$LOG_FILE"
```

## Search Logs for Errors

Find error messages in the log:

```bash
#!/bin/bash
# ログからエラーを検索

LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log

if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found"
  exit 1
fi

echo "=== Searching for Errors ==="
echo ""

# エラーパターン検索
echo "1️⃣ ERROR entries:"
grep -i "ERROR" "$LOG_FILE" || echo "No errors found"

echo ""
echo "2️⃣ WARN entries:"
grep -i "WARN" "$LOG_FILE" || echo "No warnings found"

echo ""
echo "3️⃣ Exception entries:"
grep -i "exception\|error\|failed\|failed" "$LOG_FILE" || echo "No exceptions found"

echo ""
echo "4️⃣ Latest 10 entries:"
tail -10 "$LOG_FILE"
```

## Debug with Ruby Inspector

Run the script with debug output:

```bash
#!/bin/bash
# Rubyデバッガーでの実行

cd /Users/bash/src/claude-history-to-obsidian

echo "=== Running with Debug Output ==="
echo ""

# テストデータ作成
cat > /tmp/debug-hook.json <<'EOF'
{
  "session_id": "debug-test",
  "transcript_path": "/tmp/debug-transcript.json",
  "cwd": "/Users/bash/src/debug",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/debug-transcript.json <<'EOF'
{
  "session_id": "debug-test",
  "cwd": "/Users/bash/src/debug",
  "messages": [
    {"role": "user", "content": "Debug test"},
    {"role": "assistant", "content": "Testing debug output"}
  ]
}
EOF

# Ruby スクリプトに-d フラグで実行（構文チェック）
echo "1️⃣ Syntax check:"
bundle exec ruby -c bin/claude-history-to-obsidian

echo ""
echo "2️⃣ Running with debug:"
# DEBUG環境変数を使用（実装時に対応している場合）
DEBUG=1 cat /tmp/debug-hook.json | bundle exec ruby bin/claude-history-to-obsidian

echo ""
echo "3️⃣ With verbose output:"
cat /tmp/debug-hook.json | bundle exec ruby -w bin/claude-history-to-obsidian 2>&1
```

## Inspect JSON Input/Output

Validate JSON structure at each stage:

```bash
#!/bin/bash
# JSONデータの検証

echo "=== JSON Input Validation ==="
echo ""

# テスト Hook JSON
HOOK_JSON=/tmp/test-hook.json
cat > "$HOOK_JSON" <<'EOF'
{
  "session_id": "inspect-test",
  "transcript_path": "/tmp/inspect-transcript.json",
  "cwd": "/Users/bash/src/inspect",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

echo "1️⃣ Hook JSON validation:"
if command -v jq &> /dev/null; then
  echo "Parsed JSON:"
  cat "$HOOK_JSON" | jq .

  echo ""
  echo "Checking required fields:"
  jq -e '.session_id' "$HOOK_JSON" > /dev/null && echo "✅ session_id" || echo "❌ session_id missing"
  jq -e '.transcript_path' "$HOOK_JSON" > /dev/null && echo "✅ transcript_path" || echo "❌ transcript_path missing"
  jq -e '.cwd' "$HOOK_JSON" > /dev/null && echo "✅ cwd" || echo "❌ cwd missing"
else
  echo "jq not found, using ruby:"
  bundle exec ruby -rjson -e "JSON.parse(File.read('$HOOK_JSON')).each { |k,v| puts \"#{k}: #{v}\" }"
fi

# テスト Transcript JSON
TRANSCRIPT_JSON=/tmp/inspect-transcript.json
cat > "$TRANSCRIPT_JSON" <<'EOF'
{
  "session_id": "inspect-test",
  "cwd": "/Users/bash/src/inspect",
  "messages": [
    {"role": "user", "content": "User message"},
    {"role": "assistant", "content": "Assistant response"}
  ]
}
EOF

echo ""
echo "2️⃣ Transcript JSON validation:"
if command -v jq &> /dev/null; then
  jq . "$TRANSCRIPT_JSON"

  echo ""
  echo "Message count:"
  jq '.messages | length' "$TRANSCRIPT_JSON"

  echo ""
  echo "Message roles:"
  jq '.messages[].role' "$TRANSCRIPT_JSON"
else
  bundle exec ruby -rjson -e "json = JSON.parse(File.read('$TRANSCRIPT_JSON')); puts \"Messages: #{json['messages'].count}\"; json['messages'].each { |m| puts \"  #{m['role']}: #{m['content'][0..50]}\" }"
fi
```

## Test JSON Parsing

Verify JSON parsing logic:

```bash
#!/bin/bash
# JSON パースロジックのテスト

echo "=== JSON Parsing Test ==="
echo ""

# Ruby で JSON パースをテスト
bundle exec ruby <<'RUBY'
require 'json'

# テスト 1: 有効な JSON
puts "1️⃣ Valid JSON parsing:"
valid_json = '{"session_id": "test123", "cwd": "/test"}'
begin
  data = JSON.parse(valid_json)
  puts "✅ Parsed successfully"
  puts "  session_id: #{data['session_id']}"
  puts "  cwd: #{data['cwd']}"
rescue JSON::ParserError => e
  puts "❌ Parse error: #{e.message}"
end

puts ""

# テスト 2: 無効な JSON
puts "2️⃣ Invalid JSON handling:"
invalid_json = '{invalid json}'
begin
  data = JSON.parse(invalid_json)
  puts "✅ Parsed"
rescue JSON::ParserError => e
  puts "✅ Caught error (expected): #{e.message[0..50]}"
end

puts ""

# テスト 3: メッセージ処理
puts "3️⃣ Message parsing:"
transcript = {
  "session_id" => "test",
  "cwd" => "/test",
  "messages" => [
    {"role" => "user", "content" => "Hello"},
    {"role" => "assistant", "content" => "Hi there"}
  ]
}

transcript['messages'].each_with_index do |msg, idx|
  puts "  Message #{idx}: #{msg['role']}"
  puts "    Content: #{msg['content'][0..30]}..."
end

RUBY
```

## Trace File Operations

Debug file read/write operations:

```bash
#!/bin/bash
# ファイル操作のトレース

echo "=== File Operations Trace ==="
echo ""

# テストセットアップ
TEST_DIR="/tmp/trace-test"
mkdir -p "$TEST_DIR"

TRANSCRIPT_FILE="$TEST_DIR/transcript.json"
cat > "$TRANSCRIPT_FILE" <<'EOF'
{
  "session_id": "trace-test",
  "cwd": "/Users/bash/src/trace",
  "messages": [
    {"role": "user", "content": "Test"},
    {"role": "assistant", "content": "Response"}
  ]
}
EOF

# Ruby でファイル操作をテスト
bundle exec ruby <<RUBY
require 'json'

puts "1️⃣ Reading transcript file:"
file_path = "$TRANSCRIPT_FILE"
puts "  Path: #{file_path}"
puts "  Exists: #{File.exist?(file_path)}"
puts "  Size: #{File.size(file_path)} bytes"

puts ""
puts "2️⃣ Parsing content:"
content = File.read(file_path)
data = JSON.parse(content)
puts "  Session ID: #{data['session_id']}"
puts "  CWD: #{data['cwd']}"
puts "  Message count: #{data['messages'].count}"

puts ""
puts "3️⃣ Testing directory creation:"
vault_path = File.expand_path("~/test-vault/project")
puts "  Would create: #{vault_path}"
puts "  Parent exists: #{File.exist?(File.dirname(vault_path))}"

puts ""
puts "4️⃣ Markdown output (preview):"
markdown = "# Claude Code Session\n\n**Project**: test\n**Date**: #{Time.now}\n"
puts "  Length: #{markdown.length} chars"
puts "  First 100 chars:"
puts "  " + markdown[0..100]

RUBY
```

## Test Session Name Extraction

Debug the session name generation logic:

```bash
#!/bin/bash
# セッション名抽出ロジックのテスト

echo "=== Session Name Extraction Test ==="
echo ""

bundle exec ruby <<'RUBY'
# セッション名抽出ロジック（CLAUDE.md から）
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

# テストケース
test_cases = [
  {
    name: "Normal message",
    messages: [{"role" => "user", "content" => "Implementing the feature for button handling"}]
  },
  {
    name: "Message with special chars",
    messages: [{"role" => "user", "content" => "Fix: bug@#$% in the API—shouldn't break!"}]
  },
  {
    name: "Very long message",
    messages: [{"role" => "user", "content" => "Implementing comprehensive error handling with retry logic and exponential backoff strategies"}]
  },
  {
    name: "Empty message",
    messages: [{"role" => "user", "content" => ""}]
  },
  {
    name: "No user message",
    messages: [{"role" => "assistant", "content" => "Hello"}]
  },
  {
    name: "Multiline message",
    messages: [{"role" => "user", "content" => "First line only\nSecond line\nThird line"}]
  }
]

test_cases.each do |test|
  result = extract_session_name(test[:messages])
  input = test[:messages].first['content'][0..40]
  puts "✅ #{test[:name]}"
  puts "   Input: \"#{input}...\" "
  puts "   Output: \"#{result}\""
  puts ""
end

RUBY
```

## Debug Markdown Generation

Test markdown formatting:

```bash
#!/bin/bash
# Markdown生成のテスト

echo "=== Markdown Generation Test ==="
echo ""

bundle exec ruby <<'RUBY'
require 'json'

# テスト用データ
data = {
  "session_id" => "markdown-test-12345",
  "cwd" => "/Users/bash/src/test-project",
  "messages" => [
    {"role" => "user", "content" => "Test user message"},
    {"role" => "assistant", "content" => "Test assistant response\n\n```ruby\nputs 'code block'\n```"}
  ]
}

# Markdown 構築
markdown = []
markdown << "# Claude Code Session"
markdown << ""
markdown << "**Project**: #{File.basename(data['cwd'])}"
markdown << "**Path**: #{data['cwd']}"
markdown << "**Session ID**: #{data['session_id']}"
markdown << "**Date**: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
markdown << ""
markdown << "---"
markdown << ""

data['messages'].each do |msg|
  if msg['role'] == 'user'
    markdown << "## 👤 User"
  else
    markdown << "## 🤖 Claude"
  end
  markdown << ""
  markdown << msg['content']
  markdown << ""
  markdown << "---"
  markdown << ""
end

output = markdown.join("\n")

puts "Generated Markdown (first 500 chars):"
puts "---"
puts output[0..500]
puts "---"
puts ""
puts "Stats:"
puts "  Total lines: #{output.split("\n").count}"
puts "  Total chars: #{output.length}"
puts "  Sections: #{output.scan(/^## /).count}"

RUBY
```

## Check Ruby Syntax

Validate Ruby script syntax:

```bash
#!/bin/bash
# Ruby スクリプト構文チェック

cd /Users/bash/src/claude-history-to-obsidian

echo "=== Ruby Syntax Check ==="
echo ""

echo "1️⃣ Entry point script:"
bundle exec ruby -c bin/claude-history-to-obsidian && echo "✅ bin/claude-history-to-obsidian syntax OK" || echo "❌ Syntax error"

echo ""
echo "2️⃣ Core logic class:"
bundle exec ruby -c lib/claude_history_to_obsidian.rb && echo "✅ lib/claude_history_to_obsidian.rb syntax OK" || echo "❌ Syntax error"

echo ""
echo "3️⃣ Load library:"
bundle exec ruby -e "require './lib/claude_history_to_obsidian'; puts '✅ Library loaded successfully'" 2>&1
```

## Inspect Gem Dependencies

Debug gem-related issues:

```bash
#!/bin/bash
# Gem 依存関係のデバッグ

cd /Users/bash/src/claude-history-to-obsidian

echo "=== Gem Dependency Debug ==="
echo ""

echo "1️⃣ Gemfile requirements:"
bundle check

echo ""
echo "2️⃣ Installed gems:"
bundle list

echo ""
echo "3️⃣ Gem load paths:"
bundle exec ruby -e "puts \$LOAD_PATH.select { |p| p.include?('vendor/bundle') }"

echo ""
echo "4️⃣ Terminal notifier availability:"
bundle exec ruby -e "begin; require 'terminal_notifier'; puts '✅ terminal-notifier available'; rescue LoadError; puts '⚠️ terminal-notifier not loaded (optional)'; end"
```

## Memory and Performance Debug

Check script performance:

```bash
#!/bin/bash
# パフォーマンスデバッグ

cd /Users/bash/src/claude-history-to-obsidian

echo "=== Performance Debug ==="
echo ""

# テストデータ作成
cat > /tmp/perf-hook.json <<'EOF'
{
  "session_id": "perf-test",
  "transcript_path": "/tmp/perf-transcript.json",
  "cwd": "/Users/bash/src/perf",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/perf-transcript.json <<'EOF'
{
  "session_id": "perf-test",
  "cwd": "/Users/bash/src/perf",
  "messages": [
    {"role": "user", "content": "Performance test message"},
    {"role": "assistant", "content": "Response"}
  ]
}
EOF

echo "Execution time measurement:"
time cat /tmp/perf-hook.json | bundle exec ruby bin/claude-history-to-obsidian

echo ""
echo "Memory usage (top output):"
(cat /tmp/perf-hook.json | timeout 5 bundle exec ruby bin/claude-history-to-obsidian &)
sleep 1
ps aux | grep claude-history-to-obsidian | grep -v grep || echo "Process completed"
```

## Debug Environment Variables

Check environment setup:

```bash
#!/bin/bash
# 環境変数デバッグ

echo "=== Environment Debug ==="
echo ""

bundle exec ruby <<'RUBY'
puts "Ruby Information:"
puts "  Version: #{RUBY_VERSION}"
puts "  Platform: #{RUBY_PLATFORM}"
puts "  Home: #{Gem.user_home}"
puts ""

puts "Load Paths:"
$LOAD_PATH.each { |p| puts "  #{p}" if p.include?('vendor/bundle') || p.include?('ruby') }
puts ""

puts "Working Directory:"
puts "  #{Dir.pwd}"
puts ""

puts "Home Directory:"
puts "  #{File.expand_path('~')}"
puts ""

puts "Useful Paths:"
puts "  Log: #{File.expand_path('~/.local/var/log')}"
puts "  Vault: #{File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code')}"

RUBY
```

## Run with Debugging Enabled

Execute with maximum verbosity:

```bash
#!/bin/bash
# デバッグモードでの実行

cd /Users/bash/src/claude-history-to-obsidian

# テストデータ
cat > /tmp/verbose-hook.json <<'EOF'
{
  "session_id": "verbose-test",
  "transcript_path": "/tmp/verbose-transcript.json",
  "cwd": "/Users/bash/src/verbose",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/verbose-transcript.json <<'EOF'
{
  "session_id": "verbose-test",
  "cwd": "/Users/bash/src/verbose",
  "messages": [
    {"role": "user", "content": "Verbose test"},
    {"role": "assistant", "content": "Testing verbose output"}
  ]
}
EOF

echo "Running with debug flags:"
echo ""

# 最大デバッグ
set -x
DEBUG=1 VERBOSE=1 cat /tmp/verbose-hook.json | bundle exec ruby -w -d bin/claude-history-to-obsidian 2>&1 | head -100
set +x
```
