M = {}

function M.get_github_username()
  local result = vim.fn.system("gh api user --jq '.login' 2>/dev/null")
  if vim.v.shell_error == 0 then
    return string.gsub(result, "\n$", "") -- remove newline
  else
    return nil
  end
end

return M
