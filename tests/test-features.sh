#!/usr/bin/env bash
# z-tmux Feature Test Suite
# Validates all tmux configuration features work correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Test session name
TEST_SESSION="z-tmux-test-$$"

# Helper functions
log_pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASSED=$((PASSED + 1))
}

log_fail() {
  echo -e "${RED}✗${NC} $1"
  FAILED=$((FAILED + 1))
}

log_skip() {
  echo -e "${YELLOW}○${NC} $1 (skipped)"
  SKIPPED=$((SKIPPED + 1))
}

log_section() {
  echo -e "\n${BLUE}━━━ $1 ━━━${NC}"
}

# Check if a tmux option equals expected value
check_option() {
  local option="$1"
  local expected="$2"
  local scope="${3:-}" # -g, -w, -s, or empty

  local actual
  if [ -n "$scope" ]; then
    actual=$(tmux show-option $scope -v "$option" 2>/dev/null || echo "NOT_SET")
  else
    actual=$(tmux show-option -gv "$option" 2>/dev/null || echo "NOT_SET")
  fi

  if [ "$actual" = "$expected" ]; then
    log_pass "$option = $expected"
    return 0
  else
    log_fail "$option: expected '$expected', got '$actual'"
    return 1
  fi
}

# Check if a key binding exists
check_binding() {
  local key="$1"
  local description="$2"
  local table="${3:-prefix}"

  # For special characters like $, check both escaped and unescaped forms
  local search_pattern="$key"
  if [ "$key" = '$' ]; then
    search_pattern='\$'
  fi

  if tmux list-keys -T "$table" 2>/dev/null | grep -qF "$search_pattern"; then
    log_pass "Binding: $key ($description)"
    return 0
  else
    log_fail "Binding: $key ($description) not found"
    return 1
  fi
}

# Check if a command exists in PATH
check_command() {
  local cmd="$1"

  if command -v "$cmd" >/dev/null 2>&1; then
    log_pass "Command: $cmd available"
    return 0
  else
    log_fail "Command: $cmd not found"
    return 1
  fi
}

# Check if plugin loaded (by checking its options or bindings)
check_plugin() {
  local plugin="$1"
  local check_cmd="$2"

  if eval "$check_cmd" >/dev/null 2>&1; then
    log_pass "Plugin: $plugin loaded"
    return 0
  else
    log_fail "Plugin: $plugin not loaded"
    return 1
  fi
}

