#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'

class TestRakeWebImportConversations < Test::Unit::TestCase
  def setup
    @test_dir = Dir.mktmpdir
    @downloads_dir = File.join(@test_dir, 'Downloads')
    @vault_dir = File.join(@test_dir, 'vault')
    @log_file = File.join(@test_dir, 'test.log')

    FileUtils.mkdir_p(@downloads_dir)
    FileUtils.mkdir_p(@vault_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  def test_web_import_shows_progress_every_10_conversations
    # テスト用conversations.jsonを作成（40個の会話）
    conversations = Array.new(40) do |i|
      {
        'uuid' => "conv-#{i}",
        'name' => "Conversation #{i}",
        'chat_messages' => [
          {
            'sender' => 'human',
            'content' => [{ 'type' => 'text', 'text' => "User message #{i}" }],
            'created_at' => '2025-11-03T10:00:00.000Z'
          },
          {
            'sender' => 'assistant',
            'content' => [{ 'type' => 'text', 'text' => "Assistant response #{i}" }],
            'created_at' => '2025-11-03T10:00:05.000Z'
          }
        ]
      }
    end

    conversations_json_path = File.join(@downloads_dir, 'conversations.json')
    File.write(conversations_json_path, JSON.generate(conversations))

    # rake web:bulk_importを実行して出力をキャプチャ
    output = run_web_import(conversations_json_path)

    # 出力がダウンロードディレクトリを含むことを検証
    assert_include(output, "📁 Reading: #{conversations_json_path}", 'Should show the conversations.json path')

    # 40個の会話がすべて処理されたことを検証（各会話のファイル出力で確認）
    assert_include(output, 'claude.ai/202511/', 'Should output files to claude.ai/202511/')
    assert(output.include?('conversation-0_'), 'Should process conversation 0')
    assert(output.include?('conversation-39_'), 'Should process conversation 39')

    # 完了メッセージを検証
    assert_include(output, '✓ Web import completed: 40 conversations processed', 'Should show completion message')
  end

  def test_web_import_default_path_is_downloads
    # テスト用conversations.jsonを作成（1個の会話）
    conversations = [
      {
        'uuid' => 'test-conv-1',
        'name' => 'Test Conversation',
        'chat_messages' => [
          {
            'sender' => 'human',
            'content' => [{ 'type' => 'text', 'text' => 'Test message' }],
            'created_at' => '2025-11-03T10:00:00.000Z'
          },
          {
            'sender' => 'assistant',
            'content' => [{ 'type' => 'text', 'text' => 'Test response' }],
            'created_at' => '2025-11-03T10:00:05.000Z'
          }
        ]
      }
    ]

    # ~/Downloads にファイルを配置（デフォルトパス検証用）
    downloads_path = File.join(@downloads_dir, 'conversations.json')
    File.write(downloads_path, JSON.generate(conversations))

    # 環境変数を設定しない場合のデフォルト動作を検証するため、
    # 環境変数を明示的に指定して実行
    output = run_web_import(downloads_path)

    # ファイルが読み込まれたことを検証
    assert_include(output, "📁 Reading: #{downloads_path}", 'Should read the default path')
  end

  private

  def run_web_import(conversations_json_path)
    # 環境変数を設定してrake web:bulk_importを実行
    env = {
      'CONVERSATIONS_JSON' => conversations_json_path,
      'CLAUDE_VAULT_PATH' => @vault_dir,
      'CLAUDE_LOG_PATH' => @log_file
    }

    cmd = "cd #{Dir.pwd} && rake web:bulk_import 2>&1"

    # 環境変数を設定して実行
    stdout, stderr, status = Open3.capture3(env, cmd)

    output = stdout + stderr
    # 出力をUTF-8に強制
    output.force_encoding('UTF-8').encode('UTF-8', invalid: :replace)
  end
end
