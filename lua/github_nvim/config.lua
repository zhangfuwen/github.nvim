local sep = vim.fn.has("win32") == 1 and "\\" or "/"
local home = vim.env.HOME or os.getenv("HOME")
local defaults = {
    sep = sep,
    home = home,
    github_dir = home .. sep .. "Code" .. sep .. "github.com",
    spawn_command = {
        python = "ipython",
        scala = "sbt console",
        lua = "ilua",
    }
}

local function set(_, key, value)
    defaults[key] = value
end

local function get(_, key)
    return defaults[key]
end

return {
    defaults = defaults,
    get = get,
    set = set
}
