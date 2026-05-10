# Objective
Replace the `oil.nvim` file explorer with `neo-tree.nvim` to provide a persistent, VSCode-like sidebar file tree in the Neovim configuration (`init.lua`).

# Key Files & Context
- `/home/co5mo/.config/nvim/init.lua`

# Implementation Steps
1. Remove the previously added `oil.nvim` plugin definition from `require("lazy").setup` in `init.lua`.
2. Add the `neo-tree.nvim` plugin definition in its place.
3. Configure `neo-tree` to show hidden files (so it matches the behavior we wanted with `oil`), follow the current file, and auto-close if it's the last window open.
4. Set up convenient keymaps. We'll map `-` to toggle the Neo-tree sidebar, and `\` to reveal the current file in the tree.

The `neo-tree` configuration snippet to replace `oil.nvim`:
```lua
    -- File Explorer: Neo-tree
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                filesystem = {
                    filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                    },
                    follow_current_file = {
                        enabled = true,
                    },
                },
            })

            vim.keymap.set("n", "\\", "<Cmd>Neotree reveal<CR>", { desc = "Reveal file in Neo-tree" })
            vim.keymap.set("n", "-", "<Cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
        end,
    },
```

# Verification & Testing
1. Restart Neovim.
2. Verify that `lazy.nvim` cleans up `oil.nvim` and installs `neo-tree.nvim` successfully.
3. Press `-` to toggle the sidebar file explorer.
4. Open a file and press `\` to ensure the file tree reveals and highlights the correct file in the sidebar.
