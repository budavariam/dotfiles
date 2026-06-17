-- Neovim configuration
-- Transformed from vim/.vimrc + Rust LSP + general tooling

-- ============================================================
-- Options
-- ============================================================

vim.g.mapleader = ' '                   -- Space as leader key

vim.opt.hidden = true                   -- switch buffers without saving
vim.opt.wildmenu = true                 -- better command-line completion
vim.opt.showcmd = true                  -- show partial commands in status line
vim.opt.hlsearch = true                 -- highlight searches
vim.opt.ignorecase = true               -- case-insensitive search...
vim.opt.smartcase = true                -- ...unless capital letters used
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.autoindent = true
vim.opt.startofline = false             -- don't jump to line start on movement
vim.opt.ruler = true                    -- show cursor position
vim.opt.laststatus = 2                  -- always show status line
vim.opt.confirm = true                  -- ask to save instead of failing
vim.opt.visualbell = true               -- visual bell instead of beep
vim.opt.mouse = ''                      -- disable mouse
vim.opt.cmdheight = 2                   -- avoid "press enter" prompts
vim.opt.number         = true
vim.opt.relativenumber = true
-- Show both columns: absolute (grey) on the left, relative on the right
-- v:lnum = absolute, v:relnum = relative distance (0 on current line)
vim.opt.statuscolumn = '%#LineNr#%5{v:lnum}%* %3{v:relnum} '
vim.opt.timeout = false                 -- never time out on mappings
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 200
vim.opt.splitbelow = true               -- new splits open below
vim.opt.splitright = true               -- new vertical splits open right
vim.opt.signcolumn = 'yes'             -- always show sign column (no layout shifts)
vim.opt.updatetime = 250               -- faster sign/diagnostic updates
vim.opt.termguicolors = true           -- true color support
vim.opt.cursorline    = true           -- highlight current line so cursor is always visible

-- insert cursor: keep default thin bar and white color
vim.opt.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50'

-- show whitespace like vscode does (dots for spaces, arrow for tabs)
vim.opt.list = true
vim.opt.listchars = { space = '·', tab = '→ ', trail = '·' }

-- strip leading colon when pasting vim commands copied from docs (e.g. :w → w)
vim.api.nvim_create_autocmd('CmdlineChanged', {
  callback = function()
    local line = vim.fn.getcmdline()
    if line:match('^%s*:') then
      vim.fn.setcmdline((line:gsub('^%s*:', '')))
    end
  end,
})

-- trim trailing whitespace on save, keep cursor position
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('%s/\\s\\+$//e')
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- Line number colors: grey for both absolute (current line) and relative numbers
-- Applied in an autocmd so they survive colorscheme changes
local function set_linenr_colors()
  vim.api.nvim_set_hl(0, 'LineNr',       { fg = '#555555' }) -- relative nums: dark grey
  vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#888888', bold = true }) -- absolute: lighter grey
end
set_linenr_colors()
vim.api.nvim_create_autocmd('ColorScheme', { callback = set_linenr_colors })

-- Indentation: 4 spaces
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- ============================================================
-- General Mappings
-- Keymap groups (shown by which-key):
--   <leader>f  = Find (telescope)
--   <leader>b  = Buffer
--   <leader>g  = Git (gitsigns)
--   <leader>l  = LSP actions
--   <leader>d  = Diagnostics
--   <leader>e  = Explorer (file tree)
--   <leader>w  = Write / save
--   <leader>q  = Quit
-- ============================================================

-- Y yanks to end of line (like D and C)
vim.keymap.set({ 'n', 'v' }, 'Y', 'y$')

-- <C-L> clears search highlight
vim.keymap.set('n', '<C-L>', ':nohl<CR><C-L>', { noremap = true })

