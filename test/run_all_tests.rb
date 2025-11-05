#!/usr/bin/env ruby
# frozen_string_literal: true

# 全テストを統合実行するランナー
# SimpleCovによる統合カバレッジ計測用

# ENV変数をテスト用に設定（lib読み込み前に定数を初期化）
ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault/Claude Code'
ENV['CLAUDE_WEB_VAULT_PATH'] = '/tmp/test-vault/claude.ai'
ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'

# SimpleCov初期化（最初に一度だけ）
require_relative 'test_helper'

# 全テストファイルをrequire
require_relative 'test_claude_history_importer'
require_relative 'test_claude_history_to_obsidian'
require_relative 'test_rake_bulk_import'
require_relative 'test_rake_web_import'
require_relative 'test_rake_web_import_conversations'
