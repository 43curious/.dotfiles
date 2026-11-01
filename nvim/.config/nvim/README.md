# 💤 LazyVim

LazyVim starter defaults with the Evergarden (evergreen-style) theme outside Rex.

Inside Rex, Neovim uses its built-in `default` colorscheme with RGB colors disabled,
and Lualine uses its `16color` theme with the filename area inheriting Rex's default
foreground and background. Both use Rex's terminal palette, so changing
the Rex theme updates their colors immediately, including in an open Neovim.
Restart Neovim once after installing this configuration. No theme plugin or Rex
configuration is needed; Rex's `REX_BLOCK` environment variable or its `xterm-rex`
terminal type enables this mode. Mist highlights also use the terminal palette
and are restored after `:colorscheme` changes. Evergarden loads only when selected.

## Performance review

Reviewed on 2026-11-01 with Neovim 0.12.5 and the installed, locked plugins:

- Seven alternating runs of the previous and updated configurations with an
  attached 100×30 terminal UI reported roughly 61 ms median startup CPU time
  in both cases. Timings varied substantially; this is not a claim of an overall
  startup speedup or a measurement of typing latency.
- Mist previously scanned all 43 Markdown files in `~/notes` at every `VimEnter`.
  Direct measurements took about 10–24 ms. The index now builds on its first query
  or vault-note save. Opening code or a directory does not scan the notes vault.
  Five alternating runs with an attached UI measured median time from `VimEnter`
  to the next scheduled callback at 17.5 ms before and 6.7 ms after the change.
- Rex now loads 14 of 32 plugins after `VeryLazy`, instead of 15: Evergarden stays
  unloaded. LSP, completion, syntax parsing and other LazyVim features retain
  their existing loading triggers. The unused bufferline, Oil, explorer and
  animated scrolling remain disabled.

To inspect startup locally, run `nvim --startuptime /tmp/nvim-startup.log` and use
`:Lazy profile` for plugin costs. Headless startup alone omits UI-triggered plugins
and is not representative of a complete interactive launch.

The focused Mist check covers lazy initialization, the first agenda, saving before
the first query, incremental updates and explicit rebuilds. Run from the dotfiles root:

```sh
nvim --headless -u NONE -l nvim/.config/nvim/tests/mist_index.lua
```

Terminal palette behavior follows Neovim's [terminal UI color handling](https://neovim.io/doc/user/tui/).

See: https://www.lazyvim.org/
