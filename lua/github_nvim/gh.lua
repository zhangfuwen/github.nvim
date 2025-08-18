local vim = vim
local util = require("github_nvim.util")
M = {}

function M.get_github_username()
    local result = vim.fn.system("gh api user --jq '.login' 2>/dev/null")
    if vim.v.shell_error == 0 then
        return string.gsub(result, "\n$", "") -- remove newline
    else
        return nil
    end
end

local plugin = util.plugin_name
local function do_clone(config, user_name, repo_name, opts)
    opts = opts or {}
    local user_dir = config.github_dir .. config.sep .. user_name
    local repo_dir = user_dir .. config.sep .. repo_name
    if util.path_exists(repo_dir) then
        vim.notify("Error: repo exists", vim.log.levels.ERROR, { title = plugin })
        util.promptYesNo("remove local and retry?", function()
            util.rm_rf(repo_dir)
            do_clone(config, user_name, repo_name, opts)
        end)
        return
    end

    if not util.path_exists(user_dir) then
        print("making user_dir " .. user_dir)
        util.mkdir_p(user_dir)
    end



    local clone_command = "gh repo clone " .. user_name .. config.sep .. repo_name
    local message = "running command " .. clone_command .. " ..."
    vim.notify(message, vim.log.levels.INFO, {
        title = plugin,
        on_open = function()
            local function on_command_exit(result)
                vim.schedule(function()
                    if result.code == 0 then
                        vim.notify("success, path: " .. repo_dir, vim.log.levels.INFO, { title = plugin })
                        if opts.on_success then opts.on_success(repo_dir) end
                    else
                        vim.notify("failed, reason: " .. result.stderr, "Error", { title = plugin })
                        util.promptYesNo("retry(remove local)?", function()
                            util.rm_rf(repo_dir)
                            do_clone(config, user_name, repo_name, opts)
                        end, function()
                            if opts.on_fail then opts.on_fail() end
                        end
                        )
                    end
                end
                )
            end


            vim.system({ "bash", "-c", clone_command }, {
                text = true,
                cwd = user_dir,
            }, on_command_exit)

            -- local timer = vim.loop.new_timer()
            -- timer:start(2000, 0, function()
            --     vim.notify({ "executing ", "Please wait..." }, "info", {
            --         title = plugin,
            --         timeout = 3000,
            --         on_close = function()
            --             vim.notify("Problem solved", nil, { title = plugin })
            --             vim.notify("Error code 0x0395AF", 1, { title = plugin })
            --         end,
            --     })
            -- end)
        end,
    })
end

M.do_clone = do_clone

return M
