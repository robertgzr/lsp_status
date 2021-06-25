local redraw = require('spinner.redraw')

local clients = {} -- indexed by client ID
local config = {
  spinner = {'-', '\\', '|', '/'},
  interval = 130,
  redraw_rate = 100,
}

local M = {}

local function find_index(tb, value)
  for i, v in ipairs(tb) do
    if v == value then
      return i
    end
  end
end

function M.on_progress(event, job_id, client_id)
  if not clients[client_id] then
    return
  end
  if event == 'begin' then
    table.insert(clients[client_id].jobs, job_id)
    if not clients[client_id].timer then
      local timer = vim.loop.new_timer()
      clients[client_id].timer = timer
      clients[client_id].frame = 1
      timer:start(config.interval, config.interval, vim.schedule_wrap(function()
        clients[client_id].frame =
          clients[client_id].frame < #config.spinner and
            clients[client_id].frame + 1 or 1
        redraw.redraw()
      end))
    end
  elseif event == 'end' then
    local jobs = clients[client_id].jobs
    local index = find_index(jobs, job_id)
    table.remove(jobs, index)
    if vim.tbl_isempty(jobs) then
      clients[client_id].timer:stop()
      clients[client_id].timer:close()
      clients[client_id].timer = nil
      redraw.redraw()
    end
  end
end

local function get_clients_by_bufnr(bufnr)
  local ids = {}
  for id, client in pairs(clients) do
    if vim.tbl_contains(client.buffers, bufnr) then
      table.insert(ids, id)
    end
  end
  return ids
end

function M.get_status(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local status = ''
  local ids = get_clients_by_bufnr(bufnr)
  for i, id in ipairs(ids) do
    local client = clients[id]
    status = string.format('%s%s', status, client.name)
    if not vim.tbl_isempty(client.jobs) then
      status = string.format('%s %s', status, config.spinner[client.frame])
    end
    if i < vim.tbl_count(ids) then
      status = string.format('%s ', status)
    end
  end
  return status
end

function M.setup(opts)
  vim.validate {
    config = {
      opts, function(c)
        if c and type(c) ~= 'table' then
          return false
        end
        if c and c.spinner and not vim.tbl_islist(c.spinner) then
          return false
        end
        if c and c.interval and type(c.interval) ~= 'number' then
          return false
        end
        if c and c.redraw_rate and type(c.redraw_rate) ~= 'number' then
          return false
        end
        return true
      end, [[table with keys (optional)
        spinner: table list[string] - the spinner frames
        interval: number - spinner frame rate in ms
        redraw_rate: number - statusline max refresh rate in ms
      ]],
    },
  }
  if opts then
    config = vim.tbl_extend('force', config, opts)
  end
  redraw.init(config)
end

function M.on_attach(client_id, client_name, bufnr)
  if not clients[client_id] then
    clients[client_id] = {name = client_name or client_id, jobs = {}, buffers = {bufnr}}
  else
    if not vim.tbl_contains(clients[client_id].buffers, bufnr) then
      table.insert(clients[client_id].buffers, bufnr)
    end
  end
end

function M.on_exit(_, _, client_id)
  if not clients[client_id] then
    return
  end
  if clients[client_id].timer then
    clients[client_id].timer:close()
  end
  clients[client_id] = nil
end

return M
