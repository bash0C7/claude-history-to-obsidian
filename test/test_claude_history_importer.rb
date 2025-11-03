#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'fileutils'
require 'tmpdir'
require_relative 'test_helper'
require_relative '../lib/claude_history_importer'

class TestClaudeHistoryImporter < Test::Unit::TestCase
  include TestHelpers

  def test_parse_and_group_sessions
    Dir.mktmpdir do |test_dir|
      # テスト用 JSONL ファイルを作成
      jsonl_path = File.join(test_dir, 'test.jsonl')
      File.write(jsonl_path, <<~JSONL)
        {"sessionId":"session-001","cwd":"/test/project","message":{"role":"user","content":"Test message"},"timestamp":"2025-11-03T10:00:00.000Z"}
        {"sessionId":"session-001","cwd":"/test/project","message":{"role":"assistant","content":"Response"},"timestamp":"2025-11-03T10:00:05.000Z"}
        {"sessionId":"session-002","cwd":"/test/project","message":{"role":"user","content":"Another session"},"timestamp":"2025-11-03T11:00:00.000Z"}
      JSONL

      # プライベートメソッドを呼び出す
      importer = ClaudeHistoryImporter.new
      sessions = importer.send(:parse_and_group_sessions, jsonl_path)

      # アサーション
      assert_equal 2, sessions.length, 'Should parse 2 sessions'
      assert_true sessions.key?('session-001'), 'Should contain session-001'
      assert_true sessions.key?('session-002'), 'Should contain session-002'

      assert_equal 2, sessions['session-001'][:messages].length, 'session-001 should have 2 messages'
      assert_equal 1, sessions['session-002'][:messages].length, 'session-002 should have 1 message'

      assert_equal '/test/project', sessions['session-001'][:cwd]
      assert_equal 'user', sessions['session-001'][:messages][0]['role']
      assert_equal 'assistant', sessions['session-001'][:messages][1]['role']
    end
  end

  def test_extract_first_message_timestamp
    messages = [
      {
        'role' => 'user',
        'content' => 'Test',
        'timestamp' => '2025-11-03T10:30:45.000Z'
      },
      {
        'role' => 'assistant',
        'content' => 'Response',
        'timestamp' => '2025-11-03T10:30:50.000Z'
      }
    ]

    importer = ClaudeHistoryImporter.new
    timestamp = importer.send(:extract_first_message_timestamp, messages)

    assert_equal '20251103-103045', timestamp, 'Should extract and format timestamp correctly'
  end

  def test_extract_first_message_timestamp_empty_messages
    importer = ClaudeHistoryImporter.new
    timestamp = importer.send(:extract_first_message_timestamp, [])
    assert_nil timestamp, 'Should return nil for empty messages'
  end

  def test_extract_first_message_timestamp_no_timestamp
    messages = [
      {
        'role' => 'user',
        'content' => 'Test'
        # timestamp なし
      }
    ]

    importer = ClaudeHistoryImporter.new
    timestamp = importer.send(:extract_first_message_timestamp, messages)
    assert_nil timestamp, 'Should return nil when timestamp is missing'
  end

  def test_parse_empty_jsonl
    Dir.mktmpdir do |test_dir|
      jsonl_path = File.join(test_dir, 'empty.jsonl')
      File.write(jsonl_path, '')

      importer = ClaudeHistoryImporter.new
      sessions = importer.send(:parse_and_group_sessions, jsonl_path)
      assert_equal 0, sessions.length, 'Empty JSONL should result in 0 sessions'
    end
  end

  def test_process_session_outputs_hook_json
    # シンプルなセッションデータを作成
    messages = [
      {
        'role' => 'user',
        'content' => 'Test message',
        'timestamp' => '2025-11-03T10:00:00.000Z'
      },
      {
        'role' => 'assistant',
        'content' => 'Response',
        'timestamp' => '2025-11-03T10:00:05.000Z'
      }
    ]

    session_data = {
      messages: messages,
      cwd: '/test/project'
    }

    # 標準出力をキャプチャ
    importer = ClaudeHistoryImporter.new
    output = capture_stdout do
      importer.send(:process_session, 'test-session-123', session_data)
    end.strip

    # Hook JSON をパース
    hook_json = JSON.parse(output)

    # アサーション
    assert_equal 'test-session-123', hook_json['session_id']
    assert_equal '/test/project', hook_json['cwd']
    assert_equal 'default', hook_json['permission_mode']
    assert_equal 'Stop', hook_json['hook_event_name']

    # transcript が埋め込まれていることを確認
    assert_not_nil hook_json['transcript'], 'transcript should be embedded'
    assert_equal 'test-session-123', hook_json['transcript']['session_id']
    assert_equal 2, hook_json['transcript']['messages'].length
    assert_equal '20251103-100000', hook_json['transcript']['_first_message_timestamp']
  end

  def test_run_with_multiple_jsonl_paths
    Dir.mktmpdir do |test_dir|
      # 2つのJSONLファイルを作成
      jsonl1 = File.join(test_dir, 'file1.jsonl')
      jsonl2 = File.join(test_dir, 'file2.jsonl')

      File.write(jsonl1, '{"sessionId":"session-001","cwd":"/test/project1","message":{"role":"user","content":"test"},"timestamp":"2025-11-03T10:00:00.000Z"}')
      File.write(jsonl2, '{"sessionId":"session-002","cwd":"/test/project2","message":{"role":"user","content":"test"},"timestamp":"2025-11-03T11:00:00.000Z"}')

      importer = ClaudeHistoryImporter.new
      output = capture_stdout do
        with_stdin("#{jsonl1}\n#{jsonl2}\n") do
          importer.run
        end
      end

      # 2つのHook JSONが出力されることを確認
      lines = output.strip.split("\n")
      assert_equal 2, lines.length, '2つのJSONL入力で2つのHook JSONが出力されるべき'

      # 各Hook JSONがパース可能であることを確認
      hook1 = JSON.parse(lines[0])
      hook2 = JSON.parse(lines[1])

      assert_equal 'session-001', hook1['session_id']
      assert_equal 'session-002', hook2['session_id']
    end
  end

  def test_run_with_empty_input
    importer = ClaudeHistoryImporter.new
    output = capture_stdout do
      with_stdin('') do
        importer.run
      end
    end

    # 空入力では出力がないことを確認
    assert_equal '', output.strip, '空入力では出力がないべき'
  end

  def test_import_from_jsonl_file_not_found
    Dir.mktmpdir do |test_dir|
      non_existent_path = File.join(test_dir, 'non_existent.jsonl')
      importer = ClaudeHistoryImporter.new

      # ファイル不存在時はエラーが出力されるはず
      output = capture_stdout do
        importer.send(:import_from_jsonl, non_existent_path)
      end

      # import_from_jsonlはログ出力するため、出力は空（stderr）
      # そのため、呼び出し自体がエラーを引き起こさないことを確認
    end
  end
end
