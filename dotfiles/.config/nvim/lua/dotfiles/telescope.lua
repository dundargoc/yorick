local telescope = require('telescope')
local actions = require('telescope.actions')
local sorters = require('telescope.sorters')
local layout = require('telescope.actions.layout')

local picker_defaults = {
  previewer = false,
  show_line = false,
  prompt_title = false,
  results_title = false,
}

local function picker_opts(opts)
  return vim.tbl_extend('force', picker_defaults, opts or {})
end

telescope.setup({
  defaults = {
    prompt_prefix = '> ',
    sorting_strategy = 'ascending',
    layout_strategy = 'bottom_pane',
    layout_config = {
      prompt_position = 'bottom',
      height = { 0.4, max = 40, min = 5 },
    },
    preview = {
      hide_on_startup = true,
    },
    borderchars = {
      prompt = { '─', ' ', '─', ' ', ' ', ' ', '─', '─' },
      results = { '─', ' ', '─', ' ', '─', '─', ' ', ' ' },
      preview = { '─', ' ', '─', '│', '┬', '─', '─', '╰' },
    },
    mappings = {
      i = {
        ['<tab>'] = actions.move_selection_next,
        ['<s-tab>'] = actions.move_selection_previous,
        ['<C-p>'] = layout.toggle_preview,
      },
      n = {
        ['<tab>'] = actions.move_selection_next,
        ['<s-tab>'] = actions.move_selection_previous,
      },
    },
    file_ignore_patterns = {
      '.git/',
    },
  },
  pickers = {
    file_browser = picker_defaults,
    find_files = picker_defaults,
    git_files = picker_defaults,
    buffers = picker_defaults,
    tags = picker_defaults,
    current_buffer_tags = picker_defaults,
    lsp_references = picker_defaults,
    lsp_document_symbols = picker_defaults,
    lsp_workspace_symbols = picker_defaults,
    lsp_implementations = picker_defaults,
    lsp_definitions = picker_defaults,
    git_commits = picker_defaults,
    git_bcommits = picker_defaults,
    git_branches = picker_defaults,
    treesitter = picker_defaults,
    reloader = picker_defaults,
  },
  extensions = {
    fzf = {
      fuzzy = false,
      override_generic_sorter = true,
      override_file_sorter = true,
    },
  },
})

telescope.load_extension('fzf')
