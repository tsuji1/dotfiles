vim.api.nvim_create_user_command("InitLua", function()
	vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Open init.lua" })

vim.api.nvim_create_user_command("PandocFromUrl", function(opts)
	local url = opts.args
	local ts = os.date("%Y%m%d_%H%M%S")
	local out = string.format("articles/%s.md", ts)
	local dir = string.format("articles/%s_assets", ts)
	vim.fn.mkdir("articles", "p")
	local cmd = string.format('pandoc "%s" -f html -t gfm --extract-media="%s" -o "%s"', url, dir, out)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error == 0 then
		vim.cmd.edit(out)
	else
		print("Pandoc failed: " .. result)
	end
end, { nargs = 1 })
