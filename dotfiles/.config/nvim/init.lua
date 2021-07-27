-- vim: set fdm=marker
local g = vim.g
local o = vim.opt
local e = vim.env

-- Settings to set before loading plugins {{{1
g.python3_host_prog = '/usr/bin/python'
g.python_host_prog = '/usr/bin/python2'

g.NERDSpaceDelims = 1
g.NERDDefaultAlign = 'left'
g.NERDCustomDelimiters = { inko = { left = '#' } }
g.NERDCreateDefaultMappings = 0

g.qfenter_keymap = {
  vopen = { '<leader>v' }
}

-- Config files and plugins {{{1
require('dotfiles.packages')

require('dotfiles.linters.flake8')
require('dotfiles.linters.gitlint')
require('dotfiles.linters.inko')
require('dotfiles.linters.lua')
require('dotfiles.linters.rubocop')
require('dotfiles.linters.ruby')
require('dotfiles.linters.shellcheck')
require('dotfiles.linters.vale')

require('dotfiles.lsp')
require('dotfiles.window')
require('dotfiles.commands')
require('dotfiles.hooks')
require('dotfiles.comments')

_G.dotfiles = {
  completion = require('dotfiles.completion'),
  diagnostics = require('dotfiles.diagnostics'),
  pairs = require('dotfiles.pairs'),
  lint = require('dotfiles.lint'),
  quickfix = require('dotfiles.quickfix'),
  package = require('dotfiles.package'),
  statusline = require('dotfiles.statusline'),
  tabline = require('dotfiles.tabline'),
  workspace = require('dotfiles.workspace'),
  diff = require('dotfiles.diff'),
  callbacks = require('dotfiles.callbacks'),
  maps = require('dotfiles.maps'),
}

-- Colorscheme {{{1
vim.cmd('syntax on')
vim.cmd('color grey')

-- Code completion {{{1
o.pumheight = 30
o.completeopt = 'menu'
o.complete = { '.', 'b' }
o.completefunc = 'v:lua.dotfiles.completion.start'

-- Fugitive {{{1
g.fugitive_dynamic_colors = 0

-- FZF {{{1
e.FZF_DEFAULT_COMMAND = 'rg --files --follow'
e.FZF_DEFAULT_OPTS = '--bind=tab:down,shift-tab:up'

g.fzf_colors = {
  ['fg'] = { 'fg', 'Normal' },
  ['fg+'] = { 'fg', 'Normal' },
  ['bg'] = { 'bg', 'Normal' },
  ['bg+'] = { 'bg', 'Cursor' },
  ['hl'] = { 'bg', 'WhiteOnYellow' },
  ['hl+'] = { 'bg', 'WhiteOnYellow' },
  ['info'] = { 'fg', 'Number' },
  ['gutter'] = { 'bg', 'Normal' },
  ['prompt'] = { 'fg', 'Normal' },
  ['pointer'] = { 'fg', 'Normal' },
  ['marker'] = { 'fg', 'Normal' },
  ['spinner'] = { 'fg', 'Normal' },
  ['header'] = { 'fg', 'Comment' },
}

g.fzf_layout = {
  window = {
    width = 0.7,
    height = 0.6,
    border = 'sharp',
    highlight = 'VertSplit'
  }
}

g.fzf_preview_window = ''

-- Generic {{{1
o.colorcolumn = '80'
o.number = true
o.relativenumber = true
o.ruler = false
o.signcolumn = 'yes'
o.synmaxcol = 256
o.termguicolors = true
o.textwidth = 80
o.wrap = false
o.cursorcolumn = false
o.cursorline = false
o.backspace = 'indent,eol,start'
o.backupskip = '/tmp/*'
o.clipboard = 'unnamed'
o.diffopt = 'filler,vertical,internal,algorithm:patience,indent-heuristic'
o.lz = true
o.showcmd = false
o.pastetoggle = '<F2>'
o.splitright = true
o.title = true
o.mouse = ''
o.shortmess = 'atOIcF'
o.inccommand = 'nosplit'
o.scrollback = 1000
o.updatetime = 1000
o.fillchars = { fold = ' ', diff = ' ' }
o.printoptions = { number = 'n', header = '0' }
o.regexpengine = 0

-- Gutentags {{{1
g.gutentags_ctags_exclude = {
  'target',
  'tmp',
  'node_modules',
  'public',
  '*/fixtures/*',
  '*/locale/*',
  '*.json',
  '*.svg'
}

g.gutentags_file_list_command = 'rg --files'
g.gutentags_ctags_extra_args = { '--exclude=@.gitignore', '--excmd=number' }

-- Indentation {{{1
o.expandtab = true
o.shiftwidth = 4
o.shiftround = true
o.softtabstop = 4
o.tabstop = 4

-- Markdown {{{1
g.markdown_fenced_languages = { 'ruby', 'rust', 'sql', 'inko', 'yaml' }

-- Mergetool {{{1
g.mergetool_layout = 'mr'
g.mergetool_prefer_revision = 'local'

-- netrw {{{1
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- Quickfix {{{1
-- This is needed until https://github.com/neovim/neovim/pull/14909 is merged.
vim.cmd([[
  function! DotfilesQuickfixTextFunc(info)
    return luaeval('dotfiles.quickfix.format(_A)', a:info)
  endfunction
]])

o.quickfixtextfunc = 'DotfilesQuickfixTextFunc'

-- Rust {{{1
g.rust_recommended_style = 0

-- Searching {{{1
o.grepprg = 'rg --vimgrep'
o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
o.incsearch = true
o.hlsearch = false

-- Don't show the output window of grep
vim.cmd('cnoreabbrev <expr> grep v:lua.dotfiles.callbacks.abbreviate_grep()')

-- Statusline {{{1
o.statusline = '%!v:lua.dotfiles.statusline.render()'
g.qf_disable_statusline = true

-- Tabline {{{1
o.tabline = '%!v:lua.dotfiles.tabline.render()'

-- vsnip {{{1
g.vsnip_snippet_dir = '/home/yorickpeterse/.config/nvim/snippets'
