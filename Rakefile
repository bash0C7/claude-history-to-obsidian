#!/usr/bin/env rake
# frozen_string_literal: true

require 'json'
require_relative 'lib/claude_history_to_obsidian'

desc 'Run all tests with coverage report'
task 'test:coverage' do
  test_files = Dir.glob('test/test_*.rb').reject { |f| f.include?('test_helper') }.join(' ')
  sh "bundle exec ruby -I lib:test -rtest/unit #{test_files}"
  puts "\n📊 Coverage report: coverage/index.html"
  sh 'open coverage/index.html' if RUBY_PLATFORM.include?('darwin')
end

desc 'Run all tests'
task :test do
  test_files = Dir.glob('test/test_*.rb').reject { |f| f.include?('test_helper') }.join(' ')
  sh "bundle exec ruby -I lib:test -rtest/unit #{test_files}"
end

task default: :test

namespace :web do
  desc 'Import Claude Web Export conversations.json to Obsidian (CONVERSATIONS_JSON=/path/to/file or ~/Downloads/conversations.json)'
  task :import_conversations do
    conversations_json = ENV['CONVERSATIONS_JSON'] || File.expand_path('~/Downloads/conversations.json')

    unless File.exist?(conversations_json)
      warn "Error: #{conversations_json} does not exist"
      exit 1
    end

    begin
      # jq + filter-conversations パイプライン
      # conversations.json → JSONL → Hook JSON → process_transcript
      cmd = "jq -c '.[]' '#{conversations_json}' | bundle exec ruby bin/filter-conversations"
      IO.popen(cmd, 'r') do |pipe|
        pipe.each_line do |line|
          next if line.strip.empty?

          begin
            hook_json = JSON.parse(line)
            process_web_conversation(hook_json)
          rescue JSON::ParserError => e
            warn "ERROR: Failed to parse Hook JSON: #{e.message}"
            next
          rescue StandardError => e
            warn "ERROR: Failed to process conversation: #{e.message}"
            next
          end
        end
      end

      exit_status = $?.exitstatus
      raise "jq + filter-conversations failed with status #{exit_status}" unless exit_status == 0

    rescue StandardError => e
      warn "✗ Web import failed: #{e.message}"
      exit 1
    end
  end
end

desc 'Bulk import past Claude Code sessions from ~/.claude/projects/'
task :bulk_import do
  projects_dir = File.expand_path('~/.claude/projects/')

  unless Dir.exist?(projects_dir)
    puts "Error: #{projects_dir} does not exist"
    exit 1
  end

  puts '🔄 Bulk importing Claude Code sessions...'
  puts "📁 Source: #{projects_dir}"

  count = 0
  errors = 0

  # Ctrl+C で終了
  Signal.trap('INT') do
    puts "\n⚠️  Interrupt received, stopping import..."
    exit 130
  end

  begin
    # JSONL ファイルをパースしてセッションごとに処理
    Dir.glob("#{projects_dir}/**/*.jsonl").each do |jsonl_path|
      sessions = parse_and_group_jsonl(jsonl_path)

      sessions.each do |session_id, session_data|
        begin
          process_session(session_id, session_data)
          count += 1
          puts "✓ Imported session #{count}" if count % 10 == 0
        rescue StandardError => e
          errors += 1
          warn "Error processing session #{session_id}: #{e.message}"
        end
      end
    end

    puts "✓ Bulk import completed: #{count} sessions imported, #{errors} errors"
  rescue StandardError => e
    puts "✗ Bulk import failed: #{e.message}"
    exit 1
  ensure
    Signal.trap('INT', 'DEFAULT')
  end
end

private

def parse_and_group_jsonl(path)
  sessions = {}

  # UTF-8 エンコーディングで読み込む（invalid byte は置換）
  File.open(path, 'r:UTF-8', invalid: :replace) do |file|
    file.each_line do |line|
      next if line.strip.empty?

      begin
        parsed = JSON.parse(line)
        session_id = parsed['sessionId']
        cwd = parsed['cwd']
        timestamp = parsed['timestamp']
        message = parsed['message']

        next unless session_id && cwd && message

        sessions[session_id] ||= { messages: [], cwd: cwd }

        # content が配列の場合（Assistant メッセージ）、テキストを抽出
        content = message['content']
        if content.is_a?(Array)
          content = content.map { |c| c.is_a?(Hash) && c['type'] == 'text' ? c['text'] : c.to_s }.join("\n")
        end

        sessions[session_id][:messages] << {
          'role' => message['role'],
          'content' => content,
          'timestamp' => timestamp
        }
      rescue JSON::ParserError => e
        # JSON パースエラーの場合はスキップ
        warn "WARNING: Failed to parse JSON in #{path}: #{e.message[0..100]}"
        next
      end
    end
  end

  sessions
end

def process_session(session_id, session_data)
  messages = session_data[:messages]
  cwd = session_data[:cwd]

  # トランスクリプトを生成
  first_msg_timestamp = extract_first_message_timestamp(messages)
  transcript = {
    'session_id' => session_id,
    'cwd' => cwd,
    'messages' => messages,
    '_first_message_timestamp' => first_msg_timestamp
  }.compact

  # ClaudeHistoryToObsidian を直接呼び出す
  processor = ClaudeHistoryToObsidian.new
  processor.process_transcript(
    project_name: File.basename(cwd),
    cwd: cwd,
    session_id: session_id,
    transcript: transcript,
    messages: messages
  )
end

def extract_first_message_timestamp(messages)
  return nil unless messages && messages.length.positive?

  first_msg = messages.first
  return nil unless first_msg['timestamp']

  Time.parse(first_msg['timestamp']).strftime('%Y%m%d-%H%M%S')
rescue StandardError => e
  warn "WARNING: Failed to extract timestamp: #{e.message}"
  nil
end

def process_web_conversation(hook_json)
  session_id = hook_json['session_id']
  transcript = hook_json['transcript']
  cwd = hook_json['cwd']
  conversation_name = hook_json['conversation_name'] || 'conversation'

  # conversation_name をスラッグ化して project_name として使用
  project_name = slugify_name(conversation_name)

  processor = ClaudeHistoryToObsidian.new
  processor.process_transcript(
    project_name: project_name,
    cwd: cwd,
    session_id: session_id,
    transcript: transcript,
    messages: transcript['messages']
  )
end

def slugify_name(name)
  # 最初の30文字を取得
  text = name[0..29]

  normalized = text
               .downcase
               .gsub(/[^a-z0-9]+/, '-')
               .sub(/^-+/, '')
               .sub(/-+$/, '')

  normalized.empty? ? 'conversation' : normalized
end
