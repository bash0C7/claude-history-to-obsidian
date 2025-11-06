# Claude Web Import 構造分析

**作成日**: 2025-11-06
**調査対象**: conversations.json (97MB, 単一行JSON配列)
**既存実装**: Rakefile:81-126 (完全実装済み)

---

## 📊 データ構造比較

### Claude Code トランスクリプト形式

**ソース**: `~/.claude/sessions/session-YYYYMMDD-HHMMSS.json`

```json
{
  "session_id": "abc123456789def0123456789def012",
  "cwd": "~/src/claude-history-to-obsidian",
  "messages": [
    {
      "role": "user",
      "content": "User message text here",
      "timestamp": "2025-11-03T14:30:22.000Z"
    },
    {
      "role": "assistant",
      "content": "Assistant response here",
      "timestamp": "2025-11-03T14:30:25.000Z"
    }
  ]
}
```

**フィールド定義**:
- `session_id` (string): セッション識別子
- `cwd` (string): 作業ディレクトリ
- `messages` (array): メッセージ配列
  - `role` (string): "user" または "assistant"
  - `content` (string | array): メッセージ内容（string または content arrayの場合あり）
  - `timestamp` (string): ISO 8601 UTC形式 (Z サフィックス)

---

### Claude Web エクスポート形式 (conversations.json)

**ソース**: Claude Web UI からのエクスポート (`~/Downloads/conversations.json`)

**ファイル情報**:
- **サイズ**: 97MB
- **形式**: 単一行 JSON 配列
- **エンコーディング**: UTF-8 (無効バイト含まれる可能性あり → `invalid: :replace` で処理)

#### Conversation オブジェクト

```json
{
  "uuid": "d20c59c1-c755-4926-a2f8-ed1dc4bd0a52",
  "name": "Unclear situation explanation",
  "summary": "A brief summary of the conversation",
  "created_at": "2025-10-29T11:07:25.622604Z",
  "updated_at": "2025-10-29T11:07:27.223563Z",
  "account": {
    "uuid": "a1b2c3d4-e5f6-47a8-b9c0-d1e2f3a4b5c6"
  },
  "chat_messages": [
    { /* Message Object */ },
    { /* Message Object */ }
  ]
}
```

**フィールド定義**:
- `uuid` (string): 会話の一意識別子
- `name` (string): 会話のタイトル/セッション名
- `summary` (string): 会話のサマリー
- `created_at` (string): 会話作成時刻 (ISO 8601 UTC)
- `updated_at` (string): 最終更新時刻 (ISO 8601 UTC)
- `account` (object): アカウント情報
  - `uuid` (string): アカウントID
- `chat_messages` (array): メッセージ配列

#### Message オブジェクト (chat_messages 内)

```json
{
  "uuid": "24f64562-21a6-4513-b186-fce0b76b28ad",
  "text": "これ翻訳してください。\n# Fix...",
  "content": [
    {
      "type": "text",
      "text": "実際のテキスト内容",
      "start_timestamp": "2025-10-29T12:09:40.296328Z",
      "stop_timestamp": "2025-10-29T12:09:40.296328Z",
      "citations": []
    },
    {
      "type": "thinking",
      "thinking": "思考プロセスの内容",
      "summaries": [
        {
          "summary": "Thinking summary",
          "reasoning": "Reasoning steps"
        }
      ]
    }
  ],
  "sender": "human",
  "created_at": "2025-10-29T12:09:40.310021Z",
  "attachments": [],
  "files": []
}
```

**フィールド定義**:
- `uuid` (string): メッセージの一意識別子
- `text` (string): メッセージの全テキスト（複数content要素を結合したもの）
- `content` (array): **コンテンツ要素配列** ← 常に配列形式（Claude Codeと異なる）
  - `type` (string): "text" または "thinking" など
  - `text` (string): テキストコンテンツ
  - `thinking` (string): 思考プロセス
  - `start_timestamp`, `stop_timestamp` (string): ISO 8601 UTC
  - `citations` (array): 引用情報
  - `summaries` (array): サマリー情報
- `sender` (string): "human" または "assistant" ← Claude Code の "role" に対応
- `created_at` (string): メッセージ作成時刻 (ISO 8601 UTC)
- `attachments` (array): 添付ファイル
- `files` (array): ファイル情報

---

## 🔄 フォーマット変換マッピング

### Claude Web → Claude Code (Rakefile での変換)

