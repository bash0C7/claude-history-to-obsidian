---
name: hook-integration
description: "🪝 Create Hook test data, simulate Claude Code Stop event, verify transcript processing, validate Obsidian output. Use when 'testing hook', 'simulate hook', 'verify hook integration', or 'end-to-end test'. Use PROACTIVELY for integration testing and Hook workflow validation."
---

# Hook Integration Skill

Test and verify Claude Code Hook integration for the claude-history-to-obsidian application.

## Skill Role & Use Cases

**Use this skill for**:
- End-to-end hook integration testing
- Simulating Claude Code Stop event
- Verifying full hook workflow
- Testing Obsidian vault output
- Validating transcript processing through Hook JSON
- Testing multiple format scenarios (Web vs Code)
- Error handling in hook scenarios

**Do NOT use for**:
- Unit testing individual Ruby methods (use ruby-testing skill instead)
- Quick script validation with minimal setup
- Testing code logic without hook simulation

## Hook Configuration Setup

Configure the Hook in Claude Code settings:

```bash
# Hook設定を .claude/settings.local.json に追加
# (プロジェクトディレクトリで実行)

cd ~/src/claude-history-to-obsidian

cat > ~/.claude/settings.local.json <<'EOF'
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "cd ~/src/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
EOF

echo "✅ Hook configuration saved to ~/.claude/settings.local.json"

# 設定確認
echo ""
echo "Current hook configuration:"
cat ~/.claude/settings.local.json | jq '.hooks.Stop'
```

## Create Test Hook JSON

Generate test data for hook simulation:

```bash
#!/bin/bash
# Hook テスト用 JSON データ作成

SESSION_ID="hook-test-$(date +%s)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Creating test hook JSON with session ID: $SESSION_ID"

# Hook JSON 入力テンプレート
cat > /tmp/hook-input-test.json <<EOF
{
  "session_id": "$SESSION_ID",
  "transcript_path": "/tmp/test-transcript-$SESSION_ID.json",
  "cwd": "~/src/hook-test",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

# Transcript JSON テンプレート
cat > /tmp/test-transcript-$SESSION_ID.json <<'EOF2'
{
  "session_id": "hook-test-session",
  "cwd": "~/src/hook-test",
  "messages": [
    {
      "role": "user",
      "content": "Testing Hook Integration with Claude Code"
    },
    {
      "role": "assistant",
      "content": "I'll help you test the hook integration.\n\nHere's what will happen:\n1. This script receives the session data via stdin\n2. Parses the transcript JSON\n3. Converts to Markdown\n4. Saves to Obsidian vault\n\n```ruby\n# Example hook processing\ndef process_hook_input\n  json = JSON.parse(STDIN.read)\n  transcript = load_transcript(json['transcript_path'])\n  # Process...\nend\n```"
    },
    {
      "role": "user",
      "content": "Verify the output file is created"
    },
    {
      "role": "assistant",
      "content": "The Hook should have created a markdown file in the Obsidian vault at:\n\n`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/hook-test/`\n\nFile naming format: `{YYYYMMDD-HHMMSS}_{session-name}_{session-id-short}.md`"
    }
  ]
}
EOF2

echo ""
echo "✅ Test files created:"
echo "  - /tmp/hook-input-test.json"
echo "  - /tmp/test-transcript-$SESSION_ID.json"
echo ""
echo "Hook input content:"
cat /tmp/hook-input-test.json | jq .
```

## Simulate Hook Execution

Run the application as if triggered by the Hook:

```bash
#!/bin/bash
# Hook実行のシミュレーション

cd ~/src/claude-history-to-obsidian

# テストデータが存在することを確認
if [ ! -f "/tmp/hook-input-test.json" ]; then
  echo "❌ Test data not found. Run 'Create Test Hook JSON' first."
  exit 1
fi

echo "🚀 Simulating Hook execution..."
echo ""
echo "Command: cat /tmp/hook-input-test.json | bundle exec ruby bin/claude-history-to-obsidian"
echo ""

# Hook実行（stdin から JSON を読み込み）
cat /tmp/hook-input-test.json | bundle exec ruby bin/claude-history-to-obsidian

