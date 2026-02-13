# frozen_string_literal: true

module Cli
  # Formats API responses for terminal output.
  # Supports both human-readable tables and JSON output for agents.
  class Formatter
    def initialize(format: :table)
      @format = format
    end

    def render(data, columns: nil)
      if @format == :json
        puts JSON.pretty_generate(data)
        return
      end

      case data
      when Array
        render_table(data, columns: columns)
      when Hash
        render_hash(data)
      else
        puts data
      end
    end

    def success(message)
      if @format == :json
        puts JSON.generate({ status: "ok", message: message })
      else
        puts "\e[32m#{message}\e[0m" # Green
      end
    end

    def error(message)
      if @format == :json
        puts JSON.generate({ status: "error", message: message })
      else
        $stderr.puts "\e[31mError: #{message}\e[0m" # Red
      end
    end

    private

    def render_table(rows, columns: nil)
      return puts "No results." if rows.empty?

      columns ||= rows.first.keys
      columns = columns.map(&:to_s)

      # Calculate column widths
      widths = columns.map { |col| col.length }
      rows.each do |row|
        columns.each_with_index do |col, i|
          val = row[col].to_s
          widths[i] = [widths[i], val.length].max
        end
      end

      # Cap column widths
      widths = widths.map { |w| [w, 40].min }

      # Header
      header = columns.each_with_index.map { |col, i| col.upcase.ljust(widths[i]) }.join("  ")
      puts header
      puts "-" * header.length

      # Rows
      rows.each do |row|
        line = columns.each_with_index.map do |col, i|
          row[col].to_s.ljust(widths[i])[0...widths[i]]
        end.join("  ")
        puts line
      end

      puts "\n#{rows.size} result(s)"
    end

    def render_hash(hash, indent: 0)
      hash.each do |key, value|
        prefix = "  " * indent
        case value
        when Hash
          puts "#{prefix}#{key}:"
          render_hash(value, indent: indent + 1)
        when Array
          if value.first.is_a?(Hash)
            puts "#{prefix}#{key}:"
            value.each_with_index do |item, idx|
              puts "#{prefix}  [#{idx}]"
              render_hash(item, indent: indent + 2)
            end
          else
            puts "#{prefix}#{key}: #{value.join(', ')}"
          end
        else
          puts "#{prefix}#{key}: #{value}"
        end
      end
    end
  end
end
