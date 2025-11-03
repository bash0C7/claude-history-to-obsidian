---
name: project-setup
description: Verify project environment setup, check Ruby version, initialize bundler, validate directory structure, ensure dependencies installed, and confirm Obsidian vault path accessibility. Use during initial setup, environment verification, or troubleshooting setup issues.
---

# Project Setup Skill

Complete environment verification and initialization for the claude-history-to-obsidian project.

## Full Environment Check

Run comprehensive environment validation:

```bash
#!/bin/bash
# プロジェクト環境の完全検証

PROJ_DIR="/Users/bash/src/claude-history-to-obsidian"

echo "=========================================="
echo "Claude History to Obsidian - Setup Check"
echo "=========================================="
echo ""

# 1. Git リポジトリの確認
echo "📦 Git Repository"
cd "$PROJ_DIR" || exit 1
git status | head -5
echo ""

# 2. Ruby バージョン確認
echo "🐍 Ruby Version"
echo "Expected: 3.4.7"
echo "Actual: $(cat .ruby-version)"
echo "System Ruby: $(ruby -v)"
echo ""

# 3. .ruby-version ファイル確認
echo "📄 .ruby-version File"
if [ -f ".ruby-version" ]; then
  echo "✅ Found: $(cat .ruby-version)"
else
  echo "❌ Missing"
fi
echo ""

# 4. Gemfile 確認
echo "📦 Gemfile"
if [ -f "Gemfile" ]; then
  echo "✅ Found"
  echo "Ruby requirement: $(grep "^ruby" Gemfile)"
  echo "Gems:"
  grep "^gem" Gemfile
else
  echo "❌ Missing"
fi
echo ""

# 5. Bundler 設定確認
echo "🔧 Bundler Configuration"
bundle config | grep path
echo ""

# 6. ディレクトリ構造確認
echo "📂 Directory Structure"
echo "Checking required directories..."
for dir in bin lib vendor; do
  if [ -d "$dir" ]; then
    echo "✅ $dir/"
  else
    echo "❌ $dir/ (missing)"
  fi
done
echo ""

# 7. 重要ファイルの確認
echo "📋 Required Files"
for file in .ruby-version Gemfile CLAUDE.md .gitignore; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ $file (missing)"
  fi
done
echo ""

# 8. エントリーポイント確認
echo "🚀 Entry Point"
if [ -f "bin/claude-history-to-obsidian" ]; then
  echo "✅ bin/claude-history-to-obsidian found"
  echo "Executable: $(test -x bin/claude-history-to-obsidian && echo 'Yes' || echo 'No')"
else
  echo "❌ bin/claude-history-to-obsidian missing"
fi
echo ""

# 9. メインロジック確認
echo "📝 Core Logic"
if [ -f "lib/claude_history_to_obsidian.rb" ]; then
  echo "✅ lib/claude_history_to_obsidian.rb found"
else
  echo "❌ lib/claude_history_to_obsidian.rb missing"
fi
echo ""

# 10. Gem インストール確認
echo "💎 Gem Installation"
if [ -d "vendor/bundle" ]; then
  echo "✅ vendor/bundle found"
  gem_count=$(find vendor/bundle/ruby/*/gems -maxdepth 0 2>/dev/null | wc -l)
  echo "Installed gems: approximately $gem_count"
else
  echo "❌ vendor/bundle missing (run 'bundle install')"
fi
echo ""

# 11. Obsidian Vault パス確認
echo "🗂️ Obsidian Vault Path"
VAULT_PATH=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude\ Code
if [ -d "$VAULT_PATH" ]; then
  echo "✅ Vault found: $VAULT_PATH"
  echo "Subdirs: $(ls -d "$VAULT_PATH"/*/ 2>/dev/null | wc -l) projects"
else
  echo "⚠️ Vault path not found (iCloud Drive may not be configured)"
  echo "Expected: $VAULT_PATH"
fi
echo ""

# 12. ログディレクトリ確認
echo "📋 Logging Directory"
LOG_DIR=~/.local/var/log
if [ -d "$LOG_DIR" ]; then
  echo "✅ Log directory exists: $LOG_DIR"
else
  echo "⚠️ Log directory not found (will be created on first run)"
fi
echo ""

echo "=========================================="
echo "Setup Check Complete"
echo "=========================================="
```

