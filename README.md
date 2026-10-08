# wayland-launcher

A launcher application built with [OCaml](https://ocaml.org) and
[tsdl](https://erratique.ch/software/tsdl) (thin SDL2 bindings).

## Requirements

- OCaml >= 4.08 and [opam](https://opam.ocaml.org)
- dune >= 3.0
- SDL2 (macOS: `brew install sdl2`, Debian: `apt install libsdl2-dev`)
- The `tsdl` opam package

Install OCaml dependencies:

```sh
opam install tsdl
```

## Build and run

```sh
dune build          # compile everything
dune exec bin/main.exe   # build (if needed) and run
dune clean          # remove _build
```

Press Escape or close the window to quit the demo.

## Project layout

```
dune-project    # dune language version + package metadata
bin/
  dune          # executable stanza
  main.ml       # entry point, SDL loop + debug overlay
lib/
  dune          # library stanza
  font.ml       # embedded 8x8 bitmap font (ASCII 32..126, no assets)
```

Adding another module later: drop `morestuff.ml` into `lib/` — dune
picks it up automatically; refer to it as `Launcher.Morestuff`. Add
new opam deps to `lib/dune`'s `(libraries ...)` line.

## Debug text rendering (lib/font.ml)

No tsdl-ttf needed for debug output. `Launcher.Font` bakes an embedded
8x8 pixel font atlas (ASCII 32..126) into an SDL texture at startup:

```ocaml
(* once, after creating the renderer *)
let font = match Launcher.Font.create renderer with
  | Ok f -> f
  | Error e -> Sdl.log "Font error: %s" e; exit 1

(* per frame *)
Launcher.Font.draw_text font renderer ~x:8 ~y:8 "FPS: 60"
Launcher.Font.draw_text_color font renderer ~x:8 ~y:24
  ~r:255 ~g:200 ~b:80 "warning"   (* tinted *)

(* on shutdown *)
Launcher.Font.destroy font
```

8 pixels per char, 9px advance, no wrapping/scrolling — keep lines
short and within window bounds. Swap for `tsdl-ttf` when you want
real fonts; the `draw_text ~x ~y` call sites map 1:1.

---

## Offline cheatsheet: dune

Dune is invoked as `dune <command>`; the configuration lives in plain
`dune` files (a tiny s-expression DSL), not in the `dune-project`.

### Everyday commands

| Command | What it does |
|---|---|
| `dune build` | Build everything incrementally |
| `dune build @all` | Same, but includes `@doc`, `@fmt` etc. aliases |
| `dune exec bin/main.exe` | Build and run the executable |
| `dune build @fmt` | Check formatting (auto-fix: `dune build @fmt --auto-promote`) |
| `dune runtest` | Run tests (`dune build @runtest` is equivalent) |
| `dune clean` | Delete `_build` |
| `dune top` | Print lines for `.ocamlinit` (for utop integration) |
| `dune build @doc` | Generate odoc HTML into `_doc/_html` |

### Executable + interactive

To get a REPL with your project's libraries loaded, create
`test/dune` with:

```lisp
(executable
 (name repl)
 (libraries tsdl))
```

plus a minimal `test/repl.ml`, then run `dune utop .` (needs the
`utop` opam package). Alternatively: `dune utop` from the project root
loads the libraries of whatever directory you're in.

### Stanza reference (what we use)

```lisp
(executable
 (name main)              ; file must be main.ml
 (public_name wayland-launcher) ; installed binary name, optional
 (libraries tsdl))        ; opam libs, space-separated for several
```

Other common stanzas, for when you grow the project:

- `(library (name launcher) (modules ...) (libraries tsdl))` — internal
  library; modules are referred to as `Launcher.foo`.
- `(tests (name test_launcher) (modules test_launcher) (libraries launcher))`
  in a `test/` directory; run via `dune runtest`, assertions use the
  `alcotest` opam package if you add it.
- `(rule (alias runtest) (action ...))` — custom test actions.
- Preprocess: `(preprocess (pps ppx_deriving.show))` if you ever use
  ppx.

### Gotchas

- Dune files have **no comments other than `;` line comments**.
- After creating a new `dune` file, nothing extra is needed — dune
  discovers files automatically; just rebuild.
- `(name foo)` requires `foo.ml` in the same directory.
- Build errors sometimes leave partial artifacts; `dune clean` then
  rebuild fixes confusing states.
- Foreign C stubs (if needed later): `(foreign_stubs (language c)
  (names foo))` with `foo.c` in the directory; tsdl already handles its
  own stubs.

## Offline cheatsheet: tsdl

The library defines a single module `Tsdl` exposing `Sdl`. Start files
with `open Tsdl` — then everything is `Sdl.something`. Full odoc docs
also live at https://erratique.ch/software/tsdl/doc/ (when online).

### Conventions to remember

- Integer types: `uint8`/`int16` = plain `int`, but **`uint32` = `int32`
  and `uint64` = `int64`** — so write `16l` for delay ticks, `255` for
  colors.
- Errors: most functions return `('a, [ `Msg of string ]) result`.
  Pattern-match `Error (`Msg e)`; the actual SDL error string is also
  available via `Sdl.get_error ()`.
- Events use **field accessors**, not variants: allocate one
  `Sdl.Event.create ()` event, poll into it, read fields with
  `Sdl.Event.get ev Sdl.Event.field_name`, and switch on
  `Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ)` which gives a
  variant like `` `Quit ``, `` `Key_down ``, `` `Mouse_motion ``...
- Flags combine with `Sdl.Init.(video + events)` — note that `Init`
  and `Window` flags are **different types**, don't mix them.

### Minimal event loop skeleton (this repo, `bin/main.ml`)

```ocaml
open Tsdl

let () =
  match Sdl.init Sdl.Init.(video + events) with
  | Error (`Msg e) -> Sdl.log "Init error: %s" e; exit 1
  | Ok () -> (
    match Sdl.create_window_and_renderer ~w:800 ~h:600 Sdl.Window.opengl with
    | Error (`Msg e) -> Sdl.log "Window error: %s" e; Sdl.quit (); exit 1
    | Ok (window, renderer) ->
      let ev = Sdl.Event.create () in
      let quit = ref false in
      while not !quit do
        while Sdl.poll_event (Some ev) do
          match Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ) with
          | `Quit -> quit := true
          | `Key_down when Sdl.Event.get ev Sdl.Event.keyboard_keycode
                          = Sdl.K.escape -> quit := true
          | _ -> ()
        done;
        (* draw here *)
        Sdl.render_present renderer;
        Sdl.delay 16l
      done;
      Sdl.destroy_window window;
      Sdl.quit ())
