-- rex-projects: start a Rex session for a project.
--
-- The flow:
--   1. Pick a project from a list you keep (or add one by its folder).
--   2. Pick where to work: the current checkout, a worktree the project
--      already has, or a new worktree.
--   3. For a new worktree, name its branch and pick what to start from.
-- Then Rex opens a session in that folder. The last choice for each project
-- is listed first next time.
--
-- Install: put this file next to init.lua and add to init.lua
--
--     require("projects")
--
-- Optional settings, before or after the require:
--
--     require("projects").setup{
--       key       = "alt+cmd+n",        -- false to bind nothing
--       worktrees = "~/.rex/worktrees", -- where new worktrees are made
--       roots     = { "~/Code" },       -- folders whose repositories are
--                                       -- listed without being added
--     }
--
-- Written for Lua 5.1 (what Rex embeds) and for init.lua, which runs
-- unsandboxed on the server. Without io, the project list is kept only
-- until the server restarts, and the script says so in the log.

local M = {}

-- Servers before control API revision 17 have no rex.ui. Do nothing there
-- instead of failing the whole init.lua.
local has_ui, ui = pcall(function() return rex.ui end)
if not has_ui or ui == nil then
  return M
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

-- The settings. A call to M.setup replaces the ones it names.
local config = {
  key = "alt+cmd+n",
  worktrees = nil, -- nil means <home>/.rex/worktrees
  roots = {},
  state_file = nil, -- nil means <config dir>/rex/projects.json
}

-- The key that is bound now, so that setup can move it.
local bound_key = nil

---------------------------------------------------------------------------
-- Platform
---------------------------------------------------------------------------

-- The first character of package.config is the directory separator, and it
-- is a backslash only on Windows.
local is_windows = (package and package.config or "/"):sub(1, 1) == "\\"

-- env returns an environment variable, or nil when it is unset or empty, or
-- when this script has no os library.
local function env(name)
  if os == nil or os.getenv == nil then return nil end
  local value = os.getenv(name)
  if value == nil or value == "" then return nil end
  return value
end

local home = env("HOME") or env("USERPROFILE") or ""

-- slashes writes every separator as "/", which git and Windows both take.
local function slashes(path)
  return (path:gsub("\\", "/"))
end

-- expand writes a leading ~ as the home folder and trims blanks and quotes
-- that a pasted path carries.
local function expand(path)
  path = path:gsub("^%s+", ""):gsub("%s+$", "")
  path = path:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  path = slashes(path)
  if path == "~" then return slashes(home) end
  if path:sub(1, 2) == "~/" then return slashes(home) .. path:sub(2) end
  return path
end

