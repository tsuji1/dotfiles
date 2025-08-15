-- lua/plugins/clipboard-osc52.local

return {
	{
		"ojroques/nvim-osc52",
		event = "VeryLazy",
		opts = { max_length = 0, silent = true, trim = false },

		config = function(_, opts)
			local ok, osc52 = pcall(require, "osc52")
			if not ok then
				return
			end
			osc52.setup(opts)

			-- 無名レジスタで yank したときだけローカルへ送る
			vim.api.nvim_create_autocmd("TextYankPost", {
				group = vim.api.nvim_create_augroup("YankToOSC52", { clear = true }),
				callback = function()
					if vim.v.event.operator == "y" and vim.v.event.regname == "" then
						osc52.copy_register('"')
					end
				end,
			})

			-- “システムクリップボード”連携は使わない（警告も抑止したいなら↓も）
			vim.opt.clipboard = ""
			vim.g.loaded_clipboard_provider = 1 -- 任意：:checkhealth の警告を消す
		end,
	},
}
