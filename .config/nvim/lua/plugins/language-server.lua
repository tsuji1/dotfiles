return {
	{
		"neovim/nvim-lspconfig",
		-- ファイルを開いたときに読み込む（起動直後には読まない）
		event = { "BufReadPre", "BufNewFile" },
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
			-- NOTE: Windows では vim.fn.executable / exepath が 1 回 50〜70ms かかる。
			-- そのため起動時には一切呼ばず、各サーバの filetype を初めて開いたときに
			-- 1 回だけ実行ファイルを探し、見つかったら enable する。
			-- さらに cmd[1] を絶対パスに置き換えておくことで、バッファを開くたびに
			-- Neovim 内部で走る executable() チェック（PATH 走査）も速くなる。
			local function enable_on_ft(name, fts)
				vim.api.nvim_create_autocmd("FileType", {
					pattern = fts,
					once = true,
					callback = function(args)
						local cfg = vim.lsp.config[name]
						local cmd = cfg and cfg.cmd
						if type(cmd) ~= "table" or not cmd[1] then
							return
						end
						local path = vim.fn.exepath(cmd[1])
						if path == "" then
							return -- 入っていなければ何もしない
						end
						local new_cmd = vim.deepcopy(cmd)
						new_cmd[1] = path
						vim.lsp.config(name, { cmd = new_cmd })
						vim.lsp.enable(name)
						-- 起動中(VimEnter 前)の enable は既存バッファに適用されないので、
						-- いま開いているバッファに対して明示的に起動させる
						if vim.v.vim_did_enter == 0 then
							vim.api.nvim_exec_autocmds("FileType", { group = "nvim.lsp.enable", buffer = args.buf })
						end
					end,
				})
			end

			-- Go (gopls)
			vim.lsp.config("gopls", {
				cmd = { "gopls" }, -- mise で入れる
				settings = {
					gopls = {
						-- よく使う推奨設定
						staticcheck = true, -- 静的解析を有効化
						gofumpt = true, -- gofumpt で整形
						usePlaceholders = true, -- 補完のプレースホルダ
						hints = { -- inlay hints（必要なら）
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
						analyses = { -- 有効にする解析
							unusedparams = true,
							unusedwrite = true,
							shadow = true,
							nilness = true,
							deprecation = true,
						},
					},
				},
			})
			enable_on_ft("gopls", { "go", "gomod", "gowork", "gotmpl" })

			-- Python (pylsp) — Lintは不要ならプラグインを切る
			vim.lsp.config("pylsp", {
				cmd = { "pylsp" },
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
			enable_on_ft("pylsp", { "python" })

			-- Lua
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})
			enable_on_ft("lua_ls", { "lua" })

			-- YAML
			vim.lsp.config("yamlls", {
				settings = { yaml = { keyOrdering = false } },
			})
			enable_on_ft("yamlls", { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" })

			-- JSON（vscode-langservers-extracted）
			vim.lsp.config("jsonls", {})
			enable_on_ft("jsonls", { "json", "jsonc" })

			-- JavaScript / TypeScript (typescript-language-server)
			vim.lsp.config("ts_ls", {})
			enable_on_ft("ts_ls", { "javascript", "javascriptreact", "typescript", "typescriptreact" })

			-- Bash
			vim.lsp.config("bashls", {})
			enable_on_ft("bashls", { "sh", "bash" })

			-- Nix (nil)
			vim.lsp.config("nil_ls", {
				-- lspconfig が filetype や root dir を自動で設定してくれるので
				-- 基本的に {} だけで OK です
			})
			enable_on_ft("nil_ls", { "nix" })

			-- C / C++ 用 (clangd)
			vim.lsp.config("clangd", {
				-- 必要ならここに設定を書く
				cmd = { "clangd" },
				filetypes = { "c", "C", "cpp", "objc", "objcpp" },
			})
			enable_on_ft("clangd", { "c", "C", "cpp", "objc", "objcpp" })
		end,
	},
}
