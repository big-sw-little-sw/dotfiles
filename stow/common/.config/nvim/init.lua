-- Managed by GNU Stow — edit in dotfiles/stow/common/.config/nvim/init.lua

-- ── Options ──────────────────────────────────────────────────
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 4
vim.opt.tabstop        = 4
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.cursorline     = true
vim.opt.termguicolors  = true
vim.opt.signcolumn     = "yes"
vim.opt.undofile       = true
vim.opt.scrolloff      = 8
vim.opt.splitright     = true
vim.opt.splitbelow     = true

-- ── Leader key ───────────────────────────────────────────────
vim.g.mapleader = " "

-- ── Key maps ─────────────────────────────────────────────────
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>",  { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>",   { desc = "Quit" })
map("n", "<Esc>",     "<cmd>nohlsearch<cr>")

-- Move selected lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
