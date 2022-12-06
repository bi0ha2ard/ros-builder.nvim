local M = {}

M.systems = {
  colcon = require("ros-builder.colcon"),
  catkin = require("ros-builder.catkin"),
}

-- This defaults to colcon for ROS2 workspaces and catkin for ROS1 workspaces.
M.guess_build_system = function()
  if vim.fn.executable("ros2") == 1 then
    return "colcon"
  else
    return "catkin"
  end
end

M.setup = function(opts)
   M.systems = vim.tbl_deep_extend("force", M.systems, opts or {})
end

return M
