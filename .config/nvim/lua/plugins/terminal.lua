return {
	"akinsho/toggleterm.nvim",
	version = "*", -- 安定版 (任意でタグ指定もOK)
	config = function()
		require("toggleterm").setup({
			size = 50,
			open_mapping = [[<C-\>]], -- デフォルトのトグルキー
			shade_terminals = true,
			direction = "vertical", -- "vertical" | "float" も可
			start_in_insert = true,
			persist_size = true,
		})

		-- 🔑 terminal 用キーマップ
		function _G.set_terminal_keymaps()
			local opts = { buffer = 0 }
			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
			vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
			vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
			vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
			vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
		end

		-- toggleterm が開いたときだけ適用
		vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
	end,
}
