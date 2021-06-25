local lsp = vim.lsp
local spinner = require('spinner.core')

local M = {}

function M.init_capabilities(capabilities)
  vim.validate {
    capabilities = {
      capabilities, function(c)
        if not type(c) == 'table' then
          return false
        end
        if type(c.window) == 'table' then
          return true
        end
      end, 'capabilities.window = table',
    },
  }
  if not capabilities.window.workDoneProgress then
    capabilities.window.workDoneProgress = true
  end
end

function M.setup()
  local lsp_progress_handler = lsp.handlers['$/progress']
  local function progress_handler(_, _, params, client_id)
    spinner.on_progress(params.value.kind, params.token, client_id)
    lsp_progress_handler(nil, nil, params, client_id)
  end
  lsp.handlers['$/progress'] = progress_handler
end

function M.on_attach(client, bufnr)
  spinner.on_attach(client.id, client.name, bufnr)
  client.on_exit = spinner.on_exit
end

return M
