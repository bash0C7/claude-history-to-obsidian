---
name: ruby-testing
description: "🧪 Test the Ruby script with sample Hook JSON, verify markdown output, check transcript conversion. Use when you want to 'test the script', 'verify output', 'check if it works', 'run tests', or 'simulate hook execution'. Use PROACTIVELY before commits."
---

# Ruby Testing Skill

Comprehensive testing for the claude-history-to-obsidian Ruby CLI application. Creates test data, executes the script, and validates output.

## Skill Role & Use Cases

**Use this skill for**:
- Unit testing Ruby code with test data
- Verifying script output locally with sample JSON
- Testing edge cases and error handling
- Validating markdown formatting
- Quick feedback during development

**Do NOT use for**:
- End-to-end hook integration testing (use hook-integration skill instead)
- Full hook workflow simulation
- Obsidian vault output verification

## Quick Test

Create test data and run the application:

```bash
# テスト用 Hook JSON を作成（stdin入力シミュレート）
cat > /tmp/hook-input.json <<'EOF'
{
  "session_id": "test123456789abc",
  "transcript_path": "/tmp/test-transcript.json",
  "cwd": "~/src/test-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

# テスト用 Transcript JSON を作成
cat > /tmp/test-transcript.json <<'EOF'
{
  "session_id": "test123456789abc",
  "cwd": "~/src/test-project",
  "messages": [
    {"role": "user", "content": "Implementing the feature for button handling"},
    {"role": "assistant", "content": "I'll help you implement the button handling feature. Here's what we need to do:\n\n```ruby\nclass ButtonHandler\n  def initialize\n    @state = :idle\n  end\nend\n```"},
    {"role": "user", "content": "Great! Now add the click event handler"},
    {"role": "assistant", "content": "Perfect! Here's the click handler implementation..."}
  ]
}
EOF

# スクリプト実行テスト
cd ~/src/claude-history-to-obsidian
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

## Verify Output

Check that the markdown file was created correctly:

```bash
# Obsidian Vault の出力確認
VAULT_PATH=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code/test-project

# ファイルが存在するか確認
ls -la "$VAULT_PATH/" 2>/dev/null || echo "Vault directory not found"

