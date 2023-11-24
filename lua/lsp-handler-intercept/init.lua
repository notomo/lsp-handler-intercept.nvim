local M = {}

--- @class LspHandlerInterceptHandlerContext
--- @field original_handler fun(err:table?,result:table?,ctx:table,config:table) |lsp-handler|

--- Returns a wrapped handler.
--- @param original_handler fun(err:table?,result:table?,ctx:table,config:table) original handler to wrap. |lsp-handler|
--- @return fun(err:table?,result:table?,ctx:table,config:table,additional_ctx:LspHandlerInterceptHandlerContext) # wrapped handler
function M.wrap(original_handler)
  return require("lsp-handler-intercept.command").wrap(original_handler)
end

--- @class LspHandlerInterceptKeySet
--- @field client_id integer? |vim.lsp.client| id
--- @field method string? |vim.lsp.protocol.Methods|
--- @field buffer integer? buffer number

--- Sets an intercept handler.
--- This is a low level api. Normally use |lsp-handler-intercept.on_request()|.
--- @param key_set LspHandlerInterceptKeySet |LspHandlerInterceptKeySet|
--- @param handler fun(err:table?,result:table?,ctx:table,config:table) |lsp-handler|
function M.set(key_set, handler)
  require("lsp-handler-intercept.command").set(key_set, handler)
end

--- @class LspHandlerInterceptOnRequestOptions
--- @field methods string[]? if not nil, intercepts only matched method request. |vim.lsp.protocol.Methods|
--- @field client_names string[]? if not nil, intercepts only matched client request.
--- @field buffer integer? if not nil, intercepts only matched buffer number.
--- @field predicate (fun(autocmd_args:table):boolean)? if not nil, intercepts only when the function returns true.

--- Sets a conditioal intercept handler for lsp request.
--- @param handler fun(err:table?,result:table?,ctx:table,config:table) |lsp-handler|
--- @param opts LspHandlerInterceptOnRequestOptions |LspHandlerInterceptOnRequestOptions|
function M.on_request(handler, opts)
  require("lsp-handler-intercept.command").on_request(handler, opts)
end

--- Clears all intercept handlers.
function M.clear()
  require("lsp-handler-intercept.command").clear()
end

return M
