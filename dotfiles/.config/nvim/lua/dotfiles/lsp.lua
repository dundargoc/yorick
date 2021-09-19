-- Configuration for NeoVim's LSP integration.

local config = require('lspconfig')
local lsp = vim.lsp
local diag = vim.diagnostic
local util = require('dotfiles.util')

-- Markdown popup {{{1
do
  local default = lsp.util.open_floating_preview

  lsp.util.open_floating_preview = function(contents, syntax, opts)
    local local_opts = {
      max_width = 120,
      max_height = 20,
      separator = false
    }

    local combined_opts = vim.tbl_deep_extend('force', opts or {}, local_opts)

    return default(contents, syntax, combined_opts)
  end
end

-- Floating window borders {{{1
do
  local default = lsp.util.make_floating_popup_options

  lsp.util.make_floating_popup_options = function(width, height, opts)
    local new_opts =
      vim.tbl_deep_extend('force', opts or {}, { border = 'single' })

    return default(width, height, new_opts)
  end
end

-- Snippet support {{{1
local capabilities = lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem.snippetSupport = true

-- Diagnostics {{{1
do
  diag.config({
    underline = {
      severity = { min = diag.severity.WARN }
    },
    signs = {
      severity = { min = diag.severity.WARN }
    },
    severity_sort = true,
    virtual_text = false,
    update_in_insert = false
  })

  local show = diag.show
  local timeout = 100
  local timeouts = {}

  -- This callback gets called _a lot_. Populating the location list every time
  -- can sometimes lead to empty or out of sync location lists. To prevent this
  -- from happening we defer updating the location list.
  diag.show = function(namespace, bufnr, diagnostics, opts)
    show(namespace, bufnr, diagnostics, opts)

    -- Timers are stored per buffer and client, otherwise diagnostics produced
    -- for one buffer/client may reset the timer of an unrelated buffer/client.
    if timeouts[bufnr] == nil then
      timeouts[bufnr] = {}

      -- Clear the cache when the buffer unloads
      vim.api.nvim_buf_attach(bufnr, false, {
        on_detach = function()
          timeouts[bufnr] = nil
        end
      })
    end

    if timeouts[bufnr][namespace] then
      timeouts[bufnr][namespace]:stop()
    end

    local callback = function()
      if diagnostics then
        util.set_diagnostics_location_list(bufnr, diagnostics)
      end
    end

    timeouts[bufnr][namespace] = vim.defer_fn(callback, timeout)
  end
end

-- Signs {{{1
vim.cmd('sign define DiagnosticSignError text=E numhl=ErrorMsg texthl=ErrorMsg')
vim.cmd('sign define DiagnosticSignWarn text=W numhl=Yellow texthl=Yellow')

-- Completion symbols {{{1
local lsp_symbols = {
  Class = 'Class',
  Color = 'Color',
  Constant = 'Constant',
  Constructor = 'Constructor',
  Enum = 'Enum',
  EnumMember = 'Member',
  File = 'File',
  Folder = 'Folder',
  Function = 'Function',
  Interface = 'Interface',
  Keyword = 'Keyword',
  Method = 'Method',
  Module = 'Module',
  Property = 'Property',
  Snippet = 'Snippet',
  Struct = 'Struct',
  Text = 'Text',
  Unit = 'Unit',
  Value = 'Value',
  Variable = 'Variable',
  Namespace = 'Namespace',
  Field = 'Field',
  Number = 'Number',
  TypeParameter = 'Type parameter'
}

for kind, symbol in pairs(lsp_symbols) do
  local kinds = lsp.protocol.CompletionItemKind
  local index = kinds[kind]

  if index ~= nil then
    kinds[index] = symbol
  end
end

-- Rust {{{1
config.rust_analyzer.setup {
  root_dir = config.util.root_pattern('Cargo.toml', 'rustfmt.toml'),
  capabilities = capabilities,
  flags = {
    allow_incremental_sync = true
  },
  settings = {
    ["rust-analyzer"] = {
      diagnostics = {
        -- Disable diagnostics while typing, as this is rather annoying.
        -- Diagnostics are still produced when loading/writing a file.
        enable = false,
        enableExperimental = false
      },
      inlayHints = {
        typeHints = false,
        chainingHints = false,
        enable = false
      },
      server = {
        path = "/usr/bin/rust-analyzer"
      },
      lruCapacity = 64,
      completion = {
        postfix = {
          enable = false
        }
      }
    }
  }
}

-- Python {{{1
config.jedi_language_server.setup {
  capabilities = capabilities,
  flags = {
    allow_incremental_sync = true
  },
  init_options = {
    markupKindPreferred = 'markdown',
    startupMessage = false,
    diagnostics = {
      -- Linting as you type is distracting, and thus is disabled.
      didChange = false
    }
  }
}

-- Go {{{1
config.gopls.setup {
  capabilities = capabilities,
  flags = {
    allow_incremental_sync = true
  },
}

-- vim: set foldmethod=marker:
