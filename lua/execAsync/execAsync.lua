local Job = require 'plenary.job'

local show_notification = require('execAsync.notification')

local M = {}
local _latest_output = {}

local function execute_command(cmd, on_completed_callback, is_silent)
    local parts = vim.split(cmd, " ")
    local command = parts[1]
    local args = vim.list_slice(parts, 2, #parts)
    local description = 'Running: ' .. cmd

    _latest_output = {}

    local on_complete = show_notification(description, is_silent)

    Job:new({
        command = command,
        args = args,
        on_stdout = function(_, data)
            table.insert(_latest_output, data)
        end,
        on_stderr = function(_, data)
            table.insert(_latest_output, data)
        end,
        on_exit = function(_, return_val)
            _latest_output = _latest_output

            if on_completed_callback then
                vim.schedule(function()
                    on_completed_callback(_latest_output, return_val)
                end)
            end

            if return_val == 0 then
                on_complete("success")
            else
                on_complete("error")
            end
        end
    }):start()
end

M.exec_async = function(command, on_completed_callback, is_silent)
    if is_silent == nil then
        is_silent = false
    end

    local ok, _ = pcall(
        execute_command,
        command,
        on_completed_callback,
        is_silent
    )

    if not ok then
        vim.notify("Error executing command: " .. command, "error")
    end
end

M.get_latest_output = function()
    return _latest_output
end

return M
