return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	-- 起動時には読み込まず、コマンド/キーで初めて使うときに読み込む
	cmd = {
		"AerialToggle",
		"AerialOpen",
		"AerialOpenAll",
		"AerialClose",
		"AerialCloseAll",
		"AerialNext",
		"AerialPrev",
		"AerialGo",
		"AerialInfo",
		"AerialNavToggle",
		"AerialNavOpen",
		"AerialNavClose",
	},
	keys = {
		{ "<leader>ao", "<cmd>AerialToggle!<cr>", desc = "Toggle Aerial outline" },
		{ "<F4>", "<cmd>AerialToggle!<CR>", desc = "Toggle Aerial outline" },
		{ "<leader>aj", function() require("aerial").next() end, desc = "Aerial next" },
		{ "<leader>ak", function() require("aerial").prev() end, desc = "Aerial prev" },
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
	end,
}
