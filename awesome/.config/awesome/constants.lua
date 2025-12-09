---@diagnostic disable: lowercase-global
terminal = "alacritty"
editor = "nvim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

return {
    themes_path = "~/.config/awesome/",
    theme = "default",
}
