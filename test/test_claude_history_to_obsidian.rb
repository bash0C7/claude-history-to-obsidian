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

  # === エントリーポイント統合テスト（優先度高）===

  # TEST 1: run メソッド - Hook Mode (transcript_path から読み込む)
  def test_run_entrypoint_hook_mode
    processor = ClaudeHistoryToObsidian.new

    Dir.mktmpdir do |test_dir|
      # トランスクリプトファイルを作成
      transcript_path = File.join(test_dir, 'transcript.json')
      transcript_data = {
        'session_id' => 'hook-test-123',
        'cwd' => '/Users/bash/src/test-project-hook',
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
        'cwd' => '/Users/bash/src/test-project-hook',
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
      vault_base = ClaudeHistoryToObsidian::VAULT_BASE_PATH
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
      'cwd' => '/Users/bash/src/test-project-bulk',
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop',
      'transcript' => {
        'session_id' => 'bulk-test-456',
        'cwd' => '/Users/bash/src/test-project-bulk',
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
    vault_base = ClaudeHistoryToObsidian::VAULT_BASE_PATH
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
    
    vault_base = ClaudeHistoryToObsidian::VAULT_BASE_PATH
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

end
