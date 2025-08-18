vim.opt.runtimepath:prepend("/home/liutao/Code/github.com/zhangfuwen/github.nvim/")
github_nvim = require("github_nvim")
github_nvim.setup({})
require('telescope').load_extension('github_repos')

vim.keymap.set("n", "<leader>ghr", function()
    vim.cmd("Telescope github_repos")
end, { desc = "List github repos", buffer = bufnr })

vim.keymap.set("n", "<leader>ghc", function()
    require("github_nvim").clone()
end, { desc = "Clone a github repo", buffer = bufnr })

vim.keymap.set("n", "<leader>ghn", function()
    require("github_nvim").create()
end, { desc = "New github repo", buffer = bufnr })
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
