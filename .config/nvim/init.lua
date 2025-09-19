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
-- if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
-- 	vim.opt.clipboard = "" -- "+y でなく普通の y で送る構成
-- else
-- 	-- share clipboard with OS
-- 	vim.opt.clipboard:append("unnamedplus,unnamed")
-- end

-- InitLua
require("user_command")
require("config.lazy")

vim.keymap.set("i", "jk", "<Esc>", { noremap = true, desc = "Insertモードを抜ける" })

-- 分割
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "横分割" })
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "縦分割" })
vim.keymap.set("n", "<leader>sc", "<cmd>close<CR>", { desc = "ウィンドウ閉じる" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "サイズ均等" })

-- 移動
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- リサイズ（矢印キー派）
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>")
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>")
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -4<CR>")
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +4<CR>")

-- active/inactive window の背景を差別化
-- vim.api.nvim_set_hl(0, "Normal", { bg = "#1e1e2e" }) -- 非アクティブ
-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "#161622" }) -- アクティブ以外

vim.opt.laststatus = 2 -- 各分割にステータスライン

-- 反応速度
vim.o.updatetime = 250

vim.keymap.set("n", "<A-h>", "gT", { desc = "前のタブ" })
vim.keymap.set("n", "<A-l>", "gt", { desc = "次のタブ" })

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

-- vim.keymap.set("n", "gl", function()
-- 	vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
-- end, { desc = "Show diagnostic under cursor" })
--
-- vim.diagnostic.config({
-- 	virtual_text = false, -- 行内の文字は非表示
-- 	signs = {
-- 		text = {
-- 			[vim.diagnostic.severity.ERROR] = "E",
-- 			[vim.diagnostic.severity.WARN] = "W",
-- 			[vim.diagnostic.severity.INFO] = "I",
-- 			[vim.diagnostic.severity.HINT] = "H",
-- 		},
-- 		numhl = false, -- 番号欄のハイライト（お好み）
-- 	},
-- 	underline = true,
-- 	severity_sort = true,
-- })
