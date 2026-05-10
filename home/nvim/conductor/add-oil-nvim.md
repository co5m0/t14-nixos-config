# Objective
Add and configure the `oil.nvim` plugin in the Neovim configuration (`init.lua`) using the `lazy.nvim` plugin manager. The keymap to open Oil should open the git root if the current file is in a git repository, otherwise it should open the parent directory.

# Key Files & Context
- `/home/co5mo/.config/nvim/init.lua`

# Implementation Steps
1. Add the `oil.nvim` plugin definition to the `require("lazy").setup` table in `init.lua`.
2. Configure basic settings for `oil.nvim`, ensuring it loads `nvim-web-devicons` as a dependency.
3. Add a keymap (e.g., `-`) with a custom function that uses `vim.fs.root(0, ".git")` to find the git root and opens it using `require("oil").open(git_root)`. If no git root is found, it falls back to `require("oil").open()`.

The configuration snippet to be added inside `lazy.setup({ ... })`:
```lua
    -- File Explorer: Oil.nvim
    {
        "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("oil").setup({
                default_file_explorer = true,
                columns = {
                    "icon",
                },
                view_options = {
                    show_hidden = true,
                },
            })
            
            vim.keymap.set("n", "-", function()
                local git_root = vim.fs.root(0, ".git")
                if git_root then
                    require("oil").open(git_root)
                else
                    require("oil").open()
                end
            end, { desc = "Open Oil at Git Root or parent directory" })
        end,
    },
```

# Verification & Testing
1. Restart Neovim.
2. Verify that `lazy.nvim` installs `oil.nvim` successfully.
3. Open a file inside a git repository and press `-`. Verify that Oil opens at the root of the git repository.
4. Open a file outside of a git repository and press `-`. Verify that Oil opens at the parent directory of the current file.
5. Verify that hidden files are shown and icons are displayed correctly.
