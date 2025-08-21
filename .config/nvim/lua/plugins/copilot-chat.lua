return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {
			-- === 基本設定 ===
			model = "gpt-4o", -- 必要なら指定
			temperature = 0.1,
			auto_insert_mode = true,
			window = {
				layout = "vertical",
				width = 0.5,
			},

			-- === 既存プロンプトを日本語で上書き（selection は後で注入）===
			prompts = {
				Explain = {
					prompt = "このコードの動作を日本語で詳しく説明してください。すべて日本語で回答してください。",
					system_prompt = "あなたは日本語で専門的かつ分かりやすくコードを説明するアシスタントです。箇条書きを活用してください。",
				},
				Refactor = {
					prompt = "選択したコードを読みやすくリファクタリングしてください。必要に応じて日本語コメントを追加してください。",
					system_prompt = "可読性向上を最優先し、日本語コメントは簡潔に付けてください。",
				},
				EnglishToJapanese = {
					prompt = "選択した英語文字列を日本語に翻訳してください。",
					system_prompt = "選択した英語文字列を日本語に翻訳してください。",
					mapping = "<Space>gT",
				},
			},
		},
		-- ここで require する：プラグイン読込後に確実に解決される
		config = function(_, opts)
			local select = require("CopilotChat.select")
			-- 既存キーを“上書き”する形で selection を注入
			if opts.prompts and opts.prompts.Explain then
				opts.prompts.Explain.selection = select.visual
			end
			if opts.prompts and opts.prompts.Refactor then
				opts.prompts.Refactor.selection = select.visual
			end
			if opts.prompts and opts.prompts.EnglishToJapanese then
				opts.prompts.EnglishToJapanese.selection = select.visual
			end

			require("CopilotChat").setup(opts)
		end,
	},
}
