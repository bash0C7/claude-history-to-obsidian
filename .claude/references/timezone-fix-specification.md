# タイムゾーン処理修正 仕様書

**作成日**: 2025-11-06
**優先度**: 🚨 **高**
**実装計画**: CLAUDE_TODO.md タスク2-7 参照

---

## 📋 問題の概要

### 現象

**ファイル名のタイムスタンプが UTC のままになっている**

例（JST環境の場合）:
```
入力: 2025-11-03T14:30:22.000Z (UTC)
出力: 20251103-143022 ❌ (UTC のまま、9時間ズレている)
期待: 20251103-233022 ✅ (JST = UTC+9時間)
```

**Markdown Date フィールドが取り込み時刻になっている**

例:
```
セッション開始: 2025-11-03 14:30:22 (セッション開始時刻)
ファイル作成: 2025-11-06 10:00:00 (取り込み実行時刻)

現在: **Date**: 2025-11-06 10:00:00 ❌ (取り込み時刻)
期待: **Date**: 2025-11-03 23:30:22 ✅ (セッション開始時刻)
```

### 影響範囲

| 影響項目 | 現在 | 期待 |
|---|---|---|
| ファイル名 | 20251103-143022 (UTC) | 20251103-233022 (JST) |
| Markdown Date | 2025-11-06 10:00:00 | 2025-11-03 23:30:22 |
| Bulk Import | UTC タイムスタンプ | ローカルタイムスタンプ |
| Hook mode | UTC タイムスタンプ | ローカルタイムスタンプ |

### 根本原因

1. **`Time.parse()` の動作**:
   ```ruby
   ts = "2025-11-03T14:30:22.000Z"
   time_obj = Time.parse(ts)
   # => 2025-11-03 14:30:22 UTC として認識
   ```
   Z サフィックスがあるので UTC として正しく認識している

2. **`.localtime` が不足**:
   ```ruby
   # 現在の実装 ❌
   time_obj.strftime('%Y%m%d-%H%M%S')
   # => "20251103-143022" (UTC のまま出力)

   # 修正後 ✅
   time_obj.localtime.strftime('%Y%m%d-%H%M%S')
   # => "20251103-233022" (ローカルタイムに変換して出力)
   ```

3. **`Time.now` の誤用**:
   ```ruby
   # 現在の実装 ❌ build_markdown:165
   timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
   # => 現在時刻 (スクリプト実行時刻)

   # 修正後 ✅
   session_time = extract_session_time(messages)
   timestamp = session_time.localtime.strftime('%Y-%m-%d %H:%M:%S')
   # => セッション開始時刻 (ローカルタイム)
   ```

---

## 🔧 修正対象メソッド

### 1️⃣ `extract_session_timestamp` (lib/claude_history_to_obsidian.rb:288-304)

**現在の実装**:
```ruby
def extract_session_timestamp(transcript)
  return transcript['_first_message_timestamp'] if transcript['_first_message_timestamp']

  messages = transcript['messages']
  return nil unless messages && messages.length > 0

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp']).strftime('%Y%m%d-%H%M%S')  # ❌ .localtime なし
rescue StandardError => e
  log("WARNING: Failed to extract session timestamp: #{e.message}")
  nil
end
```

**修正内容**:
```ruby
def extract_session_timestamp(transcript)
  return transcript['_first_message_timestamp'] if transcript['_first_message_timestamp']

  messages = transcript['messages']
  return nil unless messages && messages.length > 0

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp']).localtime.strftime('%Y%m%d-%H%M%S')  # ✅ .localtime 追加
rescue StandardError => e
  log("WARNING: Failed to extract session timestamp: #{e.message}")
  nil
end
```

**変更点**: 行300に `.localtime` を追加

**用途**: ファイル名のタイムスタンプ生成

**テスト**:
```ruby
def test_extract_session_timestamp_converts_utc_to_local
  processor = ClaudeHistoryToObsidian.new

  transcript = {
    'messages' => [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'}
    ]
  }

  timestamp = processor.send(:extract_session_timestamp, transcript)
  expected = Time.parse('2025-11-03T14:30:22.000Z').localtime.strftime('%Y%m%d-%H%M%S')
  assert_equal expected, timestamp
end
```

---

### 2️⃣ `extract_first_message_timestamp` (Rakefile:197-207)

**現在の実装**:
```ruby
def extract_first_message_timestamp(messages)
  return nil unless messages && messages.length.positive?

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp']).strftime('%Y%m%d-%H%M%S')  # ❌ .localtime なし
rescue StandardError => e
  warn "WARNING: Failed to extract timestamp: #{e.message}"
  nil
end
```

