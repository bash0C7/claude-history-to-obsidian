#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'fileutils'
require 'tmpdir'

# ENV変数をテスト用に設定（lib読み込み前に定数を初期化）
ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault'
ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'

require_relative 'test_helper'
require_relative '../lib/claude_history_to_obsidian'

class TestClaudeHistoryToObsidian < Test::Unit::TestCase
  include TestHelpers

  def test_extract_session_name_from_first_user_message
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Implementing the feature for button handling'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    name = processor.send(:extract_session_name, messages)
    # 最初の30文字: "Implementing the feature for b"
    # 正規化後: "implementing-the-feature-for-b"
    assert_equal 'implementing-the-feature-for-b', name
  end

  def test_extract_session_name_with_30_char_limit
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'This is a very long session name that should be truncated to thirty characters'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    name = processor.send(:extract_session_name, messages)
    # 最初の30文字: "This is a very long session na"
    # 正規化後: "this-is-a-very-long-session-na"
    assert_equal 'this-is-a-very-long-session-na', name
  end

  def test_extract_session_name_normalizes_special_chars
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Fix bug: [ERROR] @runtime'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    name = processor.send(:extract_session_name, messages)
    # 特殊文字が-に正規化される
    assert_equal 'fix-bug-error-runtime', name
  end

  def test_extract_session_name_removes_consecutive_hyphens
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Fix   multiple    spaces'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    name = processor.send(:extract_session_name, messages)
    # 連続するハイフンが単一に圧縮される
    assert_equal 'fix-multiple-spaces', name
  end

  def test_extract_session_name_fallback_to_session
    processor = ClaudeHistoryToObsidian.new

    # 空メッセージの場合
    messages_empty = []
    name = processor.send(:extract_session_name, messages_empty)
    assert_equal 'session', name, 'Empty messages should default to "session"'

    # ユーザーメッセージがない場合
    messages_no_user = [
      {'role' => 'assistant', 'content' => 'Only assistant message'}
    ]
    name = processor.send(:extract_session_name, messages_no_user)
    assert_equal 'session', name, 'No user message should default to "session"'

    # ユーザーメッセージの内容が空の場合
    messages_empty_content = [
      {'role' => 'user', 'content' => ''}
    ]
    name = processor.send(:extract_session_name, messages_empty_content)
    assert_equal 'session', name, 'Empty user content should default to "session"'

    # 正規化後に空になる場合
    messages_special_only = [
      {'role' => 'user', 'content' => '!@#$%^&*()'}
    ]
    name = processor.send(:extract_session_name, messages_special_only)
    assert_equal 'session', name, 'Content with only special chars should default to "session"'
  end

  def test_extract_session_timestamp_from_field
    processor = ClaudeHistoryToObsidian.new
    transcript = {
      '_first_message_timestamp' => '20251103-143022',
      'messages' => []
    }

    timestamp = processor.send(:extract_session_timestamp, transcript)
    assert_equal '20251103-143022', timestamp
  end

  def test_extract_session_timestamp_from_messages
    processor = ClaudeHistoryToObsidian.new
    transcript = {
      'messages' => [
        {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'},
        {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T14:30:25.000Z'}
      ]
    }

    timestamp = processor.send(:extract_session_timestamp, transcript)
    assert_equal '20251103-143022', timestamp
  end

  def test_extract_session_timestamp_returns_nil_when_missing
    processor = ClaudeHistoryToObsidian.new

    # タイムスタンプフィールドがない場合
    transcript_no_field = {'messages' => []}
    timestamp = processor.send(:extract_session_timestamp, transcript_no_field)
    assert_nil timestamp

    # メッセージにタイムスタンプがない場合
    transcript_no_timestamp = {
      'messages' => [
        {'role' => 'user', 'content' => 'Test'}
      ]
    }
    timestamp = processor.send(:extract_session_timestamp, transcript_no_timestamp)
    assert_nil timestamp
  end

  def test_generate_filename_format
    processor = ClaudeHistoryToObsidian.new
    transcript = {
      '_first_message_timestamp' => '20251103-143022',
      'messages' => []
    }

    filename = processor.send(:generate_filename, 'test-session', 'abc12345xyz', transcript)
    assert_equal '20251103-143022_test-session_abc12345.md', filename
  end

  def test_build_markdown_structure
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'First user message'},
      {'role' => 'assistant', 'content' => 'First assistant response'},
      {'role' => 'user', 'content' => 'Second user message'},
      {'role' => 'assistant', 'content' => 'Second assistant response'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/project',
      session_id: 'abc123',
      messages: messages)

    # ヘッダー確認
    assert_include markdown, '# Claude Code Session'

    # メタデータ確認
    assert_include markdown, '**Project**: test-project'
    assert_include markdown, '**Path**: /test/project'
    assert_include markdown, '**Session ID**: abc123'
    assert_include markdown, '**Date**:'

    # ユーザー/アシスタントセクション確認
    assert_include markdown, '## 👤 User'
    assert_include markdown, '## 🤖 Claude'
    assert_include markdown, 'First user message'
    assert_include markdown, 'First assistant response'
    assert_include markdown, 'Second user message'
    assert_include markdown, 'Second assistant response'

    # セパレータ確認
    assert_include markdown, '---'

    # メッセージ順序確認（ユーザー → アシスタント → ユーザー → アシスタント）
    user_pos1 = markdown.index('First user message')
    assistant_pos1 = markdown.index('First assistant response')
    user_pos2 = markdown.index('Second user message')
    assistant_pos2 = markdown.index('Second assistant response')

    assert user_pos1 < assistant_pos1, 'First user before first assistant'
    assert assistant_pos1 < user_pos2, 'First assistant before second user'
    assert user_pos2 < assistant_pos2, 'Second user before second assistant'
  end

  # Phase 2: ファイルI/Oテスト

  def test_load_hook_input_with_valid_json
    processor = ClaudeHistoryToObsidian.new
    hook_json = {
      'session_id' => 'test123',
      'transcript_path' => '/tmp/test.json',
      'cwd' => '/test/project',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop'
    }

    result = with_stdin(JSON.generate(hook_json)) do
      processor.send(:load_hook_input)
    end

    assert_equal 'test123', result['session_id']
    assert_equal '/tmp/test.json', result['transcript_path']
    assert_equal '/test/project', result['cwd']
  end

  def test_load_hook_input_with_invalid_json
    processor = ClaudeHistoryToObsidian.new
    invalid_json = '{invalid json}'

    result = with_stdin(invalid_json) do
      processor.send(:load_hook_input)
    end

    assert_nil result, 'Invalid JSON should return nil'
  end

  def test_load_transcript_from_file
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |test_dir|
      transcript_path = File.join(test_dir, 'transcript.json')
      transcript_data = {
        'session_id' => 'test123',
        'cwd' => '/test',
        'messages' => [
          {'role' => 'user', 'content' => 'Test message'},
          {'role' => 'assistant', 'content' => 'Response'}
        ]
      }
      File.write(transcript_path, JSON.generate(transcript_data))

      result = processor.send(:load_transcript, transcript_path)

      assert_equal 'test123', result['session_id']
      assert_equal '/test', result['cwd']
      assert_equal 2, result['messages'].length
      assert_equal 'Test message', result['messages'][0]['content']
    end
  end

  def test_load_transcript_file_not_found
    processor = ClaudeHistoryToObsidian.new
    non_existent_path = '/tmp/non_existent_file_12345.json'

    result = processor.send(:load_transcript, non_existent_path)

    assert_nil result, 'Non-existent file should return nil'
  end

  def test_load_transcript_with_invalid_json
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |test_dir|
      transcript_path = File.join(test_dir, 'invalid.json')
      File.write(transcript_path, '{invalid json}')

      result = processor.send(:load_transcript, transcript_path)

      assert_nil result, 'Invalid JSON should return nil'
    end
  end

  # Phase 3: iCloud Drive依存テスト（ENV変数で隔離）

  def test_ensure_directories_creates_project_dir
    processor = ClaudeHistoryToObsidian.new

    # ENV['CLAUDE_VAULT_PATH']は既にテスト開始時に'/tmp/test-vault'に設定済み
    # ここでは VAULT_BASE_PATH定数の値を使用してテスト
    vault_path = File.join(ClaudeHistoryToObsidian::VAULT_BASE_PATH, 'test-project')

    # テスト用ディレクトリを事前にクリーンアップ
    FileUtils.rm_rf(vault_path) if Dir.exist?(vault_path)

    result = processor.send(:ensure_directories, 'test-project')

    assert_equal vault_path, result
    assert Dir.exist?(vault_path), 'Project directory should be created'

    # クリーンアップ
    FileUtils.rm_rf(vault_path)
  end

  def test_save_to_vault_writes_markdown_file
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |vault_base|
      vault_dir = File.join(vault_base, 'test-project')
      FileUtils.mkdir_p(vault_dir)

      content = "# Test\n\nThis is test content"
      filename = '20251103-143022_test-session_abc12345.md'

      processor.send(:save_to_vault, vault_dir, filename, content)

      filepath = File.join(vault_dir, filename)
      assert File.exist?(filepath), 'Markdown file should be created'

      written_content = File.read(filepath)
      assert_equal content, written_content, 'File content should match'
    end
  end

  def test_process_transcript_end_to_end
    processor = ClaudeHistoryToObsidian.new

    # ENV['CLAUDE_VAULT_PATH']は既に'/tmp/test-vault'に設定済み
    # テスト用プロジェクトディレクトリを準備
    vault_base = ClaudeHistoryToObsidian::VAULT_BASE_PATH
    project_dir = File.join(vault_base, 'test-project-e2e')

    # 前回実行のクリーンアップ
    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)

    begin
      transcript_data = {
        'session_id' => 'test-session-123',
        'cwd' => '/test/project',
        'messages' => [
          {'role' => 'user', 'content' => 'Implementing end-to-end test', 'timestamp' => '2025-11-03T10:00:00.000Z'},
          {'role' => 'assistant', 'content' => 'I will help with the test', 'timestamp' => '2025-11-03T10:00:05.000Z'}
        ],
        '_first_message_timestamp' => '20251103-100000'
      }

      # process_transcriptを呼び出す
      processor.send(:process_transcript,
        project_name: 'test-project-e2e',
        cwd: '/test/project',
        session_id: 'test-session-123',
        transcript: transcript_data,
        messages: transcript_data['messages']
      )

      # ファイルが作成されたことを確認
      assert Dir.exist?(project_dir), 'Project directory should be created'

      # ファイルリストを確認
      files = Dir.glob(File.join(project_dir, '*.md'))
      assert files.length > 0, 'Markdown files should be created'

      # ファイル名形式を確認（YYYYMMDD-HHMMSS_name_sessionid.md）
      filename = File.basename(files[0])
      assert filename.match?(/^\d{8}-\d{6}_.*_.{8}\.md$/), "Filename format should match pattern: #{filename}"
    ensure
      # クリーンアップ
      FileUtils.rm_rf(project_dir)
    end
  end
end