| Claude Web | Claude Code | 変換方法 |
|---|---|---|
| conversation.uuid | session_id | そのまま使用 |
| conversation.name | (session name) | first user message から抽出 |
| chat_message.sender | message.role | "human" → "user", "assistant" → "assistant" |
| chat_message.content | message.content | array のまま使用（処理済み） |
| chat_message.created_at | message.timestamp | そのまま使用 |
| conversation.created_at | (file timestamp) | ファイル名生成に使用 |

### Rakefile での実装 (81-126行目)

```ruby
namespace :web do
  desc 'Bulk import Claude Web Export conversations.json'
  task :bulk_import do
    conversations_json = File.join(
      File.expand_path('~/Downloads'),
      'conversations.json'
    )

    # 1️⃣ UTF-8 エンコーディング処理
    file_content = File.read(conversations_json, encoding: 'UTF-8')
    file_content = file_content.encode('UTF-8', invalid: :replace)

    # 2️⃣ JSON パース（単一行の巨大ファイル対応）
    conversations = JSON.parse(file_content)

    # 3️⃣ 各会話をイテレート
    conversations.each_with_index do |conversation, index|
      process_web_conversation(conversation)
      puts "Imported #{index + 1} conversations..." if (index + 1) % 10 == 0
    end
  end
end

def process_web_conversation(conversation)
  # 会話ID と メッセージ配列
  session_id = conversation['uuid']
  chat_messages = conversation['chat_messages'] || []
  conversation_name = conversation['name']

  # メッセージを Claude Code フォーマットに変換
  messages = chat_messages.map do |msg|
    {
      'role' => msg['sender'] == 'human' ? 'user' : msg['sender'],
      'content' => msg['content'],  # Array format は維持
      'timestamp' => msg['created_at']
    }
  end

  # ClaudeHistoryToObsidian に処理を委譲
  processor = ClaudeHistoryToObsidian.new
  processor.process_transcript(
    project_name: slugify_name(conversation_name),
    session_id: session_id,
    messages: messages,
    source: 'web'  # ← Web vault に保存
  )
end

def slugify_name(name)
  name
    .downcase
    .gsub(/[^a-z0-9]+/, '-')
    .sub(/^-+/, '')
    .sub(/-+$/, '')
end
```

---

## 🔍 Content Array 処理の詳細

### Claude Code での Content 形式

**String 形式** (従来):
```ruby
message['content'] = "This is plain text content"
```

**Array 形式** (複数要素):
```ruby
message['content'] = [
  {
    "type": "text",
    "text": "Text content here"
  },
  {
    "type": "thinking",
    "thinking": "Thinking process"
  }
]
```

### Claude Web での Content 形式

**常に Array 形式**:
```ruby
message['content'] = [
  {
    "type": "text",
    "text": "Text content",
    "start_timestamp": "...",
    "stop_timestamp": "...",
    "citations": []
  },
  {
    "type": "thinking",
    "thinking": "Thinking process",
    "summaries": [...]
  }
]
```

### Markdown 生成時の Content 処理

**lib/claude_history_to_obsidian.rb:186-244** (`build_markdown` メソッド)

```ruby
# Content が Array の場合、各要素を処理
if content.is_a?(Array)
  content.each do |item|
    case item['type']
    when 'text'
      output << item['text'] || item['content']
    when 'thinking'
      output << "## 💭 Claude's Thinking\n"
      output << item['thinking']
    when 'code'
      # その他のタイプも処理可能
    end
  end
else
  # String の場合、そのまま使用
  output << content
end
```

**結果**: Claude Code/Web 両形式を統一的に処理可能 ✅

---

## 🕐 タイムスタンプ処理の詳細

### 入力形式

**Claude Code & Claude Web 共通**:
```
ISO 8601 UTC: "2025-11-03T14:30:22.000Z"
                                         ↑ Z = UTC 指定子
```

### 処理フロー

```
入力: "2025-11-03T14:30:22.000Z"
  ↓
Time.parse() → Timeオブジェクト (UTC時刻として解釈)
  ↓
【修正が必要】.localtime → ローカルタイムゾーン変換
  ↓
.strftime() → 文字列フォーマット
  ↓
出力: "20251103-233022" (JST の場合、UTC+9時間)
```

### 具体例 (JST の場合)

