local M = {}

M.colcon_base_cmd = function(colcon, ws, verb)
  return { colcon,
    "--log-base", vim.fs.joinpath(ws, "log"), verb,
    "--build-base", vim.fs.joinpath(ws, "build"),
    "--install-base", vim.fs.joinpath(ws, "install")
  }
end

M.append_mixins = function(cmd, mixins)
  if mixins and #mixins > 0 then
    vim.list_extend(cmd, { "--mixin" })
    vim.list_extend(cmd, mixins)
  end
end

M.append_cmake_args = function(cmd, cmake)
  if cmake and #cmake > 0 then
    vim.list_extend(cmd, { "--cmake-args" })
    vim.list_extend(cmd, cmake)
  end
end

M.append_with_message = function(lines)
  local msg = table.concat(lines, "\\n")
  return "&& echo -e \"" .. msg .. "\" &&"
end

M.divider = function(text)
  local spacer = string.rep("=", string.len(text))
  return {
    "",
    spacer,
    text,
    spacer,
    "",
  }
end

return M
