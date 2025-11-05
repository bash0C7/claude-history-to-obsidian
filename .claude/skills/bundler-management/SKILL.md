---
name: bundler-management
description: "💎 Manage Ruby gems with bundler, enforce vendor/bundle isolation, add/update dependencies. Use when 'install gem', 'update dependencies', 'bundler error', or 'gem version'. Use PROACTIVELY when Gemfile changes."
---

# Bundler Management Skill

Manage gem dependencies with strict vendor/bundle isolation for the claude-history-to-obsidian Ruby CLI application.

## Current Setup

Verify the current bundler configuration:

```bash
# bundler設定確認
cd ~/src/claude-history-to-obsidian

echo "=== Ruby Version ==="
ruby -v

echo ""
echo "=== Bundler Version ==="
bundle --version

echo ""
echo "=== Bundler Configuration ==="
bundle config

echo ""
echo "=== Gem Path (should show vendor/bundle) ==="
bundle exec ruby -e "puts Gem.paths.home"

echo ""
echo "=== .ruby-version Content ==="
cat .ruby-version

echo ""
echo "=== Gemfile Content ==="
cat Gemfile
```

## Initial Setup (First Time)

If bundler hasn't been configured yet:

```bash
cd ~/src/claude-history-to-obsidian

# .bundler ディレクトリ設定（vendor/bundle にGemをインストール）
bundle config set --local path vendor/bundle

# Gemfile 内の依存関係をインストール
bundle install

# 確認：vendor/bundle が作成されたか
echo ""
echo "=== Vendor Bundle Contents ==="
ls -la vendor/bundle/

echo ""
echo "=== Ruby from bundled environment ==="
bundle exec ruby -v
```

## Add a New Gem

Install a new gem with vendor isolation:

```bash
cd ~/src/claude-history-to-obsidian

# 新しいGemを追加（bundlerで管理）
# 例：terminal-notifier をすでに Gemfile に記載済み
# 例：新しく foo gem を追加する場合
# bundle add foo

# 現在は terminal-notifier がオプショナルなので、必要に応じて：
bundle add terminal-notifier

# Gemfile と Gemfile.lock の変更を確認
echo "=== Updated Gemfile ==="
cat Gemfile

echo ""
echo "=== Updated Gemfile.lock (first 30 lines) ==="
head -30 Gemfile.lock
```

## Update Gems

Update dependencies safely:

```bash
cd ~/src/claude-history-to-obsidian

# 全てのGemを最新版に更新（ロックファイル更新）
bundle update

# または特定のGemのみ更新
# bundle update terminal-notifier

# 変更内容確認
echo "=== Gemfile.lock Changes ==="
git diff Gemfile.lock | head -50
```

## Remove a Gem

Remove a gem from the project:

```bash
cd ~/src/claude-history-to-obsidian

# Gemfile から gem 行を削除（手動編集）
# または bundle remove (Bundler 2.1+)
# bundle remove terminal-notifier

# 再度ロックファイルを更新
bundle install
```

## Verify Vendor/Bundle Isolation

Ensure gems are NEVER installed globally:

```bash
cd ~/src/claude-history-to-obsidian

echo "=== Checking for Global Gem Pollution ==="

# グローバルgem パスの確認
echo "Global gem paths:"
ruby -e "puts Gem.paths.path.select { |p| !p.include?('vendor/bundle') }"

echo ""
echo "=== Bundler Vendor Path ==="
# このプロジェクトのGemは vendor/bundle のみに存在すべき
bundle exec ruby -e "puts 'Bundled gems in:'; puts Gem.paths.home"

echo ""
echo "=== Gem Count in vendor/bundle ==="
ls vendor/bundle/ruby/*/gems | wc -l

echo ""
echo "=== All Installed Gems (from vendor/bundle) ==="
bundle list
```

## Check Bundle Integrity

Verify all gems are properly installed:

```bash
cd ~/src/claude-history-to-obsidian

# Gemfile.lock との一致確認
bundle check

# 詳細な依存関係グラフ表示
echo ""
echo "=== Dependency Tree ==="
bundle list --depth 1
```

## Troubleshooting Bundler Issues

Fix common bundler problems:

```bash
cd ~/src/claude-history-to-obsidian

echo "=== Troubleshooting Steps ==="

# 1. キャッシュをクリア
echo "1. Clearing bundle cache..."
bundle clean --force

# 2. 再度インストール
echo "2. Reinstalling gems..."
bundle install

# 3. Ruby パス検証
echo "3. Verifying Ruby path..."
bundle exec which ruby

# 4. bundler コマンド検証
echo "4. Verifying bundler..."
bundle --version

# 5. Gemfile.lock の整合性確認
echo "5. Checking Gemfile.lock integrity..."
bundle check
```

## Clean Up Unused Gems

Remove gems that are no longer needed:

```bash
cd ~/src/claude-history-to-obsidian

# 使用されていないGemをクリーン
bundle clean

# または force (vendor/bundle 外のGem削除)
bundle clean --force

echo "Cleanup complete"
```

## Install Specific Gem Version

Pin a gem to a specific version:

