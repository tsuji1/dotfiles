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
				vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous symbol" })
				vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol" })
			end,
		})
		-- F4キーでアウトラインの表示/非表示を切り替える
		vim.keymap.set("n", "<F4>", "<cmd>AerialToggle!<CR>", { desc = "Toggle Aerial outline" })
	end,
}
