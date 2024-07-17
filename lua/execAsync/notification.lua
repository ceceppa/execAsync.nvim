local spinner = { "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾" }

local function format_notification_msg(msg, spinner_idx)
    if spinner_idx == 0 or spinner_idx == nil then
        return string.format(" %s ", msg)
    end

    return string.format(" %s %s ", spinner[spinner_idx], msg)
end

local function show_notification(command, description, is_silent)
    local run_command
    local on_complete
    local notify_record
    local show = not is_silent
    local spinner_idx = 0
    local hide_from_history = false

    run_command = function()
        if not show then
            return
        end

        local options = notify_record and {
            replace = notify_record.id,
            hide_from_history = hide_from_history,
            on_close = function()
                notify_record = nil
            end,
        } or {}

        options.title = command

        notify_record = vim.notify(
            format_notification_msg(description, spinner_idx),
            nil,
            options
        )

        hide_from_history = true

        spinner_idx = spinner_idx + 1

        if spinner_idx > #spinner then
            spinner_idx = 1
        end

        vim.defer_fn(run_command, 125)
    end

    on_complete = function(level)
        show = false

        if is_silent then
            return
        end

        local options = notify_record and { replace = notify_record.id } or {}

        if level == "error" then
            vim.schedule(function()
                vim.notify(" ❌ " .. description .. " failed: 😭😭😭", "error", options)
            end)
        else
            vim.schedule(function()
                vim.notify(" ✅ " .. description .. " successful: 🎉🎉🎉", nil, options)
            end)
        end
    end

    hide_from_history = false

    run_command()

    return on_complete
end

return show_notification
