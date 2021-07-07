-- Switching of windows similar to hop.nvim
--
-- Using this plugin I can switch between windows much easier compared to using
-- CTRL-W.
--
-- When activated, a floating window is displayed in the middle of every window.
-- The text in this window indicates what to type to jump to the window.
local api = vim.api
local fn = vim.fn
local M = {}

local chars = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
  'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}

local escape = 27
local float_height = 3
local float_width = 6

local function is_regular_window(winid)
  return api.nvim_win_get_config(winid).relative == ''
end

local function window_keys(windows)
  local mapping = {}

  for _, win in ipairs(windows) do
    local key = chars[(win % #chars) + 1]

    if mapping[key] then
      key = key .. chars[((win + 1) % #chars) + 1]
    end

    mapping[key] = win
  end

  return mapping
end

local function ask_second_char(keys, start)
  for key, _ in pairs(keys) do
    if key ~= start and key:sub(1, 1) == start then
      return true
    end
  end

  return false
end

local function open_floats(mapping)
  local floats = {}

  for key, window in pairs(mapping) do
    local bufnr = api.nvim_create_buf(false, true)

    if bufnr > 0 then
      local win_width = api.nvim_win_get_width(window)
      local win_height = api.nvim_win_get_height(window)

      local row = math.max(0, math.floor((win_height / 2) - 1))
      local col = math.max(0, math.floor((win_width / 2) - float_width))

      api.nvim_buf_set_lines(bufnr, 0, -1, true, { '', '  ' .. key .. '  ', '' })
      api.nvim_buf_add_highlight(bufnr, 0, 'Bold', 1, 0, -1)

      local float_window = api.nvim_open_win(bufnr, false, {
        relative = 'win',
        win = window,
        row = row,
        col = col,
        width = #key == 1 and float_width - 1 or float_width,
        height = float_height,
        focusable = false,
        style = 'minimal',
        border = 'none',
        noautocmd = true
      })

      api.nvim_win_set_option(float_window, 'winhl', 'Normal:BlackOnLightYellow')

      floats[float_window] = bufnr
    end
  end

  return floats
end

-- Picks a window to jump to, and makes it the active window.
function M.pick()
  local windows =
    vim.tbl_filter(is_regular_window, api.nvim_tabpage_list_wins(0))

  local window_keys = window_keys(windows)
  local floats = open_floats(window_keys)

  vim.cmd('redraw')

  local char = fn.getchar()
  local key = fn.nr2char(char)
  local window = window_keys[key]

  -- Only ask for the second character if we actually have a pair that starts
  -- with the first character.
  if not window and char ~= escape and ask_second_char(window_keys, key) then
    window = window_keys[key .. fn.nr2char(fn.getchar())]
  end

  for window, bufnr in pairs(floats) do
    api.nvim_win_close(window, true)
    api.nvim_buf_delete(bufnr, { force = true })
  end

  if window then
    api.nvim_set_current_win(window)
  end
end

return M
