# Repository maintenance guide

This repository owns a portable interactive Zsh setup for macOS and
Debian/Ubuntu. It keeps one hand-maintained `.zshrc`, installs it by symlink,
and lets Antigen fetch Oh My Zsh and third-party plugins. Read this file,
`README.md`, `.zshrc`, and `install.sh` before changing behavior.

## 1. Repository shape

- `.zshrc`: the only tracked interactive-shell configuration and the source
  linked to the user's Zsh startup file.
- `install.sh`: POSIX `sh` installer; package installation is opt-in through
  `--packages`.
- `README.md`: user-facing installation, usage, package, and maintenance docs.
- `.gitignore`: excludes editor files and generated Zsh cache/compiled files.
- `.editorconfig`: defines UTF-8, LF, final newline, and two-space indentation.
- `.gitattributes`: normalizes tracked text to LF.
- `AGENTS.md`: durable decisions, failure history, and acceptance criteria.

There is no vendored Oh My Zsh tree, plugin lockfile, CI workflow, or automated
test suite. Antigen downloads current upstream code. Treat `antigen update` as
an external dependency update that requires explicit validation.

## 2. Non-negotiable design

- Keep exactly one tracked, hand-maintained `.zshrc`. Do not split it into
  `.zprofile`, `.zshenv`, plugin fragments, generated startup files, or a
  vendored Oh My Zsh copy. The untracked `~/.zsh_secrets` file is the only
  supported machine-local values file. Zsh's role for each startup file is
  defined in its
  [official startup-file reference](https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files).
- Preserve the prompt unless the user explicitly asks to change it:
  `antigen theme steeef` and
  `RPROMPT="[%D{%f/%m/%y} | %D{%L:%M:%S}]"`. The theme comes from the
  [official Oh My Zsh theme](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/steeef.zsh-theme).
- Keep optional integrations guarded by command, platform, or readable-file
  checks. A missing optional tool must not make startup noisy or fail.
- Keep the terminal-provided `TERM`; do not hard-code or rewrite it.
- Initialize Zsh completion exactly once. Duplicate `compinit` calls are a
  correctness and startup-time regression.
- Keep Atuin, fzf, and zoxide as the only history search, fuzzy widget, and
  directory-jump owners. Do not add overlapping history-substring, fuzzy
  search, or directory-jump plugins.
- Keep credentials and machine-specific values out of tracked files.
- The remote currently has exactly four reachable commits by explicit owner
  request. Do not rewrite or force-push history unless the current task
  explicitly authorizes it. If a future authorized change must preserve that
  count, amend the tip and use `--force-with-lease` against a freshly verified
  remote SHA.

## 3. Installer contract

`install.sh` accepts no arguments or exactly `--packages`. `-h` and `--help`
print usage; any other argument exits with status 2. It uses `set -eu` and must
remain valid POSIX `sh`.

Without `--packages`, the installer must not change system packages. It:

1. resolves the repository's real directory and the target
   `${ZDOTDIR:-$HOME}/.zshrc`;
2. checks for Zsh and Git and runs `zsh -n` on the repository `.zshrc`;
3. finds Antigen in supported Homebrew/system locations or clones it to the
   user data directory;
4. backs up a different existing target with a timestamp, then links the
   repository `.zshrc`;
5. removes the target's stale `.zwc` file;
6. creates `~/.zsh_secrets` with mode `0600` when absent and restores that mode
   on every run; and
7. reports missing optional commands without failing.

It never changes the login shell. It prints `scope:`, `ok:`, `summary:`, and
`next:` messages so the operator can see its mutations.

With `--packages`, package installation happens first:

### macOS

Homebrew is required. The installer calls `brew install` for:

```text
antigen atuin btop curl fzf git htop jq ncdu pyenv ripgrep rsync
tmux tree uv wget zoxide
```

