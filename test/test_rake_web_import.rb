#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'

# ENV変数をテスト用に設定（lib読み込み前に定数を初期化）
ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault/Claude Code'
ENV['CLAUDE_WEB_VAULT_PATH'] = '/tmp/test-vault/claude.ai'
ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'

require_relative 'test_helper'

class TestRakeWebImport < Test::Unit::TestCase
  def setup
    @test_dir = Dir.mktmpdir
    @vault_code_dir = File.join(@test_dir, 'vault-code')
    @vault_web_dir = File.join(@test_dir, 'vault-web')
    @log_file = File.join(@test_dir, 'test.log')

    FileUtils.mkdir_p(@vault_code_dir)
    FileUtils.mkdir_p(@vault_web_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  def test_web_import_saves_to_yyyy_mm_directory
    # 期待値を定義（テストデータとの同期のため先に定義）
    expected_user_message = 'Hello Claude Web'
    expected_assistant_message = 'Hello! How can I help?'
    expected_project_name = 'test-project'

    # テストデータを生成（期待値を埋め込む）
    conversations_json = create_test_conversations_json_with(
      user_message: expected_user_message,
      assistant_message: expected_assistant_message,
      project_name: expected_project_name
    )

    # rake web:bulk_import を実行
    output = run_web_import(conversations_json)

    # Web vault ディレクトリに yyyymm ディレクトリが作成されたことを確認
    year_month_dir = File.join(@vault_web_dir, '202511')
    assert(
      Dir.exist?(year_month_dir),
      "Web vault yyyymm directory should exist: #{year_month_dir}\nVault Web Dir contents: #{Dir.glob(File.join(@vault_web_dir, '**/*'))}"
    )

    # Markdown ファイルが Web vault に保存されたことを確認
    markdown_files = Dir.glob(File.join(year_month_dir, '*.md'))
    assert(
      markdown_files.length > 0,
      "Markdown file should exist in web vault yyyymm dir"
    )

    # ファイル名の形式を確認（{timestamp}_{project-name}_{session-name}.md）
    filename = File.basename(markdown_files.first)
    assert_match(/^\d{8}-\d{6}_test-project_.*\.md$/, filename,
                 "Filename should be {timestamp}_{project-name}_{session-name}.md format, got: #{filename}")

    # ファイル名に session_id が含まれていないことを確認
    assert(!filename.include?('uuid'), "Filename should not contain session_id, got: #{filename}")

    # Markdown の内容を検証
    content = File.read(markdown_files.first)

    # ヘッダを確認
    assert_include(content, '# Claude Web Session', 'Should have Claude Web Session header')

    # メッセージセクションヘッダーが含まれていることを確認
    assert content.include?('User'), 'User section header should exist'
    assert content.include?('Claude'), 'Claude section header should exist'

    # テストデータの期待値が出力に含まれていることを確認（厳密な突合）
    assert_include(content, expected_user_message, "Expected user message '#{expected_user_message}' should appear in file")
    assert_include(content, expected_assistant_message, "Expected assistant message '#{expected_assistant_message}' should appear in file")

    # Code vault には保存されていないことを確認
    code_year_month_dir = File.join(@vault_code_dir, '202511')
    assert(
      !Dir.exist?(code_year_month_dir),
      "Code vault yyyymm directory should NOT exist for web import: #{code_year_month_dir}"
    )
  end

  def test_web_import_handles_multiple_conversations_with_yyyy_mm
    conversations = [
      {
        'uuid' => 'conv-001',
        'name' => 'first conversation',
        'chat_messages' => [
          { 'sender' => 'human', 'content' => [{ 'type' => 'text', 'text' => 'Hello' }], 'created_at' => '2025-11-01T10:00:00Z' },
          { 'sender' => 'assistant', 'content' => [{ 'type' => 'text', 'text' => 'Hi there' }], 'created_at' => '2025-11-01T10:00:05Z' }
        ]
      },
      {
        'uuid' => 'conv-002',
        'name' => 'second conversation',
        'chat_messages' => [
          { 'sender' => 'human', 'content' => [{ 'type' => 'text', 'text' => 'How are you?' }], 'created_at' => '2025-10-15T10:00:00Z' },
          { 'sender' => 'assistant', 'content' => [{ 'type' => 'text', 'text' => 'I am good' }], 'created_at' => '2025-10-15T10:00:05Z' }
        ]
      }
    ]

    conversations_json = File.join(@test_dir, 'conversations.json')
    File.write(conversations_json, JSON.generate(conversations))

    # rake web:import_conversations を実行
    run_web_import(conversations_json)

    # 異なる月のディレクトリが作成されたことを確認
    nov_dir = File.join(@vault_web_dir, '202511')
    oct_dir = File.join(@vault_web_dir, '202510')

    assert(
      Dir.exist?(nov_dir),
      "November directory should exist: #{nov_dir}"
    )
    assert(
      Dir.exist?(oct_dir),
      "October directory should exist: #{oct_dir}"
    )

    # 各月のディレクトリに Markdown ファイルが存在することを確認
    nov_files = Dir.glob(File.join(nov_dir, '*.md'))
    oct_files = Dir.glob(File.join(oct_dir, '*.md'))

    assert(
      nov_files.length > 0,
      'November directory should have markdown file'
    )
    assert(
      oct_files.length > 0,
      'October directory should have markdown file'
    )

    # ファイル名に session_id が含まれていないことを確認
    all_files = nov_files + oct_files
    all_files.each do |file|
      filename = File.basename(file)
      assert(!filename.include?('conv-'), "Filename should not contain session_id: #{filename}")
    end
  end

  def test_web_import_skips_empty_conversations
    conversations = [
      {
        'uuid' => 'conv-empty',
        'name' => 'empty conversation',
        'chat_messages' => []  # 空の会話
      },
      {
        'uuid' => 'conv-valid',
        'name' => 'valid conversation',
        'chat_messages' => [
          { 'sender' => 'human', 'content' => [{ 'type' => 'text', 'text' => 'Hello' }], 'created_at' => '2025-11-01T10:00:00Z' }
        ]
      }
    ]

    conversations_json = File.join(@test_dir, 'conversations.json')
    File.write(conversations_json, JSON.generate(conversations))

    # rake web:import_conversations を実行
    run_web_import(conversations_json)

    # 有効な会話だけが保存されたことを確認（yyyymm ディレクトリ）
    year_month_dir = File.join(@vault_web_dir, '202511')

    assert(
      Dir.exist?(year_month_dir),
      'Year-month directory should exist'
    )

    # 有効な会話のファイルが存在することを確認
    markdown_files = Dir.glob(File.join(year_month_dir, '*.md'))
    assert(
      markdown_files.length > 0,
      'Valid conversation should have markdown file'
    )

    # 空の会話に関連するファイルがないことを確認（ファイル名で判定）
    markdown_files.each do |file|
      filename = File.basename(file)
      assert(!filename.include?('empty-conversation'), "Empty conversation should not create file: #{filename}")
    end
  end

  private

  def create_test_conversations_json_with(user_message:, assistant_message:, project_name:)
    # 期待値を埋め込んだテストデータを生成
    conversations = [
      {
        'uuid' => 'uuid-12345678',
        'name' => project_name,
        'chat_messages' => [
          {
            # 実データ構造: 'sender' フィールド（'role' ではなく）
            'sender' => 'human',
            # 実データ構造: content は配列形式（文字列ではなく）
            'content' => [
              {
                'type' => 'text',
                'text' => user_message
              }
            ],
            'created_at' => '2025-11-03T10:00:00Z'
          },
          {
            'sender' => 'assistant',
            'content' => [
              {
                'type' => 'text',
                'text' => assistant_message
              }
            ],
            'created_at' => '2025-11-03T10:00:05Z'
          }
        ]
      }
    ]

    conversations_json = File.join(@test_dir, 'conversations.json')
    File.write(conversations_json, JSON.generate(conversations))
    conversations_json
  end

  def run_web_import(conversations_json)
    env = {
      'CONVERSATIONS_JSON' => conversations_json,
      'CLAUDE_VAULT_PATH' => @vault_code_dir,
      'CLAUDE_WEB_VAULT_PATH' => @vault_web_dir,
      'CLAUDE_LOG_PATH' => @log_file
    }

    cmd = "cd #{Dir.pwd} && rake web:bulk_import 2>&1"

    stdout, stderr, status = Open3.capture3(env, cmd)

    output = stdout + stderr
    output.force_encoding('UTF-8').encode('UTF-8', invalid: :replace)
  end
end
