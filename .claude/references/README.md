# Reference Documentation Index

詳細な実装情報および稀少シナリオに関するドキュメント（必要な時に`@`インポートで参照）

## 📚 Available References

### Large File Handling
**@.claude/references/large-file-handling.md**

Claude Web の `conversations.json`（100+ MB）処理のベストプラクティス：
- 安全なファイル探索コマンド（cat/lessなし）
- JSON バリデーション方法
- テストデータ生成パターン
- 本番環境での効率的処理

**Use case**: Claude Web bulk import、大規模ファイル処理のデバッグ

### Implementation Details
**@.claude/references/implementation-details.md**

JSON ネスティングと Markdown 変換の詳細仕様：
- Array Content vs String Content 処理
- Signature フィルタリング（2段階）
- Newline 変換ロジック
- テストケースの詳細

**Use case**: コンテンツフォーマットの詳細理解、Markdown 出力のカスタマイズ

---

## When to Reference

**Load `large-file-handling.md` when**:
- `conversations.json` import に関する質問
- 大容量ファイル処理のデバッグ
- テストデータ生成パターンの確認

**Load `implementation-details.md` when**:
- Array vs String Content の処理を詳しく知る必要がある
- Signature フィルタリングのカスタマイズ
- JSON ネスティング構造の詳細理解

---

## Core Documentation

**Main specifications** (always loaded): @.claude/specifications.md
- Hook Integration
- Output Specifications
- Error Handling Philosophy
- Environment Variables (Quick Reference)
