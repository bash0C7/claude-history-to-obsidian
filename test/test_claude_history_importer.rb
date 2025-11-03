#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'fileutils'
require_relative '../lib/claude_history_importer'

class TestClaudeHistoryImporter < Test::Unit::TestCase
  def setup
    @test_dir = Dir.mktmpdir
    @importer = ClaudeHistoryImporter.new
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end

  def test_parse_and_group_sessions
    # テスト用 JSONL ファイルを作成
    jsonl_path = File.join(@test_dir, 'test.jsonl')
    File.write(jsonl_path, <<~JSONL)
      {"sessionId":"session-001","cwd":"/test/project","message":{"role":"user","content":"Test message"},"timestamp":"2025-11-03T10:00:00.000Z"}
      {"sessionId":"session-001","cwd":"/test/project","message":{"role":"assistant","content":"Response"},"timestamp":"2025-11-03T10:00:05.000Z"}
      {"sessionId":"session-002","cwd":"/test/project","message":{"role":"user","content":"Another session"},"timestamp":"2025-11-03T11:00:00.000Z"}
    JSONL

    # プライベートメソッドを呼び出す
    sessions = @importer.send(:parse_and_group_sessions, jsonl_path)

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

    timestamp = @importer.send(:extract_first_message_timestamp, messages)

    assert_equal '20251103-103045', timestamp, 'Should extract and format timestamp correctly'
  end

  def test_extract_first_message_timestamp_empty_messages
    timestamp = @importer.send(:extract_first_message_timestamp, [])
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

    timestamp = @importer.send(:extract_first_message_timestamp, messages)
    assert_nil timestamp, 'Should return nil when timestamp is missing'
  end

  def test_parse_empty_jsonl
    jsonl_path = File.join(@test_dir, 'empty.jsonl')
    File.write(jsonl_path, '')

    sessions = @importer.send(:parse_and_group_sessions, jsonl_path)
    assert_equal 0, sessions.length, 'Empty JSONL should result in 0 sessions'
  end
end