-- short writes the home folder at the start of path as ~.
local function short(path)
  local h = slashes(home)
  if h ~= "" and path:sub(1, #h + 1) == h .. "/" then
    return "~" .. path:sub(#h + 1)
  end
  return path
end

-- basename returns the last component of a slash-separated path.
local function basename(path)
  return (path:gsub("/+$", ""):match("([^/]+)$")) or path
end

-- trim removes blanks from both ends of s.
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- worktrees_dir is the folder that new worktrees are made in, as
-- <dir>/<project>/<branch>.
local function worktrees_dir()
  if config.worktrees then return expand(config.worktrees) end
  local from_env = env("REX_WORKTREES")
  if from_env then return expand(from_env) end
  return slashes(home) .. "/.rex/worktrees"
end

---------------------------------------------------------------------------
-- State: the project list and each project's last choice
---------------------------------------------------------------------------

-- state is { projects = { path, ... }, last = { [path] = choice } }, where a
-- choice is "current", a worktree's folder, or "new".
local state = nil

-- state_path returns where the state is kept, or nil when there is nowhere.
local function state_path()
  if config.state_file then return expand(config.state_file) end
  local base
  if is_windows then
    base = env("APPDATA")
  else
    base = env("XDG_CONFIG_HOME") or (home ~= "" and (home .. "/.config") or nil)
  end
  if base == nil then return nil end
  return slashes(base) .. "/rex/projects.json"
end

-- warned_memory_only keeps the log to one warning about a missing io library.
local warned_memory_only = false

-- load_state reads the state once and returns it. A missing or unreadable
-- file is an empty state: a corrupt list must never stop a session starting.
local function load_state()
  if state ~= nil then return state end
  state = { projects = {}, last = {} }
  local path = state_path()
  if io == nil or io.open == nil or path == nil then return state end
  local file = io.open(path, "r")
  if file == nil then return state end
  local text = file:read("*a")
  file:close()
  local ok, decoded = pcall(rex.json.decode, text)
  if ok and type(decoded) == "table" then
    -- Read each member by hand: a newer version of this file may hold more.
    if type(decoded.projects) == "table" then
      for _, p in ipairs(decoded.projects) do
        if type(p) == "string" then state.projects[#state.projects + 1] = p end
      end
    end
    if type(decoded.last) == "table" then
      for k, v in pairs(decoded.last) do
        if type(k) == "string" and type(v) == "string" then state.last[k] = v end
      end
    end
  end
  return state
end

-- save_state writes the state. It returns nothing and never raises: failing
-- to remember is not worth stopping a session for.
local function save_state()
  local path = state_path()
  if io == nil or io.open == nil or path == nil then
    if not warned_memory_only then
      warned_memory_only = true
      rex.log("warn", "projects: no place to save the project list; it lasts until the server restarts")
    end
    return
  end
  -- Make the folder first. mkdir -p exists on every Unix; Windows mkdir
  -- makes parents by itself and fails when the folder exists, which is fine.
  local dir = path:match("^(.*)/[^/]+$")
  if dir then
    if is_windows then
      rex.exec({ "cmd", "/c", "mkdir", (dir:gsub("/", "\\")) })
    else
      rex.exec({ "mkdir", "-p", dir })
    end
  end
  local file, err = io.open(path, "w")
  if file == nil then
    rex.log("warn", "projects: cannot save " .. path .. ": " .. tostring(err))
    return
  end
  file:write(rex.json.encode({ projects = state.projects, last = state.last }))
  file:close()
end

---------------------------------------------------------------------------
-- Git
---------------------------------------------------------------------------

-- git runs git in dir and returns what it printed, or nil and a message.
-- Arguments go as a list, never through a shell, so no quoting is needed.
local function git(dir, ...)
  local r, err = rex.exec({ "git", "-C", dir, ... })
  if r == nil then return nil, err end
  if not r.ok then
    local message = trim(r.stderr)
    return nil, message ~= "" and message or ("git exited with status " .. tostring(r.code))
  end
  return r.stdout
end

-- is_repo_root says whether dir is the top folder of a repository. It asks for
-- the way up to the top, which is empty at the top, instead of comparing paths:
-- git spells a symlinked folder (/tmp, a linked ~/Code) its own way.
local function is_repo_root(dir)
  local out = git(dir, "rev-parse", "--show-cdup")
  return out ~= nil and trim(out) == ""
end

-- current_branch returns the branch checked out in dir, or nil when HEAD is
-- detached or the repository has no commit yet.
local function current_branch(dir)
  local out = git(dir, "symbolic-ref", "--short", "-q", "HEAD")
  if out == nil then return nil end
  out = trim(out)
  return out ~= "" and out or nil
end

-- worktrees lists a project's checkouts, main one first, as
-- { path = ..., branch = ... or nil }. It returns nil for a folder that is
-- not a repository.
local function worktrees(project)
  local out = git(project, "worktree", "list", "--porcelain")
  if out == nil then return nil end
  local list = {}
  -- Each checkout is a paragraph of lines. Appending a blank line makes the
  -- last one end like the others.
  -- Take gsub's first result into a local before using it. A gsub call inside
  -- a ".." expression, with :gmatch called on the result, makes gopher-lua
  -- (the Lua in Rex) panic with a nil dereference.
  local text = out:gsub("\r", "")
  text = text .. "\n"
  for entry in text:gmatch("(.-)\n\n") do
    local path = entry:match("^worktree ([^\n]+)")
    if path then
      list[#list + 1] = {
        path = slashes(path),
        branch = entry:match("\nbranch refs/heads/([^\n]+)"),
        prunable = entry:find("\nprunable", 1, true) ~= nil,
      }
    end
  end
  return list
end

-- local_branches returns the names of the branches, newest commit first.
local function local_branches(project)
  local out = git(project, "for-each-ref", "--sort=-committerdate",
    "--format=%(refname:short)", "refs/heads")
  local names = {}
  if out == nil then return names end
  for line in out:gmatch("[^\r\n]+") do names[#names + 1] = line end
  return names
end

-- remote_default returns "origin/main" and the like, the branch that the
-- remote's HEAD names, or nil when there is none.
local function remote_default(project)
  local out = git(project, "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD")
  if out == nil then return nil end
  out = trim(out)
  return out ~= "" and out or nil
end

-- valid_branch_name says whether git accepts name as a branch name.
local function valid_branch_name(project, name)
  return git(project, "check-ref-format", "--branch", name) ~= nil
end

---------------------------------------------------------------------------
-- Projects
---------------------------------------------------------------------------

-- scan lists the repositories directly under each folder in config.roots,
-- as paths. Only folders are searched, one level down, so it stays quick.
local function scan()
  local found = {}
  local roots = config.roots
  local from_env = env("REX_PROJECTS")
  if from_env then
    roots = { from_env }
    for _, r in ipairs(config.roots) do roots[#roots + 1] = r end
  end
  for _, root in ipairs(roots) do
    root = expand(root)
    if is_windows then
      -- dir /b /ad lists folder names only.
      local r = rex.exec({ "cmd", "/c", "dir", "/b", "/ad", (root:gsub("/", "\\")) })
      if r ~= nil and r.ok then
        for name in r.stdout:gmatch("[^\r\n]+") do
          local path = root .. "/" .. name
          if is_repo_root(path) then found[#found + 1] = path end
        end
      end
    else
      -- A repository has a .git entry: a folder, or a file in a worktree.
      -- -print0 ends each path with NUL, the one byte a path cannot hold.
      local r = rex.exec({
        "find", root, "-mindepth", "2", "-maxdepth", "2", "-name", ".git", "-print0",
      })
      if r ~= nil and r.ok then
        for hit in r.stdout:gmatch("[^%z]+") do
          local path = hit:match("^(.*)/%.git$")
          if path then found[#found + 1] = path end
        end
      end
    end
  end
  return found
end

-- project_rows returns the rows of the project picker: the added projects
-- and the scanned ones with the most recently used first, then the row that
-- adds a project.
local ADD_PROJECT = "\0add"
local function project_rows()
  local s = load_state()
  local seen, paths = {}, {}
  for _, p in ipairs(s.projects) do
    if not seen[p] then seen[p] = true; paths[#paths + 1] = p end
  end
  for _, p in ipairs(scan()) do
    if not seen[p] then seen[p] = true; paths[#paths + 1] = p end
  end
  table.sort(paths, function(a, b)
    return basename(a):lower() < basename(b):lower()
  end)
  local rows = {}
  for _, p in ipairs(paths) do
    rows[#rows + 1] = { id = p, title = basename(p), subtitle = short(p), icon = "folder" }
  end
  rows[#rows + 1] = { id = ADD_PROJECT, title = "Add project…", subtitle = "Choose a folder", icon = "plus" }
  return rows
end

-- is_folder says whether path is a folder on this machine.
local function is_folder(path)
  if is_windows then
    -- A folder holds the NUL device on Windows; a file does not.
    local native = path:gsub("/", "\\")
    local r = rex.exec({ "cmd", "/c", "if", "exist", native .. "\\NUL", "echo", "yes" })
    return r ~= nil and r.ok and r.stdout:find("yes", 1, true) ~= nil
  end
  local r = rex.exec({ "test", "-d", path })
  return r ~= nil and r.ok
end

-- subfolders lists the folders directly inside dir as { path = ..., repo =
-- boolean }, sorted by name, hidden folders left out. It returns an empty list
-- for a folder it cannot read.
local function subfolders(dir)
  local list = {}
  if is_windows then
    -- dir /b /ad lists folder names only. Repositories are not marked: one
    -- git call for each folder would be slow, and Return then opens the
    -- folder, from where "Add" is one row away.
    local r = rex.exec({ "cmd", "/c", "dir", "/b", "/ad", (dir:gsub("/", "\\")) })
    if r ~= nil and r.ok then
      for name in r.stdout:gmatch("[^\r\n]+") do
        if name:sub(1, 1) ~= "." then
          local base = dir:gsub("/+$", "")
          list[#list + 1] = { path = base .. "/" .. name, repo = false }
        end
      end
    end
  else
    -- -print0 ends each path with NUL, the one byte a path cannot hold.
    local r = rex.exec({ "find", dir, "-mindepth", "1", "-maxdepth", "1", "-type", "d",
      "-not", "-name", ".*", "-print0" })
    local repos = {}
    local g = rex.exec({ "find", dir, "-mindepth", "2", "-maxdepth", "2", "-name", ".git", "-print0" })
    if g ~= nil and g.ok then
      for hit in g.stdout:gmatch("[^%z]+") do
        local path = hit:match("^(.*)/%.git$")
        if path then repos[path] = true end
      end
    end
    if r ~= nil and r.ok then
      for path in r.stdout:gmatch("[^%z]+") do
        list[#list + 1] = { path = path, repo = repos[path] == true }
      end
    end
  end
  table.sort(list, function(a, b) return basename(a.path):lower() < basename(b.path):lower() end)
  return list
end

-- parent_of returns the folder above dir, or nil at the top.
local function parent_of(dir)
  local parent = dir:match("^(.*)/[^/]+/?$")
  if parent == nil or parent == "" then
    -- "/x" has the parent "/"; "C:/x" has "C:/".
    if dir:match("^/[^/]+/?$") then return "/" end
    return nil
  end
  if parent:match("^%a:$") then return parent .. "/" end
  return parent
end

-- save_project adds path to the list, once, and returns it.
local function save_project(path)
  local s = load_state()
  for _, p in ipairs(s.projects) do
    if p == path then return path end
  end
  s.projects[#s.projects + 1] = path
  save_state()
  return path
end

-- add_project is a folder browser in the palette. Each page lists the
-- folders inside one folder. Return on a repository adds it, and on any
-- other folder opens it. The first row adds the folder being browsed, so
-- a folder that is no repository can be a project too. Typing a path and
-- pressing Return on the last row jumps there, and a path that is a repository
-- is added. It returns the folder, or nil and why ("cancelled" when the
-- person gave up).
local ADD_HERE = "\0here"
local UP = "\0up"
local function add_project()
  local dir = config.roots[1] and expand(config.roots[1]) or env("REX_PROJECTS") and expand(env("REX_PROJECTS"))
    or slashes(home)
  if dir == "" or not is_folder(dir) then dir = "/" end
  -- A folder tree is finite, but a typed path can loop; the cap keeps a
  -- script from asking forever.
  for _ = 1, 200 do
    dir = dir:gsub("/+$", "")
    if dir == "" then dir = "/" end
    local rows = {
      { id = ADD_HERE, title = "Add " .. (dir == "/" and "/" or basename(dir)), subtitle = short(dir), icon = "plus" },
    }
    if parent_of(dir) ~= nil then
      rows[#rows + 1] = { id = UP, title = "..", subtitle = short(parent_of(dir)), icon = "folder" }
    end
    local children = {}
    for _, child in ipairs(subfolders(dir)) do
      children[child.path] = child
      rows[#rows + 1] = {
        id = child.path,
        title = basename(child.path),
        icon = "folder",
      }
    end
    local picked, why = rex.ui.pick{
      title = "Add project",
      placeholder = short(dir) .. "/  (type a path to jump)",
      allow_other = true,
      items = rows,
    }
    if picked == nil then return nil, why end
    if type(picked) == "table" then
      -- The person typed a path instead of choosing a row.
      local typed = expand(picked.text or "")
      if typed == "" then return nil, "cancelled" end
      if not is_folder(typed) then return nil, "not a folder: " .. typed end
      if is_repo_root(typed) then return save_project(typed) end
      dir = typed
    elseif picked == ADD_HERE then
      return save_project(dir)
    elseif picked == UP then
      dir = parent_of(dir)
    elseif children[picked] and children[picked].repo then
      return save_project(picked)
    else
      dir = picked
    end
  end
  return nil, "too many steps"
end

---------------------------------------------------------------------------
-- Checkouts
---------------------------------------------------------------------------

-- NEW_WORKTREE and CURRENT are the ids of the rows that are not a folder.
-- The NUL byte keeps them apart from any real path.
local NEW_WORKTREE = "\0new"
local CURRENT = "\0current"

-- checkout_rows returns the rows of the checkout picker, with the one that
-- was used last for project first. Its second result is the project's list of
-- worktrees, nil for a folder with no repository.
local function checkout_rows(project)
  local trees = worktrees(project)
  local rows = {}
  if trees == nil then
    rows[1] = { id = CURRENT, title = "Current folder", subtitle = short(project), icon = "folder" }
    return rows, nil
  end
  local branch = current_branch(project)
  rows[#rows + 1] = {
    id = CURRENT,
    title = "Current checkout",
    subtitle = (branch or "detached HEAD") .. " · " .. short(project),
    icon = "folder",
  }
  rows[#rows + 1] = { id = NEW_WORKTREE, title = "New worktree…", icon = "plus" }
  for i, tree in ipairs(trees) do
    -- The first entry is the checkout that CURRENT already names.
    if i > 1 and not tree.prunable then
      rows[#rows + 1] = {
        id = tree.path,
        title = tree.branch or basename(tree.path),
        subtitle = short(tree.path),
        icon = "branch",
      }
    end
  end
  local last = load_state().last[project]
  if last ~= nil then
    for i, row in ipairs(rows) do
      if row.id == last and i > 1 then
        table.remove(rows, i)
        table.insert(rows, 1, row)
        break
      end
    end
  end
  return rows, trees
end

-- base_rows returns the rows that say what a new branch starts from.
local function base_rows(project)
  local rows, seen = {}, {}
  local function add(ref, title, subtitle)
    if ref ~= nil and not seen[ref] then
      seen[ref] = true
      rows[#rows + 1] = { id = ref, title = title or ref, subtitle = subtitle, icon = "branch" }
    end
  end
  local branch = current_branch(project)
  if branch then add(branch, branch, "current branch") else add("HEAD", "HEAD", "detached") end
  -- origin's default branch, so a worktree can start from the remote's
  -- latest instead of a stale local branch.
  add(remote_default(project), nil, "remote default")
  for _, name in ipairs(local_branches(project)) do add(name) end
  return rows
end

-- add_worktree makes a worktree of project for branch, starting from base
-- when the branch is new. It returns the folder, or nil and a message.
local function add_worktree(project, branch, base)
  -- A branch name may hold slashes; a folder name may not.
  local folder = branch:gsub("[/\\:]", "-")
  local dir = worktrees_dir() .. "/" .. basename(project) .. "/" .. folder
  local exists = git(project, "rev-parse", "--verify", "--quiet", "refs/heads/" .. branch)
  local _, err
  if exists then
    _, err = git(project, "worktree", "add", dir, branch)
  else
    _, err = git(project, "worktree", "add", "-b", branch, dir, base or "HEAD")
  end
  if err ~= nil then return nil, err end
  return dir
end

---------------------------------------------------------------------------
-- The action
---------------------------------------------------------------------------

-- fail raises a one-line error that names the action.
local function fail(message)
  error("new_project_session: " .. tostring(message), 0)
end

-- run is the body of New Session in Project…
local function run(ctx)
  -- The projects are on this server's machine. A session on another host
  -- would start in a folder that may not exist there.
  if ctx ~= nil and ctx.server ~= nil then
    fail("the session is on " .. ctx.server .. ", and the projects are here")
  end
  -- stop ends the action. A person who cancels is not worth a log line.
  local function stop(why)
    if why ~= "cancelled" then rex.log("warn", "new_project_session: " .. tostring(why)) end
  end

  -- 1. The project.
  local project, why = rex.ui.pick{
    title = "New session",
    placeholder = "Choose a project",
    items = project_rows(),
  }
  if project == nil then return stop(why) end
  if project == ADD_PROJECT then
    project, why = add_project()
    if project == nil then return stop(why) end
  end
  local name = basename(project)

  -- 2. The checkout.
  local rows, trees = checkout_rows(project)
  local choice
  choice, why = rex.ui.pick{
    title = name,
    placeholder = "Choose where to work",
    items = rows,
  }
  if choice == nil then return stop(why) end

  local dir, label = project, name
  if choice == NEW_WORKTREE then
    -- 3. The branch, then what it starts from.
    local branch
    branch, why = rex.ui.input{
      title = "New worktree in " .. name,
      placeholder = "Branch name",
      confirm = "Create worktree",
    }
    if branch == nil then return stop(why) end
    branch = trim(branch)
    if branch == "" then return end
    if not valid_branch_name(project, branch) then
      return stop("not a valid branch name: " .. branch)
    end
    -- An existing branch needs no base.
    local base
    if git(project, "rev-parse", "--verify", "--quiet", "refs/heads/" .. branch) == nil then
      base, why = rex.ui.pick{
        title = "Start " .. branch .. " from",
        placeholder = "Choose a base",
        items = base_rows(project),
      }
      if base == nil then return stop(why) end
    end
    local err
    dir, err = add_worktree(project, branch, base)
    if dir == nil then fail(err) end
    label = name .. " · " .. branch
  elseif choice ~= CURRENT then
    dir = choice
    for _, tree in ipairs(trees or {}) do
      if tree.path == choice then
        label = name .. " · " .. (tree.branch or basename(choice))
      end
    end
  end

  -- Remember the choice. A new worktree is remembered as that worktree.
  -- Git may spell the folder differently from the path made here (a symlink
  -- such as /tmp), and the picker's rows use git's spelling, so look the new
  -- worktree up by its branch.
  local remembered = choice
  if choice == NEW_WORKTREE then
    remembered = dir
    for _, tree in ipairs(worktrees(project) or {}) do
      if tree.branch ~= nil and label == name .. " · " .. tree.branch then
        remembered = tree.path
      end
    end
  end
  load_state().last[project] = remembered
  save_state()

  -- A window in the API is a tab in the app.
  local session, failed = rex.call("session.create", {
    label = label,
    initial_windows = { {
      window_label = "shell",
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = { cwd = dir },
      },
    } },
  })
  if session == nil then error(failed, 0) end

  -- Creating a session does not show it. Ask the app to switch to it.
  rex.client.queue("session.select", { session_id = session.session_id })
end

-- remove_run is the body of Remove Project from List….
local function remove_run()
  local s = load_state()
  if #s.projects == 0 then return end
  local items = {}
  for _, p in ipairs(s.projects) do
    items[#items + 1] = { id = p, title = basename(p), subtitle = short(p), icon = "folder" }
  end
  local project = rex.ui.pick{
    title = "Remove project",
    placeholder = "Choose a project to forget (its folder stays)",
    items = items,
  }
  if project == nil then return end
  for i, p in ipairs(s.projects) do
    if p == project then table.remove(s.projects, i); break end
  end
  s.last[project] = nil
  save_state()
end

rex.action{
  name = "new_project_session",
  title = "New Session in Project…",
  description = "Choose a project, then a checkout or a new worktree, and start a session there",
  category = "Projects",
  keywords = "worktree branch repository folder thread add project",
  run = run,
}

rex.action{
  name = "remove_project",
  title = "Remove Project from List…",
  description = "Forget a project that was added to the New Session picker",
  category = "Projects",
  keywords = "forget delete project list",
  run = remove_run,
}

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------

-- bind_key moves the key for New Session in Project… to key, or removes it
-- for false.
local function bind_key(key)
  -- Removing a binding works only while the file loads, which is when setup
  -- runs. pcall keeps a refusal from stopping the rest of init.lua.
  if bound_key ~= nil then pcall(rex.unbind, bound_key) end
  bound_key = nil
  if key then
    rex.bind(key, "new_project_session")
    bound_key = key
  end
end

-- M.setup changes the settings it is given and leaves the rest as they were.
function M.setup(opts)
  opts = opts or {}
  if opts.worktrees ~= nil then config.worktrees = opts.worktrees end
  if opts.roots ~= nil then config.roots = opts.roots end
  if opts.state_file ~= nil then config.state_file = opts.state_file; state = nil end
  if opts.key ~= nil then bind_key(opts.key) end
  return M
end

bind_key(config.key)

-- Pure helpers, for the tests in test/.
M._internal = {
  expand = expand, short = short, basename = basename, slashes = slashes,
  load_state = load_state, save_state = save_state, worktrees = worktrees,
  checkout_rows = checkout_rows, base_rows = base_rows, add_worktree = add_worktree,
  project_rows = project_rows, valid_branch_name = valid_branch_name,
  run = run, config = config, subfolders = subfolders, parent_of = parent_of, is_folder = is_folder,
  reset = function() state = nil end,
}

return M