-- Enforce vim navigation habits
vim.keymap.set('n', '<Left>',  ':echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('n', '<Down>',  ':echoe "Use j"<CR>', { noremap = true })
vim.keymap.set('n', '<Up>',    ':echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>', { noremap = true })

-- Quick save / quit
vim.keymap.set('n', '<leader>w', ':w<CR>',  { noremap = true, silent = true, desc = 'Save file' })
vim.keymap.set('n', '<leader>q', ':q<CR>',  { noremap = true, silent = true, desc = 'Quit' })

-- Buffer navigation
vim.keymap.set('n', '<leader>bn', ':bnext<CR>',     { noremap = true, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', ':bprevious<CR>', { noremap = true, silent = true, desc = 'Prev buffer' })
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>',   { noremap = true, silent = true, desc = 'Delete buffer' })

-- ============================================================
-- LSP Keymaps (attached per-buffer on LspAttach)
-- ============================================================

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf
    local opts  = { buffer = bufnr, silent = true }
    local function o(desc) return vim.tbl_extend('force', opts, { desc = desc }) end

    -- Navigation
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition,      o('Go to definition'))
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration,     o('Go to declaration'))
    vim.keymap.set('n', 'gr', vim.lsp.buf.references,      o('References'))
    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, o('Type definition'))
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation,  o('Implementation'))
    vim.keymap.set('n', 'K',  vim.lsp.buf.hover,           o('Hover docs'))

    -- LSP actions  (<leader>l*)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,      o('Code action'))
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,           o('Rename symbol'))
    vim.keymap.set('n', '<leader>cw', vim.lsp.buf.workspace_symbol, o('Workspace symbols'))
    vim.keymap.set('n', '<leader>lf', function()                    -- NOTE: <leader>f* is for telescope
      vim.lsp.buf.format({ async = true })
    end, o('Format buffer'))

    -- Diagnostics  (<leader>d*)
    vim.keymap.set('n', '[d',        vim.diagnostic.goto_prev,   o('Prev diagnostic'))
    vim.keymap.set('n', ']d',        vim.diagnostic.goto_next,   o('Next diagnostic'))
    vim.keymap.set('n', '<leader>de', vim.diagnostic.open_float,  o('Show diagnostic'))
    vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist,  o('Diagnostic list'))

    -- Inlay hints (type annotations, parameter names)
    if vim.lsp.inlay_hint then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      vim.keymap.set('n', '<leader>dh', function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
          { bufnr = bufnr }
        )
      end, o('Toggle inlay hints'))
    end
  end,
})

-- ============================================================
-- Diagnostics display
-- ============================================================

vim.diagnostic.config({
  virtual_text    = true,
  signs           = true,
  underline       = true,
  update_in_insert = false,
  severity_sort   = true,
})

