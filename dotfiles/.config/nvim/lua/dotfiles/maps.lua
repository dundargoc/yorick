local M = {}

local completion = require('dotfiles.completion')
local pairs = require('dotfiles.pairs')
local util = require('dotfiles.util')
local window = require('nvim-window')
local diag = require('dotfiles.diagnostics')
local telescope_builtin = require('telescope.builtin')
local parsers = require('nvim-treesitter.parsers')

local keycode = util.keycode
local popup_visible = util.popup_visible
local au = util.au
local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local g = vim.g

local function map_key(kind, key, action, options)
  local opts = vim.tbl_extend('force', { silent = true }, options or {})
  local cmd = action

  if type(cmd) == 'table' then
    local kind = cmd[1]
    local run = cmd[2]

    if kind == 'cmd' then
      cmd = '<cmd>' .. run .. '<CR>'
    elseif kind == 'expr' then
      cmd = run
      opts.expr = true
    end
  end

  api.nvim_set_keymap(kind, key, cmd, opts)
end

local function unmap(key) api.nvim_del_keymap('', key) end

local function map(key, action, options) map_key('', key, action, options) end
local function nmap(key, action, options) map_key('n', key, action, options) end
local function imap(key, action, options) map_key('i', key, action, options) end
local function smap(key, action, options) map_key('s', key, action, options) end
local function tmap(key, action, options) map_key('t', key, action, options) end
local function vmap(key, action, options) map_key('v', key, action, options) end
local function xmap(key, action, options) map_key('x', key, action, options) end
local function ismap(key, action, options)
  imap(key, action, options)
  smap(key, action, options)
end

local function cmd(string)
  return { 'cmd', string }
end

local function func(name)
  return cmd('lua dotfiles.maps.' .. name .. '()')
end

local function expr(name)
  return { 'expr', 'v:lua.dotfiles.maps.' .. name .. '()' }
end

function M.enter()
  return popup_visible() and completion.confirm() or pairs.enter()
end

function M.shift_tab()
  return popup_visible() and keycode('<C-p>') or keycode('<S-tab>')
end

function M.tab()
  if popup_visible() then
    return keycode('<C-n>')
  end

  local col = fn.col('.') - 1

  if col == 0 or api.nvim_get_current_line():sub(col, col):match('%s') then
    return keycode('<tab>')
  else
    return keycode('<C-x><C-U>')
  end
end

function M.next_conflict()
  util.restore_register('/', function() vim.cmd('silent! /<<< HEAD') end)
end

function M.previous_conflict()
  util.restore_register('/', function() vim.cmd('silent! ?<<< HEAD') end)
end

function M.leader_w()
  window.pick()
end

function M.leader_d()
  if util.has_lsp_clients() then
    lsp.buf.definition()
  else
    api.nvim_feedkeys(keycode('<C-]>'), 'n', true)
  end
end

function M.leader_e()
  diag.show_line_diagnostics()
end

function M.leader_f()
  if fn.isdirectory(fn.join({ fn.getcwd(), '.git' }, '/')) == 1 then
    telescope_builtin.git_files()
  else
    telescope_builtin.find_files()
  end
end

function M.leader_t()
  if util.has_lsp_clients() then
    telescope_builtin.lsp_document_symbols()
    return
  end

  if parsers.has_parser() then
    telescope_builtin.treesitter()
    return
  end

  telescope_builtin.current_buffer_tags()
end

function M.control_s()
  if fn['vsnip#expandable']() then
    return keycode('<Plug>(vsnip-expand)')
  else
    return keycode('<C-s>')
  end
end

function M.control_j()
  if fn['vsnip#jumpable'](1) then
    return keycode('<Plug>(vsnip-jump-next)')
  else
    return keycode('<C-j>')
  end
end

function M.control_k()
  if fn['vsnip#jumpable'](-1) then
    return keycode('<Plug>(vsnip-jump-prev)')
  else
    return keycode('<C-k>')
  end
end

-- The leader key must be defined before any mappings are set.
g.mapleader = ' '
g.maplocalleader = ' '

-- Generic
map('<space>', '<nop>')
map('<leader>w', func('leader_w'))
map('K', '<nop>')
nmap('s', cmd('HopWord'))
xmap('s', cmd('HopWord'))

-- Allow copy/pasting using Control-c and Control-v
vmap('<C-c>', '"+y')
imap('<C-v>', '<Esc>"+pa')
tmap('<C-s-v>', [[<C-\><C-n>"+pa]])

-- Commenting
nmap('<leader>c', '<Plug>kommentary_line_default<Esc>')
vmap('<leader>c', '<Plug>kommentary_visual_default<Esc>')

-- Code and pairs completion
imap('<CR>', expr('enter'))

imap('<tab>', expr('tab'))
imap('<S-tab>', expr('shift_tab'))

vmap('<s-tab>', '<')
vmap('<tab>', '>')

-- Dirvish
unmap('-')
au('dirvish', {
  'FileType dirvish nmap <buffer><silent><leader>v <cmd>call dirvish#open("vsplit", 0)<CR>'
})

-- Fugitive/Git
map('<leader>gs', cmd('vert rightbelow Git'))
map('<leader>gd', cmd('Gdiffsplit'))

map(']n', func('next_conflict'))
map('[n', func('previous_conflict'))

-- LSP
map('<leader>h', cmd('lua vim.lsp.buf.hover()'))
map('<leader>r', cmd('lua vim.lsp.buf.rename()'))
map('<leader>d', func('leader_d'))

map('<leader>i', cmd('lua vim.lsp.buf.references()'))
map('<leader>a', cmd('lua vim.lsp.buf.code_action()'))
map('<leader>e', func('leader_e'))

-- Telescope
map('<leader>f', func('leader_f'))
map('<leader>t', func('leader_t'))
map('<leader>b', cmd('Telescope buffers'))

-- Terminals
tmap('<C-[>', [[<C-\><C-n>]])
tmap('<C-]>', [[<C-\><C-n>]])

-- Quickfix
map(']q', cmd('try | cnext | catch | silent! cfirst | endtry'))
map('[q', cmd('try | cprev | catch | silent! clast | endtry'))
map(']l', cmd('try | lnext | catch | silent! lfirst | endtry'))
map('[l', cmd('try | lprev | catch | silent! llast | endtry'))

-- Snippets
ismap('<C-s>', expr('control_s'))
ismap('<C-j>', expr('control_j'))
ismap('<C-k>', expr('control_k'))

return M
