-- Neovim configuration
-- Transformed from vim/.vimrc

-- ============================================================
-- Options
-- ============================================================

vim.opt.hidden = true           -- switch buffers without saving
vim.opt.wildmenu = true         -- better command-line completion
vim.opt.showcmd = true          -- show partial commands in status line
vim.opt.hlsearch = true         -- highlight searches
vim.opt.ignorecase = true       -- case-insensitive search...
vim.opt.smartcase = true        -- ...unless capital letters used
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.autoindent = true
vim.opt.startofline = false     -- don't jump to line start on movement
vim.opt.ruler = true            -- show cursor position
vim.opt.laststatus = 2          -- always show status line
vim.opt.confirm = true          -- ask to save instead of failing
vim.opt.visualbell = true       -- visual bell instead of beep
vim.opt.mouse = ''              -- disable mouse
vim.opt.cmdheight = 2           -- avoid "press enter" prompts
vim.opt.relativenumber = true   -- relative line numbers
vim.opt.timeout = false         -- never time out on mappings
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 200
vim.opt.splitbelow = true       -- new splits open below

-- Indentation: 4 spaces
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- ============================================================
-- Mappings
-- ============================================================

-- Y yanks to end of line (like D and C)
vim.keymap.set({ 'n', 'v' }, 'Y', 'y$')

-- <C-L> clears search highlight
vim.keymap.set('n', '<C-L>', ':nohl<CR><C-L>', { noremap = true })

-- Enforce vim navigation habits
vim.keymap.set('n', '<Left>',  ':echoe "Use h"<CR>',  { noremap = true })
vim.keymap.set('n', '<Down>',  ':echoe "Use j"<CR>',  { noremap = true })
vim.keymap.set('n', '<Up>',    ':echoe "Use k"<CR>',  { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>',  { noremap = true })

-- ============================================================
-- Folds: save and restore view on buffer leave/enter
-- ============================================================

vim.api.nvim_create_autocmd('BufWinLeave', {
  pattern = '?*',
  command = 'mkview',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = '?*',
  command = 'silent! loadview',
})

-- ============================================================
-- Plugin manager: lazy.nvim
-- Bootstrap: auto-installs on first run
-- ============================================================

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- VS Code dark theme (same as vimrc codedark)
  {
    'tomasiser/vim-code-dark',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('codedark')
    end,
  },

  -- CoC for LSP completion (same as vimrc)
  -- After install run: :CocInstall coc-rust-analyzer
  {
    'neoclide/coc.nvim',
    branch = 'release',
  },
})
