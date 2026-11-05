return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		-- コマンドで初めて使うときに読み込む
		cmd = {
			"CopilotChat",
			"CopilotChatOpen",
			"CopilotChatClose",
			"CopilotChatToggle",
			"CopilotChatVsplitToggle",
			"CopilotChatBuffer",
			"CopilotChatInPlace",
			"CopilotChatVisual",
			"CopilotChatStop",
			"CopilotChatReset",
			"CopilotChatSave",
			"CopilotChatLoad",
			"CopilotChatPrompts",
			"CopilotChatModels",
			-- プロンプト由来のコマンド
			"CopilotChatExplain",
			"CopilotChatReview",
			"CopilotChatFix",
			"CopilotChatOptimize",
			"CopilotChatDocs",
			"CopilotChatTests",
			"CopilotChatCommit",
			"CopilotChatRefactor",
		},
		-- プロンプト選択（以前は opts 内にあって効いていなかったものを lazy の keys に移動。
		-- 旧 telescope 連携は廃止されたので組み込みの select_prompt を使う）
		keys = {
			{
				"<leader>gT",
				function()
					require("CopilotChat").select_prompt()
				end,
				mode = { "n", "v" },
				desc = "CopilotChat - Prompt actions",
			},
		},
		opts = {

			-- === 基本設定 ===
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
				-- EnglishToJapanese = {
				-- 	prompt = "選択した英語文字列を日本語に翻訳してください。",
				-- 	system_prompt = "選択した英語文字列を日本語に翻訳してください。",
				-- 	mapping = "kkk",
				-- },
			},
			mappings = {
				reset = {
					normal = "<M-l>",
					insert = "<M-l>",
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
