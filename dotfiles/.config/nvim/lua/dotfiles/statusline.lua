local M = {}
local api = vim.api
local icons = require('dotfiles.icons')

-- This is the "EN SPACE" character. Regular and unbreakable spaces sometimes
-- get swallowed in statuslines. This kind of space doesn't.
-- local forced_space = utf8.char(8194)
local forced_space = string.char(226, 128, 130)

local preview = '%w'
local modified = '%m'
local readonly = '%r'
local separator = '%='
local active_hl = 'BlackOnLightYellow'

local function diagnostic_count(buffer, kind)
  local amount = vim.lsp.diagnostic.get_count(buffer, kind)

  if amount > 0 then
    return forced_space .. kind:sub(1, 1) .. ': ' .. amount .. forced_space
  else
    return ''
  end
end

local function highlight(text, group)
  return '%#' .. group .. '#' .. text .. '%*'
end

-- Renders the status line.
function M.render()
  local window = vim.g.statusline_winid
  local active = window == api.nvim_get_current_win()
  local buffer = api.nvim_win_get_buf(window)
  local name = ' ' .. icons.icon(vim.fn.bufname(buffer)) .. '%f '
  local has_qf_title, qf_title =
    pcall(api.nvim_win_get_var, window, 'quickfix_title')

  return table.concat({
    active and highlight(name, active_hl) or name,
    has_qf_title and ' ' .. qf_title or '',
    ' ',
    preview,
    modified,
    readonly,
    separator,
    highlight(diagnostic_count(buffer, 'Warning'), 'WhiteOnYellow'),
    highlight(diagnostic_count(buffer, 'Error'), 'WhiteOnRed'),
  })
end

return M
