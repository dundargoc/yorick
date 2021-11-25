local M = {}
local util = require('dotfiles.util')
local au = util.au
local keycode = util.keycode
local fn = vim.fn
local lsp = vim.lsp
local api = vim.api

-- The namespace to use for restoring cursors after formatting a buffer.
local format_mark_ns = api.nvim_create_namespace('')

function M.remove_trailing_whitespace()
  local line = fn.line('.')
  local col = fn.col('.')

  -- In .snippets files, a line may start with just a tab so snippets can
  -- include empty lines. In this case we don't want to remove the tab.
  if vim.bo.ft == 'snippets' then
    vim.cmd([[%s/ \+$//eg]])
  else
    vim.cmd([[%s/\s\+$//eg]])
  end

  fn.cursor(line, col)
end

function M.yanked()
  vim.highlight.on_yank({
    higroup = 'Visual',
    timeout = 150,
    on_visual = false,
  })
end

function M.format_buffer()
  if not util.has_lsp_clients() then
    return
  end

  local bufnr = api.nvim_win_get_buf(0)
  local windows = fn.win_findbuf(bufnr)
  local marks = {}

  -- Until https://github.com/neovim/neovim/issues/14645 is solved, I use this
  -- code to ensure the cursor position is properly restored after formatting a
  -- buffer. The approach used supports restoring cursors for different windows
  -- using the same buffer.
  for _, window in ipairs(windows) do
    local line, col = unpack(api.nvim_win_get_cursor(window))

    marks[window] = api.nvim_buf_set_extmark(
      bufnr,
      format_mark_ns,
      line - 1,
      col,
      {}
    )
  end

  lsp.buf.formatting_sync(nil, 5000)

  for _, window in ipairs(windows) do
    local mark = marks[window]

    local line, col = unpack(
      api.nvim_buf_get_extmark_by_id(bufnr, format_mark_ns, mark, {})
    )

    local max_line_index = api.nvim_buf_line_count(bufnr) - 1

    if line and col and line <= max_line_index then
      api.nvim_win_set_cursor(window, { line + 1, col })
    end
  end

  api.nvim_buf_clear_namespace(bufnr, format_mark_ns, 0, -1)
end

-- Moves back to the previous window when closing a quickfix window, unless we
-- closed the quickfix window from another window (e.g. using `:cclose`).
function M.close_quickfix()
  local closed_win = tonumber(fn.expand('<afile>'))
  local current_win = api.nvim_get_current_win()

  if closed_win == current_win then
    api.nvim_feedkeys(keycode('<C-w>p'), 'n', true)
  end
end

function M.toggle_list(enter)
  if enter then
    vim.w.list_enabled = vim.wo.list
    vim.wo.list = false
  elseif vim.w.list_enabled ~= nil then
    vim.wo.list = vim.w.list_enabled
  end
end

au('completion', { 'CompleteDonePre * lua dotfiles.completion.done()' })

au('filetypes', {
  'BufRead,BufNewFile *.rll set filetype=rll',
  'BufRead,BufNewFile Dangerfile set filetype=ruby',
})

au('yank', { 'TextYankPost * lua dotfiles.hooks.yanked()' })

au('trailing_whitespace', {
  'BufWritePre * lua dotfiles.hooks.remove_trailing_whitespace()',
  'InsertEnter * lua dotfiles.hooks.toggle_list(true)',
  'InsertLeave * lua dotfiles.hooks.toggle_list(false)',
})

-- LSP and linting
au('lsp', {
  'BufWritePre * lua dotfiles.hooks.format_buffer()',
  'CursorMoved * lua dotfiles.diagnostics.echo_diagnostic()',
  'BufWinEnter * lua dotfiles.location_list.enter_window()',
  'DiagnosticChanged * lua dotfiles.location_list.diagnostics_changed()',
  'User LspProgressUpdate redrawtabline',
})

-- Fix diff highlights in fugitive
au('fugitive', {
  'BufAdd fugitive://* lua require("dotfiles.diff").fix_highlight()',
})

-- Automatically create leading directories when writing a file. This makes it
-- easier to create new files in non-existing directories.
au('create_dirs', { "BufWritePre * call mkdir(expand('<afile>:p:h'), 'p')" })

-- Open the quickfix window at the bottom when using `:grep`.
au('grep_quickfix', { 'QuickFixCmdPost grep cwindow' })

-- Highlight all search matches while searching, but not when done searching.
au('search_highlight', {
  [[CmdlineEnter [/\?] :set hlsearch]],
  [[CmdlineLeave [/\?] :set nohlsearch]],
})

return M
