--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local uv = vim.loop
local cmd = vim.cmd

local config = {}
local last_redraw = nil
local timer = uv.new_timer()

local function init(_config)
  config = _config
end

local function redraw_logic(now)
  last_redraw = now or uv.now()
  cmd 'redrawstatus!'
end

local function redraw()
  local now = uv.now()
  if not last_redraw or now - last_redraw >= config.redraw_rate then
    timer:stop()
    redraw_logic(now)
  elseif not timer:is_active() then
    timer:start((last_redraw + config.redraw_rate) - now, 0,
                vim.schedule_wrap(redraw_logic))
  end
end

local M = {init = init, redraw = redraw}

return M
