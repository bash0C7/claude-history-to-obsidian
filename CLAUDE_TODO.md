# TODO & Known Issues

## ✅ 実装チェックリスト

### 完了項目
- [x] Repository 作成：`claude-history-to-obsidian`
- [x] .gitignore作成（Ruby、Claude Code、Mac設定、Gemfile.lock管理）
- [x] `Gemfile`, `.ruby-version` (3.4.7) 作成
- [x] bundle install（vendor配下に配置）
- [x] `lib/claude_history_to_obsidian.rb` 実装
- [x] `bin/claude-history-to-obsidian` 作成
- [x] Hook JSON stdin 読み込み
- [x] Transcript JSON パース
- [x] セッション名推測ロジック実装
- [x] Markdown 変換ロジック実装
- [x] Obsidian Vault ディレクトリ作成
- [x] ファイル名生成（日時 + セッション名 + ID）
- [x] ファイル書き込み（iCloud Drive）
- [x] エラーハンドリング（非ブロッキング exit）
- [x] ログ記録機能
- [x] 通知機能（オプション、terminal-notifier）
- [x] ローカルテスト実行・確認
- [x] README 作成
- [x] GitHub にプッシュ
- [x] Bulk import機能実装
- [x] テストカバレッジ計測の仕組み導入（SimpleCov）
- [x] ClaudeHistoryToObsidianクラスのユニットテスト追加（Phase 1-3）
- [x] ClaudeHistoryImporterクラスのテスト拡充
- [x] VAULT_BASE_PATH依存メソッドのテスト実装（ENV.fetch方式）

---

## ✅ 解決済み: VAULT_BASE_PATH依存メソッドのテスト改善

### 解決策：環境変数（ENV.fetch）方式

**実装内容**:
- `VAULT_BASE_PATH`と`LOG_FILE_PATH`を`ENV.fetch()`で初期化に変更
- テスト開始時に環境変数をセット（`/tmp/test-vault`）
- Phase 3テスト追加：`ensure_directories`, `save_to_vault`, `process_transcript`エンドツーエンド

**実装詳細**:

1. **lib/claude_history_to_obsidian.rb** (9-16行目)
   ```ruby
   VAULT_BASE_PATH = ENV.fetch(
     'CLAUDE_VAULT_PATH',
     File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code')
   )
   LOG_FILE_PATH = ENV.fetch(
     'CLAUDE_LOG_PATH',
     File.expand_path('~/.local/var/log/claude-history-to-obsidian.log')
   )
   ```

2. **test/test_claude_history_to_obsidian.rb** (9-11行目)
   ```ruby
   ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault'
   ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'
   ```

3. **test/test_helper.rb** (40-58行目)
   - `with_env`ヘルパーメソッド追加（ENV一時変更・自動復元）

**メリット**:
- ✅ Ruby-idiomatic（DI不要）
- ✅ stdlib onlyで外部依存なし
- ✅ プロダクトコード振る舞い不変（デフォルト値が同一）
- ✅ Hook/CLI環境で環境変数で設定可能
- ✅ テスト時は隔離環境で実行可能
- ✅ 実際のiCloud Drive汚染リスクなし

**テスト結果**:
- 合計18テスト（ClaudeHistoryToObsidian 15 + ClaudeHistoryImporter 12）
- 45アサーション
- 100%パス率
- カバレッジ: 14.6% (最初のPhase 3テストで増加予定)

**関連ファイル**:
- `lib/claude_history_to_obsidian.rb:9-16` - ENV.fetch化
- `test/test_helper.rb:40-58` - with_envヘルパー
- `test/test_claude_history_to_obsidian.rb:278-362` - Phase 3テスト

---

## ✅ 解決済み: CLAUDE.md & Skills リファクタリング（2025-11-05）

### 実施内容

公式ドキュメント（Progressive Disclosure）に準拠したドキュメント再構成：

