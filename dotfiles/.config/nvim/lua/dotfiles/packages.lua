local pkg = require('dotfiles.package')
local use = pkg.use

use('nvim-lua/plenary.nvim')
use('numToStr/Comment.nvim')
use('YorickPeterse/rust.vim')
use('neovim/nvim-lspconfig')
use('dcampos/nvim-snippy')
use('inko-lang/inko.vim')
use('yorickpeterse/nvim-grey')
use('yorickpeterse/nvim-window')
use('yorickpeterse/nvim-pqf')
use('yorickpeterse/nvim-dd')
use('kyazdani42/nvim-web-devicons')
use('sindrets/diffview.nvim')
use('nvim-telescope/telescope.nvim')
use({ 'nvim-telescope/telescope-fzf-native.nvim', run = '!make' })
use('nvim-treesitter/nvim-treesitter')
use('mfussenegger/nvim-lint')
use('stevearc/oil.nvim')
use('stevearc/conform.nvim')
use('stevearc/dressing.nvim')
use('rlane/pounce.nvim')

pkg.install()