local diagnostics_visible = true
vim.keymap.set('n', '<leader>dt', function()
  diagnostics_visible = not diagnostics_visible
  vim.diagnostic.config({
    virtual_text = diagnostics_visible,
    signs        = diagnostics_visible,
    underline    = diagnostics_visible,
  })
end, { desc = 'Toggle diagnostics' })

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
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({

  -- ----------------------------------------------------------
  -- Colorscheme: VS Code dark
  -- ----------------------------------------------------------
  {
    'tomasiser/vim-code-dark',
    lazy     = false,
    priority = 1000,
    config   = function() vim.cmd.colorscheme('codedark') end,
  },

  -- ----------------------------------------------------------
  -- Status line
  -- ----------------------------------------------------------
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'codedark',
          component_separators = '|',
          section_separators   = '',
        },
        sections = {
          lualine_c = { { 'filename', path = 1 } }, -- show relative path
        },
      })
    end,
  },

  -- ----------------------------------------------------------
  -- File explorer  (<leader>e to toggle)
  -- ----------------------------------------------------------
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch       = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '<leader>e', ':Neotree toggle<CR>', desc = 'Explorer', silent = true },
    },
    config = function()
      require('neo-tree').setup({
        window = { width = 30 },
        filesystem = {
          filtered_items = {
            visible        = true,  -- show dotfiles (like .env)
            hide_dotfiles  = false,
            hide_gitignored = false,
          },
        },
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Fuzzy finder  (<leader>f*)
  -- ----------------------------------------------------------
  {
    'nvim-telescope/telescope.nvim',
    branch       = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      local telescope = require('telescope')
      local builtin   = require('telescope.builtin')

      telescope.setup({
        defaults = {
          mappings = {
            i = { ['<C-u>'] = false, ['<C-d>'] = false },
          },
        },
      })
      telescope.load_extension('fzf')

      -- Find
      vim.keymap.set('n', '<leader>ff', builtin.find_files,              { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep,               { desc = 'Grep' })
      vim.keymap.set('n', '<leader>fs', builtin.grep_string,             { desc = 'Grep word under cursor' })
      vim.keymap.set('n', '<leader>fr', builtin.oldfiles,                { desc = 'Recent files' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers,                 { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags,               { desc = 'Help' })
      vim.keymap.set('n', '<leader>fc', builtin.commands,                { desc = 'Commands' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics,             { desc = 'Diagnostics' })
      vim.keymap.set('n', '<leader>fk', builtin.keymaps,                 { desc = 'Keymaps' })
      -- grep in current file
      vim.keymap.set('n', '<leader>/',  builtin.current_buffer_fuzzy_find, { desc = 'Search in file' })
    end,
  },

  -- ----------------------------------------------------------
  -- Syntax highlighting + text objects (treesitter)
  -- ----------------------------------------------------------
  -- ----------------------------------------------------------
  -- Syntax highlighting + text objects (treesitter)
  -- Requires: cargo install tree-sitter-cli  (for :TSInstall)
  -- ----------------------------------------------------------
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main  = 'nvim-treesitter',
    opts  = {
      ensure_installed = {
        'lua', 'vim', 'vimdoc',
        'rust', 'go', 'python',
        'json', 'yaml', 'toml',
        'csv', 'tsv',
        'bash', 'markdown', 'gitignore',
      },
      auto_install = true,
      highlight    = { enable = true },
      indent       = { enable = true },
    },
  },

  -- ----------------------------------------------------------
  -- Treesitter text objects  (af/if = function, ac/ic = class, etc.)
  -- nvim-treesitter 0.9+ removed nvim-treesitter.configs entirely;
  -- keymaps must be registered manually via the module functions.
  -- ----------------------------------------------------------
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      local select = require('nvim-treesitter-textobjects.select')
      local move   = require('nvim-treesitter-textobjects.move')

      require('nvim-treesitter-textobjects').setup({ select = { lookahead = true } })

      local sel_maps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['aC'] = '@comment.outer',
      }
      for key, query in pairs(sel_maps) do
        vim.keymap.set({ 'x', 'o' }, key, function()
          select.select_textobject(query, 'textobjects')
        end, { desc = query })
      end

      local move_maps = {
        [']f'] = { fn = move.goto_next_start,     query = '@function.outer' },
        [']c'] = { fn = move.goto_next_start,     query = '@class.outer' },
        ['[f'] = { fn = move.goto_previous_start, query = '@function.outer' },
        ['[c'] = { fn = move.goto_previous_start, query = '@class.outer' },
      }
      for key, m in pairs(move_maps) do
        vim.keymap.set('n', key, function()
          m.fn(m.query, 'textobjects')
        end, { desc = m.query })
      end
    end,
  },

  -- ----------------------------------------------------------
  -- Git signs in gutter  (<leader>g*)
  -- ----------------------------------------------------------
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gs   = package.loaded.gitsigns
          local opts = { buffer = bufnr, silent = true }

          vim.keymap.set('n', ']h', gs.next_hunk,                   vim.tbl_extend('force', opts, { desc = 'Next hunk' }))
          vim.keymap.set('n', '[h', gs.prev_hunk,                   vim.tbl_extend('force', opts, { desc = 'Prev hunk' }))
          vim.keymap.set('n', '<leader>gs', gs.stage_hunk,          vim.tbl_extend('force', opts, { desc = 'Stage hunk' }))
          vim.keymap.set('n', '<leader>gu', gs.undo_stage_hunk,     vim.tbl_extend('force', opts, { desc = 'Undo stage hunk' }))
          vim.keymap.set('n', '<leader>gp', gs.preview_hunk,        vim.tbl_extend('force', opts, { desc = 'Preview hunk' }))
          vim.keymap.set('n', '<leader>gb', gs.toggle_current_line_blame, vim.tbl_extend('force', opts, { desc = 'Toggle blame' }))
          vim.keymap.set('n', '<leader>gd', gs.diffthis,            vim.tbl_extend('force', opts, { desc = 'Diff this' }))
        end,
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Commenting  (gcc = line, gc + motion, gc in visual)
  -- ----------------------------------------------------------
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  -- ----------------------------------------------------------
  -- Auto-close brackets / quotes
  -- ----------------------------------------------------------
  {
    'windwp/nvim-autopairs',
    event  = 'InsertEnter',
    config = function()
      local autopairs = require('nvim-autopairs')
      autopairs.setup({ check_ts = true }) -- use treesitter for smarter pairing

      -- Hook into cmp so <CR> doesn't double-insert closing bracket
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp           = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- ----------------------------------------------------------
  -- Surround text objects  (ys / cs / ds)
  --   ysiw"  = surround word with "
  --   cs"'   = change " to '
  --   ds"    = delete surrounding "
  -- ----------------------------------------------------------
  {
    'kylechui/nvim-surround',
    version = '*',
    event   = 'VeryLazy',
    config  = function() require('nvim-surround').setup() end,
  },

  -- ----------------------------------------------------------
  -- Indentation guides
  -- ----------------------------------------------------------
  {
    'lukas-reineke/indent-blankline.nvim',
    main   = 'ibl',
    config = function() require('ibl').setup() end,
  },

  -- ----------------------------------------------------------
  -- Keymap discovery popup  (<leader>? to open)
  -- ----------------------------------------------------------
  {
    'folke/which-key.nvim',
    event  = 'VeryLazy',
    config = function()
      local wk = require('which-key')
      wk.setup()
      -- Register group labels shown in the popup
      wk.add({
        { '<leader>f',  group = 'Find (telescope)' },
        { '<leader>b',  group = 'Buffer' },
        { '<leader>g',  group = 'Git' },
        { '<leader>l',  group = 'LSP actions' },
        { '<leader>d',  group = 'Diagnostics' },
        { '<leader>c',  group = 'Code' },
        { '<leader>v',  group = 'Vim learn' },
      })
      vim.keymap.set('n', '<leader>?', '<cmd>WhichKey<CR>', { desc = 'Show all keymaps' })
    end,
  },

  -- ----------------------------------------------------------
  -- CSV: column-coloring so each column has its own color
  -- ----------------------------------------------------------
  {
    'mechatroner/rainbow_csv',
    ft = { 'csv', 'tsv', 'csv_semicolon', 'csv_pipe' },
  },

  -- ----------------------------------------------------------
  -- .env: hide secret values (toggle with <leader>ch)
  -- ----------------------------------------------------------
  {
    'laytan/cloak.nvim',
    ft     = { 'sh', 'zsh', 'bash', 'dotenv', 'env' },
    config = function()
      require('cloak').setup({
        enabled       = true,
        cloak_character = '*',
        patterns = {
          { file_pattern = { '.env*', '*.env', 'config.*.local' }, cloak_pattern = '=.+' },
        },
      })
      vim.keymap.set('n', '<leader>ch', ':CloakToggle<CR>', { desc = 'Toggle .env cloak', silent = true })
    end,
  },

  -- ----------------------------------------------------------
  -- JSON / YAML schema validation (provides schemas for 2000+ configs)
  -- ----------------------------------------------------------
  { 'b0o/schemastore.nvim' },

  -- ----------------------------------------------------------
  -- Mason: installs and manages LSP servers
  -- ----------------------------------------------------------
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end,
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'rust_analyzer',
          'gopls',
          'pyright',
          'jsonls',
          'yamlls',
        },
        automatic_installation = true,
      })
    end,
  },

  -- ----------------------------------------------------------
  -- LSP configuration  (Neovim 0.11+ API: vim.lsp.config / vim.lsp.enable)
  -- lspconfig still provides server defaults (cmd, filetypes, root detection)
  -- ----------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
      'b0o/schemastore.nvim',
    },
    config = function()
      -- Apply cmp capabilities to every server globally
      vim.lsp.config('*', {
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
      })

      -- Rust (clippy on save, inlay hints, proc macros)
      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = {
            checkOnSave = true,
            check = {
              command  = 'clippy',
              features = 'all',
            },
            cargo = {
              loadOutDirsFromCheck = true,
              features             = 'all',
            },
            procMacro  = { enable = true },
            inlayHints = {
              bindingModeHints = { enabled = true },
              parameterHints   = { enabled = true },
              typeHints        = { enabled = true },
            },
          },
        },
      })

      -- Go
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            analyses    = { unusedparams = true, shadow = true },
            staticcheck = true,
            gofumpt     = true,
          },
        },
      })

      -- Python
      vim.lsp.config('pyright', {
        settings = {
          python = {
            analysis = { typeCheckingMode = 'basic' },
          },
        },
      })

      -- JSON (schema auto-detection via schemastore)
      vim.lsp.config('jsonls', {
        settings = {
          json = {
            schemas  = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      })

      -- YAML (schema auto-detection via schemastore)
      vim.lsp.config('yamlls', {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = '' },
            schemas     = require('schemastore').yaml.schemas(),
            validate    = true,
            hover       = true,
            completion  = true,
          },
        },
      })

      vim.lsp.enable({ 'rust_analyzer', 'gopls', 'pyright', 'jsonls', 'yamlls' })
    end,
  },

  -- ----------------------------------------------------------
  -- Completion engine
  -- ----------------------------------------------------------
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets', -- pre-built snippet library
    },
    config = function()
      local cmp     = require('cmp')
      local luasnip = require('luasnip')

      -- Load friendly-snippets
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>']     = cmp.mapping.scroll_docs(-4),
          ['<C-f>']     = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>']     = cmp.mapping.abort(),
          ['<CR>']      = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Vim cheatsheet + quiz overlay
  -- Source of truth: ui-cheatsheet/src/data.json (same as the web app)
  -- Plugin code lives in the nvim-plugin/ subdirectory of the repo
  -- ----------------------------------------------------------
  {
    'budavariam/learn-vim',
    config = function()
      local root = vim.fn.stdpath('data') .. '/lazy/learn-vim/nvim-plugin'
      vim.opt.rtp:prepend(root)
      require('vim-learn').setup({
        data_path = vim.fn.stdpath('data') .. '/lazy/learn-vim/ui-cheatsheet/src/data.json',
      })
    end,
    keys = {
      { '<leader>vl', '<cmd>VimLearnCheatsheet<CR>', desc = 'Vim cheatsheet' },
      { '<leader>vq', '<cmd>VimLearnQuiz<CR>',       desc = 'Vim quiz' },
    },
  },

})
