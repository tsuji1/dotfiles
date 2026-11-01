return {
	-- 保存時に自動整形
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			-- 保存時に走る。下に書いていない filetype (json / yaml など) は LSP で整形する
			-- ツール本体は mise (~/.config/mise/config.toml) で入れる
			format_on_save = { lsp_format = "fallback", timeout_ms = 1000 },
			notify_on_error = true,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format" },
				go = { "goimports", "gofumpt" },
				rust = { "rustfmt" }, -- rustup に同梱
			},
		},
	},
}
