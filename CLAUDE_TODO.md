# 📝 CLAUDE_TODO - Improvement Checklist

Project-wide improvement items based on full codebase analysis.

---

## 🔴 Critical (Immediate Action)

- [ ] **Log Timezone Unification** (✅ Safe - No Side Effects)
  - **File**: `lib/claude_history_importer.rb:133`
  - **Change**: Update timestamp format from `'%Y-%m-%d %H:%M:%S'` to `'%Y-%m-%d %H:%M:%S %z'`
  - **Current Code**:
    ```ruby
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    ```
  - **Proposed Code**:
    ```ruby
    timestamp = Time.now.getlocal.strftime('%Y-%m-%d %H:%M:%S %z')
    ```
  - **Why**:
    - `ClaudeHistoryToObsidian` already uses `%z` format (lib/claude_history_to_obsidian.rb:367)
    - Unifies log format across both classes for consistency
    - Improves debugging by explicitly showing timezone offset
  - **Safety Analysis** (✅ Safe):
    - **grep/awk parsing**: NOT used in this project
    - **Log analysis method**: All analysis is JSON-based (JSON.parse)
    - **Impact on JSON parsing**: ZERO - timestamp format is metadata, not structured data
    - **Impact on Ruby code**: ZERO - all timestamp handling uses Time.parse which is format-agnostic
    - **Real-world usage**: Only manual log reading benefits from timezone visibility
  - **Verification Performed**:
    - Searched entire codebase for grep/awk/sed usage on log files: NONE found
    - Verified all timestamp processing uses JSON.parse or Time.parse: CONFIRMED
    - Tested mixed-format logs with Ruby JSON parser: WORKS fine
  - **Confidence Level**: HIGH - Safe to apply immediately

---

## 🟠 High Priority (Important Improvements)

- [ ] **Remove Unused Legacy File**
  - **File**: `bin/claude-history-import`
  - **Action**: Delete (superseded by Rakefile bulk_import task)
  - **Reason**: No longer used; causes confusion in documentation

- [ ] **Test Coverage Visibility**
  - **Files**: `test/test_helper.rb`, `.gitignore`
  - **Action**: Add SimpleCov initialization to test_helper.rb
  - **Action**: Verify `coverage/` is in `.gitignore`
  - **Reason**: `rake test:coverage` needs working setup

- [ ] **Notification Feature Testing**
  - **File**: `test/test_claude_history_to_obsidian.rb:962-975`
  - **Action**: Add proper mock-based test for `notify` method
  - **Reason**: Current test only verifies no errors; should test actual notification

- [ ] **Error Handling Documentation**
  - **File**: `.claude/specifications.md`
  - **Action**: Add section documenting error behavior differences:
    - Hook mode: Always exits 0 (non-blocking)
    - Bulk Import mode: Exits non-zero on errors
  - **Reason**: Clarify intentional design difference

---

## 🟡 Medium Priority (Usability Enhancements)

- [ ] **File Collision Detection**
  - **File**: `lib/claude_history_to_obsidian.rb:337-344` (save_to_vault)
  - **Action**: Add warning log when overwriting existing file
  - **Reason**: Detect unintended overwrites of session files

- [ ] **Web Import Specification Update**
  - **File**: `.claude/specifications.md`
  - **Action**: Document filename format differences between Web and Code sources
  - **Reason**: Current spec doesn't clearly explain Web import format

- [ ] **Test Mode Documentation**
  - **Files**: `CLAUDE.md`, `.claude/skills/ruby-testing/SKILL.md`, `.claude/skills/hook-integration/SKILL.md`
  - **Action**: Add concrete examples of using `CLAUDE_VAULT_MODE=test`
  - **Reason**: Feature exists but usage examples are sparse

---

## 🔵 Low Priority (Nice to Have)

- [ ] **Content Block Type Extensibility**
  - **File**: `lib/claude_history_to_obsidian.rb:230-246` (format_content_blocks)
  - **Action**: Handle unknown block types gracefully (warn and pass through)
  - **Reason**: Future-proof for new message block types

- [ ] **Session Name Test Coverage**
  - **File**: `test/test_claude_history_to_obsidian.rb:101-165`
  - **Action**: Add edge case tests:
    - Array with missing `type` field
    - Array with nil elements
    - Empty array
  - **Reason**: Improve robustness for unexpected message formats

- [ ] **Web Hook Support Clarification**
  - **File**: `README.md:82-86`
  - **Action**: Clarify whether Claude Web has native hook support or recommend bulk import
  - **Reason**: Current doc suggests Web hook is available but unclear how to set up

- [ ] **Bulk Import Error Reporting**
  - **File**: `Rakefile:71`
  - **Action**: Add detailed error session logging
  - **Reason**: Currently shows error count but not which sessions failed

---

## 📚 Documentation Tasks

- [ ] **Skill Role Clarification**
  - **Files**: `.claude/skills/ruby-testing/SKILL.md`, `.claude/skills/hook-integration/SKILL.md`
  - **Action**: Explicitly define use cases:
    - `ruby-testing`: Unit tests, local testing with sample JSON
    - `hook-integration`: E2E tests, Hook simulation, transcript verification
  - **Reason**: Reduce user confusion about which skill to use

- [ ] **References Directory Index**
  - **File**: `.claude/references/README.md` (create new)
  - **Action**: Create overview file listing all references with descriptions
  - **Reason**: Help users navigate documentation

- [ ] **Timezone Specification Consolidation**
  - **Files**: `.claude/specifications.md`, `.claude/references/timezone-fix-specification.md`
  - **Action**: Consolidate timezone handling rules into main spec, link from other docs
  - **Reason**: Currently scattered across multiple files

- [ ] **test/run_all_tests.rb Verification**
  - **File**: `Rakefile:9`
  - **Action**: Verify `test/run_all_tests.rb` exists and works
  - **Reason**: `rake test:coverage` depends on this file

- [ ] **Git Subtree Documentation Review**
  - **File**: `.claude/practices.md:15-16`
  - **Action**: Verify if Git Subtree management is actually used in this project
  - **Action**: If not used, remove or clarify as external reference
  - **Reason**: Currently suggests feature that may not be relevant

---

## 📊 Summary

| Priority | Count | Impact |
|---|---|---|
| 🔴 Critical | 1 | Must verify before applying |
| 🟠 High | 4 | Quality & clarity improvements |
| 🟡 Medium | 3 | User experience enhancements |
| 🔵 Low | 4 | Future-proofing & robustness |
| 📚 Documentation | 5 | Knowledge organization |
| **TOTAL** | **17** | |

---

## 🎯 Recommended Execution Order

1. **Critical** → Verify and apply
2. **High** → Improves code quality immediately
3. **Medium** → Enhances day-to-day usability
4. **Low** → Future-proof improvements
5. **Documentation** → Knowledge consolidation (ongoing)

チェケラッチョ！すべての改善項目をリストアップしたピョン！
