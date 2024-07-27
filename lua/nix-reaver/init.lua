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

      local hash = reaver.get_latest_commit_hash(owner, repo, commit_hash)
      reaver.update_git_rev(node, commit_hash)
      if not hash then
        return
      end

      reaver.update_git_rev_hash(node, hash)
    end
  end, {})
end

return M
