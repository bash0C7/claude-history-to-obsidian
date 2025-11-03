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

### 進行中
- [ ] テストカバレッジ計測の仕組み導入（SimpleCov）
- [ ] ClaudeHistoryToObsidianクラスのユニットテスト追加
- [ ] ClaudeHistoryImporterクラスのテスト拡充

---

## 🚨 テスト困難な課題

### VAULT_BASE_PATH依存メソッドのテスト改善

**現状**:
- `ClaudeHistoryToObsidian`クラスの以下メソッドがiCloud DriveパスにハードコードされたVAULT_BASE_PATH定数に依存
  - `ensure_directories` (lib/claude_history_to_obsidian.rb:160-168)
  - `save_to_vault` (lib/claude_history_to_obsidian.rb:196-203)
  - `process_transcript` (上記2つを呼び出し)

**問題点**:
- 実際のiCloud Driveパスを使わないとテストできない
- テスト用に一時プロジェクトを作成・削除する必要あり
- プロダクトコード変更禁止のため、依存性注入も不可

**暫定対応（採用しない）**:
- テスト用ランダムプロジェクト名生成 → 実際のVault汚染のリスク
- teardownでクリーンアップ → 実行中断時に残骸が残る

**推奨アプローチ（今回は対象外）**:
- Phase 3テストは今回スキップ
- カバレッジは純粋関数 + ファイルI/Oテストで60-70%を目指す
- 重要なビジネスロジックは完全カバー

**理想的な解決策（将来課題）**:

1. **オプションA: 環境変数で切り替え**
   - `VAULT_BASE_PATH`を環境変数から読み込むよう変更
   - テスト時は`VAULT_BASE_PATH=/tmp/test-vault`でオーバーライド
   - プロダクトコードの変更が必要

2. **オプションB: 依存性注入**
   - コンストラクタで`vault_base_path`を受け取る設計に変更
   - デフォルト値としてiCloud Driveパスを設定
   - プロダクトコードの変更が必要

**優先度**: 中（現状の機能は満たしている）

**関連ファイル**:
- `lib/claude_history_to_obsidian.rb:9-11` - VAULT_BASE_PATH定数定義
- `lib/claude_history_to_obsidian.rb:160-168` - ensure_directories
- `lib/claude_history_to_obsidian.rb:196-203` - save_to_vault

---

## 📝 その他のTODO

（将来的な改善項目をここに追加）
