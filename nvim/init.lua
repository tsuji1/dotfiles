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

vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

-- share clipboard with OS 
vim.opt.clipboard:append('unnamedplus,unnamed')

-- InitLua
require('user_command')
require('config.lazy')



