# novellum.nvim

Neovim integration for the
[novellum](https://github.com/leogabac/novellum) CLI.

`novellum.nvim` is a thin Neovim client for a linked LaTeX note workflow.
It keeps `novellum` as the source of truth for workspace operations and note
data, while providing editor-native lookup, stitching, compilation, and
completion inside TeX buffers.

## Status

`novellum.nvim` is approaching a first pre-release.

The current implementation is already usable for the core workflow, but the
plugin is still evolving and the command surface may continue to tighten before
the first tagged release.

Current focus:

* fast note lookup
* stitching and compilation from inside Neovim
* `mini.pick` integration for note selection
* completion for `\nvlink{}` targets

## Features

* Note lookup with `mini.pick` previews
* Search and direct note opening by ID or alias
* Stitched document generation through `novellum stitch`
* PDF compilation and opening through the existing CLI
* Buffer-local completion for `\nvlink{}` targets in Novellum TeX workspaces
* Blink-compatible completion via the built-in `omni` provider
* Workspace-aware caching for note lookup and completion
* Health checks and refresh commands

## Requirements

Minimum requirements:

* Neovim `0.12+`
* a working `novellum` CLI installation or command override

Recommended integrations:

* [`mini.pick`](https://github.com/echasnovski/mini.pick) for the best picker UX
* [`blink.cmp`](https://github.com/Saghen/blink.cmp) if you want the completion
  source to show up in the regular completion menu
* [`nvim-notify`](https://github.com/rcarriga/nvim-notify) if you want
  persistent watch-mode notifications instead of plain transient `vim.notify`
  messages; `novellum.nvim` will use it directly when installed

The plugin works without `mini.pick`, but falls back to `vim.ui.select()` and
loses the richer picker experience.

## Installation

### `vim.pack`

```lua
vim.pack.add({
  { src = "https://github.com/leogabac/novellum.nvim" },
}, { load = true })
```

### Setup

```lua
require("novellum").setup({})
```

If `novellum` is not on your `PATH`, configure an explicit command:

```lua
require("novellum").setup({
  command = {
    "env",
    "PYTHONPATH=/path/to/novellum/src",
    "python",
    "-m",
    "novellum.cli",
  },
})
```

`command` may be either a string or a list.

## Commands

The current command surface includes:

* `:NovellumFind`
* `:NovellumSearch [query]`
* `:NovellumOpenNote [reference]`
* `:NovellumStitch [args...]`
* `:NovellumStitchCurrent`
* `:NovellumCompile [target]`
* `:NovellumBuildNow`
* `:NovellumBuildStart`
* `:NovellumBuildStop`
* `:NovellumBuildStatus`
* `:NovellumOpen [target]`
* `:NovellumRefresh`
* `:NovellumHealth`

Some relevant comments:

* `NovellumCompile` currently defaults to the `stitched` target.

Neovim help is available in [doc/novellum.txt](doc/novellum.txt).

## Stitch Workflow

`NovellumStitch` supports two usage styles:

* direct forwarding to `novellum stitch` when you pass arguments
* interactive mode when you call it with no arguments

`NovellumStitchCurrent` is the fastest path when you are editing one note and
want to stitch that note immediately.

Interactive mode currently supports:

* selected notes
* all notes
* one category at a time

When `mini.pick` is available:

* `<CR>` stitches the current note
* `<C-b>` marks notes in the stitch picker
* `<M-CR>` stitches marked notes

`<C-m>` was considered for marking, but in terminal Neovim it usually collapses
to the same input as `<CR>`, so it is not reliable as a separate picker action.
For the stitch picker specifically, `novellum.nvim` gives `<C-b>` priority over
mini.pick's default preview-page-up mapping.

The interactive stitch flow then prompts for:

* document title
* optional output path

Every successful stitch also records a build session in the plugin. That lets
you rebuild the same stitched selection without stepping through the picker
again.

## Rebuild Workflow

The plugin now keeps track of the most recent stitch request.

Available commands:

* `:NovellumBuildNow` reruns the last stitch session and then compiles it
* `:NovellumBuildStart` enables auto rebuild on save
* `:NovellumBuildStop` disables auto rebuild on save
* `:NovellumBuildStatus` reports the current build-session state

Auto rebuild currently watches note saves inside the same Novellum workspace,
debounces repeated writes, and avoids overlapping builds.

With `nvim-notify`, watch mode shows a persistent notification only while a
rebuild is running or queued. Idle watch mode is kept quiet, and rebuilds
suppress the regular stitch/compile success messages.

## Completion

Inside a Novellum TeX workspace, the plugin installs a buffer-local `omnifunc`
for `\nvlink{}` targets.

Supported forms:

* `\nvlink{target}`
* `\nvlink[label]{target}`

If `blink.cmp` is installed, `novellum.nvim` also tries to expose the same
completion source through blink's `omni` provider for `tex` and `plaintex`
buffers.

## Scope

`novellum.nvim` is intentionally narrow.

It does not try to replace:

* VimTeX
* your LaTeX toolchain
* the `novellum` CLI itself

The plugin is there to make the existing workflow easier to drive from inside
Neovim, not to duplicate the full Novellum feature set in Lua.

## Roadmap

Near-term follow-up work includes:

* add autocompletion for references
* link and backlink browsing
* broken-link diagnostics inside Neovim
* better graph-aware note navigation
* further cleanup of the stitch interaction flow

## License

[MIT](LICENSE)
