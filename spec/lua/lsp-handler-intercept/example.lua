-- switch tsserver and cssmodules_ls handler by context

vim.lsp.handlers[vim.lsp.protocol.Methods.textDocument_hover] =
  require("lsp-handler-intercept").wrap(vim.lsp.handlers.hover)

vim.lsp.handlers[vim.lsp.protocol.Methods.textDocument_definition] = require("lsp-handler-intercept").wrap(function()
  -- implement
end)

-- The following is after/ftplugin/typescriptreact.lua

local cursor_on_jsx_class_name = function()
  -- implement
  return true
end

local methods = {
  vim.lsp.protocol.Methods.textDocument_definition,
  vim.lsp.protocol.Methods.textDocument_hover,
}
require("lsp-handler-intercept").on_request(function() end, {
  bufnr = 0,
  client_names = { "tsserver" },
  methods = methods,
  predicate = function()
    return cursor_on_jsx_class_name()
  end,
})
require("lsp-handler-intercept").on_request(function() end, {
  bufnr = 0,
  client_names = { "cssmodules_ls" },
  methods = methods,
  predicate = function()
    return not cursor_on_jsx_class_name()
  end,
})
