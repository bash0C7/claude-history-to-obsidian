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

## 📝 その他のTODO

（将来的な改善項目をここに追加）
