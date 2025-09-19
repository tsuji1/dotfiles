return {
	-- Mason 本体
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		opts = {
			ui = { border = "rounded" },
			PATH = "append",
		},
	},

	-- mason-lspconfig v2（0.11+ の新流儀）
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
		opts = {
			-- 必要なサーバを好きに追加
			ensure_installed = { "lua_ls", "yamlls", "jsonls", "bashls" },
			automatic_enable = true, -- ← v2 の新設定（既定で true）
		},
		config = function(_, opts)
			require("mason-lspconfig").setup(opts)

			local caps = require("cmp_nvim_lsp").default_capabilities()
			-- mason / mason-lspconfig はいつも通りでOK
			require("lspconfig").pylsp.setup({
				settings = {
					pylsp = {
						plugins = {
							pyflakes = { enabled = false }, -- ← これでOFF
						},
					},
				},
			})

			-- すべての LSP に共通設定（0.11+）
			vim.lsp.config("*", {
				capabilities = caps,
				on_attach = function(_, bufnr)
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = desc })
					end
					map("n", "gd", vim.lsp.buf.definition, "LSP: goto definition")
					map("n", "gD", vim.lsp.buf.declaration, "LSP: goto declaration")
					map("n", "gr", vim.lsp.buf.references, "LSP: references")
					map("n", "gi", vim.lsp.buf.implementation, "LSP: implementations")
					map("n", "K", vim.lsp.buf.hover, "LSP: hover")
					map("n", "<leader>lr", vim.lsp.buf.rename, "LSP: rename")
					map("n", "<leader>la", vim.lsp.buf.code_action, "LSP: code action")
					map("n", "<leader>lf", function()
						vim.lsp.buf.format({ async = true })
					end, "LSP: format")
				end,
				flags = { debounce_text_changes = 150 },
			})

			-- サーバ個別の上書き
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})

			vim.lsp.config("yamlls", {
				settings = { yaml = { keyOrdering = false } },
			})
		end,
	}, -- 3) 開発ツールの自動インストール（任意）
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- フォーマッタ/リンタなど（必要に応じて）
					"stylua",
					"prettierd",
					"shfmt",
				},
				run_on_start = true,
				start_delay = 100,
			})
		end,
	},
}
