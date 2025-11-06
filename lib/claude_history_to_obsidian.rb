#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

class ClaudeHistoryToObsidian
  CLAUDE_CODE_VAULT_PATH = ENV.fetch(
    'CLAUDE_VAULT_PATH',
    File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/Claude Code')
  )
  CLAUDE_WEB_VAULT_PATH = ENV.fetch(
    'CLAUDE_WEB_VAULT_PATH',
    File.expand_path('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/claude.ai')
  )
  LOG_FILE_PATH = ENV.fetch(
    'CLAUDE_LOG_PATH',
    File.expand_path('~/.local/var/log/claude-history-to-obsidian.log')
  )

  def run
    hook_input = load_hook_input
    return unless hook_input

    # Bulk Import時: transcript が直接埋め込まれている
    # Hook時: transcript_path から読み込む
    transcript = hook_input['transcript'] || load_transcript(hook_input['transcript_path'])
    return unless transcript

    source = hook_input['source'] || 'code'  # デフォルト: Claude Code
    project_name = hook_input['project'] || File.basename(hook_input['cwd'])
    session_id = hook_input['session_id']
    session_name = extract_session_name(transcript['messages'])

    markdown = build_markdown(
      project_name: project_name,
      cwd: hook_input['cwd'],
      session_id: session_id,
      messages: transcript['messages'],
      source: source
    )

    vault_dir = ensure_directories(project_name, source, transcript)
    filename = generate_filename(session_name, session_id, transcript, source, project_name)
    save_to_vault(vault_dir, filename, markdown)

    log("Successfully saved transcript: #{filename}")
    notify("Claude transcript saved: #{filename}")
  rescue StandardError => e
    log("ERROR: #{e.class}: #{e.message}")
    log(e.backtrace.join("\n"))
    warn "ERROR: Failed to process and save transcript"
    warn "  Exception: #{e.class}"
    warn "  Message: #{e.message}"
    warn "  Backtrace: #{e.backtrace.first(3).join(', ')}"
  ensure
    exit 0
  end

  # Bulk Import 用: Ruby から直接呼び出し（プロセス化しない）
  # 戻り値: Vault相対パス（例: "Claude Code/project/20251103-143022_name_abc12345.md" または "claude.ai/202511/20251103-143022_project-name_session.md"）
  def process_transcript(project_name:, cwd:, session_id:, transcript:, messages:, source: 'code')
    session_name = extract_session_name(messages)

    markdown = build_markdown(
      project_name: project_name,
      cwd: cwd,
      session_id: session_id,
      messages: messages,
      source: source
    )

    # vault_dir と 実際のディレクトリ名（year_month または project_name）を取得
    vault_dir = ensure_directories(project_name, source, transcript)

    # Web の場合、ディレクトリ名は yyyymm になるので、それを反映させる
    actual_dir_name = if source == 'web' && transcript
      timestamp = extract_session_timestamp(transcript)
      # timestamp はローカルタイム (e.g. "20251103-233022") なので [0..5] で "202511" を取得
      timestamp ? timestamp[0..5] : project_name
    else
      project_name
    end

    filename = generate_filename(session_name, session_id, transcript, source, project_name)
    save_to_vault(vault_dir, filename, markdown)

    # Vault相対パスを構築して返す
    vault_subdir = source == 'web' ? 'claude.ai' : 'Claude Code'
    relative_path = File.join(vault_subdir, actual_dir_name, filename)

    log("Successfully imported transcript: #{filename}")
    relative_path
  rescue StandardError => e
    log("ERROR: #{e.class}: #{e.message}")
    log(e.backtrace.join("\n"))
    raise "Failed to process transcript: #{e.message}"
  end

  private

  def load_hook_input
    input = $stdin.read
    JSON.parse(input)
  rescue JSON::ParserError => e
    log("ERROR: Failed to parse hook input JSON: #{e.message}")
    # デバッグ用に詳細情報を stderr に出力
    warn "ERROR: Invalid hook input JSON"
    warn "  Message: #{e.message}"
    warn "  Input (first 200 chars): #{input[0..199].inspect}"
    nil
  end

  def load_transcript(path)
    unless File.exist?(path)
      log("WARNING: Transcript file not found: #{path}")
      warn "ERROR: Transcript file not found"
      warn "  Path: #{path}"
      return nil
    end

    content = File.read(path)
    JSON.parse(content)
  rescue JSON::ParserError => e
    log("ERROR: Failed to parse transcript JSON: #{e.message}")
    warn "ERROR: Invalid transcript JSON"
    warn "  Path: #{path}"
    warn "  Message: #{e.message}"
    nil
  end

  def extract_session_name(messages)
    first_user_msg = messages.find { |m| m['role'] == 'user' }
    return 'session' unless first_user_msg && first_user_msg['content']

    content = first_user_msg['content']

    # content が配列形式の場合（conversations.json形式）、テキストを抽出
    if content.is_a?(Array)
      text_parts = content.map do |block|
        if block.is_a?(Hash) && block['type'] == 'text'
          block['text']
        elsif block.is_a?(String)
          block
        end
      end.compact
      text = text_parts.join(" ")
    else
      text = content
    end

    first_line = text.split("\n").first || ''
    name = first_line[0..29]

    normalized = name
                 .downcase
                 .gsub(/[^a-z0-9]+/, '-')
                 .sub(/^-+/, '')
                 .sub(/-+$/, '')

    normalized.empty? ? 'session' : normalized
  end

  def build_markdown(project_name:, cwd:, session_id:, messages:, source: 'code')
    # セッション開始時刻を使用（Time.now は使わない）
    # ローカルタイム: マシンのタイムゾーンで表示（オフセット付き）
    local_time = extract_session_time(messages)
    if local_time
      # ローカルタイムのオフセットを取得して整形
      offset_str = local_time.strftime('%z')  # e.g., "+0900"
      offset_formatted = "#{offset_str[0..2]}:#{offset_str[3..4]}"  # e.g., "+09:00"
      timestamp = local_time.strftime("%Y-%m-%d %H:%M:%S #{offset_formatted}")
    else
      timestamp = 'Unknown'
    end

    session_type = source == 'web' ? 'Claude Web Session' : 'Claude Code Session'

    output = []
    output << "# #{session_type}"
    output << ""
    output << "**Project**: #{project_name}"
    output << "**Path**: #{cwd}"
    output << "**Session ID**: #{session_id}"
    output << "**Date**: #{timestamp}"
    output << ""
    output << "---"
    output << ""

    messages.each do |msg|
      # signature フィールドはスキップ（トレース情報、出力対象外）
      next if msg['signature']

      role = msg['role']
      content = msg['content']

      # content が配列形式の場合（conversations.json形式）、ブロックごとに処理
      if content.is_a?(Array)
        content = format_content_blocks(content)
      elsif content.is_a?(String)
        # 文字列の場合、\n（エスケープされた改行）を実際の改行に変換
        content = content.gsub('\\n', "\n")
      end

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

  # Content配列（conversations.json形式）をMarkdownブロック形式に変換
  def format_content_blocks(blocks)
    output = []

    # ブロックタイプのマッピング（タイプ → [絵文字, ラベル, キー]）
    block_map = {
      'thinking' => ['💭', '思考', 'thinking'],
      'text' => ['💬', '回答', 'text'],
      'input' => ['⌨️', '入力', 'text']
    }

    blocks.each do |block|
      next unless block.is_a?(Hash)

      block_type = block['type']
      block_config = block_map[block_type]

      # signature や未定義型はスキップ
      next if block_config.nil?

      emoji, label, content_key = block_config
      content_text = block[content_key] || ''
      content_text = content_text.gsub('\\n', "\n") if content_text.is_a?(String)

      output << "### #{emoji} #{label}"
      output << ""
      output << content_text
      output << ""
    end

    output.join("\n")
  end

  def ensure_directories(project_name, source = 'code', transcript = nil)
    vault_base = source == 'web' ? CLAUDE_WEB_VAULT_PATH : CLAUDE_CODE_VAULT_PATH

    # Web の場合、タイムスタンプから yyyymm を抽出してディレクトリ名にする
    if source == 'web' && transcript
      timestamp = extract_session_timestamp(transcript)
      if timestamp
        year_month = timestamp[0..5]  # "20251103-233022" (ローカルタイム) -> "202511"
        project_name = year_month
      end
    end

    # テストモード時は [test] サフィックスを付加
    if ENV['CLAUDE_VAULT_MODE'] == 'test'
      project_name = "#{project_name} [test]"
    end

    vault_dir = File.join(vault_base, project_name)
    FileUtils.mkdir_p(vault_dir)
    log("Ensured directory exists: #{vault_dir}")
    vault_dir
  rescue StandardError => e
    log("ERROR: Failed to create directory #{vault_dir}: #{e.message}")
    raise
  end

  def generate_filename(session_name, session_id, transcript, source = 'code', project_name = nil)
    # セッションの最初のメッセージのタイムスタンプを使用（冪等性を保つため）
    # なければフォールバック（Hook互換性のため）
    timestamp = extract_session_timestamp(transcript) || Time.now.getlocal.strftime('%Y%m%d-%H%M%S')

    if source == 'web'
      # Web の場合は session_id を含めない
      "#{timestamp}_#{project_name}_#{session_name}.md"
    else
      # Code の場合は従来通り session_id を含める
      short_id = session_id[0..7]
      "#{timestamp}_#{session_name}_#{short_id}.md"
    end
  end

  def extract_session_timestamp(transcript)
    # Bulk Import時: _first_message_timestamp フィールドをチェック
    return transcript['_first_message_timestamp'] if transcript['_first_message_timestamp']

    # Hook時: messages から最初のメッセージのタイムスタンプを抽出
    messages = transcript['messages']
    return nil unless messages && messages.length > 0

    first_msg = messages.first
    return nil unless first_msg['timestamp']

    # ISO 8601形式のタイムスタンプをYYYYMMDD-HHMMSSに変換
    # ローカルタイム: UTC から読んだ時刻をローカルに変換して出力
    utc_time = Time.parse(first_msg['timestamp']).utc
    local_time = utc_time.getlocal
    local_time.strftime('%Y%m%d-%H%M%S')
  rescue StandardError => e
    log("WARNING: Failed to extract session timestamp: #{e.message}")
    nil
  end

  # メッセージ配列から最初のメッセージのTimeオブジェクトを取得
  # build_markdownで使用（Dateフィールド生成用）
  def extract_session_time(messages)
    return nil unless messages && messages.length > 0

    first_msg = messages.first
    return nil unless first_msg['timestamp']

    # ローカルタイムの Time オブジェクトを返す
    utc_time = Time.parse(first_msg['timestamp']).utc
    utc_time.getlocal
  rescue StandardError => e
    log("WARNING: Failed to parse session time: #{e.message}")
    nil
  end

  def save_to_vault(vault_dir, filename, content)
    filepath = File.join(vault_dir, filename)

    # ファイルが既に存在する場合は警告ログを出す
    if File.exist?(filepath)
      log("WARNING: Overwriting existing file: #{filepath}")
    end

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

  public

  def log(message)
    log_dir = File.dirname(LOG_FILE_PATH)
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

    # タイムゾーンを明示的に扱う: 現在時刻をローカルタイムで取得
    local_time = Time.now.getlocal
    timestamp_with_tz = local_time.strftime('%Y-%m-%d %H:%M:%S %z')
    formatted_message = format_log_message(message)

    File.open(LOG_FILE_PATH, 'a') do |f|
      f.puts "[#{timestamp_with_tz}] #{formatted_message}"
    end
  rescue StandardError => e
    warn "Failed to write log: #{e.message}"
  end

  private

  def format_log_message(message)
    case message
    when Hash, Array
      # JSONはpretty printで整形。複数行の場合はインデント付き
      json_str = JSON.pretty_generate(message)
      indent_multiline(json_str)
    when String
      if message.include?("\n")
        # 複数行文字列はインデント付きで出力
        indent_multiline(message)
      else
        message
      end
    else
      message.to_s
    end
  end

  def indent_multiline(text)
    lines = text.lines.map(&:chomp)
    lines.map.with_index do |line, index|
      index.zero? ? line : "  #{line}"
    end.join("\n")
  end

  def macos?
    RUBY_PLATFORM.include?('darwin')
  end
end
