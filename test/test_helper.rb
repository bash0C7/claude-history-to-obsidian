#!/usr/bin/env ruby
# frozen_string_literal: true

# SimpleCov設定（全テストの最初で起動）
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  add_group 'Libraries', 'lib'

  # 最低カバレッジ設定（テスト追加に応じて引き上げ予定）
  # 現在はテストスイート構築中のため検証をスキップ
  # minimum_coverage 70
end

require 'stringio'

# STDOUT/STDINキャプチャ用ヘルパー
module TestHelpers
  # STDOUTをキャプチャして文字列として返す
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  # STDINを指定した入力で置き換えて実行
  def with_stdin(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    $stdin.rewind
    yield
  ensure
    $stdin = original_stdin
  end

  # 環境変数を一時的に上書きしてブロック内で実行
  # ブロック終了後に元の値に自動復元
  def with_env(overrides)
    original = {}
    overrides.each do |key, value|
      original[key] = ENV[key.to_s]
      ENV[key.to_s] = value
    end

    yield
  ensure
    original.each do |key, value|
      if value.nil?
        ENV.delete(key.to_s)
      else
        ENV[key.to_s] = value
      end
    end
  end
end
