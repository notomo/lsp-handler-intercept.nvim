local helper = require("lsp-handler-intercept.test.helper")
local intercepter = helper.require("lsp-handler-intercept")

describe("lsp-handler-intercept", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("intercepts handler if key is matched", function()
    local handler = intercepter.wrap(function() end)

    local got
    intercepter.set({
      buffer = 1,
      client_id = 2,
      method = "method_name",
    }, function(...)
      got = { ... }
    end)

    handler("err", "result", {
      buffer = 1,
      client_id = 2,
      method = "method_name",
    })

    assert.is_same("err", got[1])
    assert.is_same("result", got[2])
    assert.is_same({
      buffer = 1,
      client_id = 2,
      method = "method_name",
    }, got[3])
  end)

  it("does not intercept handler if buffer is not matched", function()
    local handler = intercepter.wrap(function() end)

    local called = false
    intercepter.set({
      buffer = 1,
      client_id = 2,
      method = "method_name",
    }, function()
      called = true
    end)

    handler("err", "result", {
      buffer = 2,
      client_id = 2,
      method = "method_name",
    })

    assert.is_false(called)
  end)

  it("does not intercept handler if client_id is not matched", function()
    local handler = intercepter.wrap(function() end)

    local called = false
    intercepter.set({
      buffer = 1,
      client_id = 2,
      method = "method_name",
    }, function()
      called = true
    end)

    handler("err", "result", {
      buffer = 1,
      client_id = 3,
      method = "method_name",
    })

    assert.is_false(called)
  end)

  it("does not intercept handler if method is not matched", function()
    local handler = intercepter.wrap(function() end)

    local called = false
    intercepter.set({
      buffer = 1,
      client_id = 2,
      method = "method_name1",
    }, function()
      called = true
    end)

    handler("err", "result", {
      buffer = 1,
      client_id = 2,
      method = "method_name2",
    })

    assert.is_false(called)
  end)
end)

describe("lsp-handler-intercept.clear()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("clears all conditional handler", function()
    local original_called = false
    local handler = intercepter.wrap(function()
      original_called = true
    end)

    local intercept_called = false
    intercepter.set({
      buffer = 1,
      client_id = 2,
      method = "method_name",
    }, function()
      intercept_called = true
    end)

    intercepter.clear()

    handler("err", "result", {
      buffer = 1,
      client_id = 2,
      method = "method_name",
    })

    assert.is_false(intercept_called)
    assert.is_true(original_called)
  end)

  it("clears on_request related autocmds", function()
    intercepter.on_request(function() end, {
      buffer = 0,
      methods = { vim.lsp.protocol.Methods.textDocument_definition },
    })
    intercepter.on_request(function() end, {
      buffer = 0,
      methods = { vim.lsp.protocol.Methods.textDocument_hover },
    })

    intercepter.clear()

    local autocmds = vim.api.nvim_get_autocmds({ event = "LspRequest", buffer = 0 })
    assert.is_same({}, autocmds)
  end)
end)

describe("lsp-handler-intercept.on_request()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("sets conditional handler for lsp request", function()
    local handler = intercepter.wrap(function() end)

    local method = vim.lsp.protocol.Methods.textDocument_definition
    local client_id = 2

    local called = false
    intercepter.on_request(function()
      called = true
    end, {
      buffer = 0,
      methods = { method },
    })

    local buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_exec_autocmds("LspRequest", {
      buffer = buffer,
      modeline = false,
      data = {
        client_id = client_id,
        request_id = 1,
        request = {
          type = "pending",
          buffer = buffer,
          method = method,
        },
      },
    })

    handler("err", "result", {
      buffer = buffer,
      client_id = client_id,
      method = method,
    })

    assert.is_true(called)
  end)
end)
