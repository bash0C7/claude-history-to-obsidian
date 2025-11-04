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
  desc 'Import Claude Web Export conversations.json to Obsidian (CONVERSATIONS_JSON=/path/to/file or ./conversations.json)'
  task :import_conversations do
    conversations_json = ENV['CONVERSATIONS_JSON'] || './conversations.json'

    unless File.exist?(conversations_json)
      warn "Error: #{conversations_json} does not exist"
      exit 1
    end

    begin
      puts "📁 Reading: #{conversations_json}"

      # Ruby でファイルをエンコーディング指定で読み込む（JSON 全体をパース）
      # conversations.json (UTF-8, invalid:replace) → Ruby JSON parse → process_transcript
      file_content = File.read(conversations_json, encoding: 'UTF-8')
      # 無効な UTF-8 シーケンスを ? に置換
      file_content = file_content.encode('UTF-8', invalid: :replace)

      conversations = JSON.parse(file_content)
      raise "Expected Array in conversations.json" unless conversations.is_a?(Array)

      count = 0
      conversations.each do |conversation|
        begin
          process_web_conversation(conversation)
          count += 1
          puts "✓ Processed #{count} conversations" if count % 10 == 0
        rescue StandardError => e
          warn "WARNING: Failed to process conversation: #{e.message}"
          # 次の会話を処理継続（非ブロッキング）
        end
      end

      puts "✓ Web import completed: #{count} conversations processed"

    rescue JSON::ParserError => e
      warn "✗ Failed to parse JSON: #{e.message}"
      exit 1
    rescue StandardError => e
      warn "✗ Web import failed: #{e.message}"
      exit 1
    end
  end
end

desc 'Bulk import past Claude Code sessions from ~/.claude/projects/'
task :bulk_import do
  projects_dir = ENV.fetch('CLAUDE_PROJECTS_DIR', File.expand_path('~/.claude/projects/'))

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
      project_name = extract_project_name(jsonl_path)
      puts "\n📂 #{project_name}"

      sessions = parse_and_group_jsonl(jsonl_path)

      sessions.each do |session_id, session_data|
        begin
          timestamp = extract_first_message_timestamp(session_data[:messages])
          session_id_short = session_id[0..7]
          puts "  #{timestamp || 'unknown'} #{session_id_short}"

          process_session(session_id, session_data)
          count += 1
        rescue StandardError => e
          errors += 1
          warn "Error processing session #{session_id}: #{e.message}"
        end
      end
    end

    puts "\n✓ Bulk import completed: #{count} sessions imported, #{errors} errors"
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

def process_web_conversation(conversation)
  # conversations.json のオブジェクトから必要な情報を抽出
  session_id = conversation['uuid']
  conversation_name = conversation['name'] || 'conversation'
  chat_messages = conversation['chat_messages'] || []

  # 空の会話はスキップ
  return if chat_messages.empty?

  # chat_messages を transcript 形式に変換
  messages = chat_messages.map do |msg|
    {
      'role' => msg['role'],
      'content' => msg['content'],
      'timestamp' => msg['created_at']
    }
  end

  # トランスクリプトを生成
  timestamp = extract_first_message_timestamp(messages)
  transcript = {
    'session_id' => session_id,
    'cwd' => Dir.pwd,
    'messages' => messages,
    '_first_message_timestamp' => timestamp
  }.compact

  # conversation_name をスラッグ化して project_name として使用
  project_name = slugify_name(conversation_name)

  processor = ClaudeHistoryToObsidian.new
  processor.process_transcript(
    project_name: project_name,
    cwd: Dir.pwd,
    session_id: session_id,
    transcript: transcript,
    messages: messages
  )
end

def extract_project_name(jsonl_path)
  # ~/.claude/projects/{project-name}/{file}.jsonl からproject-nameを抽出
  parts = jsonl_path.split('/')
  projects_index = parts.index('projects')
  return 'unknown' unless projects_index

  parts[projects_index + 1] || 'unknown'
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
