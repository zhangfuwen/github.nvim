M = {}
function M.mkdir_p(path)
    -- if vim.loop then
    --     -- Neovim 0.9+：使用 vim.loop
    --     local ok, err = vim.loop.fs_mkdir(path, 0755)
    --     if not ok and err ~= "EEXIST" then
    --         print("Error:", err)
    --     end
    -- else
        -- Neovim < 0.9：用 shell 命令
    local cmd = "mkdir -p " .. path
    vim.system({ "bash", "-c", cmd })
    -- end
end

function M.rm_rf(path)
    local cmd = "rm -rf " .. path
    local result = vim.system({ "bash", "-c", cmd }):wait()
    return result.code
end

function M.mysplit(inputstr, sep)
    -- if sep is null, set it as space
    if sep == nil then
        sep = '%s'
    end
    -- define an array
    local t = {}
    -- split string based on sep
    for str in string.gmatch(inputstr, '([^' .. sep .. ']+)')
    do
        -- insert the substring in table
        table.insert(t, str)
    end
    -- return the array
    return t
end


function M.path_exists(path)
    local stat = vim.loop.fs_stat(path)
    return stat ~= nil
end

function M.promptYesNo(message, on_yes, on_no, on_cancel)
    local Menu = require("nui.menu")
--    local event = require("nui.utils.autocmd").event
    on_no = on_no or function() end
    on_cancel = on_cancel or function() end
    local menu = Menu({
        position = "50%",
        size = {
            width = 25,
            height = 5,
        },
        border = {
            style = "single",
            text = {
                top = message,
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        lines = {
            Menu.item("Yes (y/Y)", { id = 1 }),
            Menu.item("No (n/N)", { id = 2 }),
        },
        max_width = 20,
        keymap = {
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            close = { "<Esc>", "<C-c>" },
            submit = { "<CR>", "<Space>" },
        },
        on_close = function()
            on_cancel()
        end,
        on_submit = function(item)
            if item.id == 1 then
                on_yes()
            else
                on_no()
            end
            print("Menu Submitted: ", item.text)
        end,
    })

    -- mount the component
    vim.cmd("normal! <C-\\><C-n>")
    menu:mount()
end


return M
