#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'

class TestRakeBulkImport < Test::Unit::TestCase
  def setup
    @test_dir = Dir.mktmpdir
    @projects_dir = File.join(@test_dir, 'projects')
    @vault_dir = File.join(@test_dir, 'vault')
    @log_file = File.join(@test_dir, 'test.log')

    FileUtils.mkdir_p(@projects_dir)
    FileUtils.mkdir_p(@vault_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  def test_bulk_import_output_shows_project_and_session_info
    # テスト用JSONLファイルを作成
    create_test_jsonl(
      'picoruby-recipes',
      [
        {
          'sessionId' => 'abc123456789abc1',
          'cwd' => '~/src/picoruby-recipes',
          'timestamp' => '2025-11-02T14:30:22.000Z',
          'message' => {
            'role' => 'user',
            'content' => 'Implementing the feature'
          }
        },
        {
          'sessionId' => 'def234567890def2',
          'cwd' => '~/src/picoruby-recipes',
          'timestamp' => '2025-11-02T15:00:00.000Z',
          'message' => {
            'role' => 'assistant',
            'content' => 'Sure, I will help'
          }
        }
      ]
    )

    create_test_jsonl(
      'arduino-project',
      [
        {
          'sessionId' => 'ghi345678901ghi3',
          'cwd' => '~/src/arduino',
          'timestamp' => '2025-11-03T10:00:00.000Z',
          'message' => {
            'role' => 'user',
            'content' => 'Help me with Arduino'
          }
        }
      ]
    )

    # rake bulk_importを実行して出力をキャプチャ
    output = run_bulk_import

    # 出力がプロジェクト名を含むことを検証
    assert_include(output, '📂 picoruby-recipes', 'Should show picoruby-recipes project')
    assert_include(output, '📂 arduino-project', 'Should show arduino-project')

    # 出力がセッション日付を含むことを検証
    assert_include(output, '20251102-143022', 'Should show session timestamp for first session')
    assert_include(output, '20251103-100000', 'Should show session timestamp for second project')

    # 出力がセッションIDを含むことを検証
    assert_include(output, 'abc12345', 'Should show first 8 chars of session ID')
    assert_include(output, 'ghi34567', 'Should show first 8 chars of session ID for second project')
  end

  private

  def create_test_jsonl(project_name, messages_data)
    project_dir = File.join(@projects_dir, project_name)
    FileUtils.mkdir_p(project_dir)

    jsonl_file = File.join(project_dir, 'sessions.jsonl')
    File.open(jsonl_file, 'w') do |f|
      messages_data.each do |msg_data|
        line = JSON.generate(msg_data)
        f.puts(line)
      end
    end

    jsonl_file
  end

  def run_bulk_import
    # 環境変数を設定してrake bulk_importを実行
    env = {
      'CLAUDE_PROJECTS_DIR' => @projects_dir,
      'CLAUDE_VAULT_PATH' => @vault_dir,
      'CLAUDE_LOG_PATH' => @log_file
    }

    cmd = "cd #{Dir.pwd} && rake code:bulk_import 2>&1"

    # 環境変数を設定して実行
    stdout, stderr, status = Open3.capture3(env, cmd)

    output = stdout + stderr
    # 出力をUTF-8に強制
    output.force_encoding('UTF-8').encode('UTF-8', invalid: :replace)
  end
end