**修正内容**:
```ruby
def extract_first_message_timestamp(messages)
  return nil unless messages && messages.length.positive?

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp']).localtime.strftime('%Y%m%d-%H%M%S')  # ✅ .localtime 追加
rescue StandardError => e
  warn "WARNING: Failed to extract timestamp: #{e.message}"
  nil
end
```

**変更点**: 行203に `.localtime` を追加

**用途**: Bulk Import / Web import 時のファイル名タイムスタンプ生成

---

### 3️⃣ `extract_session_time` (新規メソッド - lib/claude_history_to_obsidian.rb private セクション)

**実装内容**:
```ruby
# メッセージ配列から最初のメッセージの Timeオブジェクトを抽出
# build_markdown で使用（Dateフィールド生成用）
# 呼び出し側で .localtime してフォーマット
def extract_session_time(messages)
  return nil unless messages && messages.length > 0

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp'])  # Timeオブジェクトを返す
rescue StandardError => e
  log("WARNING: Failed to parse session time: #{e.message}")
  nil
end
```

**責務**:
- メッセージ配列から最初のメッセージを取得
- タイムスタンプを Time オブジェクトに変換して返す
- フォーマットは行わない（呼び出し側で処理）

**テスト**:
```ruby
def test_extract_session_time_returns_time_object
  processor = ClaudeHistoryToObsidian.new

  messages = [
    {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'}
  ]

  time_obj = processor.send(:extract_session_time, messages)

  assert_instance_of Time, time_obj
  assert_equal Time.parse('2025-11-03T14:30:22.000Z'), time_obj
end

def test_extract_session_time_returns_nil_for_invalid_timestamp
  processor = ClaudeHistoryToObsidian.new

  messages = [
    {'role' => 'user', 'content' => 'Test', 'timestamp' => 'invalid-format'}
  ]

  time_obj = processor.send(:extract_session_time, messages)
  assert_nil time_obj
end
```

---

### 4️⃣ `build_markdown` (lib/claude_history_to_obsidian.rb:164-244)

**現在の実装** (164-174行目):
```ruby
def build_markdown(project_name:, cwd:, session_id:, messages:, source: 'code')
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')  # ❌ 取り込み時刻を使用
  session_type = source == 'web' ? 'Claude Web Session' : 'Claude Code Session'

  output = []
  output << "# #{session_type}"
  output << ""
  output << "**Project**: #{project_name}"
  output << "**Path**: #{cwd}"
  output << "**Session ID**: #{session_id}"
  output << "**Date**: #{timestamp}"
  # ... 以下省略
end
```

**修正内容** (164-174行目):
```ruby
def build_markdown(project_name:, cwd:, session_id:, messages:, source: 'code')
  # ✅ セッション開始時刻を使用（Time.now は削除）
  session_time = extract_session_time(messages)
  timestamp = session_time ?
    session_time.localtime.strftime('%Y-%m-%d %H:%M:%S') :
    'Unknown'

  session_type = source == 'web' ? 'Claude Web Session' : 'Claude Code Session'

  output = []
  output << "# #{session_type}"
  output << ""
  output << "**Project**: #{project_name}"
  output << "**Path**: #{cwd}"
  output << "**Session ID**: #{session_id}"
  output << "**Date**: #{timestamp}"
  # ... 以下省略
end
```

**変更点**:
- 行165: `Time.now` 削除
- 行165-167: `extract_session_time` を呼び出し
- 行166: `.localtime.strftime()` でローカルタイム変換
- 行167: 取得失敗時は `'Unknown'`

**テスト**:
```ruby
def test_build_markdown_uses_session_timestamp_not_current_time
  processor = ClaudeHistoryToObsidian.new

  messages = [
    {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-10-01T10:00:00.000Z'},
    {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-10-01T10:00:05.000Z'}
  ]

  markdown = processor.send(:build_markdown,
    project_name: 'test-project',
    cwd: '/test/path',
    session_id: 'test123',
    messages: messages
  )

  expected_date = Time.parse('2025-10-01T10:00:00.000Z').localtime.strftime('%Y-%m-%d %H:%M:%S')
  assert_include markdown, "**Date**: #{expected_date}"
end

def test_build_markdown_handles_missing_timestamp
  processor = ClaudeHistoryToObsidian.new

  messages = [
    {'role' => 'user', 'content' => 'Test'},
    {'role' => 'assistant', 'content' => 'Response'}
  ]

  markdown = processor.send(:build_markdown,
    project_name: 'test-project',
    cwd: '/test/path',
    session_id: 'test123',
    messages: messages
  )

  assert_include markdown, '**Date**: Unknown'
end
```

