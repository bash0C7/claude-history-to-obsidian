# Reference Documentation Index

詳細な実装情報および稀少シナリオに関するドキュメント（必要な時に`@`インポートで参照）

## 📚 Available References

### Large File Handling
**@.claude/references/large-file-handling.md** — Claude Web `conversations.json`（100+ MB）処理のベストプラクティス

**Use case**: Claude Web bulk import、大規模ファイル処理のデバッグ

### Implementation Details
**@.claude/references/implementation-details.md** — JSON ネスティングと Markdown 変換の詳細仕様

**Use case**: コンテンツフォーマットの詳細理解、Markdown 出力のカスタマイズ

### Claude Web Import Analysis
**@.claude/references/claude-web-import-analysis.md** — conversations.json 構造、Claude Code/Web フォーマット比較、既存実装の詳細分析

**Use case**: Claude Web エクスポートファイルの処理、conversations.json スキーマの理解、Rakefile bulk_import 実装の詳細確認

**内容**:
- conversations.json の完全スキーマ（97MB単一行JSON）
- Claude Code vs Claude Web フォーマット比較表
- Content Array 処理の詳細
- Rakefile Web import 実装コード
- Vault ディレクトリ構造
- 実装状況チェックリスト

### Timezone Fix Specification
**@.claude/references/timezone-fix-specification.md** — タイムゾーン処理修正の完全仕様書

**Use case**: タイムゾーン処理の実装・修正、テストコード参考、データ変換フロー理解

**内容**:
- 問題の概要と具体例
- 修正対象メソッド4つの詳細仕様
  - `extract_session_timestamp` (lib:300)
  - `extract_first_message_timestamp` (Rakefile:203)
  - `extract_session_time` (新規)
  - `build_markdown` (lib:165)
- テスト実装の詳細コード（5個）
- エンドツーエンドテスト仕様
- データ変換の具体例（JST/UTC環境）
- 成功条件チェックリスト
