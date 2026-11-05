return {
	"L3MON4D3/LuaSnip",
	-- nvim-cmp の依存として InsertEnter 時に読み込まれる
	lazy = true,
	build = "make install_jsregexp",
	config = function()
		local vs = require("luasnip.loaders.from_vscode")
		vs.lazy_load()
		vs.lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	end,
}
