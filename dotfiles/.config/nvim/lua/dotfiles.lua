require('dotfiles.packages')
require('dotfiles.lsp')

require('dotfiles.linters.flake8')
require('dotfiles.linters.gitlint')
require('dotfiles.linters.inko')
require('dotfiles.linters.lua')
require('dotfiles.linters.rubocop')
require('dotfiles.linters.ruby')
require('dotfiles.linters.shellcheck')
require('dotfiles.linters.vale')

_G.dotfiles = {
  completion = require('dotfiles.completion'),
  diagnostics = require('dotfiles.diagnostics'),
  pairs = require('dotfiles.pairs'),
  lint = require('dotfiles.lint'),
  quickfix = require('dotfiles.quickfix'),
  package = require('dotfiles.package'),
  statusline = require('dotfiles.statusline'),
  tabline = require('dotfiles.tabline'),
}
