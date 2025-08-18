-- lua/github_nvim/cache.lua
local util = require("github_nvim.util")

local M = {}

-- === Configuration: Default settings === --
local DEFAULT_TTL = 60 * 60 * 24       -- 24 hours
local MAX_CACHE_FILES = 50
local CACHE_DIR_PREFIX = "github_nvim" -- e.g. "github", "weather", "news"

-- === Internal helpers === --

-- Get cache directory for a given name
local function cache_dir(cache_name)
    return vim.fn.stdpath("cache") .. "/" .. (cache_name or CACHE_DIR_PREFIX)
end
-- Generate safe filename from key
local function generate_filename(cache_name, key)
    local sanitized_key = key:gsub("[^%w_]", "_")
    local truncated = string.sub(sanitized_key, 1, 64)
    return string.format("%s/%s_%s.json", cache_dir(cache_name), cache_name, truncated)
end


-- Ensure cache dir exists
local function ensure_cache_dir(cache_name)
    local path = cache_dir(cache_name)
    if vim.uv.fs_stat(path) then
        return path
    end

    util.mkdir_p(path) -- 0755
    return path
end

-- Check if file is valid (within TTL)
local function is_valid(cache_name, key, ttl)
    local file = generate_filename(cache_name, key)
    local stat = vim.uv.fs_stat(file) 
    if not stat then
        print(string.format("file %s does not exist.", file))
        return false
    end

    local now = vim.uv.now()
    local age = now - stat.mtime.sec
    return age < (ttl or DEFAULT_TTL)
end

-- === Public API === --

-- Load cached data by key in a named cache
-- @param cache_name (string): e.g. "github", "weather"
-- @param key (string): unique identifier (e.g. "neovim", "London")
-- @param ttl (number): override TTL in seconds (optional)
-- @return table | nil: returns cached data or nil
function M.load(cache_name, key, ttl)
    local file = generate_filename(cache_name, key)
    local f = io.open(file, "r")
    if not f then
        print(string.format("cannot open %s.", file))
        return nil
    end

    local content = f:read("*a")
    f:close()

    local success, data = pcall(vim.json.decode, content)
    if not success then
        print("❌ Invalid JSON in cache file:", file, content)
        return nil
    end

--    print("data is ", vim.inspect(data))
    if not data or not data.results then
        print(string.format("data decode error, content:%s", content))
        return nil
    end

    if not is_valid(cache_name, key, ttl) then
        return nil -- expired
    end

    return data.results
end

-- Save data to cache
-- @param cache_name (string): cache namespace (e.g. "github")
-- @param key (string): unique key
-- @param results (table): your data (e.g. list of repos)
-- @param ttl (number): time-to-live in seconds (optional)
function M.save(cache_name, key, results, ttl)
    local file = generate_filename(cache_name, key)
    local dir = cache_dir(cache_name)
    ensure_cache_dir(cache_name)

    local data = {
        results = results,
        timestamp = vim.uv.now(),
        key = key,
        cache_name = cache_name,
        ttl = ttl or DEFAULT_TTL,
    }

--    print("save results: ", vim.inspect(results))
--    print("data: ", vim.inspect(data))

    local f = io.open(file, "w")
    if not f then
        print("❌ Failed to write cache file:", file)
        return
    end
    print("file is: ", vim.inspect(file))

    local content = vim.json.encode(data)
--    print("content is " .. content)
    local err = f:write(content)
    print(vim.inspect(err))
    if err then
        print("failed to write to file, msg:", err)
    end
    f:close()

    -- Optional: cleanup after save
    M.cleanup(cache_name)
end

-- Cleanup old files in a specific cache
-- @param cache_name (string): e.g. "github"
function M.cleanup(cache_name)
    local dir = cache_dir(cache_name)
    local files = vim.split(vim.fn.glob(dir .. "/*.json"), "\n", { plain = true })
    local valid_files = {}

    for _, file in ipairs(files) do
        local stat = vim.uv.fs_stat(file)
        if stat then
            table.insert(valid_files, { file = file, mtime = stat.mtime.sec })
        end
    end

    -- Sort by mtime (oldest first)
    table.sort(valid_files, function(a, b)
        return a.mtime < b.mtime
    end)

    -- Remove excess files
    while #valid_files > MAX_CACHE_FILES do
        local old_file = table.remove(valid_files, 1)
        vim.uv.fs_unlink(old_file.file)
    end
end

-- Clear all files in a cache
-- @param cache_name (string)
function M.clear(cache_name)
    local dir = cache_dir(cache_name)
    local files = vim.split(vim.fn.glob(dir .. "/*.json"), "\n", { plain = true })
    for _, file in ipairs(files) do
        vim.uv.fs_unlink(file)
    end
end

-- List all cached keys in a cache (for debugging)
-- @param cache_name (string)
-- @return table: list of keys
function M.list_keys(cache_name)
    local dir = cache_dir(cache_name)
    local files = vim.split(vim.fn.glob(dir .. "/*.json"), "\n", { plain = true })
    local keys = {}

    for _, file in ipairs(files) do
        local basename = vim.fn.fnamemodify(file, ":t:r")
        local parts = vim.split(basename, "_", { plain = true })
        if #parts >= 2 then
            table.insert(keys, parts[2])
        end
    end

    return keys
end

-- === Utility: Safe JSON decode with fallback === --
function M.safe_decode(str)
    local ok, data = pcall(vim.json.decode, str)
    return ok and data or nil
end

return M
