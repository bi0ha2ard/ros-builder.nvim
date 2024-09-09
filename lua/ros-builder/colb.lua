local M = {}

M.build = function(ws, opts, pkg, test_name, test_exe)
  local cmd = {"colb", "--workspace", ws}
  if test_name then
    -- just builds the selected test and runs it
    vim.list_extend(cmd, {"test", pkg, "--test", test_name})
    return table.concat(cmd, " ")
  end
  -- builds current package, including tests
  vim.list_extend(cmd, {"build", pkg})
  return table.concat(cmd, " ")
end
--
-- Test entire package
-- Note: doesn't build upstream
M.test = function(ws, opts, pkg)
  local cmd = {"colb", "--workspace", ws, "test", pkg}
  return table.concat(cmd, " ")
end

M.opts = {}

return M

