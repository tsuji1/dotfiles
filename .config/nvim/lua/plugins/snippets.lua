return {
	"L3MON4D3/LuaSnip",
	build = "make install_jsregexp",
	config = function()
		local vs = require("luasnip.loaders.from_vscode")
		vs.lazy_load()
		vs.lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	end,
}