echo ""
echo "✅ Hook execution complete"
echo ""
echo "Exit code: $?"
echo "Expected: 0 (non-blocking hook)"
```

## Verify Hook Output

Check that the Hook created the expected files:

```bash
#!/bin/bash
# Hook実行結果の確認

echo "=== Verifying Hook Output ==="
echo ""

VAULT_BASE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code"

# 1. Vault ディレクトリ確認
echo "1️⃣ Vault Directory Status:"
if [ -d "$VAULT_BASE" ]; then
  echo "✅ Vault base found: $VAULT_BASE"
else
  echo "❌ Vault base not found"
  echo "Expected: $VAULT_BASE"
  exit 1
fi

echo ""
echo "2️⃣ Project Directories:"
if [ -d "$VAULT_BASE/hook-test" ]; then
  echo "✅ hook-test/ directory created"
  echo "Contents:"
  ls -lh "$VAULT_BASE/hook-test/"
else
  echo "❌ hook-test/ directory not found"
fi

echo ""
echo "3️⃣ Generated Markdown Files:"
MD_FILES=$(find "$VAULT_BASE/hook-test" -name "*.md" -type f 2>/dev/null)
if [ -z "$MD_FILES" ]; then
  echo "❌ No markdown files found"
  echo "Expected file pattern: YYYYMMDD-HHMMSS_session-name_sessionid.md"
else
  echo "✅ Markdown files found:"
  echo "$MD_FILES" | while read -r file; do
    echo ""
    echo "File: $(basename "$file")"
    echo "Size: $(stat -f%z "$file") bytes"
    echo "Modified: $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$file")"
  done
fi

echo ""
echo "4️⃣ Latest File Content (first 100 lines):"
LATEST=$(find "$VAULT_BASE" -name "*.md" -type f -exec stat -f%Sm -t '%s' {} + 2>/dev/null | sort -k1 -n | tail -1 | awk '{print $2}')
if [ -n "$LATEST" ]; then
  echo "Displaying: $(basename "$LATEST")"
  echo "---"
  head -100 "$LATEST"
else
  echo "No files to display"
fi
```

## Test Hook with Real Session Data

Create realistic test data from an actual transcript:

```bash
#!/bin/bash
# 実際のセッションデータのようなテストデータ作成

SESSION_ID="realistic-$(date +%s)"
PROJ_NAME="picoruby-recipes"

echo "Creating realistic test with project: $PROJ_NAME"
echo "Session ID: $SESSION_ID"
echo ""

