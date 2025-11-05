# Implementation Details

## JSON Nesting & Content Handling

### Content Type Detection

The `build_markdown` method handles content in multiple formats by detecting the type and processing accordingly:

#### Pattern 1: Array Content (Confirmed JSON Structure)

**Condition**: `content.is_a?(Array)`

**Structure**: Typically from Claude Code API responses
```ruby
content = [
  {'type' => 'thinking', 'thinking' => '複数行\nの思考'},
  {'type' => 'text', 'text' => '回答\nテキスト'},
  {'type' => 'signature', 'text' => 'signature data'}  # Filtered out
]
```

**Processing**:
- `format_content_blocks` method processes each block individually
- Block types: `'thinking'`, `'text'`, `'input'`
- Signature blocks are skipped (type filter in block_map)
- Escaped `\n` in content is converted to actual newlines

#### Pattern 2: String Content (Text Message)

**Condition**: `content.is_a?(String)`

**Structure**: Plain text message from user or assistant
```ruby
content = "Hello\nWorld\nMultiple lines"
```

**Processing**:
- Escaped newlines `\n` (backslash-n) are converted to actual newlines via `gsub('\\n', "\n")`
- Content is included as-is in markdown output

#### Pattern 3: Unknown/Other Types

**Condition**: Any other type (rare, defensive coding)

**Processing**:
- Convert to string via `to_s`
- Apply same `\n` conversion logic

### Signature Filtering

Signatures are filtered at two levels to prevent trace data from appearing in Obsidian output:

#### Level 1: Message-Level Signature (Line 157)
```ruby
next if msg['signature']  # Skip entire message if signature field exists
```

This skips messages that contain a top-level `signature` field (tracing data).

#### Level 2: Block-Level Signature (Line 202-208)
```ruby
block_config = block_map[block_type]
next if block_config.nil?  # Skips blocks with type not in block_map
```

The `block_map` only includes `'thinking'`, `'text'`, and `'input'` types, so `'signature'` blocks are automatically filtered out.

### Newline Conversion

Escaped newlines (`\n` as two characters: backslash + n) are converted to actual newlines:

**Line 164**:
```ruby
content = content.gsub('\\n', "\n") if content.is_a?(String)
```

**Line 212**:
```ruby
content_text = content_text.gsub('\\n', "\n") if content_text.is_a?(String)
```

This ensures that:
- Multi-line content displays correctly in Obsidian
- Philosophy: `\n` in JSON becomes actual newlines in markdown output
- Applies to both top-level message content and block content

### Test Coverage

See `test/test_claude_history_to_obsidian.rb` for comprehensive test cases:

- `test_build_markdown_with_content_array_blocks` - Array content with multiple block types
- `test_build_markdown_filters_out_signature_blocks` - Signature filtering
- `test_build_markdown_handles_input_blocks` - Input block type handling
- `test_build_markdown_with_array_content` - Array content format
