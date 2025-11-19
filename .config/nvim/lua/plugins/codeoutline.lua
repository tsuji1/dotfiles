return -- lazy.nvim を使ったインストール例
{
	"stevearc/aerial.nvim",
	opts = {},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("aerial").setup({
			-- ここで細かい設定ができますが、デフォルトでも十分使えます
			on_attach = function(bufnr)
				-- ジャンプ用のキーマップなどを設定
    vim.keymap.set("n", "<leader>aj", require("aerial").next)
    vim.keymap.set("n", "<leader>ak", require("aerial").prev)
			end,
		})
		-- F4キーでアウトラインの表示/非表示を切り替える
    vim.keymap.set("n", "<leader>ao", "<cmd>AerialToggle!<cr>")
		vim.keymap.set("n", "<F4>", "<cmd>AerialToggle!<CR>", { desc = "Toggle Aerial outline" })
	end,
}
