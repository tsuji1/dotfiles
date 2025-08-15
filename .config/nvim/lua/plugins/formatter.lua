return {
  -- 保存時に自動整形
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- 保存時に走る。LSPでformatできない場合は下のformattersを使う
      format_on_save = { lsp_fallback = true, timeout_ms = 1000 },
      notify_on_error = true,
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format", "black" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        markdown = { "prettierd", "prettier" },
        go = { "gofumpt", "goimports" },
        rust = { "rustfmt" },
        php = { "phpcbf" }, -- PSR系ならこれ。好みに応じて
        ["_"] = { "trim_whitespace" }, -- フォールバック
      },
    },
  },

  -- ツールのインストール管理（任意だが便利）
  { "williamboman/mason.nvim", build = ":MasonUpdate", opts = {} },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- JS/TS/MD/JSON/YAML
        "prettierd", "prettier",
        -- Lua
        "stylua",
        -- Python
        "ruff", "black",
        -- Go
        "gofumpt", "goimports",
        -- Rust
        "rustfmt",
        -- PHP
        "phpcbf",
      },
      auto_update = true,
      run_on_start = true,
    },
  },
}

