return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		-- キー/コマンドで初めて使うときに読み込む
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Telescope: find files" },
			{ "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Telescope: live grep" },
			{ "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Telescope: buffers" },
			{ "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Telescope: help tags" },
			{
				"<leader>fp",
				function()
					require("telescope.builtin").find_files({
						cwd = vim.fn.getcwd(), -- プロジェクトルート
					})
				end,
				desc = "Telescope: find files (cwd)",
			},
		},
		config = function()
			require("telescope").setup({})
		end,
	},
}
