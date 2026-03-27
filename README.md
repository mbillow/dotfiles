# ~mbillow/.dotfiles

A simple repo with all of the things that make me feel at home.
Managed with [chezmoi](https://www.chezmoi.io/).

## Installation

Install [chezmoi](https://www.chezmoi.io/install/) if you don't have it:

```
brew install chezmoi
```

Then initialize and apply:

```
chezmoi init --apply mbillow/dotfiles
```

You'll be prompted for your git name, email, and whether this is a work machine.

## What's Included

- **Shell**: zsh with oh-my-zsh, spaceship-prompt, autosuggestions, syntax highlighting
- **Editor**: vim with onedark colorscheme and HCL syntax support
- **Terminal**: ghostty config with OneDark/OneLight themes
- **Multiplexer**: tmux with dotbar status theme
- **Git**: aliases, sane defaults, URL shorthands

## Updating

```
chezmoi update
```
