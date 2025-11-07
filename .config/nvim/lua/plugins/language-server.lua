return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			local caps = require("cmp_nvim_lsp").default_capabilities()

			-- 共通設定（全サーバ）
			vim.lsp.config("*", {
				capabilities = caps,
				on_attach = function(_, bufnr)
					local map = function(m, lhs, rhs, d)
						vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = d })
					end
					map("n", "gd", vim.lsp.buf.definition, "LSP: definition")
					map("n", "gD", vim.lsp.buf.declaration, "LSP: declaration")
					map("n", "gr", vim.lsp.buf.references, "LSP: references")
					map("n", "gi", vim.lsp.buf.implementation, "LSP: implementations")
					map("n", "gK", vim.lsp.buf.hover, "LSP: hover", { buffer = bufnr, silent = true })
					map("n", "<leader>lr", vim.lsp.buf.rename, "LSP: rename")
					map("n", "<leader>la", vim.lsp.buf.code_action, "LSP: code action")
					map("n", "<leader>lf", function()
						vim.lsp.buf.format({ async = true })
					end, "LSP: format")
				end,
				flags = { debounce_text_changes = 150 },
			})

			-- ↓ここから「入っていれば使う」個別設定 -----------------------
			local cmd = (function()
				local p = vim.fn.exepath("pylsp")
				return p ~= "" and { p } or { "pylsp" }
			end)()

			-- Python (pylsp) — Lintは不要ならプラグインを切る
			-- if vim.fn.executable("pylsp") == 1 then
			vim.lsp.config("pylsp", {
				cmd = cmd,
				settings = {
					pylsp = {
						plugins = {
							pyflakes = { enabled = false }, -- Wを出す系をOFF
							pycodestyle = { enabled = false },
							mccabe = { enabled = false },
						},
					},
				},
			})

			-- end

			-- Lua
			if vim.fn.executable("lua-language-server") == 1 then
				vim.lsp.config("lua_ls", {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
						},
					},
				})
			end

			-- YAML
			if vim.fn.executable("yaml-language-server") == 1 then
				vim.lsp.config("yamlls", {
					settings = { yaml = { keyOrdering = false } },
				})
			end

			-- JSON（vscode-langservers-extracted）
			if vim.fn.executable("vscode-json-language-server") == 1 then
				vim.lsp.config("jsonls", {})
			end

			-- Bash
			if vim.fn.executable("bash-language-server") == 1 then
				vim.lsp.config("bashls", {})
			end
			-- C / C++ 用 (clangd)
			if vim.fn.executable("clangd") == 1 then
				vim.lsp.config("clangd", {
					-- 必要ならここに設定を書く
					cmd = { "clangd" },
					filetypes = { "c", "C", "cpp", "objc", "objcpp" },
				})
				vim.lsp.enable("clangd")
			end
		end,
	},

	-- { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
}
