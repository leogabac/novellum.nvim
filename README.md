# novellum.nvim
A neovim plugin for the novellum CLI

## Status

Work in progress. The first implementation is being built around:

* note lookup
* stitch and compile helpers
* `mini.pick` for selection
* blink-friendly completion via `omnifunc`

## Current Commands

The initial command surface now includes:

* `:NovellumFind`
* `:NovellumSearch [query]`
* `:NovellumOpenNote [reference]`
* `:NovellumStitch [args...]`
* `:NovellumCompile [target]`
* `:NovellumOpen [target]`
* `:NovellumRefresh`
* `:NovellumHealth`

## Stitch Workflow

`NovellumStitch` works in two modes:

* with arguments, it forwards them to `novellum stitch`
* without arguments, it opens a note picker

Inside `mini.pick`, `<CR>` stitches the current note and `<M-CR>` stitches the
marked notes.

## Development Note

`setup()` accepts `command` as either a string or a list. That makes local
development easier when `novellum` is not installed globally yet. For example:

```lua
require("novellum").setup({
  command = { "python", "-m", "novellum.cli" },
})
```

## Plan

The initial implementation plan lives in [docs/plan.md](docs/plan.md).