**Context 削減**: 常時ロード 80KB → 20KB （75%削減）
- CLAUDE.md: 153行 → 80行（22%削減）
- specifications.md: 954行 → 487行（49%削減）
- practices.md: 725行 → 338行（53%削減）
- 合計ドキュメント: 2,734行 → 1,305行（52%削減）

**参照ドキュメント導入**:
- `.claude/references/` ディレクトリ作成
- `large-file-handling.md` - conversations.json処理（198行）
- `implementation-details.md` - JSON ネスティング詳細（80行）
- `README.md` - 参照インデックス

**Skill説明文強化**:
- 全6つのskillに絵文字追加（🧪🐛🪝📝⚙️💎）
- トリガーキーワード明確化
- "Use PROACTIVELY" 指針追加
- 自動トリガー率向上を支援

**重複排除**:
- Test-First Principle → @tdd skill統一
- Phase 0, Plan Revision → skill参照に変更
- Exit Code 0 → CLAUDE.md Critical Rules 統一

**効果**:
- ✅ Progressive Disclosure 採用（JIT ロード）
- ✅ Skill トリガー率向上（説明文強化）
- ✅ 重要情報の可視性向上
- ✅ 公式推奨ベストプラクティス準拠
- ✅ 全テスト GREEN（9/9、100%パス）

