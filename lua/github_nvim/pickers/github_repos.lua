cache = require("github_nvim.cache")
local config = require("github_nvim.config")
local util = require("github_nvim.util")
local gh = require("github_nvim.gh")
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

-- Store clone status: key = repo_name, value = "pending" | "success" | "failed"
local clone_status = {}

-- Helper: Get status for a repo
local function get_status(repo)
    return clone_status[repo] or nil
end

-- Helper: Set status
local function set_status(repo, status)
    clone_status[repo] = status
end

local function get_github_repos()
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

local function get_github_repos_cached()
    cached_result = cache.load(cache_ns, cache_key)
    if cached_result then
        print("cache hit")
        return cached_result
    end
    local items = get_github_repos()
    print("cache save")
    cache.save(cache_ns, cache_key, items)
end

local my_picker = nil

local function get_current_picker()
    return my_picker
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
        results = get_github_repos_cached(),
        entry_maker = function(entry)
            print("find...")
            local github_dir = config.defaults.github_dir
            local sep = config.defaults.sep
            local name = entry.value
            local local_path = github_dir .. sep .. name
            local local_exists = util.path_exists(local_path) and true or false
            local local_icon = local_exists and "local" or "remote"
            local status = get_status(name)
            return {
                value = entry.value,
                display = entry.display .. " " .. local_icon .. (status and "... "..status or ""),
                ordinal = entry.value,
                is_private = entry.isPrivate,
                is_fork = entry.isFork,
                is_template = entry.isTemplate,
                local_path = entry.local_path,
                local_exists = entry.local_exists,
            }
        end,
        --        searcher = conf.fuzzy_finder.new_searcher({}),
        searcher = searcher,
    })
    local pickers = require("telescope.pickers")
    my_picker = pickers.new({}, {
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
            map('i', '<C-g>', function()
                local actions = require('telescope.actions.state')
                local selection = actions.get_selected_entry()
                local local_path = selection.local_path
                local local_exists = selection.local_exists

                if local_exists then
                    vim.cmd("Telescope find_files cwd=" .. local_path)
                else
                    print("Selected:", selection.value, " local_path: ", local_path)
                end
            end)
            -- Open in browser
            map("i", "<C-o>", function()
                local actions = require('telescope.actions.state')
                local selection = actions.get_selected_entry()
                local url = "https://github.com/" .. selection.value
                util.open_url(url)
            end, { desc = "Open in browser" })

            -- Copy URL to clipboard
            map("i", "<C-s>", function()
                local actions = require('telescope.actions.state')
                local selection = actions.get_selected_entry()
                local url = "https://github.com/" .. selection.value
                vim.fn.setreg("+", url) -- Copy to system clipboard
                vim.notify("Copied: " .. url, vim.log.levels.INFO)
            end, { desc = "Copy URL to clipboard" })

            -- Clone repo
            map("i", "<C-p>", function()
                local actions = require('telescope.actions.state')
                local selection = actions.get_selected_entry()
                local repo_name = selection.value
--                gh_username = gh.get_github_username()
                local dir = vim.fn.input("Clone to directory: ",
                    config.defaults.github_dir .. config.defaults.sep .. repo_name)
                set_status(repo_name, "cloning")


                -- Refresh immediately
                vim.schedule(function()
                    local actions = require('telescope.actions.state')
                    local picker = actions.get_current_picker(prompt_bufnr)
                    --                    print("picker ", vim.inspect(picker))
--                    print("picker ", vim.inspect(picker))
                    if picker and picker.finder.results then
                        picker.finder.results = vim.tbl_map(function(item)
                            if item.value == repo_name then
                                item._status = "cloning"
                                item.display = item.display:gsub("%(.*%)", "(🔄 Cloning...)")
                            end
                            return item
                        end, picker.finder.results)
                        set_status(repo_name, "downloaded")
                        picker:refresh()
                    end
                end)

                -- Run async clone
                local url = "https://github.com/" .. repo_name
                vim.system({ "git", "clone", url, dir }, {
                    text = true, cwd = user_dir, }, function(result)
                    vim.schedule(function()
                        local actions = require('telescope.actions.state')
                        local picker = actions.get_current_picker(prompt_bufnr)
                        --                        print("picker ", vim.inspect(picker))
                        if not picker then return end

                        local updated_results = vim.tbl_map(function(item)
                            if item.value == repo_name then
                                if result.code == 0 then
                                    item._status = "success"
                                    item.display = item.display:gsub("%(.*%)", "(✅ Cloned)")
                                    vim.notify("✅ Cloned: " .. dir, vim.log.levels.INFO)
                                else
                                    item._status = "failed"
                                    item.display = item.display:gsub("%(.*%)", "(❌ Failed)")
                                    vim.notify("❌ Failed to clone: " .. vim.inspect(result), vim.log.levels.ERROR)
                                end
                            end
                            return item
                        end, picker.finder.results)

                        picker.finder.results = updated_results
                        picker:refresh()
                    end)
                end)


                -- local cmd = "git clone https://github.com/" .. selection.value .. " " .. dir
                -- vim.cmd(":silent !" .. cmd)
                -- vim.notify("Cloned to: " .. dir)
            end, { desc = "Clone repo locally" })

            -- Preview README (simple version)
            map("i", "<C- >", function()
                local actions = require('telescope.actions.state')
                local selection = actions.get_selected_entry()
                local url = "https://github.com/" .. selection.value .. "/blob/main/README.md"
                util.open_url(url)
            end, { desc = "Open README" })

            map("i", "<C-r>", function()
                local actions = require('telescope.actions.state')
                local picker = actions.get_current_picker(prompt_bufnr)
                if not picker then return end

--                print("picker ", vim.inspect(picker))

                -- Get current query from prompt
                local query = vim.api.nvim_buf_get_name(picker.prompt_bufnr) or ""

                -- Set loading prompt
--                picker.set_prompt("🔄 Refreshing...", false)

                -- Use your existing get_github_repos() function
                vim.defer_fn(function()
                    local results = get_github_repos()

                    if not results or #results == 0 then
                        vim.schedule(function()
                            local actions = require('telescope.actions.state')
                            vim.notify("⚠️ No results returned from GitHub API", vim.log.levels.WARN)
--                            picker.set_prompt("GitHub Repositories")
                        end)
                        return
                    end

                    -- Save to cache
                    local cache = require("github_nvim.cache")
                    cache.save(cache_ns, cache_key, results, 60 * 60 * 24)

                    -- Update picker UI
                    vim.schedule(function()
                        --                        local actions = require('telescope.actions.state')
                        picker.results = results
                        picker:refresh()
--                       picker.set_prompt("GitHub Repositories")
                        vim.notify("✅ Refreshed from internet", vim.log.levels.INFO)
                    end)
                end, 100) -- Small delay to avoid flicker
            end, { desc = "force refresh repos" })

            -- Optional: Add 'select' as default
            -- actions.select_default:replace(function()
            --     local selection = actions.get_selected_entry()
            --     print("Selected:", selection.value)
            --     actions.close(prompt_bufnr)
            -- end)
            return true
        end,
    })
    my_picker:find()
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