```ruby
# 入力タイムスタンプ (UTC)
timestamp_str = "2025-11-03T14:30:22.000Z"

# パース（UTC として認識）
time_obj = Time.parse(timestamp_str)  # => 2025-11-03 14:30:22 UTC

# 現在の実装 ❌ 問題点
time_obj.strftime('%Y%m%d-%H%M%S')
# => "20251103-143022" (UTC のまま)

# 修正後 ✅
time_obj.localtime.strftime('%Y%m%d-%H%M%S')
# => "20251103-233022" (JST = UTC+9時間)
```

### 修正対象メソッド

| メソッド | ファイル | 行番号 | 修正内容 |
|---|---|---|---|
| `extract_session_timestamp` | lib/claude_history_to_obsidian.rb | 300 | `.localtime` 追加 |
| `extract_first_message_timestamp` | Rakefile | 203 | `.localtime` 追加 |
| `build_markdown` | lib/claude_history_to_obsidian.rb | 165 | `Time.now` 削除、`extract_session_time` 使用 |

---

## 🏗️ Vault ディレクトリ構造

### Claude Code Vault

**パス**: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/`

```
Claude Code/
├── project-1/
│   ├── 20251103-143022_session-name_abc12345.md
│   ├── 20251103-150000_another-session_def67890.md
│   └── ...
├── project-2/
│   └── ...
└── (各プロジェクトのディレクトリ)
```

**ファイル名形式**: `YYYYMMDD-HHMMSS_session-name_session-id-8char.md`

### Claude Web Vault

**パス**: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai/`

```
claude.ai/
├── 202510/          # ← YYYYMM (年月) ディレクトリ
│   ├── 20251029-110725_project-name_session-name.md
│   ├── 20251029-110730_another-project_another-session.md
│   └── ...
├── 202511/
│   └── ...
└── (各月のディレクトリ)
```

**ファイル名形式**: `YYYYMMDD-HHMMSS_project-name_session-name.md`

**ディレクトリ構造の理由** (Rakefile:254-256):
```ruby
if source == 'web' && transcript
  timestamp = extract_session_timestamp(transcript)
  if timestamp
    year_month = timestamp[0..5]  # "20251103" → "202511"
    project_name = year_month  # プロジェクト名を YYYYMM に上書き
  end
end
```

**目的**: Web の大量の会話を月別に整理（スケーラビリティ向上）

---

## ✅ 実装状況チェックリスト

### Rakefile 実装状況

- [x] UTF-8 エンコーディング処理
- [x] JSON 単一行パース
- [x] Conversation 配列イテレーション
- [x] sender → role 変換
- [x] content Array 形式処理
- [x] `source: 'web'` パラメータ対応
- [x] CLAUDE_WEB_VAULT_PATH ルーティング
- [x] yyyymm ディレクトリ構造実装
- [x] 進捗表示 (10件ごと)

### lib/claude_history_to_obsidian.rb 実装状況

- [x] source パラメータ対応 (`build_markdown` 172行)
- [x] Markdown ヘッダー (Code/Web判定) (172-173行)
- [x] Vault ルーティング (CLAUDE_CODE/WEB_VAULT_PATH) (247-257行)
- [x] Content Array 処理 (186-244行)
- [x] yyyymm ディレクトリ構造 (254-256行)
- [ ] タイムゾーン処理 (修正予定) ⚠️
  - [ ] `extract_session_timestamp:300` - `.localtime` 追加
  - [ ] `build_markdown:165` - `Time.now` → `extract_session_time`
  - [ ] `extract_session_time` - 新規メソッド実装

---

## 📈 実装進捗

**調査完了**: 2025-11-06 ✅

**次ステップ**: CLAUDE_TODO.md の タスク2-7 実装予定

| タスク | 内容 | 実装者 | 予定 |
|---|---|---|---|
| 1 | ローカル調査 | 調査完了 | ✅ |
| 2 | extract_session_timestamp 修正 | TBD | ⏳ |
| 3 | extract_session_time 実装 | TBD | ⏳ |
| 4 | build_markdown 修正 | TBD | ⏳ |
| 5 | E2E テスト | TBD | ⏳ |
| 6 | ドキュメント更新 | TBD | ⏳ |
| 7 | テスト実行 & 確認 | TBD | ⏳ |

---

## 🔗 参考リンク

- **CLAUDE_TODO.md**: タイムゾーン修正の詳細な実装計画
- **lib/claude_history_to_obsidian.rb**: メイン実装
- **Rakefile**: Web import 実装
- **specifications.md**: Hook/JSON仕様
