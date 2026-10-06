---@type nvim-ts.parsers
return {
  resc = {
    install_info = {
      url = "https://github.com/achmutov/tree-sitter-resc",
      revision = "c7a7a3f2716c0dbe305cbde566406faa279f7402",
      generate_from_json = false,
      generate = true,
      queries = "queries",
    },
    tier = 2,
  },
  lox = {
    install_info = {
      url = "https://github.com/achmutov/tree-sitter-lox",
      revision = "213af397f123ab4da749ada8403ee037412ec6a5",
      generate_from_json = false,
      generate = true,
      queries = "queries",
    },
    tier = 2,
  },
}
