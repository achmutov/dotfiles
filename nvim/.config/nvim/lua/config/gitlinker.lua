local function get_antmicro_type_url(url_data)
    local url = "https://" .. url_data.host .. "/git/repositories/" .. url_data.repo
    if not url_data.file or not url_data.rev then
        return url
    end
    url = url .. "/blob/" .. url_data.rev .. "/" .. url_data.file

    if not url_data.lstart then
        return url
    end
    url = url .. "#L" .. url_data.lstart
    if url_data.lend then
        url = url .. "-" .. url_data.lend
    end
    return url
end

require("gitlinker").setup({
    callbacks = { ["dev.antmicro.com"] = get_antmicro_type_url },
    mappings = "<leader>gy",
})
