---@type vim.lsp.Config
return {
  filetypes = { "kotlin" },
  cmd = { "intellij-server", "--stdio" },
  settings = {
    -- intellij = {
    --   -- jdkForSymbolResolution = vim.env.JAVA_HOME
    --   ["jetbrains.kotlin.hints.settings.types.variable"] = true
    -- }

    jetbrains = {
      kotlin = {
        hints = {
          ["parameters"] = true,
          ["parameters.compiled"] = true,
          ["parameters.excluded"] = true,
          ["parameters.context"] = true,
          ["type.property"] = true,
          ["type.variable"] = true,
          ["type.function.return"] = true,
          ["type.function.parameter"] = true,
          ["lambda.return"] = true,
          ["lambda.receivers.parameters"] = true,
          ["value.ranges"] = true,
          ["value.kotlin.time"] = true,
          ["call.chains"] = true,
        },
      },
    },
  },
  root_markers = {
    "settings.gradle", -- Gradle (multi-project)
    "settings.gradle.kts", -- Gradle (multi-project)
    "pom.xml", -- Maven
    "build.gradle", -- Gradle
    "build.gradle.kts", -- Gradle
    "workspace.json", -- Used to integrate your own build system
  },
}
