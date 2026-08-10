return {
	-- mason 2.x drives servers through `vim.lsp.enable()`, which only exists on
	-- Neovim 0.11+. Pinning to the 1.x line keeps this config working on the
	-- Neovim that Debian ships. Drop both pins once you are on 0.11+.
	{
		"williamboman/mason.nvim",
		version = "^1.0",
		cmd = "Mason",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		version = "^1.0",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = { "bashls", "lua_ls", "cssls", "pylsp" },
			-- 1.x spells this `automatic_installation`; `auto_install` was
			-- silently ignored, so servers were never installed on demand.
			automatic_installation = true,
		},
	},
	-- On Neovim 0.10 and older this prints a deprecation notice on startup.
	-- It is informational (removal is planned for nvim-lspconfig v3.0.0) and
	-- the only way to silence it is running Neovim 0.11+.
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")
			lspconfig.bashls.setup({ capabilities = capabilities })
			lspconfig.cssls.setup({ capabilities = capabilities })
			lspconfig.lua_ls.setup({ capabilities = capabilities })
			lspconfig.pylsp.setup({ capabilities = capabilities })

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>gD", vim.lsp.buf.declaration, { desc = "Declaration" })
			vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Definitions" })
			vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "References" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
		end,
	},
}
