-- Stow links this directory to ~/.config/rex; Rex loads init.lua on the server.
-- After editing: rex config check && rex config reload

-- Option + arrows navigate tabs.
rex.bind("alt+down", "client.tab.next")
rex.bind("alt+up", "client.tab.previous")

-- https://github.com/almonk/rex-projects (requires control API revision 17).
require("projects").setup {
  roots = { "~/Dev" },
}
