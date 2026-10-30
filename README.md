# dotfiles

My Neovim and Zellij setup, plus one helper script. Each folder is a [GNU Stow](https://www.gnu.org/software/stow/) package. Stow links the files into your home directory, so the repo stays the single source of truth.

These steps are for a fresh Debian or Ubuntu machine. On other systems, install the same tools with your own package manager.

## What is in here

| Package | Links to | What it is |
| --- | --- | --- |
| `nvim` | `~/.config/nvim` | [LazyVim](https://www.lazyvim.org/) config with the gruvbox theme, Diffview, and a file preview on `<leader>cp` |
| `zellij` | `~/.config/zellij` | Zellij config (locked mode by default, gruvbox-dark) and a `watcher` layout: nvim and lazygit side by side |
| `bin` | `~/.local/bin` | `copy-to-clipboard`, used by Zellij to copy a mouse selection to the system clipboard |

## Install from zero

### 1. Install the tools

```sh
sudo apt update
sudo apt install -y git stow curl build-essential ripgrep fd-find \
  nodejs npm xclip wl-clipboard chafa
```

What these are for:

- `git`, `stow`: clone the repo and link the files.
- `build-essential`, `ripgrep`, `fd-find`, `curl`: LazyVim needs a C compiler (to build Treesitter parsers), `rg` and `fd` (for search), and `curl`.
- `nodejs`, `npm`: needed by the markdown browser preview and the API-spec preview.
- `xclip`, `wl-clipboard`: clipboard tools. `copy-to-clipboard` uses `wl-copy` on Wayland and `xclip` on X11. Install both and it picks the right one.
- `chafa`: shows diagrams as pictures inside the terminal.

Debian installs `fd` under the name `fdfind`. Add a link so LazyVim finds it:

```sh
mkdir -p ~/.local/bin
ln -s "$(command -v fdfind)" ~/.local/bin/fd
```

Make sure `~/.local/bin` is on your `PATH`. Debian adds it at login when the folder exists, so log out and in again if `command -v copy-to-clipboard` finds nothing later.

### 2. Install Neovim 0.10 or newer

LazyVim needs a recent Neovim. The `apt` version is often too old, so download the official build:

```sh
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
nvim --version | head -1
```

On an ARM machine, use `nvim-linux-arm64.tar.gz` and the matching folder name.

### 3. Install Zellij and lazygit

Neither is in the default apt sources. Use the official release pages:

- Zellij: <https://zellij.dev/documentation/installation>. The quickest way is `cargo install --locked zellij`, or download the binary from the [releases page](https://github.com/zellij-org/zellij/releases) and put it in `~/.local/bin`.
- lazygit: <https://github.com/jesseduffield/lazygit#installation>. Download the binary from the [releases page](https://github.com/jesseduffield/lazygit/releases) and put it in `~/.local/bin`.

Check both work:

```sh
zellij --version
lazygit --version
```

### 4. Install a Nerd Font

The config uses icons that normal fonts do not have. Download a Nerd Font (for example JetBrainsMono) from <https://www.nerdfonts.com/font-downloads>, unzip it into `~/.local/share/fonts`, and run `fc-cache -f`. Then pick it in your terminal's profile settings.

### 5. Clone the repo

Clone it to `~/dotfiles`. Stow expects the repo to sit one level below your home directory.

```sh
git clone git@github.com:FMaged/dotfiles.git ~/dotfiles
```

If you have no SSH key on this machine yet, use HTTPS instead:

```sh
git clone https://github.com/FMaged/dotfiles.git ~/dotfiles
```

### 6. Link the configs with Stow

Move any existing configs out of the way first. Stow stops with an error if a real file is already in the target place.

```sh
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.config/zellij ~/.config/zellij.bak 2>/dev/null
```

Then link all three packages:

```sh
cd ~/dotfiles
stow nvim zellij bin
```

Check the links:

```sh
ls -l ~/.config/nvim ~/.config/zellij ~/.local/bin/copy-to-clipboard
```

Each one should point back into `~/dotfiles`.

### 7. Start Neovim once

```sh
nvim
```

On the first start, `lazy.nvim` installs itself and every plugin. This needs internet and takes a minute or two. When it finishes, quit with `:q` and start `nvim` again. Run `:checkhealth lazy` if something looks wrong.

The plugin versions are pinned in `nvim/.config/nvim/lazy-lock.json`, so you get the same versions I use. To install exactly those versions again, run `:Lazy restore`.

### 8. Start Zellij

```sh
zellij
```

To open the `watcher` layout (nvim on the left, lazygit on the right):

```sh
zellij --layout watcher
```

Zellij starts in **locked** mode, so keys go straight to your program. Press `Ctrl g` to unlock it and use Zellij's own keys.

## Optional tools

The file preview (`<leader>cp` in Neovim) works without these, but some file types need an extra tool:

| You want to preview | Install |
| --- | --- |
| OpenAPI / AsyncAPI specs in the browser | `npm install -g @scalar/cli` |
| draw.io diagrams, and Mermaid blocks as pictures | the [draw.io desktop app](https://github.com/jgraph/drawio-desktop/releases) (it must be available as the `drawio` command), plus `chafa` from step 1 |
| Markdown in the browser (`<leader>cP`) | `nodejs` and `npm` from step 1 |

Diagram previews only work inside Zellij.

If `npm install -g` fails with a permission error, set a user folder first: `npm config set prefix ~/.local`.

## Update later

```sh
cd ~/dotfiles
git pull
stow -R nvim zellij bin
```

Inside Neovim, run `:Lazy sync` to update the plugins.

## Remove the links

```sh
cd ~/dotfiles
stow -D nvim zellij bin
```

This only removes the links. Your files stay in `~/dotfiles`.

## Troubleshooting

- **Stow says "existing target is not owned by stow".** A real file or folder is in the way. Move it away (step 6) and run `stow` again.
- **Icons look like empty boxes.** Your terminal is not using a Nerd Font (step 4).
- **Mouse selection in Zellij does not reach the clipboard.** Run `command -v copy-to-clipboard`. If it prints nothing, `~/.local/bin` is not on your `PATH`. Also check that `wl-clipboard` or `xclip` is installed.
- **`fd` not found in Neovim.** Create the `fd` link from step 1.
