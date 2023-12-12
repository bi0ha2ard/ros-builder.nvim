# ROS Builder

Build and test your ROS1 and ROS2 packages with catkin or colcon!

## Features

- Build current ROS package
- Build and run tests for current package
- Build and run current unit test
- Rebuild and run test on write
- Optionally uses [asyncrun](https://github.com/skywind3000/asyncrun.vim) to run builds

## Installation

> NOTE: Requires neovim v0.9 or newer with `vim.fs` support!

Installation with [lazy.nvim](https://github.com/folke/lazy.nvim), include the following spec:

```lua
{
  "bi0ha2ard/ros-builder.nvim",
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- Optional, to use asyncrun as the launcher
    'skywind3000/asyncrun.vim',
  },
  opts = {}
},
```

Installation with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
return require('packer').startup(function(use)
  use 'nvim-lua/plenary.nvim'

  use {"/home/felix/git/ros-builder.nvim",
    config = [[require("ros-builder").setup()]]
  }

  -- Optional, to use asyncrun as the launcher
  use 'skywind3000/asyncrun.vim'
end
```

## Usage

### Building

Default mapping: `<leader>b`

Builds current package and dependencies.

### Testing

Default mapping: `<leader>bt`

This builds the package without its dependencies (for less latency) and then does one of the following:

- In a unit test file (a `cpp` file in a `/test` or `/tests` folder): Builds the unit test that corresponds to the file and runs it, if it can guess the test name.
- In any other file, use the build system to run all tests for the package.

In test files, you can use `:RosAutoRunTest` to set up an autocommand to rebuild and run the test on each file write.
Use `:RosStopAutoRunTest` to disable it again.

## Configuration

### Build system and workspace root

The plugin tries to detect where the workspace root is and which build system to use.
If `ros2` is executable, it defaults to `colcon`, otherwise it selects `catkin`.
If `ros2` and `ninja` are available, the `colcon_ninja` builder is selected.
The workspace root is detected by the presence of a `.catkin_tools` folder or a `.built_by` file.

You can also overwrite these by passing them to the `setup()` function:

```lua
require("ros-builder").setup({
    options = {
        workspace = "/some/path/my_workspace",
        build_system = "colcon",
        write_before_build = true, -- Whether to write current file before building
        run_test = true, -- Whether to run tests after building them
    }
})

```

### Changing the mappings

Pass a `keys` table to the setup function:

```lua
require("ros-builder").setup({
    keys = {
      build = "<leader>b",
      test = "<leader>bt",
    }
})
```

### Changing build system flags

Pass tables with options for the specific build system, for example:

```lua
require("ros-builder").setup({
    systems = {
      colcon_ninja = {
        opts = {
          cmake_args = {"-DCMAKE_CXX_FLAGS=-ggdb"},
          mixins = {"compile-commands", "ccache"},
          build = { "--symlink-install" },
        },
      },
      colcon = {
        opts = {
          cmake_args = {"-DCMAKE_CXX_FLAGS=-ggdb"},
          mixins = {"compile-commands", "ccache"},
          build = { "--symlink-install" },
        },
      },
      catkin = {
        opts = {
          build = { "-j12", "--no-notify" },
        },
      }
    }
})
```

### Launcher

The launcher will use a split terminal from asyncrun if that's installed.
Otherwise, it uses the builtin terminal.

You can pass your own function accepting a command to run and a working directory:

```lua
require("ros-builder").setup({
    options = {
        launcher = function(command, cwd)
          vim.cmd.terminal("cd " .. cwd .. " && " .. command)
        end
    }
})
```

Run with asyncrun in quickfix instead of the terminal:

```lua
local launcher = require('ros-builder.launchers').asyncrun_qf
require("ros-builder").setup({
    options = {
        launcher = launcher,
    }
})
```
