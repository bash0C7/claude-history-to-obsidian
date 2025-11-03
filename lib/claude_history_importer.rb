#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

class ClaudeHistoryImporter
  LOG_FILE_PATH = File.expand_path('~/.local/var/log/claude-history-to-obsidian.log')

  def run
    # stdin から JSONL ファイルパスのリストを読み込む
    paths = $stdin.readlines.map(&:strip).reject(&:empty?)

    if paths.empty?
      log('No JSONL files to process')
      return
    end

    paths.each do |path|
      import_from_jsonl(path)
    end
  rescue StandardError => e
    log("ERROR: #{e.class}: #{e.message}")
    log(e.backtrace.join("\n"))
    warn "Error processing JSONL files: #{e.message}"
  end

  private

  def import_from_jsonl(path)
    unless File.exist?(path)
      log("WARNING: JSONL file not found: #{path}")
      warn "File not found: #{path}"
      return
    end

    # JSONL をパースしてセッションでグループ化
    sessions = parse_and_group_sessions(path)

    # 各セッションを処理
    sessions.each do |session_id, session_data|
      process_session(session_id, session_data)
    end

    log("Imported #{sessions.length} sessions from #{path}")
  rescue StandardError => e
    log("ERROR: Failed to import #{path}: #{e.message}")
  end

  def parse_and_group_sessions(path)
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
      sessions[session_id][:messages] << {
        'role' => message['role'],
        'content' => message['content'],
        'timestamp' => timestamp
      }
    end

    sessions
  end

  def process_session(session_id, session_data)
    messages = session_data[:messages]
    cwd = session_data[:cwd]

    # トランスクリプトを生成
    first_message_timestamp = extract_first_message_timestamp(messages)
    transcript = {
      'session_id' => session_id,
      'cwd' => cwd,
      'messages' => messages
    }
    transcript['_first_message_timestamp'] = first_message_timestamp if first_message_timestamp

    # Hook JSON を生成（transcript を直接埋め込む）
    hook_json = {
      'session_id' => session_id,
      'transcript' => transcript,
      'cwd' => cwd,
      'permission_mode' => 'default',
      'hook_event_name' => 'Stop'
    }

    puts JSON.generate(hook_json)
  rescue StandardError => e
    log("ERROR: Failed to process session #{session_id}: #{e.message}")
  end

  def extract_first_message_timestamp(messages)
    return nil unless messages && messages.length.positive?

    first_msg = messages.first
    return nil unless first_msg['timestamp']

    # ISO 8601 をYYYYMMDD-HHMMSSにフォーマット
    Time.parse(first_msg['timestamp']).strftime('%Y%m%d-%H%M%S')
  rescue StandardError => e
    log("WARNING: Failed to extract timestamp: #{e.message}")
    nil
  end

  def log(message)
    log_dir = File.dirname(LOG_FILE_PATH)
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    File.open(LOG_FILE_PATH, 'a') do |f|
      f.puts "[#{timestamp}] #{message}"
    end
  rescue StandardError => e
    warn "Failed to write log: #{e.message}"
  end
end