## Quick Setup from Scratch

Initialize a clean environment:

```bash
cd /Users/bash/src/claude-history-to-obsidian

echo "Step 1: Verify Ruby version..."
ruby -v

echo ""
echo "Step 2: Install bundler (if needed)..."
gem install bundler --user-install 2>/dev/null || echo "Bundler already installed"

echo ""
echo "Step 3: Configure bundler for vendor/bundle..."
bundle config set --local path vendor/bundle

echo ""
echo "Step 4: Install gems from Gemfile..."
bundle install

echo ""
echo "Step 5: Verify installation..."
bundle check

echo ""
echo "✅ Setup complete!"
```

## Verify Directory Structure

Check that all required directories exist:

```bash
cd /Users/bash/src/claude-history-to-obsidian

echo "=== Required Directory Structure ==="
tree -L 2 -a --gitignore 2>/dev/null || find . -type f -not -path './vendor/*' -not -path './.git/*' | head -20

echo ""
echo "=== File Permissions ==="
ls -la bin/claude-history-to-obsidian
chmod +x bin/claude-history-to-obsidian 2>/dev/null
echo "Made executable"
```

## Check rbenv Integration

Verify rbenv is managing the Ruby version:

```bash
echo "=== rbenv Status ==="

# rbenv がインストール済みか確認
if command -v rbenv &> /dev/null; then
  echo "✅ rbenv is installed"
  rbenv --version
else
  echo "❌ rbenv not found"
  echo "Install: brew install rbenv"
  exit 1
fi

echo ""
echo "=== Ruby Version Management ==="
echo "rbenv versions:"
rbenv versions

echo ""
echo "Local project Ruby version:"
cd /Users/bash/src/claude-history-to-obsidian
rbenv local

echo ""
echo "Current Ruby:"
ruby -v

echo ""
# rbenv が 3.4.7 をサポートしているか確認
if rbenv versions | grep -q 3.4.7; then
  echo "✅ Ruby 3.4.7 is installed"
else
  echo "⚠️ Ruby 3.4.7 not installed"
  echo "Install: rbenv install 3.4.7"
fi
```

## Validate Hook Configuration

Check that hook setup is ready:

```bash
cd /Users/bash/src/claude-history-to-obsidian

echo "=== Hook Configuration ==="

HOOK_CONFIG_FILE=~/.claude/settings.local.json

if [ -f "$HOOK_CONFIG_FILE" ]; then
  echo "✅ Hook config file found: $HOOK_CONFIG_FILE"
  echo ""
  echo "Content:"
  cat "$HOOK_CONFIG_FILE" | jq '.hooks.Stop // .hooks' 2>/dev/null || cat "$HOOK_CONFIG_FILE"
else
  echo "⚠️ Hook config file not found"
  echo "Should be: $HOOK_CONFIG_FILE"
  echo ""
  echo "Example hook configuration:"
  cat << 'EOF'
{
  "hooks": {
    "Stop": {
      "*": [{
        "command": "cd /Users/bash/src/claude-history-to-obsidian && bundle exec ruby bin/claude-history-to-obsidian"
      }]
    }
  }
}
EOF
fi
```

## Create Required Directories

Initialize missing directories:

```bash
cd /Users/bash/src/claude-history-to-obsidian

echo "Creating required directories..."

# bin と lib は既に存在するはず
mkdir -p bin
mkdir -p lib

# ログディレクトリ作成
mkdir -p ~/.local/var/log

# Obsidian Vault ディレクトリは自動作成される（iCloud Drive使用時）

echo "✅ Directories ready"
```

## Validate Gemfile

Check Gemfile syntax and requirements:

