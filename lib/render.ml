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

let tick ~renderer ~font ~window ~(panel_list : Panel.render_panel list)
    ~(active_index : int) () =
  let window_width, window_height = Sdl.get_window_size window in
  let draw_panel ~(panel : Panel.render_panel) ~(index : int) () =
    if index = active_index then
      Sdl.set_render_draw_color renderer 255 0 0 255 |> Result.get_ok
    else Sdl.set_render_draw_color renderer 255 255 255 255 |> Result.get_ok;
    let rect =
      Sdl.Rect.create ~x:panel.x ~y:panel.y ~w:panel.width ~h:panel.height
    in
    Sdl.render_draw_rect renderer (Some rect) |> ignore;
    (*TODO: this should likely be handled properly*)
    Font.draw_text font renderer ~x:panel.x ~y:panel.y
      (Printf.sprintf "%d" index)
  in
  (* Draw *)
  Sdl.render_clear renderer |> ignore;
  List.mapi (fun i p -> draw_panel ~panel:p ~index:i ()) panel_list |> ignore;
  (* TODO: just slapping ignore everywhere seems like it would be an antipattern *)
  let res = Sdl.set_render_draw_color renderer 24 24 32 255 in
  Result.iter_error (fun (`Msg e) -> Sdl.log "Draw color error: %s" e) res;
  (* Debug text *)
  Font.draw_text_color font renderer ~x:8 ~y:8 ~r:255 ~g:200 ~b:80
    "WAYLAND LAUNCHER [DEBUG]";
  let now = Unix.localtime (Unix.time ()) in
  Font.draw_text font renderer ~x:(window_width - 175) ~y:(window_height - 16)
    (Printf.sprintf "Unix time %d:%d:%d" now.tm_hour now.tm_min now.tm_sec);
  Font.draw_text_color font renderer ~x:8 ~y:(window_height - 16) ~r:120 ~g:180
    ~b:120 "ESC TO QUIT";
  Sdl.render_present renderer;
  Sdl.delay 16l

let teardown ~window ~font () =
  Font.destroy font;
  Sdl.destroy_window window;
  Sdl.quit ()
