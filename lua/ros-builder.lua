local lsputil = require('lspconfig.util')
local Path = require('plenary.path')
local scan = require("plenary.scandir")
local ros_pattern = lsputil.root_pattern("package.xml")

-- Autogroup for ROS helpers
local grp = vim.api.nvim_create_augroup("ros-builder", { clear = true })

-- Map of active autorun autocmds
local active_autoruns = {}

local builders = require("ros-builder.builders")

local test_name_candidate = function(bufno)
  if not (vim.bo[bufno].filetype == "cpp") then
    return nil
  end
  local fname_parts = vim.split(vim.api.nvim_buf_get_name(bufno), Path.path.sep)
  local file = fname_parts[#fname_parts]
  if vim.tbl_contains(fname_parts, "test") or vim.tbl_contains(fname_parts, "tests") then
    return vim.split(file, ".cpp")[1]
  end
end

local M = {}

M.guess_build_system = function()
  if vim.fn.executable("ros2") == 1 then
    return "colcon"
  else
    return "catkin"
  end
end

M.pkg_name = function(name)
  local abs_path = Path:new(name):absolute()
  local n = ros_pattern(abs_path)
  if not n then
    return nil
  end
  local parts = vim.split(n, Path.path.sep)
  return n, parts[#parts]
end

local function setup_test(bufno, pkg_name)
  local ws = M._workspace
  if not ws then
    return
  end

  local test_name = test_name_candidate(bufno)
  if not test_name then
    -- just run test for the whole package
    vim.keymap.set("n", M._keybinds.test, function()
      M.test_package(pkg_name)
    end, { buffer = bufno })
    return
  end


  local find_test = function(entry)
    return string.find(entry, test_name .. "$")
  end

  local test_exe = nil
  if vim.bo.filetype == "cpp" then
    vim.b[bufno].ros_builder_test_name = test_name
    if M._opts.build_system == "colcon" then
      local build_dir = table.concat{ ws, "/build/", pkg_name, }
      vim.b[bufno].ros_builder_build_dir = build_dir
      test_exe = scan.scan_dir(build_dir, {search_pattern = find_test})[1] or table.concat{build_dir, "/", test_name}
      vim.b[bufno].ros_builder_test_executable = test_exe
    else
      local build_dir = table.concat{ ws, "/devel/.private/", pkg_name, }
      vim.b[bufno].ros_builder_build_dir = build_dir
      test_exe = table.concat{build_dir, "/lib/", pkg_name, "/", test_name}
      vim.b[bufno].ros_builder_test_executable = test_exe
    end
  end

  if not M._opts.run_test then
    -- this will make the build system skip running the test
    test_exe = nil
  end

  vim.keymap.set("n", M._keybinds.test,
    function()
      M.build_package(pkg_name, test_name, test_exe)
    end,
    { buffer = bufno }
  )
  vim.api.nvim_create_user_command("RosAutoRunTest", M.activate_autorun_test, {})
  vim.api.nvim_create_user_command("RosStopAutoRunTest", M.deactivate_autorun, {})
end

-- path and name of ros package of current buffer
M.buf_ros_info = function()
  local fname = vim.api.nvim_buf_get_name(0)
  if not fname then
    return nil
  end
  return M.pkg_name(fname)
end

M.setup_ros_builder = function()
  local bufno = vim.api.nvim_get_current_buf()
  if vim.b[bufno].ros_builder_package_name then
    return
  end
  local fname = vim.api.nvim_buf_get_name(bufno)
  if not fname then
    return
  end
  local p, pkg = M.pkg_name(fname)
  if not pkg then
    return
  end
  vim.b[bufno].ros_builder_package_name = pkg
  vim.b[bufno].ros_builder_package_path = p
  vim.keymap.set("n", M._keybinds.build, function()
    M.build_package(pkg)
  end,
  {
    buffer = bufno
  })
  setup_test(bufno, pkg)
end

M.activate_autorun_test = function()
  local curr_buf = vim.api.nvim_get_current_buf()
  if active_autoruns[curr_buf] then
    vim.notify("Already active!", vim.log.levels.INFO)
    return
  end
  local pkg = vim.b[curr_buf].ros_builder_package_name
  if not pkg then
    vim.notify("Not part of a ROS package as far as we can tell", vim.log.levels.INFO)
    return
  end
  active_autoruns[curr_buf] = vim.api.nvim_create_autocmd({"BufWrite"}, {
      buffer = curr_buf,
      callback = function()
        M.build_package(vim.b[curr_buf].ros_builder_package_name, vim.b[curr_buf].ros_builder_test_name, vim.b[curr_buf].ros_builder_test_executable)
      end,
      group = grp,
      desc = "Run ros test on write"
  })
end

M.deactivate_autorun = function()
  local curr_buf = vim.api.nvim_get_current_buf()
  local ar = active_autoruns[curr_buf]
  if ar then
    vim.api.nvim_del_autocmd(ar)
    active_autoruns[curr_buf] = nil
  end
end

local prepare_and_check_build = function()
  if not M._workspace then
    vim.notify("'workspace' option must be set!", vim.log.levels.ERROR)
    return false
  end
  if M._opts.write_before_build then
    vim.cmd.write()
  end
  return true
end

-- Build given package
-- If test_name is non-nil, only builds that test
-- If test_exe is set, also run the given executable afterwards
M.build_package = function(pkg, test_name, test_exe)
  if not prepare_and_check_build() then
    return
  end
  local bs = builders.systems[M._opts.build_system]
  M._opts.launcher(bs.build(M._workspace, bs.opts, pkg, test_name, test_exe), M._workspace)
end

M.test_package = function(pkg)
  if not prepare_and_check_build() then
    return
  end
  local bs = builders.systems[M._opts.build_system]
  M._opts.launcher(bs.test(M._workspace, bs.opts, pkg), M._workspace)
end

M._opts = {
  build_system = M.guess_build_system(),
  write_before_build = true, -- Whether to write current file before building
  run_test = true, -- Whether to run tests after building them
  launcher = require("ros-builder.launchers").cmd,
}

M._workspace = nil
M._keybinds = {
  build = "<leader>b",
  test = "<leader>bt",
}

M.setup = function(opts)
  opts = opts or {}
  M._workspace = opts.workspace
  M._opts = vim.tbl_deep_extend("force", M._opts, opts.options or {})
  M._keybinds = vim.tbl_deep_extend("force", M._keybinds, opts.keys or {})
  builders.setup(opts.systems)

  if not M._workspace then
    -- vim.notify("Skipping ros autocommand hooks as workspace is not set.", vim.log.levels.DEBUG)
    return
  end

  vim.api.nvim_create_autocmd({"BufEnter"}, {
      pattern = "*",
      callback = M.setup_ros_builder,
      group = grp,
      desc = "Configures ROS specific bindings and commands for files"
  })
end

return M
