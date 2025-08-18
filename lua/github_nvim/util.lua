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

function M.open_project(dir)
    vim.cmd("Telescope find_files cwd="..dir)
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

function M.get_os()
    if vim.fn.has("win32") == 1 then
        return "windows"
    elseif vim.fn.has("mac") == 1 then
        return "macos"
    elseif vim.fn.has("unix") == 1 then
        if vim.env.WSL_DISTRO_NAME then
            return "wsl"
        elseif vim.env.SHELL and vim.env.SHELL:match("wsl") then
            return "wsl"
        elseif vim.env.MSYSTEM and vim.env.MSYSTEM:match("MINGW") then
            return "msys2"
        else
            return "linux"
        end
    else
        return "unknown"
    end
end

-- Optional: Get OS name as string
function M.is_windows() return M.get_os() == "windows" end

function M.is_macos() return M.get_os() == "macos" end

function M.is_linux() return M.get_os() == "linux" end

function M.is_wsl() return M.get_os() == "wsl" end

function M.is_msys2() return M.get_os() == "msys2" end

function M.open_url(url)
    local os = M.get_os()

    if os == "macos" then
        vim.fn.system("open " .. vim.fn.shellescape(url))
    elseif os == "windows" or os == "msys2" then
        vim.fn.system("start " .. vim.fn.shellescape(url))
    elseif os == "wsl" then
        -- Try wslview first (opens in Windows browser)
        local success, _ = pcall(vim.fn.system, "wslview --version")
        if success then
            vim.fn.system("wslview " .. vim.fn.shellescape(url))
        else
            -- Fallback: try 'start' via Windows host
            -- This requires 'wsl.exe' to be able to run Windows commands
            vim.fn.system("wsl.exe cmd.exe /c start " .. vim.fn.shellescape(url))
        end
    elseif os == "linux" then
        vim.fn.system("xdg-open " .. vim.fn.shellescape(url))
    else
        print("Unsupported OS:", os)
    end
end

M.plugin_name = "github_nvim"

function M.get_github_repos()
    local handle = io.popen(
        'gh repo list -L 200 --json nameWithOwner,description,isPrivate,isFork,isTemplate 2>/dev/null')
    local result = handle:read('*a')
    handle:close()

    if result == '' then
        return {}
    end

    local ok, json = pcall(vim.json.decode, result)
    if not ok then
        print("Error parsing GitHub repos: " .. tostring(json))
        return {}
    end

    local items = {}

    for _, repo in ipairs(json) do
        local name = repo.nameWithOwner
        local desc = repo.description or ""
        local is_private = repo.isPrivate and "🔒" or ""
        local is_fork = repo.isFork and "♻️" or ""
        local is_template = repo.isTemplate and "📦" or ""

        local display = string.format("%s %s", name, is_private .. is_fork .. is_template)
        table.insert(items, {
            value = name,
            display = display,
            description = desc,
            is_private = repo.isPrivate,
            is_fork = repo.isFork,
            is_template = repo.isTemplate,
        })
    end

    return items
end


return M
