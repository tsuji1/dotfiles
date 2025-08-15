return {
	-- 括弧/クオートの自動補完
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true, -- Treesitterと連携して誤補完を減らす
			enable_afterquote = true, -- " のあとに ) などをいい感じに
			fast_wrap = {}, -- M-e で括弧に素早く包む（必要なら）
		},
	},

	-- JSX/HTML の自動クローズ & リネーム
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		opts = {},
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}
