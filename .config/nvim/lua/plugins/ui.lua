return {
	-- {
	--   "rebelot/kanagawa.nvim",
	--   lazy = false, priority = 1000,
	--   opts = {
	--     theme = "lotus",               -- "wave"|"dragon"|"lotus"
	--     transparent = true,
	--     dimInactive = true,
	--     overrides = function(colors)
	--       return {
	--         -- 透過維持
	--         Normal       = { bg = "NONE" },
	--         NormalFloat  = { bg = "NONE" },
	--         FloatBorder  = { bg = "NONE" },
	--         -- 暖色寄りで落ち着いた配色
	--         ["@keyword"]   = { fg = colors.palette.sakuraPink, italic = false },
	--         ["@function"]  = { fg = colors.palette.autumnYellow },
	--         ["@string"]    = { fg = colors.palette.surimiOrange },
	--         ["@comment"]   = { fg = colors.palette.fujiGray, italic = false },
	--       }
	--     end,
	--   },
	--   config = function(_, opts)
	--     require("kanagawa").setup(opts)
	--     vim.cmd.colorscheme("kanagawa-wave")
	--   end,
	-- },

	-- {
	--   "nyoom-engineering/oxocarbon.nvim",
	--   lazy = false, priority = 1000,
	--   config = function()
	--     vim.opt.termguicolors = true
	--     vim.cmd.colorscheme("oxocarbon")
	--     for _, g in ipairs({"Normal","NormalFloat","FloatBorder"}) do
	--       vim.api.nvim_set_hl(0, g, { bg = "NONE" })
	--     end
	--   end,
	-- },

	-- {
	--   "sainnhe/everforest",
	--   lazy = false, priority = 1000,
	--   config = function()
	--     vim.g.everforest_transparent_background = 1
	--     vim.g.everforest_better_performance = 1
	--     vim.cmd.colorscheme("everforest")
	--   end,
	-- },

	-- テーマ本体
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "storm", -- "storm"|"night"|"moon"|"day"
			transparent = true, --
			styles = { sidebars = "transparent", floats = "transparent" },
		},
		config = function(_, opts)
			vim.opt.termguicolors = true
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")

			-- 透過が崩れるのを防ぐ（色変えのたび適用）
			local function clear_bg()
				for _, grp in ipairs({
					"Normal",
					"NormalNC",
					"NormalFloat",
					"FloatBorder",
					"SignColumn",
					"StatusLine",
					"StatusLineNC",
					"TabLineFill",
					"TelescopeNormal",
					"TelescopeBorder",
				}) do
					vim.api.nvim_set_hl(0, grp, { bg = "NONE" })
				end
				vim.o.winblend = 10 -- 浮動ウィンドウのブレンド
				vim.o.pumblend = 10 -- 補完メニューのブレンド
			end
			clear_bg()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_bg })
		end,
	},

	-- ステータスライン（テーマ揃える）
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "auto",
				globalstatus = true,
				section_separators = "",
				component_separators = "",
			},
		},
	},

	-- タブ/バッファをリッチに
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = { options = { separator_style = "slant", diagnostics = "nvim_lsp" } },
	},

	-- インデントガイド（細く上品に）
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = { indent = { char = "│" }, scope = { enabled = false } },
	},

	-- シンタックスはっきり（色が映える）
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			highlight = { enable = true },
			ensure_installed = { "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
		},
	},
}
