cache = require("github_nvim.cache")
-- Safely check if telescope is available
local function get_telescope()
    local ok, telescope = pcall(require, 'telescope')
    if not ok then return nil end
    return telescope
end

local function get_fzf_extension()
    local ok, fzf = pcall(require, 'telescope.extensions.fzf')
    if not ok then return nil end
    return fzf
end

local cache_ns = "github_nvim.pickers"
local cache_key = "github_repos"

local function get_github_repos()
    cached_result = cache.load(cache_ns, cache_key)
    if cached_result then
        print("cache hit")
        return cached_result
    end

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

    print("cache save")
    cache.save(cache_ns, cache_key, items)

    return items
end

return function()
    local conf = require('telescope.config').values
    local searcher = function(input, results)
        print(input)
        local filtered = {}
        for _, v in ipairs(results) do
            if string.find(v, input, 1, true) then
                table.insert(filtered, v)
            end
        end
        return filtered
    end

    local finder = require('telescope.finders').new_table({
        results = get_github_repos(),
        entry_maker = function(entry)
            return {
                value = entry.value,
                display = entry.display,
                ordinal = entry.value,
            }
        end,
--        searcher = conf.fuzzy_finder.new_searcher({}),
        searcher = searcher,
    })
    local pickers = require("telescope.pickers")
    pickers.new({}, {
        prompt_title = "Your github repos",
        finder = finder,
        sorter = conf.generic_sorter(opts),
        -- attach_mappings = function(prompt_bufnr, map)
        --   -- Open in browser
        --   actions.select_default:replace(function()
        --     local selection = action_state.get_selected_entry()
        --     local url = "https://github.com/" .. selection.value
        --     vim.cmd(('silent !open "%s"'):format(url))
        --   end)
        --
        --   -- Clone repo
        --   map('i', '<C-c>', function()
        --     local selection = action_state.get_selected_entry()
        --     local cmd = ('git clone https://github.com/%s.git'):format(selection.value)
        --     vim.cmd(('silent !%s'):format(cmd))
        --     vim.notify("Cloned: " .. selection.value, vim.log.levels.INFO)
        --   end)
        --
        --   return true
        -- end,
        attach_mappings = function(prompt_bufnr, map)
            -- Add mappings
            map('i', '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                print("Selected:", selection.value)
            end)
            return true
        end,
    }):find()
end

-- Main picker function
-- return function()
--   --local telescope = get_telescope()
--   local telescope = require("telescope")
--   if not telescope then
--     print("Telescope not available. Install nvim-telescope/telescope.nvim")
--     return
--   end
--
--   print(vim.inspect(telescope))
--
--   local fzf_ext = get_fzf_extension()
-- --  local picker_fn = fzf_ext and fzf_ext.fzf_picker or telescope.picker.new
--     local picker_fn = require("telescope.pickers").new
--
--   local opts = {
--     prompt_title = "GitHub Repositories",
--     results = get_github_repos(),
--     attach_mappings = function(prompt_bufnr, map)
--       -- Open in browser
--       actions.select_default:replace(function()
--         local selection = action_state.get_selected_entry()
--         local url = "https://github.com/" .. selection.value
--         vim.cmd(('silent !open "%s"'):format(url))
--       end)
--
--       -- Clone repo
--       map('i', '<C-c>', function()
--         local selection = action_state.get_selected_entry()
--         local cmd = ('git clone https://github.com/%s.git'):format(selection.value)
--         vim.cmd(('silent !%s'):format(cmd))
--         vim.notify("Cloned: " .. selection.value, vim.log.levels.INFO)
--       end)
--
--       return true
--     end,
--   }
--
--   -- Use fzf picker if available, else fallback to default
--   local picker = picker_fn(opts)
--   picker:find()
-- end
