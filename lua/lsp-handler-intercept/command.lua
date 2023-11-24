local M = {}

function M.clear()
  for group_name in pairs(M._autocmd_group_names or {}) do
    vim.api.nvim_clear_autocmds({ group = group_name })
  end
  M._handlers = {}
  M._autocmd_group_names = {}
end
M.clear()

local make_keys = function(key_set)
  return {
    key_set.buffer or "",
    key_set.client_id or "",
    key_set.method or "",
  }
end

local make_key = function(keys)
  return table.concat(keys, "|")
end

local matched_handler = function(handlers, key_set)
  local bufnr, client_id, method = unpack(make_keys(key_set))
  local all_keys = {
    { bufnr, client_id, method },
    { bufnr, client_id, "" },
    { bufnr, "", method },
    { bufnr, "", "" },
    { "", client_id, method },
    { "", client_id, "" },
    { "", "", method },
    { "", "", "" },
  }
  for _, keys in ipairs(all_keys) do
    local key = make_key(keys)
    local handler = handlers[key]
    if handler then
      return handler, key
    end
  end
end

function M.wrap(original_handler)
  return function(err, result, ctx, config)
    local handlers = require("lsp-handler-intercept.command")._handlers

    local handler, key = matched_handler(handlers, ctx)
    if handler then
      handlers[key] = nil
      handler(err, result, ctx, config, {
        original_handler = original_handler,
      })
      return
    end

    original_handler(err, result, ctx, config)
  end
end

function M.set(key_set, handler)
  local key = make_key(make_keys(key_set))
  M._handlers[key] = handler
end

local default_opts = {
  buffer = nil,
  client_names = nil,
  methods = nil,
  predicate = function(_)
    return true
  end,
}
function M.on_request(handler, raw_opts)
  raw_opts = raw_opts or {}
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts)
  opts.buffer = opts.buffer == 0 and vim.api.nvim_get_current_buf() or opts.buffer

  local group_name = ("lsp_handler_intercept_%s_%s_%s"):format(
    opts.buffer or "",
    table.concat(opts.client_names or {}, ","),
    table.concat(opts.methods or {}, ",")
  )
  M._autocmd_group_names[group_name] = true
  local group = vim.api.nvim_create_augroup(group_name, {})

  local method_is_matched = function(request)
    if not opts.methods then
      return true
    end
    return vim.tbl_contains(opts.methods, request.method)
  end

  local client_is_matched = function(client_id)
    if not opts.client_names then
      return true
    end
    return vim.iter(opts.client_names):any(function(client_name)
      local client = vim.lsp.get_clients({
        id = client_id,
        buffer = opts.buffer,
        name = client_name,
      })[1]
      return client ~= nil
    end)
  end

  vim.api.nvim_create_autocmd("LspRequest", {
    group = group,
    buffer = opts.buffer,
    callback = function(args)
      local request = args.data.request
      if request.type ~= "pending" then
        return
      end

      if not method_is_matched(request) then
        return
      end

      local client_id = args.data.client_id
      if not client_is_matched(client_id) then
        return
      end

      if not opts.predicate(args) then
        return
      end

      local key_set = {
        buffer = opts.buffer,
        client_id = opts.client_names ~= nil and client_id or nil,
        method = opts.methods ~= nil and request.method or nil,
      }
      require("lsp-handler-intercept.command").set(key_set, handler)
    end,
  })
end

return M
