#!/usr/bin/env rake
# frozen_string_literal: true

require 'json'
require_relative 'lib/claude_history_to_obsidian'

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

  File.readlines(path).each do |line|
    next if line.strip.empty?

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
