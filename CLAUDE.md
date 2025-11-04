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

### ⚠️ TEST-FIRST PRINCIPLE (絶対厳守)

**This project strictly enforces Test-First Development with three critical rules:**

#### Rule 1: Phase 0 GREEN Verification

**BEFORE starting TDD, ALWAYS verify test baseline is GREEN:**
```bash
bundle exec ruby -I lib:test -rtest/unit test/**/*.rb
```

- ✅ All tests PASS → Continue to TDD
- ❌ Any test FAILS → STOP, report to user, fix first

This ensures you start from a known-good state.

#### Rule 2: Plan Revision After Phase 0

**After Phase 0 GREEN, re-examine your implementation plan:**

1. Look at actual codebase (not assumptions)
2. Find simpler paths using existing patterns
3. Revise plan based on reality

"Initial plans are typically flawed" (t-wada) - use actual code to refine.

#### Rule 3: When GREEN Won't Pass - Examine Plan

**If RED test won't go GREEN:**

1. **Don't assume code is complex** - assume plan is incomplete
2. **Examine RED output carefully** - what's actually missing?
3. **Look for simple gaps** - usually 1-2 lines or 1 missing dependency
4. **RED FLAG warning**: If solution feels "acrobatic" or "clever", plan is wrong

**Remember**: Plans have gaps. That's normal. Gaps are usually small. Acrobatic solutions = plan incomplete.

See `@.claude/practices.md` and `@.claude/skills/tdd/SKILL.md` for details on Phase 0, Plan Revision, and Plan Examination.

---

**TDD Workflow**:
```
Phase 0: Verify GREEN baseline
Phase 0.5: Revise plan using actual code
Phase 1: Write test (RED)
Phase 2: Write code (GREEN) - examine plan if stuck
Phase 3: Refactor (REFACTOR)
```

**❌ FORBIDDEN**:
- Modifying production code/config files before writing tests
- Discovering failures after implementation (Test-Last Development)
- Skipping Phase 0 (will be caught by automation)
- Acrobatic solutions instead of simple plan fixes

---

## 🔗 Related Files

- `.claude/development.md` - Development guide
- `.claude/specifications.md` - Technical specifications
- `.claude/practices.md` - Practices and methodologies
- `CLAUDE_TODO.md` - Task tracking
- `README.md` - User documentation
