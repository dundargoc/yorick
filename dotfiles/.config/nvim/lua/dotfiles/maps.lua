local M = {}

local completion = require('dotfiles.completion')
local dpairs = require('dotfiles.pairs')
local util = require('dotfiles.util')
local window = require('nvim-window')
local telescope_builtin = require('telescope.builtin')
local parsers = require('nvim-treesitter.parsers')
local snippy = require('snippy')
local pickers = require('dotfiles.telescope.pickers')
local quickfix = require('dotfiles.quickfix')
local pounce = require('pounce')
local loclist = require('dotfiles.location_list')

local keycode = util.keycode
local popup_visible = util.popup_visible
local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local g = vim.g
local diag = vim.diagnostic
local keymap = vim.keymap

-- The LSP symbols to include when using Telescope.
local ts_lsp_symbols = {
  Class = true,
  Constant = true,
  Constructor = true,
  Enum = true,
  EnumMember = true,
  Function = true,
  Interface = true,
  Method = true,
  Module = true,
  Reference = true,
  Snippet = true,
  Struct = true,
  TypeParameter = true,
  Unit = true,
  Value = true,
}

local function map(kind, key, action, options)
  local opts = vim.tbl_extend('force', { silent = true }, options or {})

  keymap.set(kind, key, action, opts)
end

local function cmd(string)
  return '<cmd>' .. string .. '<CR>'
end

local function pair(key, func)
  return map('i', key, dpairs[func], { remap = false, expr = true })
end

-- The leader key must be defined before any mappings are set.
g.mapleader = ' '
g.maplocalleader = ' '

-- Generic
map('', '<space>', '<nop>')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')
map('n', '<C-h>', '<C-w>h')
map('n', '<leader>F', lsp.buf.format)
map('n', '<leader>s', cmd('update'))

-- Window management
map('n', '<leader>w', window.pick)
map('n', '<leader>c', cmd('quit'))
map('n', '<leader>v', cmd('vsplit'))
map('n', '<leader>k', cmd('split'))
map('n', '<leader>l', loclist.toggle)
map('n', '<leader>q', quickfix.toggle)

-- Going places
map('', 'gs', '^')
map('', 'gl', 'g_')

map({ 'n', 'x' }, 's', pounce.pounce)
map({ 'n', 'x' }, 'S', function()
  pounce.pounce({ do_repeat = true })
end)

map('v', 'y', 'ygv<Esc>')

-- Use d/dd for actually deleting, while using dx for cutting the line.
map('n', 'dx', 'dd', { noremap = true })
map('n', 'dd', '"_dd', { noremap = true })
map('n', 'd', '"_d', { noremap = true })
map('v', 'd', '"_d', { noremap = true })

-- Allow copy/pasting using Control-c and Control-v
map('v', '<C-c>', '"+y')
map('i', '<C-v>', '<Esc>"+pa')
map('t', '<C-s-v>', [[<C-\><C-n>"+pa]])

-- Code and pairs completion
map('i', '<CR>', function()
  return dpairs.enter()
end, { expr = true })

map('i', '<Esc>', function()
  return popup_visible() and '<C-e><Esc>' or '<Esc>'
end, { expr = true })

pair('<space>', 'space')
pair('<S-space>', 'space')
pair('<bs>', 'backspace')
pair('<S-bs>', 'backspace')

pair('{', 'curly_open')
pair('}', 'curly_close')

pair('[', 'bracket_open')
pair(']', 'bracket_close')

pair('(', 'paren_open')
pair(')', 'paren_close')

pair('<', 'angle_open')
pair('>', 'angle_close')

pair("'", 'single_quote')
pair('"', 'double_quote')
pair('`', 'backtick')

map('i', '<tab>', function()
  if popup_visible() then
    api.nvim_feedkeys(keycode('<C-n>'), 'n', true)
    return
  end

  local col = fn.col('.') - 1

  if col == 0 or api.nvim_get_current_line():sub(col, col):match('%s') then
    api.nvim_feedkeys(keycode('<tab>'), 'n', true)
  else
    completion.start()
  end
end)

map('i', '<S-tab>', function()
  return popup_visible() and '<C-p>' or '<S-tab>'
end, { expr = true })

map('v', '<s-tab>', '<')
map('v', '<tab>', '>')

-- LSP
map('n', '<leader>h', vim.lsp.buf.hover)
map('n', '<leader>n', vim.lsp.buf.rename)
map('n', '<leader>d', function()
  local bufnr = api.nvim_get_current_buf()

  if util.has_lsp_clients_supporting(bufnr, 'goto_definition') then
    lsp.buf.definition()
  else
    api.nvim_feedkeys(keycode('<C-]>'), 'm', true)
  end
end)

map('n', '<leader>z', function()
  diag.setqflist({ severity = { min = vim.diagnostic.severity.WARN } })
end)

map('n', '<leader>r', function()
  lsp.buf.references({ includeDeclaration = false })
end)

-- Shows all implementations of an interface.
--
-- The function `vim.lsp.buf.implementation()` automatically jumps to the first
-- location, which I don't like.
map('n', '<leader>i', function()
  local bufnr = api.nvim_get_current_buf()
  local params = lsp.util.make_position_params()

  lsp.buf_request_all(
    bufnr,
    'textDocument/implementation',
    params,
    function(response)
      for _, result in ipairs(response) do
        if result.result then
          local items = result.result

          if not vim.tbl_islist(result.result) then
            items = { items }
          end

          if #items > 0 then
            fn.setqflist({}, ' ', {
              title = 'Implementations',
              items = lsp.util.locations_to_items(items, 'utf-8'),
            })
            vim.cmd('copen')
          end
        end
      end
    end
  )
end)

map('n', '<leader>a', vim.lsp.buf.code_action)
map('n', '<leader>e', function()
  diag.open_float(0, { scope = 'line' })
end)

-- Searching
map('n', 'K', cmd([[silent grep! '\b<cword>\b']]))
map('n', '<leader>g', ':silent grep! ', { silent = false })

-- Telescope
map('n', '<leader>f', function()
  telescope_builtin.find_files({
    hidden = true,
    find_command = { 'rg', '--files', '--color', 'never' },
  })
end)

map('n', '<leader>t', function()
  local bufnr = api.nvim_get_current_buf()
  local ft = api.nvim_buf_get_option(bufnr, 'ft')

  if util.has_lsp_clients_supporting(bufnr, 'document_symbol') then
    pickers.lsp_document_symbols(bufnr, {
      -- Lua exposes variables as constants for some weird reason
      ignore_scoped_constants = ft == 'lua',
      symbols = ts_lsp_symbols,
      previewer = false,
      results_title = false,
      prompt_title = false,
    })

    return
  end

  if parsers.has_parser() then
    telescope_builtin.treesitter()
    return
  end

  telescope_builtin.current_buffer_tags()
end)

map('n', '<leader>b', telescope_builtin.buffers)

-- Terminals
map('t', '<Esc>', [[<C-\><C-n>]])
map('t', '<C-]>', [[<C-\><C-n>]])
map('t', '<S-space>', '<space>')

-- Quickfix
map('n', ']q', cmd('try | silent cnext | catch | silent! cfirst | endtry'))
map('n', '[q', cmd('try | silent cprev | catch | silent! clast | endtry'))
map('n', ']l', loclist.next)
map('n', '[l', loclist.prev)

-- Snippets
map({ 'i', 's' }, '<C-s>', function()
  if snippy.can_expand() then
    snippy.expand()
  end
end)

map({ 'i', 's' }, '<C-j>', function()
  if snippy.can_jump(1) then
    snippy.next()
  end
end)

return M
