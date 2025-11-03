#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

class ClaudeHistoryToObsidian
  VAULT_BASE_PATH = File.expand_path(
    '~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code'
  )
  LOG_FILE_PATH = File.expand_path('~/.local/var/log/claude-history-to-obsidian.log')

  def run
    hook_input = load_hook_input
    return unless hook_input

    transcript = load_transcript(hook_input['transcript_path'])
    return unless transcript

    project_name = File.basename(hook_input['cwd'])
    session_id = hook_input['session_id']
    session_name = extract_session_name(transcript['messages'])

    markdown = build_markdown(
      project_name: project_name,
      cwd: hook_input['cwd'],
      session_id: session_id,
      messages: transcript['messages']
    )

    vault_dir = ensure_directories(project_name)
    filename = generate_filename(session_name, session_id)
    save_to_vault(vault_dir, filename, markdown)

    log("Successfully saved transcript: #{filename}")
    notify("Claude transcript saved: #{filename}")
  rescue StandardError => e
    log("ERROR: #{e.class}: #{e.message}")
    log(e.backtrace.join("\n"))
    warn "Error processing transcript: #{e.message}"
  ensure
    exit 0
  end

  private

  def load_hook_input
    input = $stdin.read
    JSON.parse(input)
  rescue JSON::ParserError => e
    log("ERROR: Failed to parse hook input JSON: #{e.message}")
    warn "Invalid hook input JSON"
    nil
  end

  def load_transcript(path)
    unless File.exist?(path)
      log("WARNING: Transcript file not found: #{path}")
      warn "Transcript file not found: #{path}"
      return nil
    end

    content = File.read(path)
    JSON.parse(content)
  rescue JSON::ParserError => e
    log("ERROR: Failed to parse transcript JSON: #{e.message}")
    warn "Invalid transcript JSON: #{path}"
    nil
  end

  def extract_session_name(messages)
    first_user_msg = messages.find { |m| m['role'] == 'user' }
    return 'session' unless first_user_msg && first_user_msg['content']

    text = first_user_msg['content']
    first_line = text.split("\n").first || ''
    name = first_line[0..29]

    normalized = name
                 .downcase
                 .gsub(/[^a-z0-9]+/, '-')
                 .sub(/^-+/, '')
                 .sub(/-+$/, '')

    normalized.empty? ? 'session' : normalized
  end

  def build_markdown(project_name:, cwd:, session_id:, messages:)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')

    output = []
    output << "# Claude Code Session"
    output << ""
    output << "**Project**: #{project_name}"
    output << "**Path**: #{cwd}"
    output << "**Session ID**: #{session_id}"
    output << "**Date**: #{timestamp}"
    output << ""
    output << "---"
    output << ""

    messages.each do |msg|
      role = msg['role']
      content = msg['content']

      if role == 'user'
        output << "## 👤 User"
        output << ""
        output << content
        output << ""
        output << "---"
        output << ""
      elsif role == 'assistant'
        output << "## 🤖 Claude"
        output << ""
        output << content
        output << ""
        output << "---"
        output << ""
      end
    end

    output.join("\n")
  end

  def ensure_directories(project_name)
    vault_dir = File.join(VAULT_BASE_PATH, project_name)
    FileUtils.mkdir_p(vault_dir)
    log("Ensured directory exists: #{vault_dir}")
    vault_dir
  rescue StandardError => e
    log("ERROR: Failed to create directory #{vault_dir}: #{e.message}")
    raise
  end

  def generate_filename(session_name, session_id)
    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    short_id = session_id[0..7]
    "#{timestamp}_#{session_name}_#{short_id}.md"
  end

  def save_to_vault(vault_dir, filename, content)
    filepath = File.join(vault_dir, filename)
    File.write(filepath, content)
    log("Saved markdown to: #{filepath}")
  rescue StandardError => e
    log("ERROR: Failed to save file #{filepath}: #{e.message}")
    raise
  end

  def notify(message)
    return unless macos?

    begin
      require 'terminal-notifier'
      TerminalNotifier.notify(message, title: 'Claude History')
    rescue LoadError
      # terminal-notifier未インストール時はスキップ
    rescue StandardError => e
      log("WARNING: Notification failed: #{e.message}")
    end
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

  def macos?
    RUBY_PLATFORM.include?('darwin')
  end
end