# リアルなHook JSON
cat > /tmp/realistic-hook.json <<EOF
{
  "session_id": "$SESSION_ID",
  "transcript_path": "/tmp/realistic-transcript-$SESSION_ID.json",
  "cwd": "~/src/Arduino/$PROJ_NAME",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

# リアルなTranscript JSON（複数メッセージ）
cat > /tmp/realistic-transcript-$SESSION_ID.json <<'EOF2'
{
  "session_id": "realistic-session-123456789",
  "cwd": "~/src/Arduino/picoruby-recipes",
  "messages": [
    {
      "role": "user",
      "content": "Help me add LED control to the PicoRuby project"
    },
    {
      "role": "assistant",
      "content": "I'll help you add LED control functionality to your PicoRuby project.\n\nFirst, let's look at the current project structure. Here's a basic LED control implementation:\n\n```ruby\nclass LEDController\n  def initialize(pin)\n    @pin = pin\n    setup_gpio\n  end\n\n  def setup_gpio\n    # GPIO initialization for PicoRuby\n  end\n\n  def on\n    GPIO.high(@pin)\n  end\n\n  def off\n    GPIO.low(@pin)\n  end\nend\n```"
    },
    {
      "role": "user",
      "content": "What about PWM for brightness control?"
    },
    {
      "role": "assistant",
      "content": "Great question! PWM (Pulse Width Modulation) allows you to control brightness:\n\n```ruby\nclass PWMLEDController < LEDController\n  def set_brightness(level)\n    # level: 0-255\n    PWM.set(@pin, level)\n  end\nend\n```"
    }
  ]
}
EOF2

echo "✅ Created realistic test files"
echo ""
echo "Running hook simulation..."
cd ~/src/claude-history-to-obsidian
cat /tmp/realistic-hook.json | bundle exec ruby bin/claude-history-to-obsidian

echo ""
echo "Checking output..."
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/picoruby-recipes"
if [ -d "$VAULT_PATH" ]; then
  echo "✅ picoruby-recipes/ directory exists"
  echo "Files:"
  ls -lh "$VAULT_PATH"
else
  echo "⚠️ Directory not found yet (iCloud sync may be pending)"
fi
```

## Hook Integration Testing with Test Mode (CLAUDE_VAULT_MODE=test)

Isolate hook testing from production vault using test mode:

```bash
#!/bin/bash
# Hook統合テストをテストモードで実行（本番Vaultへの影響なし）

set -e

PROJ_DIR="~/src/claude-history-to-obsidian"
TEST_ID="hook-test-mode-$(date +%s)"

echo "🧪 Hook Integration Test (Test Mode)"
echo "===================================="
echo "Test ID: $TEST_ID"
echo ""

# テストモードでのHook設定
export CLAUDE_VAULT_PATH=/tmp/test-vault
export CLAUDE_VAULT_MODE=test

# Step 1: テストデータ作成
echo "Step 1️⃣: Creating test hook and transcript..."
cat > /tmp/test-mode-hook-$TEST_ID.json <<EOF
{
  "session_id": "$TEST_ID",
  "transcript_path": "/tmp/test-transcript-$TEST_ID.json",
  "cwd": "~/src/test-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/test-transcript-$TEST_ID.json <<'EOF2'
{
  "session_id": "test-session-123",
  "cwd": "~/src/test-project",
  "messages": [
    {"role": "user", "content": "Testing hook in test mode"},
    {"role": "assistant", "content": "This runs safely in test vault"},
    {"role": "user", "content": "Verify the output"},
    {"role": "assistant", "content": "Files are in [test] vault"}
  ]
}
EOF2

echo "✅ Test files created"

# Step 2: Hook実行（テストモード）
echo ""
echo "Step 2️⃣: Executing hook in test mode..."
cd "$PROJ_DIR"
cat /tmp/test-mode-hook-$TEST_ID.json | bundle exec ruby bin/claude-history-to-obsidian
EXIT_CODE=$?

echo ""
echo "Exit code: $EXIT_CODE (expected: 0)"

# Step 3: テストVault確認
echo ""
echo "Step 3️⃣: Verifying test vault output..."
TEST_VAULT="/tmp/test-vault/Claude Code [test]/test-project"

if [ -d "$TEST_VAULT" ]; then
  echo "✅ Test vault directory created: $TEST_VAULT"
  echo "Files:"
  ls -lh "$TEST_VAULT/"

  # ファイル内容確認
  LATEST=$(ls -t "$TEST_VAULT"/*.md 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    echo ""
    echo "✅ Generated file: $(basename "$LATEST")"
    echo "---"
    head -30 "$LATEST"
  fi
else
  echo "❌ Test vault not found"
fi

echo ""
echo "===================================="
echo "✅ Test mode hook test complete!"
echo "===================================="

# Cleanup
rm -f /tmp/test-mode-hook-$TEST_ID.json
rm -f /tmp/test-transcript-$TEST_ID.json
```

### Multiple Concurrent Hook Tests

Run multiple hook tests in parallel with different test vaults:

```bash
#!/bin/bash
# 複数のHookテストを並行実行（テストモード使用）

PROJ_DIR="~/src/claude-history-to-obsidian"

# Test 1: Web format
export CLAUDE_VAULT_PATH=/tmp/test-vault-web
export CLAUDE_VAULT_MODE=test

cat > /tmp/web-hook.json <<'EOF'
{
  "session_id": "web-test-123",
  "transcript_path": "/tmp/web-transcript.json",
  "cwd": "~/src/web-project",
  "source": "web",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/web-transcript.json <<'EOF2'
{
  "session_id": "web-test-123",
  "cwd": "~/src/web-project",
  "messages": [
    {"role": "user", "content": "Testing Web format"},
    {"role": "assistant", "content": "Web format uses different filename structure"}
  ]
}
EOF2

echo "Running Web format hook test..."
cat /tmp/web-hook.json | bundle exec ruby bin/claude-history-to-obsidian

# Test 2: Code format
export CLAUDE_VAULT_PATH=/tmp/test-vault-code
export CLAUDE_VAULT_MODE=test

cat > /tmp/code-hook.json <<'EOF'
{
  "session_id": "code-test-456",
  "transcript_path": "/tmp/code-transcript.json",
  "cwd": "~/src/code-project",
  "source": "code",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/code-transcript.json <<'EOF2'
{
  "session_id": "code-test-456",
  "cwd": "~/src/code-project",
  "messages": [
    {"role": "user", "content": "Testing Code format"},
    {"role": "assistant", "content": "Code format includes session ID in filename"}
  ]
}
EOF2

echo "Running Code format hook test..."
cat /tmp/code-hook.json | bundle exec ruby bin/claude-history-to-obsidian

# Compare results
echo ""
echo "Comparing test vault outputs:"
echo ""
echo "Web format files:"
ls -lh /tmp/test-vault-web/claude.ai\ \[test\]/**/*.md 2>/dev/null || echo "No files"

echo ""
echo "Code format files:"
ls -lh /tmp/test-vault-code/Claude\ Code\ \[test\]/**/*.md 2>/dev/null || echo "No files"
```

## Hook Error Handling Test

Test how the hook handles errors gracefully:

```bash
#!/bin/bash
# Hook エラーハンドリングのテスト

cd ~/src/claude-history-to-obsidian

echo "=== Testing Error Scenarios ==="
echo ""

# テスト 1: 無効な transcript path
echo "1️⃣ Test invalid transcript path:"
cat > /tmp/error-test-hook.json <<'EOF'
{
  "session_id": "error-test-1",
  "transcript_path": "/tmp/nonexistent.json",
  "cwd": "~/src/test",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

echo "Input:"
cat /tmp/error-test-hook.json | jq .
echo ""
echo "Execution:"
cat /tmp/error-test-hook.json | bundle exec ruby bin/claude-history-to-obsidian 2>&1
EXIT_CODE=$?
echo ""
echo "Exit Code: $EXIT_CODE (expected: 0 for non-blocking)"
echo ""

# テスト 2: 不正な JSON
echo "2️⃣ Test invalid JSON:"
echo '{invalid json}' | bundle exec ruby bin/claude-history-to-obsidian 2>&1
EXIT_CODE=$?
echo "Exit Code: $EXIT_CODE (expected: 0)"
echo ""

# テスト 3: 空のメッセージ
echo "3️⃣ Test empty messages:"
cat > /tmp/empty-hook.json <<'EOF'
{
  "session_id": "empty-test",
  "transcript_path": "/tmp/empty-transcript.json",
  "cwd": "~/src/empty",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/empty-transcript.json <<'EOF'
{
  "session_id": "empty-test",
  "cwd": "~/src/empty",
  "messages": []
}
EOF

cat /tmp/empty-hook.json | bundle exec ruby bin/claude-history-to-obsidian 2>&1
EXIT_CODE=$?
echo "Exit Code: $EXIT_CODE"
echo ""

echo "✅ Error handling tests complete"
```

## Check Hook Logs

Review logs from hook execution:

```bash
#!/bin/bash
# Hook実行ログの確認

LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log

echo "=== Hook Execution Logs ==="
echo ""

if [ -f "$LOG_FILE" ]; then
  echo "Log file: $LOG_FILE"
  echo "Size: $(stat -f%z "$LOG_FILE") bytes"
  echo ""
  echo "Recent entries (last 30 lines):"
  echo "---"
  tail -30 "$LOG_FILE"
  echo "---"
else
  echo "Log file not found: $LOG_FILE"
  echo "It will be created on first hook execution"
fi

echo ""
echo "Full log tail:"
tail -f "$LOG_FILE" &
TAIL_PID=$!
sleep 3
kill $TAIL_PID 2>/dev/null
```

## Validate Hook File Format

Check file naming and content structure:

```bash
#!/bin/bash
# Hook生成ファイルのフォーマット検証

echo "=== Validating Hook Output Format ==="
echo ""

VAULT_BASE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code"

find "$VAULT_BASE" -name "*.md" -type f 2>/dev/null | while read -r file; do
  filename=$(basename "$file")
  echo "File: $filename"

  # ファイル名フォーマット検証
  if [[ $filename =~ ^[0-9]{8}-[0-9]{6}_[a-z0-9-]+_[a-z0-9]+\.md$ ]]; then
    echo "✅ Filename format valid"
  else
    echo "❌ Filename format invalid"
    echo "Expected: YYYYMMDD-HHMMSS_name_id.md"
  fi

  # Markdown 内容検証
  echo "Checking content structure:"
  grep -q "^# Claude Code Session" "$file" && echo "✅ Has title" || echo "❌ Missing title"
  grep -q "^## 👤 User" "$file" && echo "✅ Has User sections" || echo "❌ Missing User sections"
  grep -q "^## 🤖 Claude" "$file" && echo "✅ Has Claude sections" || echo "❌ Missing Claude sections"
  grep -q "^---$" "$file" && echo "✅ Has separators" || echo "❌ Missing separators"

  echo ""
done
```

## Complete End-to-End Hook Test

Run a full integration test:

```bash
#!/bin/bash
# 完全なHook統合テスト

set -e

PROJ_DIR="~/src/claude-history-to-obsidian"
TEST_ID="e2e-$(date +%s)"

echo "🧪 Complete End-to-End Hook Test"
echo "=================================="
echo "Test ID: $TEST_ID"
echo ""

# ステップ 1: テストデータ作成
echo "Step 1️⃣: Creating test data..."
cat > /tmp/e2e-hook.json <<EOF
{
  "session_id": "$TEST_ID",
  "transcript_path": "/tmp/e2e-transcript-$TEST_ID.json",
  "cwd": "~/src/e2e-test",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat > /tmp/e2e-transcript-$TEST_ID.json <<'EOF2'
{
  "session_id": "e2e-session",
  "cwd": "~/src/e2e-test",
  "messages": [
    {"role": "user", "content": "End to end hook test"},
    {"role": "assistant", "content": "Testing complete hook workflow"}
  ]
}
EOF2

# ステップ 2: Hook 実行
echo "Step 2️⃣: Executing hook..."
cd "$PROJ_DIR"
cat /tmp/e2e-hook.json | bundle exec ruby bin/claude-history-to-obsidian

# ステップ 3: 出力確認
echo ""
echo "Step 3️⃣: Verifying output..."
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/e2e-test"
if [ -d "$VAULT" ]; then
  echo "✅ Output directory created"
  FILE_COUNT=$(find "$VAULT" -name "*.md" | wc -l)
  echo "✅ Markdown files: $FILE_COUNT"
else
  echo "⚠️ Output directory not yet visible (iCloud sync pending)"
fi

# ステップ 4: ログ確認
echo ""
echo "Step 4️⃣: Checking logs..."
LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log
if [ -f "$LOG_FILE" ]; then
  echo "✅ Log file updated"
  tail -3 "$LOG_FILE"
else
  echo "⚠️ Log file not found"
fi

echo ""
echo "=================================="
echo "✅ End-to-End test complete!"
echo "=================================="
```

## Cleanup Hook Test Data

Remove test files after testing:

```bash
#!/bin/bash
# テストデータのクリーンアップ

echo "Cleaning up hook test data..."

rm -f /tmp/hook-input-test.json
rm -f /tmp/test-transcript-*.json
rm -f /tmp/realistic-hook.json
rm -f /tmp/realistic-transcript-*.json
rm -f /tmp/error-test-hook.json
rm -f /tmp/empty-hook.json
rm -f /tmp/empty-transcript.json
rm -f /tmp/e2e-hook.json
rm -f /tmp/e2e-transcript-*.json

echo "✅ Cleanup complete"
```

## Hook Configuration Reference

Quick reference for hook setup:

**File**: `~/.claude/settings.local.json`

**Content**:
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

**How it works**:
1. Hook event "Stop" fires when Claude Code session ends
2. Passes JSON input via stdin
3. Script reads JSON from stdin (not as arguments)
4. **MUST exit with code 0** (non-blocking)
5. Writes markdown to Obsidian vault
6. Logs details to ~/.local/var/log/claude-history-to-obsidian.log

**Critical Rules**:
- ✅ Exit 0 always
- ✅ Read stdin for JSON
- ✅ Write errors to stderr
- ❌ Never block on I/O
- ❌ Never use non-zero exit codes
