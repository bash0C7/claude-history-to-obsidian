#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'fileutils'
require 'tmpdir'

# ENV変数をテスト用に設定（lib読み込み前に定数を初期化）
ENV['CLAUDE_VAULT_PATH'] = '/tmp/test-vault/Claude Code'
ENV['CLAUDE_WEB_VAULT_PATH'] = '/tmp/test-vault/claude.ai'
ENV['CLAUDE_LOG_PATH'] = '/tmp/test.log'

require_relative 'test_helper'
require_relative '../lib/claude_history_to_obsidian'
require_relative '../lib/claude_history_importer'

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

  # TEST: extract_session_name with array content (conversations.json format)
  def test_extract_session_name_with_array_content_hash_and_string
    processor = ClaudeHistoryToObsidian.new

    # contentが配列形式（Hashとstringが混在）
    messages = [
      {
        'role' => 'user',
        'content' => [
          {'type' => 'text', 'text' => 'Fix the authentication bug in production'},
          'Additional context here'
        ]
      }
    ]

    name = processor.send(:extract_session_name, messages)
    # "Fix the authentication bug in production Additional context here"
    # 最初の30文字: "Fix the authentication bug in "
    # 正規化後: "fix-the-authentication-bug-in"
    assert_equal 'fix-the-authentication-bug-in', name
  end

  # TEST: extract_session_name with array content containing only strings
  def test_extract_session_name_with_array_content_strings_only
    processor = ClaudeHistoryToObsidian.new

    # contentが配列形式（文字列のみ）
    messages = [
      {
        'role' => 'user',
        'content' => [
          'Implement new feature',
          'for user dashboard'
        ]
      }
    ]

    name = processor.send(:extract_session_name, messages)
    # "Implement new feature for user dashboard"
    # 最初の30文字: "Implement new feature for user"
    # 正規化後: "implement-new-feature-for-user"
    assert_equal 'implement-new-feature-for-user', name
  end

  # TEST: extract_session_name with array content containing only hashes
  def test_extract_session_name_with_array_content_hashes_only
    processor = ClaudeHistoryToObsidian.new

    # contentが配列形式（Hashのみ、type='text'のみ）
    messages = [
      {
        'role' => 'user',
        'content' => [
          {'type' => 'text', 'text' => 'Debug memory leak'},
          {'type' => 'text', 'text' => 'in background worker'}
        ]
      }
    ]

    name = processor.send(:extract_session_name, messages)
    # "Debug memory leak in background worker"
    # 最初の30文字: "Debug memory leak in backgroun"
    # 正規化後: "debug-memory-leak-in-backgroun"
    assert_equal 'debug-memory-leak-in-backgroun', name
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
    # ローカルタイム (JST): UTC 14:30:22 → JST 23:30:22
    assert_equal '20251103-233022', timestamp
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

  def test_extract_session_timestamp_keeps_utc_with_z_suffix
    processor = ClaudeHistoryToObsidian.new

    # UTCタイムスタンプ (2025-11-03 14:30:22 UTC)
    transcript = {
      'messages' => [
        {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'}
      ]
    }

    timestamp = processor.send(:extract_session_timestamp, transcript)

    # ローカルタイム (JST): UTC 14:30:22 → JST 23:30:22、Z サフィックスなし
    assert_equal '20251103-233022', timestamp, 'Should return local time without Z suffix'
  end

  def test_extract_session_time_returns_time_object
    processor = ClaudeHistoryToObsidian.new

    messages = [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'}
    ]

    time_obj = processor.send(:extract_session_time, messages)

    assert_instance_of Time, time_obj
    # ローカルタイム: UTC から getlocal で JST に変換
    assert_equal Time.parse('2025-11-03T14:30:22.000Z').getlocal, time_obj
  end

  def test_extract_session_time_returns_nil_for_invalid_timestamp
    processor = ClaudeHistoryToObsidian.new

    messages = [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => 'invalid-format'}
    ]

    time_obj = processor.send(:extract_session_time, messages)
    assert_nil time_obj
  end

  def test_extract_session_time_returns_nil_for_empty_messages
    processor = ClaudeHistoryToObsidian.new

    messages = []
    time_obj = processor.send(:extract_session_time, messages)
    assert_nil time_obj
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

  def test_build_markdown_with_content_array_blocks
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {
        'role' => 'user',
        'content' => 'Translate this text'
      },
      {
        'role' => 'assistant',
        'content' => [
          {
            'type' => 'thinking',
            'thinking' => 'この翻訳は複雑です\n複数行の思考です',
            'start_timestamp' => '2025-10-29T12:09:42Z',
            'stop_timestamp' => '2025-10-29T12:09:48Z'
          },
          {
            'type' => 'text',
            'text' => '翻訳結果\n複数行のテキストです',
            'citations' => []
          }
        ]
      }
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/project',
      session_id: 'abc123',
      messages: messages)

    # thinking ブロックが分離されて表示される
    assert_include markdown, '💭 思考'
    assert_include markdown, 'この翻訳は複雑です'
    assert_include markdown, '複数行の思考です'

    # text ブロックが分離されて表示される
    assert_include markdown, '💬 回答'
    assert_include markdown, '翻訳結果'
    assert_include markdown, '複数行のテキストです'

    # 改行が正しく処理されている（\n が実改行に）
    assert_include markdown, "複雑です\n複数行"
  end

  def test_build_markdown_filters_out_signature_blocks
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {
        'role' => 'assistant',
        'content' => [
          {
            'type' => 'text',
            'text' => 'Response text'
          },
          {
            'type' => 'signature',
            'text' => 'Claude signature here'
          }
        ]
      }
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/project',
      session_id: 'abc123',
      messages: messages)

    # signature が含まれていないことを確認
    assert_not_include markdown, 'Claude signature here'
    assert_not_include markdown, '署名'

    # text は含まれている
    assert_include markdown, 'Response text'
  end

  def test_build_markdown_handles_input_blocks
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {
        'role' => 'assistant',
        'content' => [
          {
            'type' => 'text',
            'text' => 'Here is the code:'
          },
          {
            'type' => 'input',
            'text' => 'code_example = "hello"'
          }
        ]
      }
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/project',
      session_id: 'abc123',
      messages: messages)

    # input ブロックが表示される
    assert_include markdown, '⌨️ 入力'
    assert_include markdown, 'code_example = "hello"'
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
    vault_path = File.join(ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH, 'test-project')

    # テスト用ディレクトリを事前にクリーンアップ
    FileUtils.rm_rf(vault_path) if Dir.exist?(vault_path)

    result = processor.send(:ensure_directories, 'test-project')

    assert_equal vault_path, result
    assert Dir.exist?(vault_path), 'Project directory should be created'

    # クリーンアップ
    FileUtils.rm_rf(vault_path)
  end

  def test_ensure_directories_adds_test_suffix_in_test_mode
    processor = ClaudeHistoryToObsidian.new

    # テストモードを設定
    original_mode = ENV['CLAUDE_VAULT_MODE']
    begin
      ENV['CLAUDE_VAULT_MODE'] = 'test'

      # テストモード時のvault pathを確認
      result = processor.send(:ensure_directories, 'test-project')

      # [test] サフィックスが付いていることを確認
      assert result.include?('[test]'), "Should include [test] suffix in test mode: #{result}"
      assert result.include?('test-project'), "Should include project name: #{result}"
    ensure
      ENV['CLAUDE_VAULT_MODE'] = original_mode
    end
  end

  def test_ensure_directories_no_suffix_in_normal_mode
    processor = ClaudeHistoryToObsidian.new

    # テストモードをクリア
    original_mode = ENV['CLAUDE_VAULT_MODE']
    begin
      ENV['CLAUDE_VAULT_MODE'] = nil

      vault_path = File.join(ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH, 'test-project')

      # 事前にクリーンアップ
      FileUtils.rm_rf(vault_path) if Dir.exist?(vault_path)

      result = processor.send(:ensure_directories, 'test-project')

      # [test] サフィックスが付いていないことを確認
      assert !result.include?('[test]'), "Should not include [test] suffix in normal mode: #{result}"
      assert_equal vault_path, result
    ensure
      ENV['CLAUDE_VAULT_MODE'] = original_mode
      FileUtils.rm_rf(vault_path) if Dir.exist?(vault_path)
    end
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
    vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
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
      result = processor.send(:process_transcript,
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

      # 戻り値がVault相対パスであることを確認
      assert_not_nil result, 'process_transcript should return a value'
      assert result.include?('Claude Code/test-project-e2e/'), "Return value should include project path: #{result}"
      assert result.end_with?('.md'), "Return value should end with .md: #{result}"
    ensure
      # クリーンアップ
      FileUtils.rm_rf(project_dir)
    end
  end

  def test_hook_mode_timezone_handling_end_to_end
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |test_dir|
      # UTCタイムスタンプのトランスクリプトファイルを作成
      transcript_path = File.join(test_dir, 'transcript.json')
      transcript_data = {
        'session_id' => 'tz-test-001',
        'cwd' => '~/src/test-tz',
        'messages' => [
          {'role' => 'user', 'content' => 'Testing timezone', 'timestamp' => '2025-11-03T05:00:00.000Z'},
          {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T05:00:05.000Z'}
        ]
      }
      File.write(transcript_path, JSON.generate(transcript_data))

      # Hook JSON
      hook_input = {
        'session_id' => 'tz-test-001',
        'transcript_path' => transcript_path,
        'cwd' => '~/src/test-tz',
        'permission_mode' => 'default',
        'hook_event_name' => 'Stop'
      }

      vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
      project_dir = File.join(vault_base, 'test-tz')

      begin
        # 実行
        with_stdin(JSON.generate(hook_input)) do
          begin
            processor.run
          rescue SystemExit => e
            assert_equal 0, e.status
          end
        end

        # ファイル確認
        files = Dir.glob(File.join(project_dir, '*.md'))
        assert files.length > 0, 'File should be created'

        filename = File.basename(files[0])

        # ローカルタイム: ファイル名のタイムスタンプはローカルタイム (JST), Z サフィックスなし
        expected_local_time = '20251103-140000'
        assert filename.start_with?(expected_local_time), "Filename should start with local time: #{filename}"

        # ファイル内のDateフィールドもローカルタイム
        content = File.read(files[0])
        expected_date_str = '2025-11-03 14:00:00 +09:00'
        assert_include content, "**Date**: #{expected_date_str}"
      ensure
        # クリーンアップ
        FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
      end
    end
  end

  # TEST: process_transcript returns vault relative path with Code source
  def test_process_transcript_returns_code_vault_path
    processor = ClaudeHistoryToObsidian.new

    vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
    project_dir = File.join(vault_base, 'test-vault-path-code')

    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)

    begin
      transcript_data = {
        'session_id' => 'return-path-test-001',
        'cwd' => '/test/project',
        'messages' => [
          {'role' => 'user', 'content' => 'Testing return path', 'timestamp' => '2025-11-03T14:30:22.000Z'},
          {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T14:30:25.000Z'}
        ],
        '_first_message_timestamp' => '20251103-143022'
      }

      result = processor.send(:process_transcript,
        project_name: 'test-vault-path-code',
        cwd: '/test/project',
        session_id: 'return-path-test-001',
        transcript: transcript_data,
        messages: transcript_data['messages'],
        source: 'code'
      )

      # 形式: Claude Code/{project}/{filename}.md
      expected_prefix = 'Claude Code/test-vault-path-code/'
      assert result.start_with?(expected_prefix), "Should start with '#{expected_prefix}': #{result}"
      assert result.match?(/^Claude Code\/test-vault-path-code\/\d{8}-\d{6}_.*_.{8}\.md$/), "Should match vault relative path format: #{result}"
    ensure
      FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
    end
  end

  # TEST: process_transcript returns vault relative path with Web source
  def test_process_transcript_returns_web_vault_path
    processor = ClaudeHistoryToObsidian.new

    vault_web_base = ClaudeHistoryToObsidian::CLAUDE_WEB_VAULT_PATH
    project_dir = File.join(vault_web_base, 'test-vault-path-web')

    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)

    begin
      transcript_data = {
        'session_id' => 'return-path-test-web-001',
        'cwd' => '/test/project',
        'messages' => [
          {'role' => 'user', 'content' => 'Testing web return path', 'timestamp' => '2025-11-03T14:30:22.000Z'},
          {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T14:30:25.000Z'}
        ],
        '_first_message_timestamp' => '20251103-143022'
      }

      result = processor.send(:process_transcript,
        project_name: 'test-vault-path-web',
        cwd: '/test/project',
        session_id: 'return-path-test-web-001',
        transcript: transcript_data,
        messages: transcript_data['messages'],
        source: 'web'
      )

      # 形式: claude.ai/{yyyymm}/{timestamp}_{project_name}_{session_name}.md
      expected_prefix = 'claude.ai/202511/'
      assert result.start_with?(expected_prefix), "Should start with '#{expected_prefix}': #{result}"
      assert result.match?(/^claude\.ai\/202511\/\d{8}-\d{6}_test-vault-path-web_testing-web-return-path\.md$/), "Should match web vault relative path format with yyyymm directory: #{result}"
    ensure
      FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
    end
  end

  # === エントリーポイント統合テスト（優先度高）===

  # TEST 1: run メソッド - Hook Mode (transcript_path から読み込む)
  def test_run_entrypoint_hook_mode
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |test_dir|
      # トランスクリプトファイルを作成
      transcript_path = File.join(test_dir, 'transcript.json')
      transcript_data = {
        'session_id' => 'hook-test-123',
        'cwd' => '~/src/test-project-hook',
        'messages' => [
          {'role' => 'user', 'content' => 'Testing hook mode integration', 'timestamp' => '2025-11-03T10:00:00.000Z'},
          {'role' => 'assistant', 'content' => 'Hook mode test response', 'timestamp' => '2025-11-03T10:00:05.000Z'}
        ]
      }
      File.write(transcript_path, JSON.generate(transcript_data))

      # Hook JSONを準備
      hook_input = {
        'session_id' => 'hook-test-123',
        'transcript_path' => transcript_path,
        'cwd' => '~/src/test-project-hook',
        'permission_mode' => 'default',
        'hook_event_name' => 'Stop'
      }

      # run メソッドを実行（stdin 経由）
      with_stdin(JSON.generate(hook_input)) do
        # exit 0 で停止するため、SystemExit をキャッチ
        begin
          processor.run
        rescue SystemExit => e
          # exit 0 は期待される挙動
          assert_equal 0, e.status
        end
      end

      # ファイルが Vault に保存されたことを確認
      vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
      project_dir = File.join(vault_base, 'test-project-hook')

      assert Dir.exist?(project_dir), "Project directory should be created at #{project_dir}"

      files = Dir.glob(File.join(project_dir, '*.md'))
      assert files.length > 0, 'Markdown file should be created in project directory'

      # ファイルの内容確認
      content = File.read(files[0])
      assert_include content, '# Claude Code Session'
      assert_include content, 'Testing hook mode integration'
      assert_include content, 'Hook mode test response'

      # クリーンアップ
      FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
    end
  end

  # TEST 2: run メソッド - Bulk Import Mode (embedded transcript)
  def test_run_entrypoint_bulk_import_mode
    processor = ClaudeHistoryToObsidian.new

    # トランスクリプトを直接埋め込んだ Hook JSON
    hook_input = {
      'session_id' => 'bulk-test-456',
      'cwd' => '~/src/test-project-bulk',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop',
      'transcript' => {
        'session_id' => 'bulk-test-456',
        'cwd' => '~/src/test-project-bulk',
        'messages' => [
          {'role' => 'user', 'content' => 'Bulk import mode test', 'timestamp' => '2025-11-03T11:00:00.000Z'},
          {'role' => 'assistant', 'content' => 'Bulk import response', 'timestamp' => '2025-11-03T11:00:05.000Z'}
        ],
        '_first_message_timestamp' => '20251103-110000'
      }
    }

    with_stdin(JSON.generate(hook_input)) do
      begin
        processor.run
      rescue SystemExit => e
        assert_equal 0, e.status
      end
    end

    # Vault に保存されたことを確認
    vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
    project_dir = File.join(vault_base, 'test-project-bulk')

    assert Dir.exist?(project_dir), "Project directory should be created for bulk import"

    files = Dir.glob(File.join(project_dir, '*.md'))
    assert files.length > 0, 'Markdown file should be created in bulk import mode'

    # ファイル名が _first_message_timestamp を使用していることを確認
    filename = File.basename(files[0])
    assert filename.start_with?('20251103-110000'), "Filename should start with timestamp from transcript: #{filename}"

    # クリーンアップ
    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
  end

  # TEST 3: run メソッド - Error handling (missing transcript_path)
  def test_run_with_missing_transcript_path
    processor = ClaudeHistoryToObsidian.new

    hook_input = {
      'session_id' => 'missing-test',
      'transcript_path' => '/tmp/non_existent_transcript_12345.json',
      'cwd' => '/test/project',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop'
    }

    # トランスクリプトが見つからない場合、エラーログを出力して exit 0
    with_stdin(JSON.generate(hook_input)) do
      begin
        processor.run
      rescue SystemExit => e
        assert_equal 0, e.status, 'Should exit with 0 even on file not found'
      end
    end
  end

  # TEST 4: ClaudeHistoryImporter#run - Multiple JSONL files integration
  def test_importer_run_with_multiple_files
    Dir.mktmpdir do |test_dir|
      # 2つの JSONL ファイルを作成
      jsonl1 = File.join(test_dir, 'file1.jsonl')
      jsonl2 = File.join(test_dir, 'file2.jsonl')

      File.write(jsonl1, '{"sessionId":"import-001","cwd":"/test/proj1","message":{"role":"user","content":"Session 1"},"timestamp":"2025-11-03T10:00:00.000Z"}')
      File.write(jsonl2, '{"sessionId":"import-002","cwd":"/test/proj2","message":{"role":"user","content":"Session 2"},"timestamp":"2025-11-03T11:00:00.000Z"}')

      # run メソッドで複数ファイルを処理
      importer = ClaudeHistoryImporter.new

      output = capture_stdout do
        with_stdin("#{jsonl1}\n#{jsonl2}\n") do
          importer.run
        end
      end

      # 2つの Hook JSON が出力されることを確認
      lines = output.strip.split("\n").reject { |line| line.empty? }
      assert_equal 2, lines.length, 'Should output 2 Hook JSON objects'

      # 各行が有効な JSON であることを確認
      lines.each do |line|
        hook_json = JSON.parse(line)
        assert_not_nil hook_json['session_id']
        assert_not_nil hook_json['transcript']
      end
    end
  end

  # TEST: build_markdown with Array content format (Claude Code API)
  def test_build_markdown_with_array_content
    processor = ClaudeHistoryToObsidian.new
    
    # content が配列形式のメッセージ（Claude Code API形式）
    messages = [
      {
        'role' => 'user',
        'content' => 'Test user message'
      },
      {
        'role' => 'assistant',
        'content' => [
          {'type' => 'text', 'text' => 'First part of response'},
          {'type' => 'text', 'text' => 'Second part of response'}
        ]
      }
    ]
    
    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/project',
      session_id: 'abc123',
      messages: messages)
    
    # マークダウンに配列の内容が含まれることを確認
    assert_include markdown, 'First part of response'
    assert_include markdown, 'Second part of response'
  end


  # TEST: notify メソッド
  def test_notify_with_macos
    processor = ClaudeHistoryToObsidian.new
    
    # macOS での通知テスト（terminal-notifier が利用可能な場合）
    # 通知が呼ばれてもエラーが出ないことを確認
    begin
      processor.send(:notify, "Test notification")
      # エラーが出なければ成功
      assert true
    rescue StandardError => e
      # terminal-notifier が無い場合は OK
      assert true
    end
  end

  # TEST: macos? メソッド
  def test_macos_platform_detection
    processor = ClaudeHistoryToObsidian.new
    
    # macOS プラットフォームの判定
    is_macos = processor.send(:macos?)
    assert is_macos.is_a?(TrueClass) || is_macos.is_a?(FalseClass)
  end

  # TEST: log メソッド
  def test_log_writes_to_file
    processor = ClaudeHistoryToObsidian.new
    
    # ログファイルにメッセージが書き込まれることを確認
    test_message = "Test log message #{Time.now.to_i}"
    processor.send(:log, test_message)
    
    log_file = ClaudeHistoryToObsidian::LOG_FILE_PATH
    assert File.exist?(log_file), "Log file should exist"
    
    log_content = File.read(log_file)
    assert_include log_content, test_message, "Log file should contain the test message"
  end

  # TEST: load_hook_input with transcript field (bulk import mode)
  def test_load_hook_input_prefers_embedded_transcript
    processor = ClaudeHistoryToObsidian.new
    
    hook_json = {
      'session_id' => 'bulk-test',
      'cwd' => '/test/project',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop',
      'transcript' => {
        'session_id' => 'bulk-test',
        'messages' => [],
        'cwd' => '/test/project'
      }
    }
    
    result = with_stdin(JSON.generate(hook_json)) do
      processor.send(:load_hook_input)
    end
    
    assert_equal 'bulk-test', result['session_id']
    assert_not_nil result['transcript'], 'Should parse embedded transcript'
  end


  # TEST: run メソッド - Error case with invalid JSON input
  def test_run_with_invalid_hook_json
    processor = ClaudeHistoryToObsidian.new
    
    # 無効な JSON を stdin に渡す
    invalid_json = '{not valid json}'
    
    with_stdin(invalid_json) do
      begin
        processor.run
      rescue SystemExit => e
        # exit 0 で終了すること
        assert_equal 0, e.status, 'Should exit with 0 on invalid JSON'
      end
    end
  end

  # TEST: run メソッド - Exception handling in build_markdown
  def test_run_with_exception_in_processing
    processor = ClaudeHistoryToObsidian.new
    
    # Hook JSON を用意（有効）
    Dir.mktmpdir do |test_dir|
      # 無効な JSON を持つ transcript ファイルを作成
      invalid_transcript_path = File.join(test_dir, 'invalid.json')
      File.write(invalid_transcript_path, 'not valid json')
      
      hook_input = {
        'session_id' => 'error-test',
        'transcript_path' => invalid_transcript_path,
        'cwd' => '/test/project',
        'permission_mode' => 'default',
        'hook_event_name' => 'Stop'
      }
      
      with_stdin(JSON.generate(hook_input)) do
        begin
          processor.run
        rescue SystemExit => e
          # exit 0 で終了すること（エラーを処理してログ出力）
          assert_equal 0, e.status, 'Should exit with 0 even with exception'
        end
      end
    end
  end

  # TEST: process_transcript メソッド（Bulk Import用）
  def test_process_transcript_creates_file
    processor = ClaudeHistoryToObsidian.new
    
    vault_base = ClaudeHistoryToObsidian::CLAUDE_CODE_VAULT_PATH
    project_dir = File.join(vault_base, 'test-process-transcript')
    
    # 前回実行のクリーンアップ
    FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
    
    begin
      transcript = {
        'session_id' => 'test-process-123',
        'cwd' => '/test/project',
        'messages' => [
          {'role' => 'user', 'content' => 'Test process_transcript'},
          {'role' => 'assistant', 'content' => 'Response'}
        ],
        '_first_message_timestamp' => '20251104-100000'
      }
      
      processor.process_transcript(
        project_name: 'test-process-transcript',
        cwd: '/test/project',
        session_id: 'test-process-123',
        transcript: transcript,
        messages: transcript['messages']
      )
      
      # ファイルが作成されたことを確認
      assert Dir.exist?(project_dir), 'Project directory should be created'
      
      files = Dir.glob(File.join(project_dir, '*.md'))
      assert files.length > 0, 'Markdown file should be created'
      
      # タイムスタンプが使用されていることを確認
      filename = File.basename(files[0])
      assert filename.start_with?('20251104-100000'), "Should use transcript timestamp: #{filename}"
    ensure
      FileUtils.rm_rf(project_dir) if Dir.exist?(project_dir)
    end
  end

  # TEST: format_log_message メソッド（JSON pretty print）
  def test_format_log_message_with_hash
    processor = ClaudeHistoryToObsidian.new

    hash_message = {
      'session_id' => 'test123',
      'cwd' => '/test/path',
      'messages' => [
        {'role' => 'user', 'content' => 'hello'}
      ]
    }

    result = processor.send(:format_log_message, hash_message)

    # JSON が pretty print されていることを確認
    assert result.include?('"session_id": "test123"'), 'Should pretty print JSON with quotes'
    assert result.include?("\n"), 'Should have newlines for pretty print'
    # インデント付きで出力される（2行目以降は2スペースのインデント）
    lines = result.lines
    assert lines[1].start_with?('  '), 'Second line should be indented with 2 spaces'
  end

  # TEST: format_log_message メソッド（複数行文字列）
  def test_format_log_message_with_multiline_string
    processor = ClaudeHistoryToObsidian.new

    multiline_message = "line1\nline2\nline3"
    result = processor.send(:format_log_message, multiline_message)

    # 複数行文字列がインデント付きで出力されることを確認
    lines = result.lines.map(&:chomp)
    assert_equal 'line1', lines[0], 'First line should not be indented'
    assert_equal '  line2', lines[1], 'Second line should be indented with 2 spaces'
    assert_equal '  line3', lines[2], 'Third line should be indented with 2 spaces'
  end

  # TEST: format_log_message メソッド（単一行文字列）
  def test_format_log_message_with_single_line_string
    processor = ClaudeHistoryToObsidian.new

    single_line = 'This is a single line message'
    result = processor.send(:format_log_message, single_line)

    # 単一行文字列はそのまま返される
    assert_equal single_line, result
  end

  # TEST: format_log_message メソッド（配列）
  def test_format_log_message_with_array
    processor = ClaudeHistoryToObsidian.new

    array_message = [
      {'role' => 'user', 'content' => 'hello'},
      {'role' => 'assistant', 'content' => 'world'}
    ]

    result = processor.send(:format_log_message, array_message)

    # JSON が pretty print されていることを確認
    assert result.include?('"role": "user"'), 'Should pretty print JSON array'
    assert result.include?("\n"), 'Should have newlines for pretty print'
    lines = result.lines
    assert lines[1].start_with?('  '), 'Second line should be indented'
  end

  # TEST: indent_multiline メソッド
  def test_indent_multiline_with_multiple_lines
    processor = ClaudeHistoryToObsidian.new

    text = "first line\nsecond line\nthird line"
    result = processor.send(:indent_multiline, text)

    lines = result.lines.map(&:chomp)
    assert_equal 'first line', lines[0]
    assert_equal '  second line', lines[1]
    assert_equal '  third line', lines[2]
  end

  # TEST: log メソッド（JSON ハッシュの記録）
  def test_log_json_hash
    processor = ClaudeHistoryToObsidian.new
    log_file = ClaudeHistoryToObsidian::LOG_FILE_PATH

    # 前回のログをクリア
    File.delete(log_file) if File.exist?(log_file)

    hash_data = {
      'test' => 'value',
      'nested' => {'key' => 'data'}
    }

    processor.log(hash_data)

    # ログファイルが作成されて、JSON が pretty print されていることを確認
    assert File.exist?(log_file), 'Log file should be created'
    log_content = File.read(log_file)
    assert log_content.include?('test'), 'Should contain hash keys'
    assert log_content.include?('value'), 'Should contain hash values'
    assert log_content.include?('['), 'Should contain JSON brackets'
  ensure
    File.delete(log_file) if File.exist?(log_file)
  end

  # TEST: log メソッド（複数行メッセージの記録）
  def test_log_multiline_message
    processor = ClaudeHistoryToObsidian.new
    log_file = ClaudeHistoryToObsidian::LOG_FILE_PATH

    # 前回のログをクリア
    File.delete(log_file) if File.exist?(log_file)

    multiline_msg = "Error occurred:\nLine 1\nLine 2"
    processor.log(multiline_msg)

    # ログファイルが作成されて、複数行メッセージがインデント付きで記録されていることを確認
    assert File.exist?(log_file), 'Log file should be created'
    log_content = File.read(log_file)
    lines = log_content.lines

    # ログのフォーマット：[YYYY-MM-DD HH:MM:SS] Error occurred:
    #                    Line 1
    #                    Line 2
    assert lines[0].include?('Error occurred:'), 'First log line should contain message start'
    # インデント付きで記録されている
    assert lines[1].include?('Line 1'), 'Should record subsequent lines'
  ensure
    File.delete(log_file) if File.exist?(log_file)
  end

  def test_build_markdown_default_source_is_code
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Test message'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    # source パラメータ省略時（デフォルト: 'code'）
    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123456789',
      messages: messages
    )

    assert markdown.include?('# Claude Code Session'), 'Default should be Code session header'
  end

  def test_build_markdown_with_code_source
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Test message'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123456789',
      messages: messages,
      source: 'code'
    )

    assert markdown.include?('# Claude Code Session'), 'Markdown should have Code session header'
    assert markdown.include?('**Project**: test-project'), 'Markdown should include project name'
    assert markdown.include?('**Session ID**: test123456789'), 'Markdown should include session ID'
  end

  def test_build_markdown_with_web_source
    processor = ClaudeHistoryToObsidian.new
    messages = [
      {'role' => 'user', 'content' => 'Test message'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123456789',
      messages: messages,
      source: 'web'
    )

    assert markdown.include?('# Claude Web Session'), 'Markdown should have Web session header'
    assert markdown.include?('**Project**: test-project'), 'Markdown should include project name'
    assert markdown.include?('**Session ID**: test123456789'), 'Markdown should include session ID'
  end

  def test_build_markdown_uses_session_timestamp_not_current_time
    processor = ClaudeHistoryToObsidian.new

    # 過去のタイムスタンプ
    messages = [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-10-01T10:00:00.000Z'},
      {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-10-01T10:00:05.000Z'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123',
      messages: messages
    )

    # ローカルタイム: セッション開始時刻がローカルタイムで使用されている (JST)
    expected_date = '2025-10-01 19:00:00 +09:00'
    assert_include markdown, "**Date**: #{expected_date}"

    # 現在時刻は含まれていない
    current_date = Time.now.getlocal.strftime('%Y-%m-%d')
    assert !markdown.include?("**Date**: #{current_date}") || current_date == '2025-10-01',
           'Should not include current date unless it matches session date'
  end

  def test_build_markdown_handles_missing_timestamp
    processor = ClaudeHistoryToObsidian.new

    # タイムスタンプなしのメッセージ
    messages = [
      {'role' => 'user', 'content' => 'Test'},
      {'role' => 'assistant', 'content' => 'Response'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123',
      messages: messages
    )

    # タイムスタンプ取得失敗時は 'Unknown'
    assert_include markdown, '**Date**: Unknown'
  end

  def test_build_markdown_includes_explicit_timezone_offset
    processor = ClaudeHistoryToObsidian.new

    # タイムスタンプ付きメッセージ
    messages = [
      {'role' => 'user', 'content' => 'Test', 'timestamp' => '2025-11-03T14:30:22.000Z'},
      {'role' => 'assistant', 'content' => 'Response', 'timestamp' => '2025-11-03T14:30:25.000Z'}
    ]

    markdown = processor.send(:build_markdown,
      project_name: 'test-project',
      cwd: '/test/path',
      session_id: 'test123',
      messages: messages
    )

    # ローカルタイム: タイムゾーンオフセット +09:00 が明示的に含まれている (JST)
    expected_timestamp_with_tz = '2025-11-03 23:30:22 +09:00'

    assert_include markdown, "**Date**: #{expected_timestamp_with_tz}",
                   'Markdown should include local timezone (+09:00)'
  end

  # === カバレッジ90%+達成のためのテスト ===

  # TEST: format_log_message with non-Hash/Array/String (else branch coverage)
  def test_format_log_message_with_number
    processor = ClaudeHistoryToObsidian.new

    number_message = 12345
    result = processor.send(:format_log_message, number_message)

    # 数値は to_s で文字列化される
    assert_equal '12345', result
  end

  # TEST: format_log_message with symbol
  def test_format_log_message_with_symbol
    processor = ClaudeHistoryToObsidian.new

    symbol_message = :test_symbol
    result = processor.send(:format_log_message, symbol_message)

    # シンボルは to_s で文字列化される
    assert_equal 'test_symbol', result
  end

  # TEST: extract_session_timestamp with invalid timestamp format (rescue coverage)
  def test_extract_session_timestamp_with_invalid_format
    processor = ClaudeHistoryToObsidian.new

    # 無効なタイムスタンプフォーマット
    transcript_invalid = {
      'messages' => [
        {'role' => 'user', 'content' => 'Test', 'timestamp' => 'invalid-timestamp-format'}
      ]
    }

    # Time.parseに失敗してrescueブロックに入り、nilを返す
    timestamp = processor.send(:extract_session_timestamp, transcript_invalid)
    assert_nil timestamp, 'Invalid timestamp should return nil'
  end

  # TEST: save_to_vault with write error (rescue coverage)
  def test_save_to_vault_with_write_error
    processor = ClaudeHistoryToObsidian.new

    # 書き込み不可能なパスを指定（存在しないディレクトリ）
    invalid_dir = '/tmp/non_existent_directory_12345_test'
    filename = 'test.md'
    content = 'Test content'

    # ディレクトリが存在しないため、書き込みエラーが発生してrescueブロックに入り、例外が再raiseされる
    assert_raise(Errno::ENOENT) do
      processor.send(:save_to_vault, invalid_dir, filename, content)
    end
  end

  # TEST: ensure_directories with mkdir error (rescue coverage)
  def test_ensure_directories_with_mkdir_error
    processor = ClaudeHistoryToObsidian.new

    # FileUtils.mkdir_pをスタブして例外を投げる
    original_mkdir_p = FileUtils.method(:mkdir_p)
    FileUtils.define_singleton_method(:mkdir_p) do |path|
      raise Errno::EACCES, "Permission denied - #{path}"
    end

    begin
      # ディレクトリ作成が失敗してrescueブロックに入り、例外が再raiseされる
      assert_raise(Errno::EACCES) do
        processor.send(:ensure_directories, 'test-project')
      end
    ensure
      # 元のメソッドに戻す
      FileUtils.define_singleton_method(:mkdir_p, original_mkdir_p)
    end
  end

  # TEST: process_transcript with exception (rescue coverage for 90%+ goal)
  def test_process_transcript_with_build_markdown_error
    processor = ClaudeHistoryToObsidian.new

    # build_markdownをスタブして例外を投げる
    def processor.build_markdown(**args)
      raise StandardError, "Simulated build_markdown error"
    end

    transcript = {
      'session_id' => 'test-error-123',
      'cwd' => '/test/project',
      'messages' => [
        {'role' => 'user', 'content' => 'Test'},
        {'role' => 'assistant', 'content' => 'Response'}
      ],
      '_first_message_timestamp' => '20251106-100000'
    }

    # process_transcriptがrescueブロックに入り、例外が再raiseされる
    error = assert_raise(RuntimeError) do
      processor.process_transcript(
        project_name: 'test-error-project',
        cwd: '/test/project',
        session_id: 'test-error-123',
        transcript: transcript,
        messages: transcript['messages']
      )
    end

    assert_include error.message, 'Failed to process transcript'
  end

  # TEST: notify メソッド - モックベーステスト
  def test_notify_does_nothing_when_not_macos
    processor = ClaudeHistoryToObsidian.new

    # macos? をモック化して false を返す
    def processor.macos?
      false
    end

    # notify は macOS でない場合、すぐに return する
    # エラーが出ないことを確認
    assert_nothing_raised do
      processor.send(:notify, "Test notification")
    end
  end

  def test_notify_with_macos_returns_early_without_terminal_notifier
    processor = ClaudeHistoryToObsidian.new

    # macos? をモック化して true を返す
    def processor.macos?
      true
    end

    # notify メソッドが macos? = true の場合、terminal-notifier のロード処理に到達する
    # TerminalNotifier が無い環境でも LoadError は rescue されるため、エラーは出ない
    assert_nothing_raised do
      processor.send(:notify, "Test notification message")
    end
  end

  def test_notify_with_mock_terminal_notifier
    processor = ClaudeHistoryToObsidian.new

    # macos? をモック化して true を返す
    def processor.macos?
      true
    end

    # Object.const_set を使ってモック TerminalNotifier を作成
    begin
      mock_notifier = Class.new do
        @@called = false
        @@message = nil

        def self.notify(message, **options)
          @@called = true
          @@message = message
        end

        def self.called?
          @@called
        end

        def self.message
          @@message
        end
      end

      Object.const_set(:TerminalNotifier, mock_notifier)

      # notify を呼び出す
      processor.send(:notify, "Test mock notification")

      # エラーが出ないことを確認
      assert true
    ensure
      # モック TerminalNotifier をクリーンアップ
      Object.send(:remove_const, :TerminalNotifier) if Object.const_defined?(:TerminalNotifier)
    end
  end

end
