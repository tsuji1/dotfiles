-- カーソル
vim.opt.number = true
vim.opt.cursorline = true

-- Leaderキーをスペースに設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- これを書くと、Neovim内でのマウス操作で勝手にtmuxモードに入らなくなります
vim.opt.mouse = "a"

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

-- backup
do
	local backup_dir = vim.fn.expand("~/.vim/backup")
	vim.fn.mkdir(backup_dir, "p")

	vim.opt.backup = true
	vim.opt.writebackup = true
	-- // を付けると「ファイル名をフルパス風にして保存」できて衝突しにくい
	vim.opt.backupdir = backup_dir .. "//"
end

-- undo (persistent)
do
	local undo_dir = vim.fn.expand("~/.local/state/nvim/undo")
	vim.fn.mkdir(undo_dir, "p")

	vim.opt.undofile = true
	vim.opt.undodir = undo_dir .. "//"
end

-- InitLua
require("user_command")
require("config.lazy")

vim.keymap.set("i", "jk", "<Esc>", { noremap = true, desc = "Insertモードを抜ける" })

-- 分割
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "横分割" })
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "縦分割" })
vim.keymap.set("n", "<leader>sc", "<cmd>close<CR>", { desc = "ウィンドウ閉じる" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "サイズ均等" })

-- 例: init.lua / keymaps.lua
local opts = { silent = true }

vim.keymap.set("t", "<C-h>", [[<C-\><C-n>:TmuxNavigateLeft<CR>]], opts)
vim.keymap.set("t", "<C-j>", [[<C-\><C-n>:TmuxNavigateDown<CR>]], opts)
vim.keymap.set("t", "<C-k>", [[<C-\><C-n>:TmuxNavigateUp<CR>]], opts)
vim.keymap.set("t", "<C-l>", [[<C-\><C-n>:TmuxNavigateRight<CR>]], opts)
vim.keymap.set("t", "<C-\\>", [[<C-\><C-n>:TmuxNavigatePrevious<CR>]], opts)

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
