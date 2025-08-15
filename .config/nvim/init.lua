-- カーソル
vim.opt.number = true
vim.opt.cursorline = true

-- Leaderキーをスペースに設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.opt.scrolloff = 3

vim.opt.whichwrap = "b,s,h,l,<,>,[,],~"

-- すでに set clipboard=unnamedplus しているなら、SSH のときだけ無効化
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
	vim.opt.clipboard = "" -- "+y でなく普通の y で送る構成
else
	-- share clipboard with OS
	vim.opt.clipboard:append("unnamedplus,unnamed")
end

-- InitLua
require("user_command")
require("config.lazy")

-- 反応速度
vim.o.updatetime = 250

-- カーソルを止めたら、その場所の警告理由をポップアップ
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	callback = function()
		vim.diagnostic.open_float(nil, {
			focus = false,
			scope = "cursor",
			source = "if_many",
			header = "",
			close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "FocusLost" },
		})
	end,
})

-- ← 以前入れていた「CursorMovedでvim.diagnostic.hide()」は削除！

vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
end, { desc = "Show diagnostic under cursor" })

vim.diagnostic.config({
	virtual_text = false, -- 行内の文字は非表示
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "E",
			[vim.diagnostic.severity.WARN] = "W",
			[vim.diagnostic.severity.INFO] = "I",
			[vim.diagnostic.severity.HINT] = "H",
		},
		numhl = false, -- 番号欄のハイライト（お好み）
	},
	underline = true,
	severity_sort = true,
})
