vim.opt.runtimepath:prepend("/home/liutao/Code/github.com/zhangfuwen/github.nvim/")
myplugin = require("github_nvim")
myplugin.setup({
    on_clone_success = function(repo_path)
        vim.cmd("FzfLua files cwd="..repo_path)

    end
})
--myplugin.create()
--
--require('telescope').load_extension('github_repos')
-- telescope = require('telescope')
-- telescope.register_extension {
--   exports = {
--     github_repos = require('github_nvim.pickers.github_repos')
--   }
-- }
-- telescope.load_extension('github_repos')
-- picker = require("github_nvim.pickers.github_repos")
-- if picker then
--     picker()
-- end

