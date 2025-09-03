return {
	-- Copilot 本体
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		build = ":Copilot auth", -- 初回は認可フロー
		opts = {
			suggestion = { enabled = false }, -- UIはcmpに統一
			panel = { enabled = false },
			-- 必要に応じて filetypes = { markdown = true, gitcommit = true } など
		},
	},

	-- Copilot を nvim-cmp の補完ソースに統合
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	-- メイン補完プラグイン
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		-- copilot-cmp を依存に入れておくと、cmp の setup より先に読み込まれる
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP 補完
			"hrsh7th/cmp-buffer", -- バッファ補完
			"hrsh7th/cmp-path", -- パス補完
			"hrsh7th/cmp-cmdline", -- コマンドライン補完
			"L3MON4D3/LuaSnip", -- スニペットエンジン
			"saadparwaiz1/cmp_luasnip", -- nvim-cmp と LuaSnip の連携
			"rafamadriz/friendly-snippets", -- 既成スニペット集
			"zbirenbaum/copilot-cmp", -- ★ 依存としても指定（読み込み順の安定化）
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- friendly-snippets 読み込み
			require("luasnip.loaders.from_vscode").lazy_load()

			-- Copilot を上位に並べたい場合の comparator（存在しない場合は無視）
			local has_copilot_cmp, copilot_cmp = pcall(require, "copilot_cmp.comparators")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- LSP/スニペットの展開
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- C-n でnextだけど開くことが可能

					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "copilot" }, -- Copilot を先頭で優先
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
					{ name = "path" },
				}),
				sorting = {
					priority_weight = 2,
					comparators = has_copilot_cmp
							and {
								copilot_cmp.prioritize, -- Copilot を上に
								cmp.config.compare.offset,
								cmp.config.compare.exact,
								cmp.config.compare.score,
								cmp.config.compare.kind,
								cmp.config.compare.sort_text,
								cmp.config.compare.length,
								cmp.config.compare.order,
							}
						or {
							cmp.config.compare.offset,
							cmp.config.compare.exact,
							cmp.config.compare.score,
							cmp.config.compare.kind,
							cmp.config.compare.sort_text,
							cmp.config.compare.length,
							cmp.config.compare.order,
						},
				},
			})

			-- 検索（/ ?）
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = { { name = "buffer" } },
			})

			-- コマンドライン (:)
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = { { name = "cmdline" } },
			})
		end,
	},
}
