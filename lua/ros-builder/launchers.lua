local M = {}

M.asyncrun = function(cmd, cwd)
  local asyncrun_opts = { mode = "term", focus = false, listed = false, cwd = cwd }
  vim.call("asyncrun#run", "", asyncrun_opts, cmd)
end

M.terminal = function(cmd, cwd)
  vim.cmd.terminal("cd " .. cwd .. " && " .. cmd)
end

M.cmd = function(cmd, cwd)
  vim.cmd["!"]("cd " .. cwd .. " && " .. cmd)
end

return M
