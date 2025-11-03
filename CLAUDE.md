# claude-history-to-obsidian

Ruby CLI tool that automatically saves Claude Code conversation transcripts to Obsidian vault via Hook integration.

<output_tone>
**日本語で出力すること**:
- **絶対に日本語で応答・プラン提示すること**
- 通常時: 語尾に「ピョン。」をつけて可愛く
- 盛り上がってきたら:「チェケラッチョ！！」と叫ぶ
- コード内コメント: 日本語、体言止め
- ドキュメント(.md): 英語で記述
- Git commit: 英語、命令形
</output_tone>

## 🎯 Project Context

- **Language**: Ruby 3.4.7 (CRuby)
- **Type**: CLI application (NOT Rails, pure Ruby)
- **Package Manager**: Bundler with vendor/bundle (NO global gems)
- **Version Manager**: rbenv with .ruby-version
- **Platform**: macOS only (iCloud Drive dependency)
- **Integration**: Claude Code Hook system (Stop event)

---

## 📚 Documentation Structure

This project's documentation is organized into focused modules. Import what you need:

- **@.claude/development.md** - Development environment, setup commands, project structure, code style, file boundaries
- **@.claude/specifications.md** - Technical specifications (Hook integration, Obsidian output, JSON formats, error handling, class structure)
- **@.claude/practices.md** - t-wada style TDD methodology, Git Subtree management, Claude Code integration best practices
- **@CLAUDE_TODO.md** - Implementation checklist and known issues
- **@README.md** - User documentation and how to get started

---

## 🚀 Quick Reference

### Initial Setup

```bash
bundle config set --local path vendor/bundle
bundle install
```

### Run Application

```bash
# From project root
bundle exec ruby bin/claude-history-to-obsidian

# With test input from stdin
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
```

### Run Tests

```bash
# All tests
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
```

### Bulk Import

```bash
# Import past Claude Code sessions from ~/.claude/projects/
rake bulk_import
```

### View Logs

```bash
# Recent logs
tail -20 ~/.local/var/log/claude-history-to-obsidian.log

# Monitor live
tail -f ~/.local/var/log/claude-history-to-obsidian.log
```

---

## 📖 For Developers

1. **Starting development**: Read `@.claude/development.md` for environment setup
2. **Understanding the code**: Read `@.claude/specifications.md` for technical details
3. **Development methodology**: Read `@.claude/practices.md` for TDD approach

---

## 🔗 Related Files

- `.claude/development.md` - Development guide
- `.claude/specifications.md` - Technical specifications
- `.claude/practices.md` - Practices and methodologies
- `CLAUDE_TODO.md` - Task tracking
- `README.md` - User documentation
