local Job = require 'plenary.job'

local show_notification = require('execAsync.notification')

local M = {}
local _latest_output = {}

local function execute_command(opts)
    local command = opts.command
    local is_silent = opts.is_silent
    local on_complete = opts.on_complete
    local on_stdout = opts.on_stdout

    local parts = vim.split(command, " ")
    local command = parts[1]
    local args = vim.list_slice(parts, 2, #parts)
    local description = 'Running: ' .. command

    _latest_output = {}

    local notification = show_notification(description, is_silent)

    Job:new({
        command = command,
        args = args,
        on_stdout = function(_, data)
            table.insert(_latest_output, data)

            if on_stdout then
                on_stdout(data)
            end
        end,
        on_stderr = function(_, data)
            table.insert(_latest_output, data)

            if on_stdout then
                on_stdout(data)
            end
        end,
        on_exit = function(_, return_val)
            _latest_output = _latest_output

            if on_complete then
                vim.schedule(function()
                    on_complete(_latest_output, return_val)
                end)

            end

            if on_stdout or notification then
                notification("success")

                return
            end

            if return_val == 0 then
                notification("success")
            else
                notification("error")
            end
        end
    }):start()
end

M.exec_async = function(opts)
    opts = vim.tbl_deep_extend("force", {}, {
        command = nil,
        is_silent = false,
        on_complete = nil,
        on_stdout = nil
    }, opts)

    local command = opts.command

    local ok, _ = pcall(
        execute_command,
        opts
    )

    if not ok then
        vim.notify("Error executing command: " .. command, "error")
    end
end

M.get_latest_output = function()
    return _latest_output
end

return M