# Cleanup function
cleanup() {
  if tmux has-session -t "$TEST_SESSION" 2>/dev/null; then
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ════════════════════════════════════════════════════════════════════════════
# TESTS
# ════════════════════════════════════════════════════════════════════════════

main() {
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║              z-tmux Feature Test Suite                         ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

  # Check if we're in tmux
  if [ -z "${TMUX:-}" ]; then
    echo -e "${RED}Error: Must run inside tmux session${NC}"
    echo "Usage: z-tmux-test && then run this script inside tmux"
    exit 1
  fi

  # Check if we're in z-tmux environment
  if [ -z "${TMUX_PLUGIN_MANAGER_PATH:-}" ]; then
    echo -e "${YELLOW}Warning: Not running in z-tmux-test environment${NC}"
    echo -e "${YELLOW}Some tests may fail. For full testing, run: z-tmux-test${NC}"
    echo ""
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Core Settings"
  # ══════════════════════════════════════════════════════════════════════════

  check_option "default-terminal" "tmux-256color"
  check_option "prefix" "C-b"
  check_option "mode-keys" "vi"
  check_option "mouse" "on"
  check_option "history-limit" "50000"
  check_option "base-index" "1"
  check_option "escape-time" "0"
  check_option "focus-events" "on"
  check_option "renumber-windows" "on"
  check_option "allow-rename" "off"

  # Window options (require -gw flag for global window options)
  check_option "pane-base-index" "1" "-gw"
  check_option "monitor-activity" "on" "-gw"

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Status Bar"
  # ══════════════════════════════════════════════════════════════════════════

  check_option "status" "on"
  check_option "status-position" "top"
  check_option "status-interval" "5"
  check_option "status-left-length" "50"
  check_option "status-right-length" "100"

  # Check status-left contains session indicator
  local status_left
  status_left=$(tmux show-option -gv status-left 2>/dev/null || echo "")
  if echo "$status_left" | grep -q "#S"; then
    log_pass "status-left contains session name (#S)"
  else
    log_fail "status-left missing session name (#S)"
  fi

  # Check status-right is configured (may contain hostname, path, or other info)
  local status_right
  status_right=$(tmux show-option -gv status-right 2>/dev/null || echo "")
  if [ -n "$status_right" ]; then
    if echo "$status_right" | grep -qE "#h|pane_current_path|continuum"; then
      log_pass "status-right configured with dynamic content"
    else
      log_pass "status-right configured"
    fi
  else
    log_fail "status-right not configured"
  fi

  # Check status-right contains tmux version format T(#{version})
  if echo "$status_right" | grep -q 'T(#{version})'; then
    log_pass "status-right contains tmux version T(#{version})"
  else
    log_skip "status-right tmux version format (may be different config)"
  fi

  # Check status-right contains user@hostname format
  if echo "$status_right" | grep -qE '\$USER@#h|#h'; then
    log_pass "status-right contains hostname indicator"
  else
    log_skip "status-right hostname format (may be different config)"
  fi

  # Check status-right contains N(version) format when configured
  # This tests the Nix repo version feature - may be omitted if not configured
  if echo "$status_right" | grep -qE 'N\([^)]+\)'; then
    log_pass "status-right contains Nix version N(version)"
  else
    log_skip "status-right Nix version (nixRepoVersion not configured)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Key Bindings"
  # ══════════════════════════════════════════════════════════════════════════

  # Core bindings
  check_binding "r" "reload config"
  check_binding "|" "split horizontal"
  check_binding "-" "split vertical"
  check_binding "c" "new window"
  check_binding "," "rename window"
  check_binding "\$" "rename session"

  # Pane navigation (vim-style)
  check_binding "h" "pane left"
  check_binding "j" "pane down"
  check_binding "k" "pane up"
  check_binding "l" "pane right"

  # Pane resize
  check_binding "H" "resize left"
  check_binding "J" "resize down"
  check_binding "K" "resize up"
  check_binding "L" "resize right"

  # Misc bindings
  check_binding "p" "popup"
  check_binding "s" "choose-tree"
  check_binding "Enter" "copy-mode"
  check_binding "S" "save-layout"

  # Resurrect bindings
  check_binding "C-s" "resurrect save"
  check_binding "C-r" "resurrect restore"

  # Copy-mode bindings
  check_binding "v" "begin-selection" "copy-mode-vi"
  check_binding "y" "copy-selection" "copy-mode-vi"
  check_binding "MouseDragEnd1Pane" "copy on select" "copy-mode-vi"

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Which-Key"
  # ══════════════════════════════════════════════════════════════════════════

  # Check which-key Space binding
  if tmux list-keys -T prefix 2>/dev/null | grep -q "Space"; then
    log_pass "Which-key: Space binding exists"
  else
    log_fail "Which-key: Space binding not found"
  fi

  # Check which-key init.tmux exists
  if [ -f "$HOME/.tmux/plugins/tmux-which-key/init.tmux" ]; then
    log_pass "Which-key: init.tmux deployed"
  else
    log_fail "Which-key: init.tmux not found at ~/.tmux/plugins/tmux-which-key/"
  fi

  # Check which-key config.yaml exists
  if [ -f "$HOME/.tmux/plugins/tmux-which-key/config.yaml" ]; then
    log_pass "Which-key: config.yaml deployed"
  else
    log_fail "Which-key: config.yaml not found"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Plugins"
  # ══════════════════════════════════════════════════════════════════════════

  # Check plugin options/bindings as evidence of loading
  check_plugin "resurrect" "tmux show-option -gv @resurrect-dir"
  check_plugin "continuum" "tmux show-option -gv @continuum-save-interval"
  # yank plugin creates y/Y bindings in prefix table
  check_plugin "yank" "tmux list-keys -T prefix | grep -q 'yank'"
  check_plugin "logging" "tmux show-option -gv @logging-path"

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Plugin Nix Store Paths"
  # ══════════════════════════════════════════════════════════════════════════

  # Verify plugins are loaded from Nix store paths (not TPM or local paths)
  # This ensures the Nix-bundled plugins are being used

  # sensible - check run-shell path exists in bindings
  if tmux list-keys 2>/dev/null | grep -q "tmuxplugin-sensible"; then
    log_pass "Plugin path: sensible (Nix store)"
  elif tmux show-options -g | grep -qE "escape-time 0|history-limit"; then
    # sensible modifies options, so we can infer it's loaded
    log_pass "Plugin path: sensible (via options)"
  else
    log_fail "Plugin path: sensible not found"
  fi

  # open - adds 'o' binding in copy-mode to open URLs/files
  if tmux list-keys -T copy-mode-vi 2>/dev/null | grep -qE "tmuxplugin-open|open.*open"; then
    log_pass "Plugin path: open (Nix store)"
  elif tmux list-keys -T copy-mode-vi 2>/dev/null | grep -q "\\bo\\b.*open"; then
    log_pass "Plugin path: open (via binding)"
  else
    log_fail "Plugin path: open not found"
  fi

  # sessionist - adds @ C X t bindings for session management
  if tmux list-keys -T prefix 2>/dev/null | grep -q "tmuxplugin-sessionist"; then
    log_pass "Plugin path: sessionist (Nix store)"
  else
    log_fail "Plugin path: sessionist not found in Nix store"
  fi

  # copycat - adds C-f C-u regex search bindings
  if tmux list-keys -T prefix 2>/dev/null | grep -q "tmuxplugin-copycat"; then
    log_pass "Plugin path: copycat (Nix store)"
  else
    log_fail "Plugin path: copycat not found in Nix store"
  fi

  # cowboy - adds * binding to kill unresponsive processes
  if tmux list-keys -T prefix 2>/dev/null | grep -q "tmuxplugin-cowboy"; then
    log_pass "Plugin path: cowboy (Nix store)"
  else
    log_fail "Plugin path: cowboy not found in Nix store"
  fi

  # prefix-highlight - modifies status format (harder to verify path directly)
  # Check if it added the prefix highlight format strings
  local status_left
  status_left=$(tmux show-option -gv status-left 2>/dev/null || echo "")
  local status_right
  status_right=$(tmux show-option -gv status-right 2>/dev/null || echo "")
  if echo "$status_left$status_right" | grep -qE "prefix_highlight|#{prefix"; then
    log_pass "Plugin path: prefix-highlight (via status format)"
  else
    # Plugin may be loaded but not using its format strings
    log_skip "Plugin path: prefix-highlight (format strings not in status)"
  fi

  # Check TMUX_PLUGIN_MANAGER_PATH is set
  local plugin_path
  plugin_path=$(tmux show-environment TMUX_PLUGIN_MANAGER_PATH 2>/dev/null || echo "")
  if [ -n "$plugin_path" ]; then
    log_pass "TMUX_PLUGIN_MANAGER_PATH set"
  elif [ -n "${TMUX_PLUGIN_MANAGER_PATH:-}" ]; then
    # We have it in shell env but not in tmux env
    log_pass "TMUX_PLUGIN_MANAGER_PATH in shell environment"
  else
    log_skip "TMUX_PLUGIN_MANAGER_PATH (requires z-tmux environment)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Helper Scripts"
  # ══════════════════════════════════════════════════════════════════════════

  check_command "tmux-workspace"
  check_command "tmuxp-loader"
  check_command "tmux-save-layout"
  check_command "tmux-split-window"
  check_command "tmux-claude-dev"
  check_command "tmux-claude-monitor"
  check_command "tmux-claude-clear-waiting"

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Runtime Environment"
  # ══════════════════════════════════════════════════════════════════════════

  # Check runtime PATH includes necessary tools
  local tmux_path
  tmux_path=$(tmux show-environment PATH 2>/dev/null | sed 's/^PATH=//' || echo "")

  # These are the runtime deps that plugin scripts need
  local runtime_tools=("ps" "grep" "awk" "sed" "kill")

  for tool in "${runtime_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      log_pass "Runtime tool: $tool available"
    else
      log_fail "Runtime tool: $tool not found"
    fi
  done

  # Check environment variables
  if [ -n "${ZTMUX_WORKSPACES_DIR:-}" ]; then
    log_pass "ZTMUX_WORKSPACES_DIR set: $ZTMUX_WORKSPACES_DIR"
  else
    log_skip "ZTMUX_WORKSPACES_DIR not set (uses default)"
  fi

  if [ -n "${ZTMUX_RESURRECT_DIR:-}" ]; then
    log_pass "ZTMUX_RESURRECT_DIR set: $ZTMUX_RESURRECT_DIR"
  else
    log_skip "ZTMUX_RESURRECT_DIR not set (uses default)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Shell Configuration"
  # ══════════════════════════════════════════════════════════════════════════

  # Check default-shell
  local default_shell
  default_shell=$(tmux show-option -gv default-shell 2>/dev/null || echo "NOT_SET")
  if [ "$default_shell" != "NOT_SET" ]; then
    log_pass "default-shell: $default_shell"
  else
    log_fail "default-shell not configured"
  fi

  # Check default-command (for macOS clipboard support)
  local default_cmd
  default_cmd=$(tmux show-option -gv default-command 2>/dev/null || echo "NOT_SET")
  if echo "$default_cmd" | grep -q "reattach-to-user-namespace"; then
    log_pass "default-command uses reattach-to-user-namespace"
  else
    log_skip "default-command: reattach-to-user-namespace not found (may be Linux)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Hooks"
  # ══════════════════════════════════════════════════════════════════════════

  # Check pane-focus-in hook for claude waiting indicator
  # This hook is set by set-hook command and stored differently
  local hook_value
  hook_value=$(tmux show-hooks -g pane-focus-in 2>/dev/null || echo "")
  if echo "$hook_value" | grep -q "@claude_waiting"; then
    log_pass "Hook: pane-focus-in clears @claude_waiting"
  elif [ -n "${TMUX_PLUGIN_MANAGER_PATH:-}" ]; then
    # Only fail if we're in z-tmux environment
    log_fail "Hook: pane-focus-in @claude_waiting not found"
  else
    log_skip "Hook: pane-focus-in (requires z-tmux environment)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  log_section "Config Syntax Validation"
  # ══════════════════════════════════════════════════════════════════════════

  # Try to source the config (this would fail if syntax errors)
  if [ -f ~/.tmux.conf ]; then
    if tmux source-file ~/.tmux.conf 2>&1; then
      log_pass "Config syntax valid (source-file succeeded)"
    else
      log_fail "Config has syntax errors"
    fi
  elif [ -n "${TMUX_PLUGIN_MANAGER_PATH:-}" ]; then
    # In z-tmux environment, config should exist
    log_fail "~/.tmux.conf not found (should be symlinked by z-tmux-test)"
  else
    log_skip "Config syntax (no ~/.tmux.conf found)"
  fi

  # ══════════════════════════════════════════════════════════════════════════
  # Summary
  # ══════════════════════════════════════════════════════════════════════════

  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}                         Test Summary                           ${NC}"
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${GREEN}Passed:${NC}  $PASSED"
  echo -e "  ${RED}Failed:${NC}  $FAILED"
  echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
  echo ""

  if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed. Review output above.${NC}"
    exit 1
  fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
