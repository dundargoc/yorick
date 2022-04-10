local M = {}

local completion = require('dotfiles.completion')
local pairs = require('dotfiles.pairs')
local util = require('dotfiles.util')
local window = require('nvim-window')
local telescope_builtin = require('telescope.builtin')
local parsers = require('nvim-treesitter.parsers')
local snippy = require('snippy')
local pickers = require('dotfiles.telescope.pickers')

local keycode = util.keycode
local popup_visible = util.popup_visible
local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local g = vim.g
local diag = vim.diagnostic
local keymap = vim.keymap

-- The LSP symbols to include when using Telescope.
local ts_lsp_symbols = {}
local ts_lsp_kinds = {
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

for _, kind in ipairs(vim.lsp.protocol.SymbolKind) do
  if ts_lsp_kinds[kind] then
    table.insert(ts_lsp_symbols, kind)
  end
end

local function map_key(kind, key, action, options)
  local opts = vim.tbl_extend('force', { silent = true }, options or {})

  keymap.set(kind, key, action, opts)
end

local function unmap(key)
  keymap.del('', key)
end

local function map(key, action, options)
  map_key('', key, action, options)
end

local function nmap(key, action, options)
  map_key('n', key, action, options)
end

local function imap(key, action, options)
  map_key('i', key, action, options)
end

local function smap(key, action, options)
  map_key('s', key, action, options)
end

local function tmap(key, action, options)
  map_key('t', key, action, options)
end

local function vmap(key, action, options)
  map_key('v', key, action, options)
end

local function xmap(key, action, options)
  map_key('x', key, action, options)
end

local function ismap(key, action, options)
  imap(key, action, options)
  smap(key, action, options)
end

local function cmd(string)
  return '<cmd>' .. string .. '<CR>'
end

local function pair(key, func)
  return imap(key, pairs[func], { remap = false, expr = true })
end

-- The leader key must be defined before any mappings are set.
g.mapleader = ' '
g.maplocalleader = ' '

-- Generic
map('<space>', '<nop>')
nmap('<leader>w', window.pick)
nmap('<leader>s', cmd('update'))
nmap('<leader>c', cmd('quit'))
nmap('<leader>v', cmd('vsplit'))

nmap('<C-j>', '<C-w>j')
nmap('<C-k>', '<C-w>k')
nmap('<C-l>', '<C-w>l')
nmap('<C-h>', '<C-w>h')

nmap('s', cmd('HopWord'))
xmap('s', cmd('HopWord'))

-- dirbuf maps this, which is annoying.
unmap('-')

-- Use d/dd for actually deleting, while using dx for cutting the line.
nmap('dx', 'dd', { noremap = true })

nmap('d', '"_d', { noremap = true })
nmap('d', '"_d', { noremap = true })
xmap('d', '"_d', { noremap = true })
nmap('dd', '"_dd', { noremap = true })

-- Allow copy/pasting using Control-c and Control-v
vmap('<C-c>', '"+y')
imap('<C-v>', '<Esc>"+pa')
tmap('<C-s-v>', [[<C-\><C-n>"+pa]])

-- Code and pairs completion
imap('<CR>', function()
  return popup_visible() and completion.confirm() or pairs.enter()
end, { expr = true })

pair('<space>', 'space')
pair('<bs>', 'backspace')

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

imap('<tab>', function()
  if popup_visible() then
    return '<C-n>'
  end

  local col = fn.col('.') - 1

  if col == 0 or api.nvim_get_current_line():sub(col, col):match('%s') then
    return '<tab>'
  else
    return '<C-x><C-U>'
  end
end, { expr = true })

imap('<S-tab>', function()
  return popup_visible() and '<C-p>' or '<S-tab>'
end, { expr = true })

vmap('<s-tab>', '<')
vmap('<tab>', '>')

nmap(']n', function()
  util.restore_register('/', function()
    vim.cmd('silent! /<<< HEAD')
  end)
end)

nmap('[n', function()
  util.restore_register('/', function()
    vim.cmd('silent! ?<<< HEAD')
  end)
end)

-- LSP
nmap('<leader>h', cmd('lua vim.lsp.buf.hover()'))
nmap('<leader>n', cmd('lua vim.lsp.buf.rename()'))
nmap('<leader>d', function()
  local bufnr = api.nvim_get_current_buf()

  if util.has_lsp_clients_supporting(bufnr, 'goto_definition') then
    lsp.buf.definition()
  else
    api.nvim_feedkeys(keycode('<C-]>'), 'm', true)
  end
end)

nmap('<leader>z', function()
  diag.setqflist({ severity = { min = vim.diagnostic.severity.WARN } })
end)

nmap('<leader>r', function()
  lsp.buf.references({ includeDeclaration = false })
end)

-- Shows all implementations of an interface.
--
-- The function `vim.lsp.buf.implementation()` automatically jumps to the first
-- location, which I don't like.
nmap('<leader>i', function()
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

nmap('<leader>a', cmd('lua vim.lsp.buf.code_action()'))

nmap('<leader>e', function()
  diag.open_float(0, { scope = 'line' })
end)

-- Searching
nmap('K', cmd('silent grep! <cword>'))
nmap('<leader>g', ':silent grep! ', { silent = false })

-- Telescope
nmap('<leader>f', function()
  telescope_builtin.find_files({
    hidden = true,
    find_command = { 'fd', '--type=f', '--strip-cwd-prefix' },
  })
end)

nmap('<leader>t', function()
  local bufnr = api.nvim_get_current_buf()

  if util.has_lsp_clients_supporting(bufnr, 'document_symbol') then
    pickers.lsp_document_symbols({
      symbols = ts_lsp_symbols,
      previewer = false,
      prompt_title = false,
      results_title = false,
      preview_title = false,
    })

    return
  end

  if parsers.has_parser() then
    telescope_builtin.treesitter()
    return
  end

  telescope_builtin.current_buffer_tags()
end)

nmap('<leader>b', cmd('Telescope buffers'))

-- Terminals
tmap('<Esc>', [[<C-\><C-n>]])

-- Quickfix
nmap(']q', cmd('try | silent cnext | catch | silent! cfirst | endtry'))
nmap('[q', cmd('try | silent cprev | catch | silent! clast | endtry'))

nmap(']l', cmd('lua dotfiles.location_list.next()'))
nmap('[l', cmd('lua dotfiles.location_list.prev()'))
nmap('<leader>l', cmd('lua dotfiles.location_list.toggle()'))
nmap('<leader>q', function()
  if #fn.filter(fn.getwininfo(), 'v:val.quickfix') == 0 then
    vim.cmd('silent! copen')
  else
    vim.cmd('silent! cclose')
  end
end)

-- Snippets
ismap('<C-s>', function()
  if snippy.can_expand() then
    snippy.expand()
  end
end)

ismap('<C-j>', function()
  if snippy.can_jump(1) then
    snippy.next()
  end
end)

return M
