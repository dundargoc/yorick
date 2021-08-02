-- Functions invoked from VimL, such as when a key is pressed.
local M = {}

local completion = require('dotfiles.completion')
local pairs = require('dotfiles.pairs')
local util = require('dotfiles.util')
local icons = require('dotfiles.icons')
local dv = require('diffview')
local dv_lib = require('diffview.lib')
local diff = require('dotfiles.diff')

local keycode = util.keycode
local popup_visible = util.popup_visible
local api = vim.api
local fn = vim.fn
local lsp = vim.lsp

-- The namespace to use for restoring cursors after formatting a buffer.
local format_mark_ns = api.nvim_create_namespace('')

function M.yanked()
  vim.highlight.on_yank({
    higroup = 'Visual',
    timeout = 150,
    on_visual = false
  })
end

function M.abbreviate_grep()
  if fn.getcmdtype() == ':' and fn.getcmdline():match('^grep') then
    return 'silent grep!'
  else
    return 'grep'
  end
end

function M.terminal(cmd)
  vim.cmd(cmd)
  vim.cmd('term')
  vim.cmd('startinsert')
end

-- Finds all occurrences of text stored in register A, replacing it with the
-- contents of register B.
function M.find_replace_register(find, replace)
  local cmd = '%s/\\V'
    .. fn.escape(fn.getreg(find), '/'):gsub('\n', '\\n')
    .. '/'
    .. fn.escape(fn.getreg(replace), '/&'):gsub('\n', '\\r')
    .. '/g'

  print(cmd)

  vim.cmd(cmd)
end

function M.remove_trailing_whitespace()
  local line = fn.line('.')
  local col = fn.col('.')

  vim.cmd([[%s/\s\+$//eg]])
  fn.cursor(line, col)
end

function M.format_buffer()
  local bufnr = api.nvim_win_get_buf(0)
  local windows = fn.win_findbuf(bufnr)
  local marks = {}

  -- Until https://github.com/neovim/neovim/issues/14645 is solved, I use this
  -- code to ensure the cursor position is properly restored after formatting a
  -- buffer. The approach used supports restoring cursors for different windows
  -- using the same buffer.
  for _, window in ipairs(windows) do
    local line, col = unpack(api.nvim_win_get_cursor(window))

    marks[window] =
      api.nvim_buf_set_extmark(bufnr, format_mark_ns, line - 1, col, {})
  end

  lsp.buf.formatting_sync(nil, 1000)

  for _, window in ipairs(windows) do
    local mark = marks[window]

    local line, col =
      unpack(api.nvim_buf_get_extmark_by_id(bufnr, format_mark_ns, mark, {}))

    if line and col then
      api.nvim_win_set_cursor(window, { line + 1, col })
    end
  end

  api.nvim_buf_clear_namespace(bufnr, format_mark_ns, 0, -1)
end

function M.fzf_statusline()
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.statusline = 'FZF'
  vim.opt_local.signcolumn = 'no'

  vim.cmd('silent file FZF')
end

function M.review(rev)
  dv.open(rev)

  local view = dv_lib.get_current_diffview()

  if view then
    diff.fix_highlight(view.left_winid, { force = true })
  end
end

return M
