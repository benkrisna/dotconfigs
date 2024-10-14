return {
  {
    "hrsh7th/cmp-nvim-lsp",
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'saadparwaiz1/cmp_luasnip',
      "rafamadriz/friendly-snippets",
    },
  },
  {
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-buffer',
    },
    config = function()
      -- Set up nvim-cmp.
      local cmp = require('cmp')
      require("luasnip/loaders/from_vscode").lazy_load()
      -- load snippets from path/of/your/nvim/config/my-cool-snippets
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./my-cool-snippets" } })
      -- jupynium
      local compare = cmp.config.compare
      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "jupynium", priority = 1000},
          { name = 'buffer' },
          { name = 'path' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, -- For luasnip users.
          { name = "latex_symbols",
            option = {
              strategy = 0,
            },
          },
        }),
        sorting = {
          priority_weight = 1.0,
          comparators = {
            compare.score,            -- Jupyter kernel completion shows prior to LSP
            compare.recently_used,
            compare.locality,
            -- ...
          },
        }
      })
      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
      require('lspconfig')['clangd'].setup {
        capabilities = capabilities
      }

    end,
  },
}