**関連ファイル**:
- CLAUDE.md - 簡潔な公開API
- .claude/development.md - セットアップ詳細
- .claude/specifications.md - Hook/JSON仕様
- .claude/practices.md - Worktree/Integration
- .claude/skills/* - Skill説明文強化

---

## 🚨 優先度高: タイムゾーン処理の修正

### 問題点

**現状の不具合**:
1. **`build_markdown` (165行目)**: `Time.now`を使用 → 取り込み時刻になっている（セッション開始時刻であるべき）
2. **`extract_session_timestamp` (300行目)**: `Time.parse`がタイムゾーン情報を考慮していない → UTCとローカルタイムが混在

**影響範囲**:
- Claude Code: Hook経由でのトランスクリプト保存
- Claude Web: エクスポートファイルからのBulk Import
- ファイル名のタイムスタンプ（YYYYMMDD-HHMMSS）
- Markdownヘッダーの**Date**フィールド

### 統一方針: 全てローカルタイムゾーンで統一

**理由**:
- Obsidianファイルは人間が読むもの → ローカルタイムが自然
- Claude Code/Web両方で一貫性を保つ
- ユーザーの作業時刻として認識しやすい

**処理フロー**:
```
入力データ → パース → localtime変換 → フォーマット → 出力
   ↓           ↓           ↓              ↓         ↓
ISO 8601   Time obj    localtime     YYYYMMDD    Markdown
(UTC)     (with TZ)    変換済み      -HHMMSS     ファイル
```

### 実装タスク

#### タスク1: ローカル調査（事前準備）✅ 完了

**目的**: Claude Code/Webの実際のタイムスタンプフォーマットを確認

**調査結果** (2025-11-06):

**1. Claude Code トランスクリプト形式**:
```json
{
  "session_id": "abc123456789...",
  "cwd": "~/src/project",
  "messages": [
    {
      "role": "user",
      "content": "User message text",
      "timestamp": "2025-11-03T14:30:22.000Z"
    },
    {
      "role": "assistant",
      "content": "Assistant response",
      "timestamp": "2025-11-03T14:30:25.000Z"
    }
  ]
}
```

**タイムスタンプ形式**: ISO 8601 UTC (Z サフィックス付き)

---

**2. Claude Web エクスポートファイル (conversations.json) 形式**:

**ファイル情報**:
- サイズ: 97MB
- 形式: 単一行JSON配列 `[{...}, {...}, ...]`
- ロケーション: `/Users/bash/src/claude-history-to-obsidian/conversations.json`

**Conversation オブジェクト**:
```json
{
  "uuid": "d20c59c1-c755-4926-a2f8-ed1dc4bd0a52",
  "name": "Session name",
  "summary": "...",
  "created_at": "2025-10-29T11:07:25.622604Z",
  "updated_at": "2025-10-29T11:07:27.223563Z",
  "account": { "uuid": "..." },
  "chat_messages": [...]
}
```

**Message オブジェクト (chat_messages 内)**:
```json
{
  "uuid": "24f64562-21a6-4513-b186-fce0b76b28ad",
  "text": "Message text content",
  "content": [
    {
      "type": "text",
      "text": "Actual text content",
      "start_timestamp": "2025-10-29T12:09:40.296328Z",
      "stop_timestamp": "2025-10-29T12:09:40.296328Z",
      "citations": []
    },
    {
      "type": "thinking",
      "thinking": "Thinking process",
      "summaries": [...]
    }
  ],
  "sender": "human",
  "created_at": "2025-10-29T12:09:40.310021Z",
  "attachments": [],
  "files": []
}
```

**タイムスタンプ形式**: ISO 8601 UTC (Z サフィックス付き)

---

**3. 主な違い (Claude Code vs Claude Web)**:

| 項目 | Claude Code | Claude Web |
|------|-------------|------------|
| role / sender | `role: "user"` | `sender: "human"` |
| role / sender | `role: "assistant"` | `sender: "assistant"` |
| Content 形式 | String または Array | **常に Array** |
| Timestamp フィールド | `timestamp` | `created_at` |
| UUID フィールド | `session_id` | `uuid` |
| ネスティング | メッセージは配列直下 | `chat_messages` フィールド内 |

---

**4. 既存実装の確認** (Rakefile:81-126):

**Web import Rakefile は既に完全実装済み** ✅

実装内容:
- ✅ UTF-8 エンコーディング処理 (invalid: :replace)
- ✅ JSON 単一行パース対応
- ✅ Conversation 配列イテレーション
- ✅ sender → role 変換 (human → user)
- ✅ content Array 形式処理
- ✅ `source: 'web'` パラメータ対応
- ✅ Vault ルーティング (`CLAUDE_WEB_VAULT_PATH`)
- ✅ yyyymm ディレクトリ構造対応

詳細は `.claude/references/claude-web-import-analysis.md` に記載

---

**5. タイムゾーン処理の現状**:

**問題箇所**:
- `lib/claude_history_to_obsidian.rb:300` - `extract_session_timestamp` に `.localtime` 不足
- `Rakefile:203` - `extract_first_message_timestamp` に `.localtime` 不足
- `lib/claude_history_to_obsidian.rb:165` - `build_markdown` が `Time.now` (取り込み時刻) を使用

**データフロー**:
```
入力: "2025-11-03T14:30:22.000Z" (UTC)
  ↓ Time.parse
Timeオブジェクト (UTC として認識)
  ↓ .localtime (修正が必要)
Timeオブジェクト (ローカルタイム変換済み)
  ↓ .strftime
出力: "20251103-233022" (JST なら +9時間)
```

---

**調査結果の記録場所**: `.claude/references/claude-web-import-analysis.md` に詳細記載

#### タスク2: `extract_session_timestamp`の修正

**ファイル**: `lib/claude_history_to_obsidian.rb:288-304`

**修正内容**:
```ruby
def extract_session_timestamp(transcript)
  # Bulk Import時: _first_message_timestamp フィールドをチェック
  return transcript['_first_message_timestamp'] if transcript['_first_message_timestamp']

  # Hook時: messages から最初のメッセージのタイムスタンプを抽出
  messages = transcript['messages']
  return nil unless messages && messages.length > 0

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  # ISO 8601形式のタイムスタンプをYYYYMMDD-HHMMSSに変換
  # 修正: .localtime を追加してローカルタイムゾーンに変換
  Time.parse(first_msg['timestamp']).localtime.strftime('%Y%m%d-%H%M%S')
rescue StandardError => e
  log("WARNING: Failed to extract session timestamp: #{e.message}")
  nil
end
```

**変更点**:
- `.localtime` を追加（300行目）
- UTCのタイムスタンプをローカルタイムゾーンに変換

**テスト追加**:
```ruby
# test/test_claude_history_to_obsidian.rb に追加

def test_extract_session_timestamp_converts_utc_to_local
  processor = ClaudeHistoryToObsidian.new

  # UTCタイムスタンプ (2025-11-03 14:30:22 UTC)
  transcript = {
    'messages' => [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'}
    ]
  }

  timestamp = processor.send(:extract_session_timestamp, transcript)

  # JST (UTC+9) の場合: 2025-11-03 23:30:22
  # 環境によって異なるため、Time.parseの結果と比較
  expected = Time.parse('2025-11-03T14:30:22.000Z').localtime.strftime('%Y%m%d-%H%M%S')
  assert_equal expected, timestamp
end
```

#### タスク3: 新規メソッド `extract_session_time` 追加

**ファイル**: `lib/claude_history_to_obsidian.rb` (private セクションに追加)

**実装内容**:
```ruby
# メッセージ配列から最初のメッセージのTimeオブジェクトを取得
# build_markdownで使用（Dateフィールド生成用）
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

**目的**:
- `build_markdown`でセッション開始時刻を取得するため
- Timeオブジェクトを返す（フォーマット前）
- 呼び出し側で`.localtime`してフォーマット

**テスト追加**:
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

#### タスク4: `build_markdown` の修正

**ファイル**: `lib/claude_history_to_obsidian.rb:164-212`

**修正内容**:
```ruby
def build_markdown(project_name:, cwd:, session_id:, messages:, source: 'code')
  # 修正: セッション開始時刻を使用（Time.now は使わない）
  session_time = extract_session_time(messages)
  timestamp = session_time ?
    session_time.localtime.strftime('%Y-%m-%d %H:%M:%S') :
    'Unknown'  # タイムスタンプ取得失敗時

  session_type = source == 'web' ? 'Claude Web Session' : 'Claude Code Session'

  output = []
  output << "# #{session_type}"
  output << ""
  output << "**Project**: #{project_name}"
  output << "**Path**: #{cwd}"
  output << "**Session ID**: #{session_id}"
  output << "**Date**: #{timestamp}"
  # ... 以下同じ
end
```

**変更点**:
- `Time.now` を削除 (165行目)
- `extract_session_time(messages)` を呼び出し
- `.localtime.strftime()` でローカルタイムゾーンに変換
- タイムスタンプ取得失敗時は `'Unknown'`

**テスト追加**:
```ruby
def test_build_markdown_uses_session_timestamp_not_current_time
  processor = ClaudeHistoryToObsidian.new

  # 過去のタイムスタンプ
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

  # セッション開始時刻が使用されている（現在時刻ではない）
  expected_date = Time.parse('2025-10-01T10:00:00.000Z').localtime.strftime('%Y-%m-%d %H:%M:%S')
  assert_include markdown, "**Date**: #{expected_date}"

  # 現在時刻は含まれていない
  current_date = Time.now.strftime('%Y-%m-%d')
  assert_not_include markdown, "**Date**: #{current_date}" unless current_date == '2025-10-01'
end

def test_build_markdown_handles_missing_timestamp
  processor = ClaudeHistoryToObsidian.new

  # タイムスタンプなしのメッセージ
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

  # タイムスタンプ取得失敗時は 'Unknown'
  assert_include markdown, '**Date**: Unknown'
end
```

#### タスク5: エンドツーエンドテスト

**目的**: Hook mode と Bulk Import mode の両方で、タイムゾーン処理が正しく動作することを確認

**テスト追加**:
```ruby
def test_timezone_handling_hook_mode_with_utc_timestamp
  processor = ClaudeHistoryToObsidian.new

  Dir.mktmpdir do |test_dir|
    # UTCタイムスタンプのトランスクリプトファイルを作成
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

    # Hook JSON
    hook_input = {
      'session_id' => 'tz-test-001',
      'transcript_path' => transcript_path,
      'cwd' => '~/src/test-tz',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop'
    }

    # 実行
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

    # ファイル名のタイムスタンプがローカルタイムに変換されている
    filename = File.basename(files[0])
    expected_local_time = Time.parse('2025-11-03T05:00:00.000Z').localtime.strftime('%Y%m%d-%H%M%S')
    assert filename.start_with?(expected_local_time), "Filename should start with local time: #{filename}"

    # ファイル内のDateフィールドも確認
    content = File.read(files[0])
    expected_date_str = Time.parse('2025-11-03T05:00:00.000Z').localtime.strftime('%Y-%m-%d %H:%M:%S')
    assert_include content, "**Date**: #{expected_date_str}"

    # クリーンアップ
    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
  end
end
```

#### タスク6: ドキュメント更新 ✅ 完了

**実施内容** (2025-11-06):

**1. CLAUDE_TODO.md - タスク1 調査結果追記** ✅
- Claude Code トランスクリプト形式の詳細記載
- Claude Web conversations.json 形式の詳細記載
- 主な違いを比較表で記載
- 既存 Rakefile 実装の確認 ✅

**2. 新規参考ドキュメント作成** ✅

**`.claude/references/claude-web-import-analysis.md`** (2025-11-06)
- ✅ データ構造比較（Claude Code vs Web）
- ✅ conversations.json の詳細スキーマ
- ✅ Content Array 処理の詳細
- ✅ フォーマット変換マッピング
- ✅ Rakefile 実装の詳細コード
- ✅ Vault ディレクトリ構造
- ✅ 実装状況チェックリスト

**`.claude/references/timezone-fix-specification.md`** (2025-11-06)
- ✅ 問題の概要と具体例
- ✅ 修正対象メソッド4つの詳細仕様
- ✅ テスト実装の詳細コード
- ✅ エンドツーエンドテスト仕様
- ✅ データ変換の具体例（JST/UTC）
- ✅ 成功条件チェックリスト

**3. `.claude/specifications.md` 更新予定** ⏳
**ファイル**: `.claude/specifications.md`

**追記箇所**: 「Transcript JSON Input Format」セクション

**追記内容**:
```markdown
### タイムスタンプとタイムゾーン処理

**入力フォーマット**:
- ISO 8601形式を想定: `2025-11-03T14:30:22.000Z`
- `Z`サフィックス: UTC時刻
- `+09:00`などのオフセット: タイムゾーン付き

**処理方針**:
- 全てのタイムスタンプを**ローカルタイムゾーン**に変換
- ファイル名: `YYYYMMDD-HHMMSS` (ローカルタイム)
- Markdown **Date**フィールド: `YYYY-MM-DD HH:MM:SS` (ローカルタイム)

**実装**:
```ruby
Time.parse(timestamp_string).localtime.strftime('%Y%m%d-%H%M%S')
```

**理由**:
- ユーザーの作業時刻として認識しやすい
- Claude Code/Web両方で一貫性を保つ
- Obsidianで閲覧時に直感的

**参考ドキュメント**:
- `.claude/references/timezone-fix-specification.md` - 修正の詳細仕様
```

**計画**: Claude Code on Web で実装後に追記予定

#### タスク7: テスト実行とカバレッジ確認

```bash
# 全テスト実行
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb

# カバレッジ確認
# テスト実行後、coverage/ ディレクトリを確認
open coverage/index.html  # macOS
```

**確認項目**:
- [ ] 全テストがパス (GREEN)
- [ ] 新規追加したタイムゾーン関連テストがパス
- [ ] カバレッジが維持または向上
- [ ] extract_session_timestamp, extract_session_time, build_markdownのカバレッジが100%

### 完了条件

- [ ] タスク1: ローカル調査完了、結果をドキュメント化
- [ ] タスク2: `extract_session_timestamp` 修正、テスト追加
- [ ] タスク3: `extract_session_time` 実装、テスト追加
- [ ] タスク4: `build_markdown` 修正、テスト追加
- [ ] タスク5: エンドツーエンドテスト追加
- [ ] タスク6: ドキュメント更新
- [ ] タスク7: 全テストパス、カバレッジ確認
- [ ] Git commit & push

---

## 📝 その他のTODO

（将来的な改善項目をここに追加）