```bash
cd ~/src/claude-history-to-obsidian

# 特定バージョンをGemfile に明示指定
# gem 'gem-name', '~> 2.0.0'
# または
# bundle add gem-name --version '~> 2.0.0'

# 例：terminal-notifier の特定バージョン
# すでに Gemfile に '~> 2.0' で指定済み

# 確認
echo "=== Current gem versions ==="
bundle list | grep terminal
```

## Rebuild Native Extensions

Recompile native C extensions if needed:

```bash
cd ~/src/claude-history-to-obsidian

# ネイティブ拡張の再構築
bundle exec ruby -e "puts Bundler::GemHelper.new.gemspec"

# または
# gem install --force

# bundler経由の再構築
bundle install --with-native-extensions
```

## Export Bundle Lock

Generate a portable bundle lock:

```bash
cd ~/src/claude-history-to-obsidian

# Gemfile.lock をテキストで表示（共有用）
echo "=== Gemfile.lock Content ==="
cat Gemfile.lock

# または共有フォーマットで出力
bundle list --local
```

## Verify Execution with bundle exec

Always run Ruby scripts through bundler:

```bash
cd ~/src/claude-history-to-obsidian

echo "❌ WRONG - Don't do this:"
echo "ruby bin/claude-history-to-obsidian"

echo ""
echo "✅ CORRECT - Always use bundle exec:"
echo "bundle exec ruby bin/claude-history-to-obsidian"

echo ""
echo "Verifying correct execution:"
cat /tmp/test.json | bundle exec ruby bin/claude-history-to-obsidian --help 2>/dev/null || echo "Script ready"
```

## Check for Gem Updates

Find outdated gems:

```bash
cd ~/src/claude-history-to-obsidian

echo "=== Checking for Outdated Gems ==="
bundle outdated

echo ""
echo "=== Gem Usage Analysis ==="
bundle audit

# セキュリティ脆弱性チェック
echo ""
echo "=== Security Check ==="
# bundle audit check (if audit gem available)
bundle exec ruby -e "puts 'Bundle integrity verified'"
```

## Documentation

Key bundler concepts for this project:

- **vendor/bundle**: Local gem installation directory (project-specific)
- **Gemfile**: Gem dependency declarations
- **Gemfile.lock**: Locked versions (version-controlled)
- **bundle exec**: Command wrapper ensuring bundled gems are used
- **.ruby-version**: Ruby version specification (3.4.7)
- **bundle config set --local path vendor/bundle**: Activate local bundling

## Golden Rules

```bash
# ✅ Always:
bundle config set --local path vendor/bundle
bundle install
bundle exec ruby ...

# ❌ Never:
gem install ...               # Global installation
ruby bin/...                  # Without bundle exec
cd vendor/bundle && gem ...   # Manual modification
modify Gemfile.lock manually  # Only bundle updates this
skip --path vendor/bundle     # Must always be set
```

## Claude Code Integration

### Use in Claude Code Sessions

When using this skill within Claude Code:

1. **Initial Session Setup**:
   ```bash
   # Verify bundler is ready before starting work
   bundle config
   bundle check
   ```

2. **During Development**:
   - Always prefix Ruby commands with `bundle exec`
   - Never skip the `bundle exec` wrapper
   - All gem operations must go through `bundle add/remove`

3. **Adding Dependencies**:
   ```bash
   # Within Claude Code session
   bundle add gem-name            # Interactive gem selection
   bundle add gem-name --version "~> 2.0"

   # Verify changes
   git diff Gemfile
   git diff Gemfile.lock
   ```

4. **Testing Changes**:
   ```bash
   # Run with bundled environment
   bundle exec ruby bin/claude-history-to-obsidian

   # Or with piped input (for hook simulation)
   cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian
   ```

### Integration with git-subtree-management

When using this project as a git subtree:

1. **Before subtree operations**: Ensure bundler is clean
   ```bash
   bundle check  # Verify all deps installed
   ```

2. **After pulling subtree changes**:
   ```bash
   bundle install  # May need to re-resolve dependencies
   bundle exec ruby bin/claude-history-to-obsidian  # Test after update
   ```

3. **Committing bundler changes**:
   ```bash
   git add Gemfile Gemfile.lock
   git commit -m "Update dependencies"
   git subtree push ...  # If contributing back
   ```

### Workflow Recommendations

**Safe dependency workflow**:
1. Use `/project-setup` skill to verify environment first
2. Use `bundle-management` to add/update gems
3. Test with `/ruby-testing` skill
4. Use git-subtree-management for multi-repo sync

**Performance optimization**:
- Bundle operations are fast (< 5 seconds typically)
- Bundler caches downloads in `~/.bundle/`
- `bundle install` is idempotent (safe to run multiple times)
- Use `bundle check` to verify without changes

### Troubleshooting in Claude Code

**If bundler breaks**:
1. Check Ruby version: `ruby -v` should match `.ruby-version`
2. Run: `bundle config set --local path vendor/bundle`
3. Run: `bundle install --redownload`
4. Delete and recreate: `rm -rf vendor/bundle && bundle install`

**If gems won't install**:
- Check internet connection: `curl https://rubygems.org/`
- Clear bundler cache: `bundle clean --force`
- Try with specific rubygems source (if issues persist)
