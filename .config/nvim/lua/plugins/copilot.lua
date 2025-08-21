return {
	{
		"zbirenbaum/copilot.lua",
		cmd = { "Copilot" },
		event = { "InsertEnter" },
		opts = {
			-- copilot-cmp と一緒に使う場合は copilot.lua の UI を無効にする
			suggestion = {
				enabled = false,
			},
			panel = {
				enabled = false,
			},
		},
	},
}
