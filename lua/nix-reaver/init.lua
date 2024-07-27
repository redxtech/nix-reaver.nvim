local M = {}

function M.setup(opts)
  opts = opts or {
    fetcherNames = { "fetchFromGitHub" },
  }

  vim.api.nvim_create_user_command("NixReaver", function()
    local reaver = require("nix-reaver.nix-reaver")

    local node = reaver.is_cursor_in_fetcher(opts.fetcherNames)
    if node then
      local owner, repo = reaver.get_owner_and_repo(node)

      local commit_hash = reaver.get_latest_commit(owner, repo)
      if not commit_hash then
        return
      end

      reaver.update_git_rev_or_hash(node, true, commit_hash)

      local hash = reaver.get_latest_commit_hash(owner, repo, commit_hash)
      if not hash then
        return
      end

      reaver.update_git_rev_or_hash(node, false, hash)

      -- notify after updating
      vim.schedule(function()
        vim.notify(string.format("Updated %s to %s", repo, hash))
      end)
    end
  end, {})
end

return M
