## github_nvim

A neovim plugin to manage github repos. It uses github command line tool (gh) to manage github repos 
so make sure you have gh installed and authorized.


## Usage

```lua
github_nvim = require("github_nvim")
github_nvim.setup({})
require('telescope').load_extension('github_repos')

vim.keymap.set("n", "<leader>ghr", function()
    vim.cmd("Telescope github_repos")
end, { desc = "List github repos(for clone or open)", buffer = bufnr })

vim.keymap.set("n", "<leader>ghc", function()
    require("github_nvim").clone()
end, { desc = "Clone a github repo", buffer = bufnr })

vim.keymap.set("n", "<leader>ghn", function()
    require("github_nvim").create()
end, { desc = "New github repo", buffer = bufnr })

```

for those who are using lazy to manage plugins:

```lua
{
    'zhangfuwen/github.nvim',
    config = function()
        local github_nvim = require("github_nvim")
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
    end
},

```

## Format

The CI uses `stylua` to format the code; customize the formatting by editing `.stylua.toml`.

## Test

See [Running tests locally](https://github.com/nvim-neorocks/nvim-busted-action?tab=readme-ov-file#running-tests-locally)

## CI

- Auto generates doc from README.
- Runs the [nvim-busted-action](https://github.com/nvim-neorocks/nvim-busted-action) for test.
- Lints with `stylua`.

## More

To see this template in action, take a look at my other plugins.

## License MIT