# 最新のファイルを表示
LATEST=$(ls -t "$VAULT_PATH"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  echo "=== Generated Markdown ==="
  cat "$LATEST"
else
  echo "No markdown files found"
fi
```

## Check Logs

Review the application logs for debugging:

```bash
# ログファイル表示
LOG_FILE=~/.local/var/log/claude-history-to-obsidian.log
if [ -f "$LOG_FILE" ]; then
  echo "=== Recent Logs ==="
  tail -20 "$LOG_FILE"
else
  echo "Log file not found: $LOG_FILE"
fi
```

## Test Edge Cases

### Test with minimal message:
```bash
cat > /tmp/minimal-transcript.json <<'EOF'
{
  "session_id": "minimal789",
  "cwd": "~/src/minimal",
  "messages": [
    {"role": "user", "content": "Help"},
    {"role": "assistant", "content": "Sure!"}
  ]
}
EOF

cat > /tmp/minimal-hook.json <<'EOF'
{
  "session_id": "minimal789",
  "transcript_path": "/tmp/minimal-transcript.json",
  "cwd": "~/src/minimal",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat /tmp/minimal-hook.json | bundle exec ruby bin/claude-history-to-obsidian
```

### Test with long session name (30+ chars):
```bash
cat > /tmp/long-name-transcript.json <<'EOF'
{
  "session_id": "longname456",
  "cwd": "~/src/very-long-project-name",
  "messages": [
    {"role": "user", "content": "Implementing comprehensive error handling with retry logic and exponential backoff strategies"},
    {"role": "assistant", "content": "I'll help implement this..."}
  ]
}
EOF

cat > /tmp/long-name-hook.json <<'EOF'
{
  "session_id": "longname456",
  "transcript_path": "/tmp/long-name-transcript.json",
  "cwd": "~/src/very-long-project-name",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat /tmp/long-name-hook.json | bundle exec ruby bin/claude-history-to-obsidian
```

### Test with special characters in session name:
```bash
cat > /tmp/special-transcript.json <<'EOF'
{
  "session_id": "special123",
  "cwd": "~/src/special-project",
  "messages": [
    {"role": "user", "content": "Fix: bug@#$% in the API—shouldn't break!"},
    {"role": "assistant", "content": "Got it!"}
  ]
}
EOF

cat > /tmp/special-hook.json <<'EOF'
{
  "session_id": "special123",
  "transcript_path": "/tmp/special-transcript.json",
  "cwd": "~/src/special-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

cat /tmp/special-hook.json | bundle exec ruby bin/claude-history-to-obsidian
```

## Validate File Format

Check the generated markdown file structure:

```bash
# ファイル命名形式の確認
# 期待形式: YYYYMMDD-HHMMSS_session-name_sessionid.md
VAULT_PATH=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code

find "$VAULT_PATH" -name "*.md" -type f 2>/dev/null | while read -r file; do
  echo "File: $(basename "$file")"
  echo "Size: $(stat -f%z "$file" 2>/dev/null) bytes"
  echo "Modified: $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$file" 2>/dev/null)"
  echo "---"
done
```

## Test Markdown Formatting

Verify that markdown content is properly formatted:

```bash
# Markdown フォーマット検証
VAULT_PATH=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code

LATEST=$(find "$VAULT_PATH" -name "*.md" -type f -exec stat -f%Sm -t '%s' {} + 2>/dev/null | sort -k1 -n | tail -1 | awk '{print $2}')

if [ -f "$LATEST" ]; then
  echo "=== Checking Markdown Structure ==="
  echo "Has title (# Claude Code Session): $(grep -c '^# Claude Code Session' "$LATEST")"
  echo "Has User sections: $(grep -c '^## 👤 User' "$LATEST")"
  echo "Has Claude sections: $(grep -c '^## 🤖 Claude' "$LATEST")"
  echo "Has separators (---): $(grep -c '^---$' "$LATEST")"
  echo ""
  echo "=== First 50 lines ==="
  head -50 "$LATEST"
else
  echo "No markdown file found"
fi
```

## Debug Mode Testing

Run with additional debugging to see internal state:

```bash
# デバッグ用環境変数を設定してスクリプト実行
# (lib/claude_history_to_obsidian.rb で DEBUG 対応している場合)
cd ~/src/claude-history-to-obsidian
DEBUG=1 cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

## Test Mode (CLAUDE_VAULT_MODE=test)

When developing or testing, use test mode to isolate output files with `[test]` suffix:

```bash
# Test mode: Files saved to Claude Code [test]/{project}/
export CLAUDE_VAULT_PATH=/tmp/test-vault
export CLAUDE_VAULT_MODE=test
cd ~/src/claude-history-to-obsidian

cat > /tmp/test-mode-transcript.json <<'EOF'
{
  "session_id": "testmode123",
  "cwd": "~/src/test-project",
  "messages": [
    {"role": "user", "content": "Testing in test mode"},
    {"role": "assistant", "content": "This will be saved to a test vault location"}
  ]
}
EOF

cat > /tmp/test-mode-hook.json <<'EOF'
{
  "session_id": "testmode123",
  "transcript_path": "/tmp/test-mode-transcript.json",
  "cwd": "~/src/test-project",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

# Run with test isolation
cat /tmp/test-mode-hook.json | bundle exec ruby bin/claude-history-to-obsidian

# Verify files are in test vault
ls -la /tmp/test-vault/Claude\ Code\ \[test\]/test-project/
```

### Multiple Test Vaults

Use different vault paths for different test scenarios:

```bash
# Test vault 1: Feature A testing
export CLAUDE_VAULT_PATH=/tmp/test-vault-feature-a
export CLAUDE_VAULT_MODE=test
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian

# Test vault 2: Feature B testing
export CLAUDE_VAULT_PATH=/tmp/test-vault-feature-b
export CLAUDE_VAULT_MODE=test
cat /tmp/different-hook.json | bundle exec ruby bin/claude-history-to-obsidian

# Compare results without affecting production vault
ls -la /tmp/test-vault-feature-a/Claude\ Code\ \[test\]/*/
ls -la /tmp/test-vault-feature-b/Claude\ Code\ \[test\]/*/
```

## Integration Test

Full end-to-end test simulating the hook scenario:

```bash
#!/bin/bash
# 完全なテストフロー

set -e

PROJ_DIR="~/src/claude-history-to-obsidian"
TEST_SESSION_ID="integration-$(date +%s)"

echo "📋 Setting up test data..."

# テスト用 Transcript を作成
cat > /tmp/integration-transcript.json <<EOF
{
  "session_id": "$TEST_SESSION_ID",
  "cwd": "~/src/integration-test",
  "messages": [
    {"role": "user", "content": "Integration test for session management"},
    {"role": "assistant", "content": "Testing the full workflow..."},
    {"role": "user", "content": "Verify all output files"},
    {"role": "assistant", "content": "All checks passed!"}
  ]
}
EOF

# テスト用 Hook JSON を作成
cat > /tmp/integration-hook.json <<EOF
{
  "session_id": "$TEST_SESSION_ID",
  "transcript_path": "/tmp/integration-transcript.json",
  "cwd": "~/src/integration-test",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF

echo "🚀 Running application..."
cd "$PROJ_DIR"
cat /tmp/integration-hook.json | bundle exec ruby bin/claude-history-to-obsidian

echo "✅ Test completed"
echo "Check ~/.local/var/log/claude-history-to-obsidian.log for details"
```

## Cleanup Test Files

Remove test data when finished:

```bash
# テストファイルのクリーンアップ
rm -f /tmp/hook-input.json
rm -f /tmp/test-transcript.json
rm -f /tmp/minimal-*.json
rm -f /tmp/long-name-*.json
rm -f /tmp/special-*.json
rm -f /tmp/integration-*.json

echo "Test files cleaned up"
```
