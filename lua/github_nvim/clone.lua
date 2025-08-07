util = require("github_nvim.util")

M = {}


function M.clone(config)
    is_repo_public = true
    message = "no message"
    messageHighlight = "SpecialKey"
    repo_input = ""
    local Popup = require("nui.popup")
    local Layout = require("nui.layout")
    local Input = require("nui.input")
    local event = require("nui.utils.autocmd").event
    local NuiLine = require("nui.line")
    local NuiText = require("nui.text")

    local clone_input = Input({
        position = "50%",
        size = {
            width = 20,
        },
        border = {
            style = "single",
            text = {
                top = "clone: (user/repo)",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        prompt = "> ",
        default_value = repo_input,
        on_close = function()
            print("Input Closed!")
        end,
        on_submit = function(value)
            print("Input Submitted: " .. value)
        end,
        on_change = function(value)
            repo_input = value
        end,
    })

    local popup_one = Popup({
        enter = true,
        border = "single",
    })

    local function set_hints(keymap, linenr)
        local line = NuiLine()
        line:append(keymap.lhs, "SpecialKey")
        line:append("\t")
        line:append(keymap.opts.desc)
        local bufnr, ns_id, linenr_start = popup_one.bufnr, -1, linenr
        line:render(bufnr, ns_id, linenr_start)
    end

    local function update_status()
        local line = NuiLine()
        line:append("Options: ")
        local bufnr, ns_id, linenr_start = popup_one.bufnr, -1, 1
        line:render(bufnr, ns_id, linenr_start)

        line = NuiLine()
        line:append("  Visibility: ")
        line:append(is_repo_public and "public" or "private", "Error")
        line:append(" <c-p>", "SpecialKey")
        local bufnr, ns_id, linenr_start = popup_one.bufnr, -1, 2
        line:render(bufnr, ns_id, linenr_start)

        --NuiLine({ NuiText("one"), NuiText("two", "Error")}):render(bufnr, ns_id, 3)
        NuiLine({ NuiText("") }):render(bufnr, ns_id, 3)
        NuiLine({ NuiText("Message: "), NuiText(string.gsub(message, "\n", ""), messageHighlight) }):render(bufnr, ns_id, 4)
        NuiLine({ NuiText("") }):render(bufnr, ns_id, 5)

        line = NuiLine()
        line:append("Keymaps: ")
        local bufnr, ns_id, linenr_start = popup_one.bufnr, -1, 6
        line:render(bufnr, ns_id, linenr_start)
    end

    local layout = Layout(
        {
            position = "50%",
            size = {
                width = 80,
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box(clone_input, { size = "10%" }),
            Layout.Box(popup_one, { size = "40%" }),
        }, { dir = "col" })
    )

    local function update_message(msg, hl)
        message = msg
        messageHighlight = hl
        update_status()
    end

    local function do_clone(user_name, repo_name)
        local user_dir = config.github_dir .. config.sep .. user_name
        local repo_dir = user_dir .. config.sep .. repo_name
        if util.path_exists(repo_dir) then
            update_message("Error: repo exists", "Error")
            util.promptYesNo("remove local and retry?", function()
                local code = util.rm_rf(repo_dir)
                --                print(string.format("rm command returns %d", code))
                do_clone(user_name, repo_name)
            end)
            return
        end

        if not util.path_exists(user_dir) then
            util.mkdir_p(user_dir)
        end

        local clone_command = "gh repo clone " .. user_name .. config.sep .. repo_name
        message = "running command " .. clone_command .. " ..."
        update_status()

        local function on_command_exit(result)
            vim.schedule(function()
                if result.code == 0 then
                    update_message("success, path: ".. repo_dir, "Error")
                    if config.on_clone_success then 
                        promptYesNo("close window and open it?", function()
                            layout:unmount()
                            config.on_clone_success(repo_dir)
                        end)
                    else
                        promptYesNo("close window?", function() 
                            layout:unmount()
                        end)
                    end
                else
                    update_message("failed, reason: " .. result.stderr, "Error")
                    promptYesNo("remove local and retry?", function()
                        util.rm_rf(repo_dir)
                        do_clone(user_name, repo_name)
                    end)
                end
            end
            )
        end


        vim.system({ "bash", "-c", clone_command }, {
            text = true,
            cwd = user_dir,
        }, on_command_exit)

        -- 错误处理
    end
    local function handle_clone()
        local user_name = ""
        local repo_name = ""
        local tokens = util.mysplit(repo_input, "/")
        if #tokens > 2 or #tokens <= 1 then
            message = "Error: invalid input, should be user/repo"
            messageHighlight = "Error"
            update_status()
            return
        elseif #tokens == 2 then
            user_name = tokens[1]
            repo_name = tokens[2]
            --        elseif #tokens == 1 then
            --            repo_name = tokens[1]
        end
        message = user_name and string.format("user_name:%s, repo:%s", user_name, repo_name) or "user_name: " ..
            user_name
        messageHighlight = "Error"
        update_status()

        print(string.format("repo: %s, visibility: %s", repo_input, is_repo_public and "public" or "private"))
        do_clone(user_name, repo_name)
    end
    --gh repo create github.nvim --template nvimdev/nvim-plugin-template --public --clone



    update_status()
    keymaps = {
        {
            mode = { "i", "n" },
            lhs = "<c-p>",
            rhs = function()
                is_repo_public = not is_repo_public
                update_status()
            end,
            opts = {
                desc = "change visibility"
            }

        },
        {
            mode = { "i", "n" },
            lhs = "<c-g>",
            rhs = handle_clone,
            opts = {
                desc = "do clone"
            }

        },
        {
            mode = { "i" },
            lhs = "<cr>",
            rhs = handle_clone,
            opts = {
                desc = "do clone"
            }

        },
        {
            mode = { "i", "n" },
            lhs = "<c-c>",
            rhs = function()
                print("close")
                layout:unmount()
            end,
            opts = {
                desc = "close window"
            }

        }
    }

    for i, keymap in ipairs(keymaps) do
        for _, mode in ipairs(keymap.mode) do
            clone_input:map(mode, keymap.lhs, keymap.rhs, keymap.opts)
            popup_one:map(mode, keymap.lhs, keymap.rhs, keymap.opts)
        end
        set_hints(keymap, 6 + i)
    end

    layout:mount()
end


return M
