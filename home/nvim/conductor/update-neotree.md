# Objective
Modify the `neo-tree.nvim` configuration in `init.lua` to change the default keybindings for opening files in splits. The user requested mapping `v` for a vertical split (vsplit) and `x` for a horizontal split (split).

# Key Files & Context
- `/home/co5mo/.config/nvim/init.lua`

# Implementation Steps
1. Locate the `neo-tree.nvim` plugin configuration within the `require("lazy").setup` block in `init.lua`.
2. Add a `window` section to the `require("neo-tree").setup` block to override default mappings.
3. Inside the `window` section, add a `mappings` table with the following overrides:
    - `"v" = "open_vsplit"`
    - `"x" = "open_split"`
    - To prevent confusion with the default keys, explicitly set the old split keys (`s` and `S`) to `"none"`.

**Note:** By default, `neo-tree` uses `x` for `cut_to_clipboard`. Overriding `x` to `open_split` will remove this functionality unless remapped. We will assume the user prefers the split functionality over the default cut action and map `x` to `open_split` without remapping cut.

The configuration snippet to modify:
```lua
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
                window = {
                    mappings = {
                        ["v"] = "open_vsplit",
                        ["x"] = "open_split",
                        ["s"] = "none",
                        ["S"] = "none",
                    },
                },
            })

            vim.keymap.set("n", "\\", "<Cmd>Neotree reveal<CR>", { desc = "Reveal file in Neo-tree" })
            vim.keymap.set("n", "-", "<Cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
        end,
```

# Verification & Testing
1. Restart Neovim.
2. Open Neo-tree using `-`.
3. Select a file and press `v`. It should open the file in a vertical split.
4. Select a file and press `x`. It should open the file in a horizontal split.
5. Verify that pressing `s` or `S` does not perform any split actions.
