return {
	needs = { "vrighter/pixel.nvim" },
	after = { "vrighter/pixel.nvim" },
	config = function()
		vim.o.termguicolors = true
		nnoremap("<leader>mario", ':lua require"mario".its_a_meee()<cr>', "silent", "Pixel: toggle little buddies")
	end,
}
