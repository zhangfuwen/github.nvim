util = require("github_nvim.util")
gh = require("github_nvim.gh")

M = {}


function M.clone(config)
    local repo_input = ""
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
        end,
        on_submit = function(value)
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
        line:append("Keymaps: ")
        local bufnr, ns_id, linenr_start = popup_one.bufnr, -1, 1
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

        gh.do_clone(config, user_name, repo_name, {
            on_success = function(repo_dir)
                layout:unmount()
                util.open_project(repo_dir)
            end,
            on_fail = function()
                layout:unmount()
            end

        })
    end
    --gh repo create github.nvim --template nvimdev/nvim-plugin-template --public --clone



    update_status()
    keymaps = {
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
                layout:unmount()
            end,
            opts = {
                desc = "close window"
            }

        },
        {
            mode = { "i", "n" },
            lhs = "<Esc>",
            rhs = function()
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
        set_hints(keymap, 1 + i)
    end

    layout:mount()
end

return M
