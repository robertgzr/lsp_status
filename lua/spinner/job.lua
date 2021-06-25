local spinner = require('spinner.core')

local M = {}

local function on_exit(job_id)
  spinner.on_progress('end', job_id, job_id)
  spinner.on_exit(nil, nil, job_id)
end

local function name_from_command(cmd)
  if cmd[1] == vim.env.SHELL then
    table.remove(cmd, 1)
    table.remove(cmd, 1)
  end
  return table.concat(cmd, ' ')
end

function M.jobstart(cmd, opts)
  local opts = opts or {}

  if opts.on_exit then
    local prev_cb = opts.on_exit
    local function cb(job_id, code, event)
      if event == 'exit' then
        on_exit(job_id)
      end
      prev_cb(job_id, code, event)
    end
    opts.on_exit = cb
  else
    local function cb(job_id, _, event)
      if event == 'exit' then
        on_exit(job_id)
      end
    end
    opts.on_exit = cb
  end


  local job_id = vim.fn.jobstart(cmd, opts)
  local name = job_id..':' .. name_from_command(cmd)
  spinner.on_attach(job_id, name, vim.fn.bufnr())
  spinner.on_progress('begin', job_id, job_id)
  return job_id
end

return M