This follows Homebrew's documented
[`brew install` contract](https://docs.brew.sh/Manpage#install-options-formulacask-).
Docker Desktop/Engine is deliberately out of scope; Docker shell integration
activates only when `docker` already exists. macOS supplies the remaining base
utilities named in `README.md`.

### Debian and Ubuntu

An `apt-get` host is required. Through root or `sudo`, the installer runs
`apt-get update` and installs with `--no-install-recommends`:

```text
btop ca-certificates curl dnsutils fzf git htop jq less locales lsof
ncdu ripgrep rsync tar time tmux tree unzip wget zip zsh
```

The package flow follows the Debian
[`apt-get` manual](https://manpages.debian.org/stable/apt/apt-get.8.en.html).
It then creates `en_US.UTF-8` with
[`localedef`](https://manpages.debian.org/stable/manpages/localedef.1.en.html)
and selects it with
[`update-locale`](https://manpages.debian.org/stable/locales/update-locale.8.en.html).

Linux intentionally installs the latest releases of Atuin, uv, and zoxide
from their official installers, and clones or fast-forwards pyenv's `master`
branch. `ATUIN_NO_MODIFY_PATH=1` and `UV_NO_MODIFY_PATH=1` prevent those two
installers from editing shell files. See the official
[Atuin installation guide](https://docs.atuin.sh/main/guide/installation/),
[uv installer options](https://docs.astral.sh/uv/reference/installer/),
[zoxide installation guide](https://github.com/ajeetdsouza/zoxide#installation),
and [pyenv Git checkout guide](https://github.com/pyenv/pyenv#basic-github-checkout).
An existing non-Git `~/.pyenv` is an error; never overwrite it.

Changing either package list, supported platform, installer URL, or the
unpinned/latest policy changes the public contract. Update `README.md` in the
same change and retest both platform paths.

## 4. Plugin and integration inventory

Antigen uses the
[official Oh My Zsh repository](https://github.com/ohmyzsh/ohmyzsh) and the
[documented Antigen bundle model](https://github.com/zsh-users/antigen#usage).

- Core Oh My Zsh: `colored-man-pages`, `common-aliases`, `copyfile`,
  `copypath`, `extract`, `history`, `git`, `iterm2`, and `sudo` are always
  declared. Individual plugins retain their upstream behavior.
- External core: `zsh-users/zsh-completions` provides extra completions;
  `zsh-users/zsh-autosuggestions` provides inline suggestions.
- Homebrew: `brew` loads only when its command exists.
- macOS: `macos` loads only for `darwin*`.
- Debian/Ubuntu: `debian` loads only on Linux with `/etc/debian_version`.
- systemd: `systemd` loads only on Linux with `systemctl`.
- Highlighting: `zdharma-continuum/fast-syntax-highlighting` is declared after
  Atuin initialization so it sees the final history widgets.
- Late Oh My Zsh: `uv`, `docker`, `docker-compose`, `gh`, and `kubectl` are
  sourced after completion initialization and only when their commands exist.
- Runtime tools: pyenv, fzf, and zoxide initialize only when installed; fzf
  also requires a TTY.
- File/tool adapters: Docker, Bun, Google Cloud SDK, Android SDK, and iTerm2
  paths are guarded by platform and readable/executable checks.

Do not move the late Oh My Zsh plugins into the main Antigen heredoc. Their
upstream implementations generate completion files at startup: see
[uv](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/uv/uv.plugin.zsh),
[docker](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker/docker.plugin.zsh),
[gh](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/gh/gh.plugin.zsh),
and [kubectl](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/kubectl/kubectl.plugin.zsh).
The Docker Compose plugin deliberately falls back from legacy
`docker-compose` to Compose v2's `docker compose`; see its
[upstream source](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker-compose/docker-compose.plugin.zsh).

## 5. Required startup order

Ordering is part of the design. Preserve this sequence:

1. Deduplicate `path`/`fpath`; define `ZSH_CACHE_DIR` and
   `ANTIGEN_COMPDUMP`; create `ZSH_CACHE_DIR/completions`; prepend it to
   `fpath`. Zsh's `compinit` scans completion functions through `fpath` and
   can reuse a named dump file, as documented in the
   [Zsh completion initialization manual](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Initialization).
2. Discover Homebrew and Antigen. Before sourcing Antigen, resolve the real
   repository `.zshrc` and invalidate `~/.antigen/init.zsh` when that source is
   newer. Antigen's automatic cache checking watches configured files and
   stores its bundle cache in `init.zsh`; see
   [Antigen configuration](https://github.com/zsh-users/antigen/wiki/Configuration)
   and its [cache boot source](https://github.com/zsh-users/antigen/blob/master/src/boot.zsh).
   The explicit real-file check is required because the installed startup
   path is a symlink whose own timestamp does not change after `git pull`.
3. Set basic environment, load `~/.zsh_secrets`, add guarded user/tool paths,
   and register Android, Google Cloud, Docker, and Bun completion paths.
4. Define completion styles and `ZSH_AUTOSUGGEST_STRATEGY`, then declare the
   core, external, and platform Antigen bundles and the unchanged prompt.
5. Initialize Atuin with `atuin init zsh --disable-ai` before declaring fast
   syntax highlighting. Atuin installs hooks and ZLE bindings
   ([Atuin init reference](https://docs.atuin.sh/main/reference/init/)); the
   highlighter must load after those widgets so it can wrap the active widget
   set. See the
   [fast-syntax-highlighting source](https://github.com/zdharma-continuum/fast-syntax-highlighting).
   This is a source-derived repository constraint, not a universal upstream
   ordering promise.
6. Run `antigen apply`, then call `_antigen_compinit` only when Antigen's
   cached loader defined it. Otherwise call `compinit -i` only when `compdef`
   is still absent. On a cold load, Antigen already ran `compinit`; on a cached
   load, `_antigen_compinit` performs the deferred single call. Never add an
   unconditional second `compinit`.
7. Source the Google Cloud completion adapter and guarded late Oh My Zsh
   plugins after `compinit`. This prevents completion discovery from racing
   the plugins' background/process-substitution completion generation.
8. Set native history options, then initialize pyenv, fzf, and zoxide. zoxide
   explicitly requires Zsh initialization after `compinit`; see its
   [shell setup](https://github.com/ajeetdsouza/zoxide/blob/main/README.md#step-2-setup-zoxide-on-your-shell).
   Prefer `fzf --zsh`; retain the packaged-script fallback because older
   Debian/Ubuntu fzf releases lack that flag. The current fzf integration and
   default `Ctrl-R`, `Ctrl-T`, and `Alt-C` widgets are documented
   [upstream](https://github.com/junegunn/fzf#setting-up-shell-integration).
9. Rebind Atuin last. fzf also owns `Ctrl-R`, so the final block restores
   Atuin's widgets for `Ctrl-R`, vi `/`, and both common up-arrow escape
   sequences. Up-arrow remains global prefix search; `Ctrl-R` remains global
   fuzzy search. Atuin documents its Zsh widgets and custom binding model in
   the [key-binding guide](https://docs.atuin.sh/main/configuration/key-binding/).

## 6. History and Atuin safeguards

Native Zsh history remains a fallback at `~/.zsh_history`. Keep the existing
limits and options: append rather than replace, record timestamp and duration,
drop older duplicates first, ignore immediate duplicates and leading-space
commands, reduce blanks, and verify expanded history before execution.
`share_history` and `inc_append_history` stay disabled because Atuin handles
interactive cross-session search and `inc_append_history_time` records after
execution. These options are defined in the
[official Zsh history option reference](https://zsh.sourceforge.io/Doc/Release/Options.html#History).

Atuin safeguards are part of the contract:

- Keep `--disable-ai` and `ATUIN_LOG=error` in shell initialization.
- A leading space excludes a one-off command from both native history and
  Atuin. Keep Atuin's default secret filter enabled, but treat it only as a
  safety net; add local `history_filter` or `cwd_filter` rules for sensitive
  patterns. See [Excluding commands](https://docs.atuin.sh/main/guide/excluding-commands/).
- Import an existing history file only after a private backup, and import the
  raw Zsh history file, never formatted output from `history`/`fc`.
  `HISTFILE=/path/to/copy atuin import zsh` leaves the source file intact
  ([Atuin import reference](https://docs.atuin.sh/main/reference/import/)).
- Sync is optional. Do not register, log in, reveal a key, change a server, or
  enable sync without explicit authorization. Atuin sync is end-to-end
  encrypted, but its key is unrecoverable and must remain private
  ([sync guide](https://docs.atuin.sh/main/guide/sync/)).
- Use `atuin doctor` for diagnostics and `atuin store verify` for record
  decryption checks. Do not run destructive store operations without a fresh
  backup and explicit scope; the
  [store reference](https://docs.atuin.sh/main/reference/store/) marks purge,
  rekey, and forced push/pull as dangerous.
- Never print command text while auditing history. Report integrity and
  aggregate counts only.

## 7. Proven failure modes and retained fixes

1. Plugin changes did not appear after a repository pull.
   - Cause: Antigen watched the stable `~/.zshrc` symlink instead of the
     updated target timestamp.
   - Fix: resolve `%N` to the real source before sourcing Antigen. Remove its
     bundle cache only when the target is newer.
2. Dynamic completions failed or startup emitted missing-file errors.
   - Cause: `ZSH_CACHE_DIR/completions` did not exist before plugins wrote it.
   - Fix: create the directory and prepend it to `fpath` before plugins load.
3. First startup intermittently raced completion generation.
   - Cause: dynamic plugins generated completion files in background jobs
     while completion initialization scanned the same directory. See the
     [inspected upstream revision](https://github.com/ohmyzsh/ohmyzsh/blob/4b657407/plugins/docker/docker.plugin.zsh).
   - Fix: initialize completion once, then source `uv`, `docker`,
     `docker-compose`, `gh`, and `kubectl`. Cold and warm startup must be silent.
4. Linux shells printed locale warnings.
   - Cause: packages existed without a generated and selected UTF-8 locale.
   - Fix: install `locales`, run `localedef`, then `update-locale`.
5. Imported commands contained human-readable date tails.
   - Cause: formatted history display was treated as command input.
   - Fix: migrate from a backed-up raw history copy, sanitize the copy before
     import, and require zero malformed date-tail records afterward.
6. Imported history contained literal `_style=''` records.
   - Cause: legacy completion/history noise was imported as commands.
   - Fix: remove only those exact records from staged migration data or a
     backed-up database workflow, then require a zero count.
7. Atuin installed successfully but was not found.
   - Cause: its default installer directory was absent from `PATH`.
   - Fix: keep `~/.atuin/bin` in guarded `user_paths`.
8. fzf widgets were absent on older Debian/Ubuntu releases.
   - Cause: packaged fzf predated `fzf --zsh`.
   - Fix: probe the flag, then source packaged key-binding/completion scripts.

Do not encode one machine's history-cleanup script in this repository. History
formats and database schemas can change; inspect the backup and current Atuin
documentation, stage transformations on copies, and prove zero bad records
without exposing command text.

## 8. Validation and acceptance

Run these checks for every change:

```sh
git diff --check
sh -n install.sh
zsh -n .zshrc
./install.sh --help
```

For `.zshrc`, plugin, or ordering changes, also run:

```sh
startup_output="$(zsh -lic exit 2>&1)"
test -z "$startup_output"
zsh -lic 'autoload -Uz compaudit; compaudit'
zsh -lic 'bindkey -M emacs "^R"; bindkey -M emacs "^[[A"; bindkey -M emacs "^[OA"'
atuin doctor
```

Do not use `zsh -x`, `set -x`, or environment dumps to diagnose startup: the
configuration sources `~/.zsh_secrets`, and tracing can disclose credentials.
Run `atuin store verify` when history storage, import, or sync behavior changes.

For installer or package changes, test a fresh supported macOS environment and
a clean Debian/Ubuntu container or VM. Running `--packages` mutates the host;
do not use it during a read-only review. Acceptance requires:

- config-only mode changes no system packages;
- each documented package command exists after package mode;
- Linux `locale` and a fresh login shell emit no locale warning;
- a pre-existing unrelated `.zshrc` is backed up, the new target links to this
  repository, and a second run does not create another backup;
- `~/.zsh_secrets` has mode `0600`;
- cold and warm interactive startup both exit successfully and print nothing;
- missing optional commands still permit a silent successful startup;
- `compdef` exists, `compaudit` reports no insecure paths, and completion is
  initialized once;
- the prompt and right prompt exactly match section 2;
- Atuin owns final `Ctrl-R` and up-arrow bindings while fzf retains its file
  and directory widgets;
- Atuin diagnostics pass, and any history migration has a backup, valid store,
  zero malformed date tails, and zero `_style=''` command records; and
- warm startup shows no material regression against a before-change baseline.

## 9. Safe continuation workflow

1. Start with `git status --short --branch`, `git diff`, and the tracked files
   in section 1. Preserve unrelated work.
2. Confirm whether the checkout's `.zshrc` is the live symlink target. If it
   is, every edit affects newly opened shells immediately; validate syntax
   before starting one.
3. Make the smallest scoped change. Preserve the one-file design, exact
   prompt, guards, and startup order unless the request changes that contract.
4. Check current primary documentation and upstream source before changing an
   integration. Antigen dependencies are unpinned and may have drifted.
5. Keep behavior, package lists, examples, and sources synchronized in
   `README.md`; keep durable maintenance decisions synchronized here.
6. Run the proportionate validation in section 8. Record results, not private
   command history or machine details.
7. Do not run package installers, `antigen update`, Atuin account/store
   mutations, `chsh`, or remote deployment commands unless the task explicitly
   authorizes that mutation.
8. Do not commit or push unless explicitly requested. Use the existing Git
   identity and task-based messages; do not add generated-by or co-author
   attribution.

## 10. Security and privacy

- Never commit or document secrets, tokens, keys, history contents, Atuin
  databases, `.zsh_secrets`, completion caches, server addresses, hostnames,
  account identifiers, or machine-specific absolute checkout paths.
- Use `$HOME`, `~`, repository-relative paths, and neutral placeholders in
  documentation and tests.
- Do not read or display private history to prove a migration. Work from a
  restricted backup, validate aggregate counts, and keep backups outside Git.
- Never pass passwords or encryption keys on a command line. Use an
  interactive prompt or protected input supported by the tool.
- Review changes to downloaded installer URLs and TLS flags carefully. Do not
  weaken HTTPS verification or pipe a new unreviewed endpoint into a shell.
- Generated files under `~/.antigen`, `~/.cache/zsh`, and Atuin's config/data
  directories are runtime state, not repository source. Do not add them.

## 11. Verification baseline

The 2026-08-30 acceptance run established this baseline without storing
machine identifiers or history content:

- On arm64 macOS, `/bin/zsh` used this repository through the installed
  symlink. Zsh 5.9.2 passed syntax and silent-start checks; seven warm starts
  took 0.23–0.27 seconds. `compaudit` reported no insecure paths. Docker, uv,
  uvx, gh, and kubectl completions resolved, and Atuin/fzf key ownership
  matched section 5.
- The local Atuin database passed SQLite integrity checks and contained no
  exact `_style=''` noise records. No command text was printed during the
  audit.
- A clean arm64 Debian 12 container ran `install.sh --packages` from zero,
  installed every documented command, generated `en_US.UTF-8`, linked the
  repository config, and exposed uv/uvx completion in the following shell.
- A private x86_64 Debian 12 consumer validated the same config for privileged
  and non-privileged users. Warm Zsh startup was about 0.11 seconds, Bash and
  Zsh emitted no locale warning, and migrated Atuin stores passed integrity
  and malformed-date-tail checks. Keep private host and automation details out
  of this public repository.
- A fresh clone exposed one `master` branch, the seven files in section 1, and
  exactly four reachable commits.

Update this baseline only after rerunning the corresponding checks. Keep
ephemeral counts, addresses, private paths, and credentials out of it.
