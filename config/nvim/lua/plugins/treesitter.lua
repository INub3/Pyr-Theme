return {
	"nvim-treesitter/nvim-treesitter",
	-- The default branch is now `main`, a rewrite that dropped the
	-- `nvim-treesitter.configs` module and requires Neovim 0.11+.
	-- `master` keeps the API this config uses.
	branch = "master",
	event = { "BufReadPre", "BufNewFile" }, -- load when a buffer is opened or created
	build = ":TSUpdate",
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
