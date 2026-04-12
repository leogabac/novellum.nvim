# novellum.nvim
A neovim plugin for the [novellum](https://github.com/leogabac/novellum) CLI.

Novellum is a CLI linked LaTeX note system for research logbooks, that is, a wannabe Obsidian for LaTeX enthusiasts.

# Status

> [!NOTE]
> This project is still early in development.
> If you have ideas, open an _issue_.

The first implementation is being built around:

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
* without arguments, it prompts for stitch mode first

Interactive stitch modes:

* selected notes via `mini.pick`
* all notes
* one note category

For selected-note stitching inside `mini.pick`, `<CR>` stitches the current
note and `<M-CR>` stitches the marked notes. The command then prompts for title
and optional output path.

## Completion

The plugin installs buffer-local `omnifunc` completion for `\nvlink{}` targets
inside Novellum TeX workspaces.

If `blink.cmp` is available, the plugin also tries to enable blink's `omni`
provider for `tex` and `plaintex` so the same completion source shows up in the
normal completion menu.

## Development Note

`setup()` accepts `command` as either a string or a list. That makes local
development easier when `novellum` is not installed globally yet. For example:

```lua
require("novellum").setup({
  command = { "python", "-m", "novellum.cli" },
})
```