```

### Frequently needed functions

| Need | Call |
|---|---|
| Init subsystems | `Sdl.init Sdl.Init.(video + events)` |
| Window + renderer | `Sdl.create_window_and_renderer ~w ~h flags` |
| Window only | `Sdl.create_window "title" ~w ~h Sdl.Window.opengl` |
| Destroy | `Sdl.destroy_window window` |
| Poll event | `Sdl.poll_event (Some ev)` — bool, true = event read into `ev` |
| Event type | `Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ)` |
| Key pressed | field `Sdl.Event.keyboard_keycode`, compare against `Sdl.K.escape` etc. |
| Mouse pos | field `Sdl.Event.mouse_motion_x` / `_y` |
| Draw color | `Sdl.set_render_draw_color renderer r g b a` (all `int` 0..255) |
| Clear screen | `Sdl.render_clear renderer` (returns result, usually `Result.is_ok`-ignored) |
| Present | `Sdl.render_present renderer` |
| Frame delay | `Sdl.delay 16l` (int32 milliseconds) |
| Load texture | `Sdl.load_bmp "path.bmp"` — surfaces only; PNG needs `tsdl-image` |
| Render texture | `Sdl.render_copy ~src ~dst:rect renderer texture` (all args optional except renderer/texture) |
| Debug text | `Launcher.Font.draw_text font renderer ~x ~y "..."` (see above) |
| Blit surface | `Sdl.blit_surface ~src ~dst_rect ~dst ()` |
| Log/printf-debug | `Sdl.log "x = %d" 42` |
| Last SDL error | `Sdl.get_error ()` |
| Ticks since init | `Sdl.get_ticks64 ()` (int64) |

### Adding text later

tsdl is core-SDL only. For fonts add the opam package `tsdl-ttf`
(needs `brew install sdl2_ttf`), which gives a `Tsdl_ttf.Ttf` module:
`Ttf.init`, `Ttf.open_file "font.ttf" 24`, then
`Sdl.Render`... actually use `Ttf.render_utf8_solid font "text" color`
to get a surface, make a texture from it, and render-copy. Do this
when you're back online; the package name is all you need to remember.

## macOS note

SDL2 from Homebrew is actually `sdl2-compat` (an SDL2-compatible
implementation over SDL3). tsdl works against it because it links via
`pkg-config sdl2`, which is what `conf-sdl2` (and thus the `tsdl`
opam package) checks at install time.

## Git

`_build/` and `.merlin` are ignored; commit everything else
(`dune-project`, `bin/dune`, `bin/main.ml`, this README).