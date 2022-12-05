local M = {}

M.systems = {
  colcon = require("ros-builder.colcon"),
  catkin = require("ros-builder.catkin"),
}

M.setup = function(opts)
   M.systems = vim.tbl_deep_extend("force", M.systems, opts or {})
end

return M
