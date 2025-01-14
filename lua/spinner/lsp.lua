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
  local function progress_handler(_, result, client_id)
    spinner.on_progress(result.value.kind, result.token, client_id)
    lsp_progress_handler(nil, result, client_id)
  end
  lsp.handlers['$/progress'] = progress_handler
end

function M.on_attach(client, bufnr)
  spinner.on_attach(client.id, client.name, bufnr)
end

M.on_exit = spinner.on_exit

return M