```bash
cd /Users/bash/src/claude-history-to-obsidian

echo "=== Gemfile Validation ==="

# Gemfile の構文チェック
bundle exec ruby -c Gemfile 2>/dev/null && echo "✅ Gemfile syntax OK" || echo "❌ Gemfile has syntax errors"

echo ""
echo "=== Ruby Version in Gemfile ==="
grep "^ruby" Gemfile

echo ""
echo "=== Gem Dependencies ==="
grep "^gem" Gemfile
```

## Pre-Development Checklist

Before starting development:

```bash
#!/bin/bash
# 開発開始前のチェックリスト

PROJ_DIR="/Users/bash/src/claude-history-to-obsidian"
cd "$PROJ_DIR" || exit 1

echo "Pre-Development Checklist"
echo "========================="
echo ""

checks=0
passed=0

# チェック 1: git
((checks++))
if git status > /dev/null 2>&1; then
  echo "✅ Git repository"
  ((passed++))
else
  echo "❌ Git repository"
fi

# チェック 2: Ruby バージョン
((checks++))
if [ "$(ruby -v | grep -o '3\.4\.[0-9]*')" == "3.4.7" ]; then
  echo "✅ Ruby 3.4.7"
  ((passed++))
else
  echo "❌ Ruby 3.4.7 (current: $(ruby -v))"
fi

# チェック 3: Bundler
((checks++))
if bundle --version > /dev/null 2>&1; then
  echo "✅ Bundler installed"
  ((passed++))
else
  echo "❌ Bundler"
fi

# チェック 4: vendor/bundle
((checks++))
if [ -d "vendor/bundle" ]; then
  echo "✅ vendor/bundle directory"
  ((passed++))
else
  echo "❌ vendor/bundle (run: bundle install)"
fi

# チェック 5: bin/claude-history-to-obsidian
((checks++))
if [ -x "bin/claude-history-to-obsidian" ]; then
  echo "✅ Executable entry point"
  ((passed++))
else
  echo "❌ bin/claude-history-to-obsidian executable"
fi

# チェック 6: lib/claude_history_to_obsidian.rb
((checks++))
if [ -f "lib/claude_history_to_obsidian.rb" ]; then
  echo "✅ Core logic class"
  ((passed++))
else
  echo "❌ lib/claude_history_to_obsidian.rb"
fi

# チェック 7: CLAUDE.md
((checks++))
if [ -f "CLAUDE.md" ]; then
  echo "✅ CLAUDE.md"
  ((passed++))
else
  echo "❌ CLAUDE.md"
fi

# チェック 8: .ruby-version
((checks++))
if [ -f ".ruby-version" ]; then
  echo "✅ .ruby-version"
  ((passed++))
else
  echo "❌ .ruby-version"
fi

echo ""
echo "Summary: $passed/$checks checks passed"

if [ "$passed" -eq "$checks" ]; then
  echo "🎉 Ready for development!"
  exit 0
else
  echo "⚠️ Some setup items missing"
  exit 1
fi
```

## Environment Variables

Set up helpful development environment variables:

```bash
# ~/.zshrc または ~/.bash_profile に追加
export PROJ_ROOT=/Users/bash/src/claude-history-to-obsidian
export VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code"
export LOG_FILE="$HOME/.local/var/log/claude-history-to-obsidian.log"

alias cdproj="cd $PROJ_ROOT"
alias cdvault="cd $VAULT_PATH"
alias ctail="tail -f $LOG_FILE"

# Quick test command
alias ctest="cd $PROJ_ROOT && cat /tmp/hook-input.json | bundle exec ruby bin/claude-history-to-obsidian"
```

## Troubleshooting Setup

Fix common setup issues:

```bash
# Ruby バージョン問題
rbenv install 3.4.7
rbenv local 3.4.7

# Bundler キャッシュの問題
bundle clean --force
bundle install

# Gem パスのリセット
rm -rf vendor/bundle
bundle config set --local path vendor/bundle
bundle install

# executable 権限の設定
chmod +x /Users/bash/src/claude-history-to-obsidian/bin/claude-history-to-obsidian

# ログディレクトリ作成
mkdir -p ~/.local/var/log
```
