local cache = require("github_nvim.cache")
local config = require("github_nvim")
local util = require("github_nvim.util")
local gh = require("github_nvim.gh")

M = {}
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

function get_github_repos_cached(skip_load_from_cache)
    if not skip_load_from_cache then
        local cached_result = cache.load(cache_ns, cache_key)
        if cached_result then
            return cached_result
        end
    end
    local items = util.get_github_repos()
    cache.save(cache_ns, cache_key, items)
    return items
end

local finders = require('telescope.finders')
local pickers = require("telescope.pickers")
local action_state = require('telescope.actions.state')
local current_prompt_bufnr = 0
local filter = "all" -- local, remote

local function entry_maker1(entry)
    local github_dir = config.github_dir
    local sep = config.sep
    local name = entry.value
    local local_path = github_dir .. sep .. name
    local local_exists = util.path_exists(local_path) and true or false
    local local_icon = local_exists and " 💾Local" or " 🌐"
    if filter == "local" and not local_exists then
        return nil
    end

    if filter == "remote" and local_exists then
        return nil
    end
    return {
        value = entry.value,
        display = entry.display .. " " .. local_icon,
        ordinal = entry.value,
        is_private = entry.isPrivate,
        is_fork = entry.isFork,
        is_template = entry.isTemplate,
        local_path = entry.local_path,
        local_exists = entry.local_exists,
    }
end
local searcher = function(input, results)
    local filtered = {}
    for _, v in ipairs(results) do
        if string.find(v, input, 1, true) then
            table.insert(filtered, v)
        end
    end
    return filtered
end

local finder = finders.new_table({
    results = get_github_repos_cached(),
    entry_maker = entry_maker1,
    searcher = searcher,
})

local function selection_open_project()
    local selection = action_state.get_selected_entry()
    local local_path = selection.local_path
    local local_exists = selection.local_exists

    if local_exists then
        util.open_project(local_path)
    else
        vim.notify("Selected:", selection.value, " local_path: ", local_path)
    end
end

local function selection_open_url()
    local selection = action_state.get_selected_entry()
    local url = "https://github.com/" .. selection.value
    util.open_url(url)
end

local function selection_copy_repo_url()
    local selection = action_state.get_selected_entry()
    local url = "https://github.com/" .. selection.value
    vim.fn.setreg("+", url) -- Copy to system clipboard
    vim.notify("Copied: " .. url, vim.log.levels.INFO)
end

local function selection_force_refresh1()
    local temp_finder = finders.new_table({
        results = get_github_repos_cached(true),
        entry_maker = entry_maker1,
        searcher = searcher,
    })

    local current_picker = action_state.get_current_picker(current_prompt_bufnr)
    current_picker:refresh(temp_finder, { reset_prompt = false })
end

local function selection_clone_repo()
    local selection = action_state.get_selected_entry()
    local repo_name = selection.value
    --                gh_username = gh.get_github_username()
    local dir = vim.fn.input("Clone to directory: ",
        config.github_dir .. config.sep .. repo_name)
    vim.notify("start cloning")

    local tokens = util.mysplit(repo_name, "/")
    local user_name = tokens[1]
    local repo_name_only = tokens[2]
    gh.do_clone(config, user_name, repo_name_only, {
        on_success = function(repo_dir)
            local picker = action_state.get_current_picker(current_prompt_bufnr)

            if not picker then return end

            vim.notify("✅ Cloned: " .. dir, vim.log.levels.INFO, { title = util.plugin_name })
            selection_force_refresh1()

            util.promptYesNo("open it?", function()
                util.open_project(repo_dir)
            end)
        end,
        on_fail = function()
            vim.notify("failed to clone.", vim.log.levels.ERROR)
        end

    })
end

local function selection_open_readme()
    local selection = action_state.get_selected_entry()
    local url = "https://github.com/" .. selection.value .. "/blob/main/README.md"
    util.open_url(url)
end

local function attach_mappings1(prompt_bufnr, map)
    current_prompt_bufnr = prompt_bufnr
    vim.notify("prompt_bufnr " .. prompt_bufnr)
    -- Open project
    map('i', '<C-g>', selection_open_project, { desc = "Open project" })

    -- Open in browser
    map("i", "<C-o>", selection_open_url, { desc = "Open in browser" })

    -- Copy URL to clipboard
    map("i", "<C-s>", selection_copy_repo_url, { desc = "Copy URL to clipboard" })

    -- Clone repo
    map("i", "<C-p>", selection_clone_repo, { desc = "Clone repo locally" })

    -- Preview README (simple version)
    map("i", "<C- >", selection_open_readme, { desc = "Open README" })

    -- Refresh repos
    map("i", "<C-r>", selection_force_refresh1, { desc = "force refresh repos" })

    map("i", "<C-l>", function()
        filter = "local"
        selection_force_refresh1()
    end, { desc = "show local only" })

    map("i", "<C-m>", function()
        filter = "remote"
        selection_force_refresh1()
    end, { desc = "show remote only" })

    map("i", "<C-a>", function()
        filter = "all"
        selection_force_refresh1()
    end, { desc = "show all" })
    return true
end


function M.pick()
    local conf = require('telescope.config').values
    local my_picker = pickers.new({}, {
        prompt_title = "Your github repos",
        finder = finder,
        sorter = conf.generic_sorter(opts),
        attach_mappings = attach_mappings1
    })
    my_picker:find()
end

return M
