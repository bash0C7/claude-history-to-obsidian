# claude-history-to-obsidian

# Claude Code 実装引き継ぎプロンプト仕様
## Ruby 版：Claude Code 会話履歴を Obsidian に自動保存

---

## 🎯 実装目標

**Ruby スクリプト**で Claude Code の会話履歴（transcript）を **Obsidian vault** に自動で保存するシステムを構築。

- リポジトリ名：`claude-history-to-obsidian`
- 言語：Ruby 3.4 + Bundler
- 保存方式：Hook 発火時に都度、現在のセッション全体を Markdown で保存
- 操作方式：完全自動（ユーザーのボタン操作不要）

---

## 📋 要件・仕様

### 1. 会話データの入力元

**Claude Code の Stop Hook** から JSON 経由で受け取る：

```json
{
  "session_id": "abc123456789...",
  "transcript_path": "/Users/bash/.claude/sessions/session-20251102-143022.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
```

**必要なフィールド**:
- `session_id`: セッション ID（後ろ 8 文字をファイル名に使用）
- `transcript_path`: 会話履歴の JSON ファイルパス（Markdown に変換する元ファイル）
- `cwd`: 現在の作業ディレクトリ（プロジェクト名抽出に使用）

### 2. 会話 JSON の構造

`transcript_path` で指定されるファイル：

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

**処理方法**:
1. `messages` 配列を順番に処理
2. 各メッセージの `role` に基づいて Markdown に変換
3. `content` は raw text（コードブロックなど既に Markdown 形式の場合あり）

### 3. 保存先

Obsidian vault（iCloud Drive 経由）：

```
/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/
├── picoruby-recipes/
│   ├── 20251102-143022_implementing-feature_abc12345.md
│   ├── 20251102-150000_fixing-bug_def67890.md
│   └── ...
├── another-project/
│   └── ...
└── README.md (オプション)
```

**ディレクトリ階層**:
- Vault ルート下に `Claude Code` フォルダ
- その下にプロジェクト名（`cwd` の basename）でフォルダ分け
- 各フォルダ内にセッション単位で `.md` ファイル生成

**パス自動構築**:
```ruby
vault_base = "/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code"
project_name = File.basename(cwd)
project_dir = File.join(vault_base, project_name)
```

### 4. ファイル名形式

```
{YYYYMMDD-HHMMSS}_{セッション名推測}_{セッションID短縮}.md
```

**例**:
- `20251102-143022_implementing-feature_abc12345.md`
- `20251102-150000_fixing-bug_def67890.md`

**パーツ**:

| パーツ | 説明 | 例 |
|---|---|---|
| `{YYYYMMDD-HHMMSS}` | 実行日時（`Time.now.strftime('%Y%m%d-%H%M%S')`) | `20251102-143022` |
| `{セッション名推測}` | 最初のユーザーメッセージから推測 | `implementing-feature` |
| `{セッションID短縮}` | `session_id` の最初の 8 文字 | `abc12345` |

**セッション名推測ロジック**:

1. `messages` 配列から最初の `{"role": "user", ...}` を探す
2. その `content` の最初の行を取得
3. 最初の 30 文字程度を抽出
4. 英数字・アンダースコア以外を `-` に置換
5. 小文字化
6. 連続する `-` を 1 つに圧縮
7. 前後の `-` を削除
8. 結果が空なら `session` をデフォルト値として使用

**Ruby 実装例**:
```ruby
def extract_session_name(messages)
  first_user_msg = messages.find { |m| m['role'] == 'user' }
  return 'session' unless first_user_msg && first_user_msg['content']
  
  text = first_user_msg['content']
  first_line = text.split("\n")[0]
  name = first_line[0..29]  # 最初の 30 文字
  
  name
    .downcase
    .gsub(/[^a-z0-9]+/, '-')
    .sub(/^-+/, '')
    .sub(/-+$/, '')
    .presence || 'session'
end
```

### 5. Markdown 変換仕様

**出力形式**:

```markdown
# Claude Code Session

**Project**: picoruby-recipes
**Path**: /Users/bash/src/Arduino/picoruby-recipes
**Session ID**: abc123456789...
**Date**: 2025-11-02 14:30:22

---

## 👤 User

{ユーザーメッセージ}

---

## 🤖 Claude

{Claude のメッセージ}

---

## 👤 User

{次のユーザーメッセージ}

---

（繰り返し）
```

**実装上の注意**:

- メッセージの `content` は既に Markdown 形式の可能性あり（code block など）
- `content` をそのまま貼り付ける（二重 escape 不要）
- ユーザー/Claude の順序は `messages` 配列の順序通り

### 6. Hook 統合設定

`.claude/settings.local.json` または `~/.claude/settings.json` に以下を記載：

```json
{
  "hooks": {
    "Stop": {
      "*": [
        {
          "command": "cd {プロジェクトディレクトリ} && bundle exec ruby ~/.local/bin/claude-history-to-obsidian.rb"
        }
      ]
    }
  }
}
```

**注意**:
- `Stop` イベント：Claude の応答完了時に発火
- stdin から Hook JSON を受け取る
- exit code 0 で成功（stderr も表示される）
- exit code 2 でブロッキングエラー（stderr が Claude に渡される）

### 7. Gem 依存

**最小化戦略**：

必須：
- なし（Ruby 標準ライブラリのみ）

オプション（推奨）：
- `terminal-notifier` gem（macOS 通知）

**Gemfile**:
```ruby
source 'https://rubygems.org'

ruby '3.4.0'

gem 'terminal-notifier', '~> 2.0', require: false
```

**理由**:
- 通知は「必須」ではなく「あると便利」レベル
- ユーザーが `terminal-notifier` 使用経験あり
- Ruby 標準の JSON, File I/O で十分

