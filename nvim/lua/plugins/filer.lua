return {
  {
    "nvim-tree/nvim-tree.lua",
    event = "VeryLazy",

    config = function()
      local nvim_tree = require("nvim-tree")

      nvim_tree.setup({
        -- nvim-tree バッファに入った時だけ走る
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")

          -- nvim-tree が用意してるデフォルト mapping を先に適用
          api.config.mappings.default_on_attach(bufnr)

          -- ここから“追 加 / 上 書 き”はバッファローカルになる
          local function map_opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          vim.keymap.set("n", "<C-t>", api.tree.change_root_to_parent, map_opts("Up"))
          vim.keymap.set("n", "?",     api.tree.toggle_help,           map_opts("Help"))
        end,
      })

      -- これはグローバルでOK（トグル起動用）
      vim.keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    end,
  },
}

