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

## 🎯 Tech Stack

- **Language**: Ruby 3.4.7 (rbenv)
- **Type**: CLI application (pure Ruby, NOT Rails)
- **Package Manager**: Bundler with vendor/bundle
- **Platform**: macOS only (iCloud Drive)
- **Integration**: Claude Code Hook system (Stop event)

## ⚡ Quick Commands

```bash
# Setup
bundle config set --local path vendor/bundle
bundle install

# Run
bundle exec ruby bin/claude-history-to-obsidian
cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian

# Test
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb

# Bulk import
rake bulk_import

# View logs
tail -f ~/.local/var/log/claude-history-to-obsidian.log
```

## 🚨 Critical Rules (絶対厳守)

- **ALWAYS exit 0** (even on errors) - Hook requirement
- **ALWAYS bundle exec** - Never global gems
- **Test-First Only** - Use @tdd skill for TDD workflow
- **Never touch**: .git/, vendor/, Gemfile.lock
- **Commit Frequently**: Create meaningful commits for every completed task (feature, fix, docs, refactor)
  - Use `git add` to stage changes
  - Use `git commit -m "message"` to record work
  - Keep commit history clean and descriptive

## 📚 Documentation (JIT Loading)

- **@.claude/development.md** - Setup, commands, structure
- **@.claude/specifications.md** - Hook, JSON, output formats
- **@.claude/practices.md** - TDD, Git Subtree, worktrees
- **@.claude/references/** - Large file handling, implementation details

## 🔧 Skills (Use PROACTIVELY)

- **@ruby-testing** 🧪 - Test script with sample Hook JSON
- **@ruby-cli-debugging** 🐛 - Debug errors, check logs
- **@hook-integration** 🪝 - Simulate Claude Code hooks
- **@tdd** 📝 - Implement features (RED-GREEN-REFACTOR)
- **@project-setup** ⚙️ - Verify environment
- **@bundler-management** 💎 - Manage gems

## 🌍 Environment Variables

| Variable | Default | Use Case |
|---|---|---|
| `CLAUDE_VAULT_PATH` | iCloud Drive `/Claude Code/` | Claude Code vault |
| `CLAUDE_WEB_VAULT_PATH` | iCloud Drive `/claude.ai/` | Claude Web vault |
| `CLAUDE_LOG_PATH` | `~/.local/var/log/...` | Log file location |
| `CLAUDE_VAULT_MODE=test` | (none) | Test isolation ([test] suffix) |

## 📝 Output Format

**Claude Code** (`source: "code"`): `Claude Code/{project}/`
**Claude Web** (`source: "web"`): `claude.ai/{project}/`
**Filename**: `YYYYMMDD-HHMMSS_{session-name}_{session-id-8}.md`
