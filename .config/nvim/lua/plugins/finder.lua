return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		-- 例: 起動後しばらくして自動ロード（遅延は残す）
		event = "VeryLazy",

		config = function()
			local telescope = require("telescope")
			telescope.setup({})

			-- ここでなら OK（ロード済み）
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope: find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope: live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope: buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: help tags" })
			vim.keymap.set("n", "<leader>fp", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.getcwd(), -- プロジェクトルート
				})
			end, { desc = "Telescope: find files (cwd)" })
		end,
	},
}
