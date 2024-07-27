local M = {}
local ts_utils = require("nvim-treesitter.ts_utils")

--- @param fetchers string[]
--- @return TSNode|nil
function M.is_cursor_in_fetcher(fetchers)
  -- Ensure Treesitter is available
  if not vim.treesitter then
    print("Treesitter not available")
    return nil
  end

  -- Get the current node
  local bufnr = vim.api.nvim_get_current_buf()
  local node = ts_utils.get_node_at_cursor()

  -- Traverse up the tree to find a function call node
  while node do
    if node:type() == "apply_expression" then
      local child = node:child(0)
      if
        child
        and child:type() == "variable_expression"
        and vim.treesitter.get_node_text(child, bufnr) == "fetchFromGitHub"
        -- TODO: Add support for other fetchers
      then
        local params = node:child(1)
        if params then
          return params
        end
      end
    end
    node = node:parent()
  end

  return nil
end

--- @param node TSNode
function M.get_owner_and_repo(node)
  local set = node:child(1)

  local owner = nil
  local repo = nil

  if set and set:type() == "binding_set" then
    local bindings = set:named_children()
    for _, binding in ipairs(bindings) do
      local key = binding:child(0)
      local value = binding:child(2)

      if key and value and key:type() == "attrpath" and value:type() == "string_expression" then
        local k = vim.treesitter.get_node_text(key, 0)
        local v = vim.treesitter.get_node_text(value, 0)

        if k == "owner" then
          owner = v
        elseif k == "repo" then
          repo = v
        end
      end
    end
  end

  if owner and repo then
    return owner, repo
  end
end

--- @param owner string
--- @param repo string
function M.get_latest_commit(owner, repo)
  local repo_url = string.format("https://github.com/%s/%s", owner, repo)

  -- run git ls-remote to get the latest commit hash
  local handle = io.popen(string.format("git ls-remote %s HEAD 2>/dev/null", repo_url))
  if not handle then
    print("Failed to run git ls-remote")
    return
  end

  local output = handle:read("*a")
  handle:close()

  local commit_hash = vim.split(output, "\t")[1]

  if not commit_hash then
    print("Failed to get commit hash")
    return
  end

  return commit_hash
end

--- @param owner string
--- @param repo string
--- @param rev string
function M.get_latest_commit_hash(owner, repo, rev)
  local cmd_args = string.format("https://github.com/%s/%s %s", owner, repo, rev)

  -- run git ls-remote to get the latest commit hash
  local handle = io.popen(string.format("nurl -H %s 2>/dev/null", cmd_args))
  if not handle then
    print("Failed to run nurl")
    return
  end

  --- @type string
  local output = handle:read("*a")
  handle:close()

  -- remove the leading and trailing whitespace
  local hash = output:gsub("^%s*(.-)%s*$", "%1")

  if not hash then
    print("Failed to get output hash")
    return
  end

  return hash
end

--- @param node TSNode
--- @param commit_hash string
function M.update_git_rev(node, commit_hash)
  local set = node:child(1)
  if set and set:type() == "binding_set" then
    local bindings = set:named_children()
    for _, binding in ipairs(bindings) do
      local key = binding:child(0)
      local value = binding:child(2)

      if key and value and key:type() == "attrpath" and value:type() == "string_expression" then
        local k = vim.treesitter.get_node_text(key, 0)

        if k == "rev" then
          -- goto the node
          ts_utils.goto_node(value)

          -- put the commit hash into the node
          vim.api.nvim_put({ commit_hash }, "c", true, true)
        end
      end
    end
  end
end

--- @param node TSNode
--- @param hash string
function M.update_git_rev_hash(node, hash)
  local set = node:child(1)
  if set and set:type() == "binding_set" then
    local bindings = set:named_children()
    for _, binding in ipairs(bindings) do
      local key = binding:child(0)
      local value = binding:child(2)

      if key and value and key:type() == "attrpath" and value:type() == "string_expression" then
        local k = vim.treesitter.get_node_text(key, 0)

        if k == "hash" or k == "sha256" then
          -- goto the node
          ts_utils.goto_node(value)

          -- put the commit hash into the node
          vim.api.nvim_put({ hash }, "c", true, true)
        end
      end
    end
  end
end

return M