---

## 📋 エンドツーエンドテスト

### テスト目的

Hook mode と Bulk Import mode の両方で、タイムゾーン処理が正しく動作することを検証

### テスト実装

```ruby
def test_timezone_handling_hook_mode_with_utc_timestamp
  processor = ClaudeHistoryToObsidian.new

  Dir.mktmpdir do |test_dir|
    # UTCタイムスタンプのトランスクリプトを作成
    transcript_path = File.join(test_dir, 'transcript.json')
    transcript_data = {
      'session_id' => 'tz-test-001',
      'cwd' => '~/src/test-tz',
      'messages' => [
        {'role' => 'user', 'content' => 'Testing timezone', 'timestamp' => '2025-11-03T05:00:00.000Z'},
        {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T05:00:05.000Z'}
      ]
    }
    File.write(transcript_path, JSON.generate(transcript_data))

    # Hook JSON を作成
    hook_input = {
      'session_id' => 'tz-test-001',
      'transcript_path' => transcript_path,
      'cwd' => '~/src/test-tz',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop'
    }

    # スクリプト実行
    with_stdin(JSON.generate(hook_input)) do
      begin
        processor.run
      rescue SystemExit => e
        assert_equal 0, e.status
      end
    end

    # ファイル確認
    vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
    project_dir = File.join(vault_base, 'test-tz')
    files = Dir.glob(File.join(project_dir, '*.md'))

    assert files.length > 0, 'File should be created'

    # ファイル名がローカルタイムスタンプで始まっていることを確認
    filename = File.basename(files[0])
    expected_local_time = Time.parse('2025-11-03T05:00:00.000Z').localtime.strftime('%Y%m%d-%H%M%S')
    assert filename.start_with?(expected_local_time), "Filename should start with local time: #{filename}"

    # ファイル内の Date フィールドもローカルタイムであることを確認
    content = File.read(files[0])
    expected_date_str = Time.parse('2025-11-03T05:00:00.000Z').localtime.strftime('%Y-%m-%d %H:%M:%S')
    assert_include content, "**Date**: #{expected_date_str}"

    # クリーンアップ
    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
  end
end
```

### テスト検証項目

- [ ] ファイルが作成される
- [ ] ファイル名がローカルタイムスタンプで始まる
- [ ] Markdown の **Date** フィールドがローカルタイム
- [ ] セッション開始時刻（UTC） = ファイル内 Date（ローカルタイム）の対応が正しい

---

## 📊 データ変換の具体例

### ケース: JST環境 (UTC+9)

**入力**:
```json
{
  "timestamp": "2025-11-03T14:30:22.000Z"
}
```

**処理**:
```ruby
ts_str = "2025-11-03T14:30:22.000Z"
time_obj = Time.parse(ts_str)           # 2025-11-03 14:30:22 UTC
local_time = time_obj.localtime          # 2025-11-03 23:30:22 JST (UTC+9)
filename = local_time.strftime(...)      # "20251103-233022"
date_field = local_time.strftime(...)    # "2025-11-03 23:30:22"
```

**出力**:
```
ファイル名: 20251103-233022_session-name_abc12345.md
Date フィールド: 2025-11-03 23:30:22 (JST)
```

### ケース: UTC環境 (UTC+0)

**入力**: 同じ

**処理**: 同じ

**出力**:
```
ファイル名: 20251103-143022_session-name_abc12345.md
Date フィールド: 2025-11-03 14:30:22 (UTC)
```

→ **環境に応じて自動変換される** ✅

---

## 🎯 成功条件

### テストレベル

- [ ] `test_extract_session_timestamp_converts_utc_to_local` - PASS
- [ ] `test_extract_session_time_returns_time_object` - PASS
- [ ] `test_extract_session_time_returns_nil_for_invalid_timestamp` - PASS
- [ ] `test_build_markdown_uses_session_timestamp_not_current_time` - PASS
- [ ] `test_build_markdown_handles_missing_timestamp` - PASS
- [ ] `test_timezone_handling_hook_mode_with_utc_timestamp` - PASS

### 全体テスト

- [ ] `bundle exec ruby -I lib:test -rtest/unit test/**/*.rb` - 全テスト GREEN
- [ ] カバレッジ 90%以上
- [ ] `extract_session_timestamp`, `extract_session_time`, `build_markdown` のカバレッジ 100%

---

## 🔗 参考

- **CLAUDE_TODO.md**: 完全な実装チェックリスト
- **claude-web-import-analysis.md**: Web import 構造分析
- **specifications.md**: Hook/JSON 仕様
- **development.md**: 開発環境セットアップ
