require('dressing').setup({
  input = {
    win_options = {
      winblend = 0,
    },
    title_pos = 'left',
    border = {
      ' ', -- top left
      ' ', -- top
      ' ', -- top right
      ' ', -- right
      ' ', -- bottom right
      ' ', -- bottom
      ' ', -- bottom left
      ' ', -- left
    },
    override = function(conf)
      conf.col = -1
      conf.row = 2

      return conf
    end,
  },
  select = {
    backend = { 'telescope' },
    telescope = {
      layout_strategy = 'grey',
      prompt_title = false,
      results_title = false,
      preview_title = false,
    },
  },
})
