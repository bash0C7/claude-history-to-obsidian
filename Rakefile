#!/usr/bin/env rake
# frozen_string_literal: true

desc 'Bulk import past Claude Code sessions from ~/.claude/projects/'
task :bulk_import do
  projects_dir = File.expand_path('~/.claude/projects/')

  unless Dir.exist?(projects_dir)
    puts "Error: #{projects_dir} does not exist"
    exit 1
  end

  # 全 JSONL ファイルをインポーター経由でObsidianに保存
  # パイプライン: find → claude-history-import → claude-history-to-obsidian
  cmd = %{find "#{projects_dir}" -name "*.jsonl" -type f | bundle exec ruby bin/claude-history-import | while IFS= read -r json; do echo "$json" | bundle exec ruby bin/claude-history-to-obsidian; done}

  puts '🔄 Bulk importing Claude Code sessions...'
  puts "📁 Source: #{projects_dir}"

  system(cmd)

  if $?.success?
    puts '✓ Bulk import completed successfully'
  else
    puts "✗ Bulk import failed with status #{$?.exitstatus}"
    exit 1
  end
end
