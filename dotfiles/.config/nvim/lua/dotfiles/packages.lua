local package = require('dotfiles.package')
local use = package.use

use 'windwp/nvim-autopairs'
use 'YorickPeterse/rust.vim'
use 'tpope/vim-fugitive'
use 'dag/vim-fish'
use 'ludovicchabant/vim-gutentags'
use 'junegunn/fzf'
use 'junegunn/fzf.vim'
use 'Vimjas/vim-python-pep8-indent'
use 'yssl/QFEnter'
use 'neovim/nvim-lspconfig'
use 'hrsh7th/vim-vsnip'
use { 'https://gitlab.com/inko-lang/inko.vim', branch = 'single-ownership' }
use 'https://gitlab.com/yorickpeterse/nvim-grey'
use 'https://gitlab.com/yorickpeterse/nvim-window'
use 'phaazon/hop.nvim'
use 'kyazdani42/nvim-web-devicons'
use 'justinmk/vim-dirvish'
use 'cespare/vim-toml'
use 'b3nj5m1n/kommentary'
use 'samoshkin/vim-mergetool'
use 'sindrets/diffview.nvim'

package.install()
