# Objective
Refactor the git root detection logic into a shared local function in `init.lua` and update both the Neo-tree and Telescope configurations to use it, ensuring consistency and cleaner code.

# Key Files & Context
- `/home/co5mo/.config/nvim/init.lua`

# Implementation Steps
1. Define a local function `get_root` at a higher scope in `init.lua` (e.g., just before the `lazy.setup` block).
2. Update the **Neo-tree** configuration to remove its local `get_root` definition and use the shared one.
3. Update the **Telescope** configuration to use the shared `get_root` function for the `<C-F>` (live_grep) mapping.

# Proposed Code Changes

### 1. Define shared function (before `lazy.setup`)
```lua
local function get_root()
    return vim.fs.root(0, ".git") or vim.uv.cwd()
end
```

### 2. Update Neo-tree
```lua
            -- (Remove the local get_root definition)
            vim.keymap.set("n", "\\", function()
                vim.cmd("Neotree reveal dir=" .. get_root())
            end, { desc = "Reveal file in Neo-tree (Root)" })

            vim.keymap.set("n", "-", function()
                vim.cmd("Neotree toggle dir=" .. get_root())
            end, { desc = "Toggle Neo-tree (Root)" })
```

### 3. Update Telescope
```lua
            vim.keymap.set("n", "<C-F>", function()
                builtin.live_grep({ cwd = get_root() })
            end, { desc = "[S]earch Files (Root)" })
```

# Verification & Testing
1. Restart Neovim.
2. Test `-`: Verify Neo-tree opens at the git root (if applicable).
3. Test `<C-F>`: Verify Telescope searches from the git root (if applicable).
