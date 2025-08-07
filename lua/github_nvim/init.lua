local M = {}
local config = require("github_nvim.config")


-- M.github_repos = require('github_nvim.pickers.github_repos')
-- local telescope = require("telescope")
-- telescope.register_extension {
--   exports = {
--     github_repos = require('github_nvim/pickers/github_repos')
--   }
-- }
require('telescope').load_extension('github_repos')

function M.setup(options)
    setmetatable(M, {
        __newindex = config.set,
        __index = config.get
    })
    if options ~= nil then
        for k1, v1 in pairs(options) do
            if (type(config.defaults[k1]) == "table") then
                for k2, v2 in pairs(options[k1]) do
                    config.defaults[k1][k2] = v2
                end
            else
                config.defaults[k1] = v1
            end
        end
    end
end

function M.clone()
    local clone = require("github_nvim.clone")
    clone.clone(M)
end

function M.create()
    local create = require("github_nvim.create")
    create.create(M)
end



return M
