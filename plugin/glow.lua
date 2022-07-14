-- create install cmd
vim.api.nvim_create_user_command("Glow", function(opts)
  require("glow").execute(opts)
end, { complete = "file", nargs = "*", bang = true })