### 8. ユーザー環境

- **OS**: macOS （iCloud Drive 使用）
- **Ruby**: 3.4.x （`.ruby-version` で固定）
- **Bundler**: yes （Gem 管理に使用）
- **jq**: 導入済み
- **Vault パス**: `/Users/bash/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/`
- **Obsidian**: Vault として上記を使用（プラグインなし）

---

## 📦 ファイル構成

```
claude-history-to-obsidian/
├── README.md                                    # 使用方法、セットアップ
├── Gemfile                                      # Ruby Gem 依存定義
├── Gemfile.lock                                 # Gem バージョン固定
├── lib/
│   └── claude_history_to_obsidian.rb            # ロジック（class）
├── bin/
│   └── claude-history-to-obsidian               # 実行エントリーポイント
└── .ruby-version                                # Ruby 3.4.0
```

### bin/claude-history-to-obsidian

```ruby
#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'time'

# 実装は lib/claude_history_to_obsidian.rb に委譲

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'claude_history_to_obsidian'

ClaudeHistoryToObsidian.new.run
```

### lib/claude_history_to_obsidian.rb

主要ロジッククラス：

```ruby
class ClaudeHistoryToObsidian
  def run
    # 1. stdin から Hook JSON を受け取る
    # 2. Transcript JSON を読む
    # 3. Markdown に変換
    # 4. Obsidian Vault に保存
    # 5. 通知（オプション）
  end

  private

  def load_hook_input
    # stdin から JSON をパース
  end

  def load_transcript(path)
    # Transcript JSON を読み込む
  end

  def extract_session_name(messages)
    # セッション名推測ロジック
  end

  def build_markdown(data, timestamp, session_name)
    # Markdown 変換
  end

  def ensure_directories(base_dir)
    # ディレクトリ作成
  end

  def save_to_vault(markdown, file_path)
    # ファイル書き込み（iCloud Drive）
  end

  def notify(message)
    # システム通知（オプション）
  end
end
```

---

## 🧪 テスト・セットアップ

### 1. ローカルテスト

**テスト用 Hook JSON 作成**：
```bash
cat > /tmp/hook-input.json <<'EOF'
{
  "session_id": "test123456789",
  "transcript_path": "/tmp/test-transcript.json",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "permission_mode": "default",
  "hook_event_name": "Stop"
}
EOF
```

**テスト用 Transcript JSON 作成**：
```bash
cat > /tmp/test-transcript.json <<'EOF'
{
  "session_id": "test123456789",
  "cwd": "/Users/bash/src/Arduino/picoruby-recipes",
  "messages": [
    {"role": "user", "content": "Implementing the feature for button handling"},
    {"role": "assistant", "content": "I'll help you implement the button handling feature..."}
  ]
}
EOF
```

**スクリプト実行**：
```bash
cat /tmp/hook-input.json | bundle exec ruby ~/.local/bin/claude-history-to-obsidian.rb
```

**確認**：
```bash
ls -la "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/picoruby-recipes/"
cat "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/picoruby-recipes/YYYYMMDD-HHMMSS_implementing-the-feature_test1234.md"
```

### 2. 実運用テスト

1. GitHub リポジトリ clone
2. `bundle install` ただしgemはこのプロジェクト内で管理するようにして、グローバルは汚染しない！絶対に！
3. `.ruby-version` 確認（Ruby 3.4 で固定）
4. `.claude/settings.local.json` に Hook 設定追加
5. Claude Code で任意のセッション実行
6. セッション終了 → Hook 発火
7. Obsidian Vault でファイル確認

### 3. ログ・デバッグ

**ログファイル**（推奨）：
```
~/.local/var/log/claude-history-to-obsidian.log
```

**ログ記録例**：
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

---

## 🚨 エラーハンドリング

### 想定される問題と対応

| 問題 | 原因 | 対応 |
|---|---|---|
| Transcript path が見つからない | Hook の transcript_path が無効 | stderr に警告、exit 0（非ブロッキング） |
| Vault ディレクトリへの書き込み失敗 | iCloud Drive のパス誤り、権限不足 | stderr に詳細ログ、exit 0 |
| JSON パースエラー | transcript_path の JSON が壊れている | stderr に詳細ログ、exit 0 |
| Ruby VM が起動できない | .ruby-version が環境に存在しない | Bundler が自動フォールバック |

**基本ルール**:
- ユーザー向けエラー → `STDERR.puts` で表示
- デバッグ情報 → ログファイルに記録
- **Hook は必ず exit code 0 で終了**（Claude Code 応答を邪魔しない）

---

## 📖 README に含める内容

1. 概要
2. インストール手順
   - Clone
   - Bundle install
   - `.ruby-version` 確認
   - Hook 設定方法
3. 使用方法
   - 自動実行型（ユーザー操作不要）
   - Obsidian Vault での確認
4. トラブルシューティング
5. ログ確認方法
6. カスタマイズ例

---

## 🔍 参考：既存実装ドキュメント

前回のドキュメント：
- パターン A（都度保管）を採用
- Hook Stop イベント時に都度セッション保存
- Ruby スクリプト版は「自動実行型」（ボタンなし）
- Gem 依存は通知程度に限定

---

## 📞 質問・確認事項

実装中のFAQ：

1. **iCloud Drive パス**：`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code/` で固定する
2. **エラー時の動作**：エラー時はスキップすべきか？
3. **ログレベル**：INFO/WARN/ERROR の 3 段階で記録する
4. **通知の詳細度**：成功時+エラー時も通知か？
5. **Markdown のカスタマイズ**：ユーザーが template をカスタマイズできる必要はない

