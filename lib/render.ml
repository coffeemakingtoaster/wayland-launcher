open Tsdl

let preflight_check () =
  match Sdl.init Sdl.Init.(video + events) with
  | Error (`Msg e) -> Error (`Msg e)
  | Ok () -> Ok ()

let setup () =
  match Sdl.create_window_and_renderer ~w:800 ~h:600 Sdl.Window.opengl with
  | Error (`Msg e) -> Error e
  | Ok (window, renderer) -> (
      match Font.create renderer with
      | Ok font -> Ok (window, renderer, font)
      | Error e -> Error e)

let tick ~renderer ~font () =
  (* Draw *)
  let res = Sdl.set_render_draw_color renderer 24 24 32 255 in
  Result.iter_error (fun (`Msg e) -> Sdl.log "Draw color error: %s" e) res;
  Sdl.render_clear renderer |> ignore;
  (* Debug text *)
  Font.draw_text_color font renderer ~x:8 ~y:8 ~r:255 ~g:200 ~b:80
    "WAYLAND LAUNCHER [DEBUG]";
  Font.draw_text_color font renderer ~x:8 ~y:(600 - 16) ~r:120 ~g:180 ~b:120
    "ESC TO QUIT";
  Sdl.render_present renderer;
  Sdl.delay 16l

let teardown ~window ~font () =
  Font.destroy font;
  Sdl.destroy_window window;
  Sdl.quit ()
