open Tsdl

let preflight_check () =
  match Sdl.init Sdl.Init.(video + events) with
  | Error (`Msg e) -> Error (`Msg e)
  | Ok () -> Ok ()

(*
let setup = 
match Sdl.create_window_and_renderer ~w:800 ~h:600 Sdl.Window.opengl with
  | Error (`Msg e) ->
      Sdl.log "Window error: %s" e;
      Sdl.quit ();
      exit 1
  | Ok (window, renderer) ->
      let font =
        match Launcher.Font.create renderer with
        | Error e ->
            Sdl.log "Font error: %s" e;
            Sdl.destroy_window window;
            Sdl.quit ();
            exit 1
        | Ok font -> font


let tick =
  (* Handle all pending events *)
  (* FPS counter, updated once per second *)
  incr frames;
  let now = Sdl.get_ticks64 () in
  if Int64.sub now !last_fps_update >= 1000L then begin
    fps := !frames;
    frames := 0;
    last_fps_update := now
  end;
  (* Draw *)
  let res = Sdl.set_render_draw_color renderer 24 24 32 255 in
  Result.iter_error (fun (`Msg e) -> Sdl.log "Draw color error: %s" e) res;
  Sdl.render_clear renderer |> ignore;
  (* Debug text *)
  Launcher.Font.draw_text_color font renderer ~x:8 ~y:8 ~r:255 ~g:200 ~b:80
    "WAYLAND LAUNCHER [DEBUG]";
  Launcher.Font.draw_text font renderer ~x:8 ~y:24
    (Printf.sprintf "FPS: %d" !fps);
  Launcher.Font.draw_text font renderer ~x:8 ~y:40
    (Printf.sprintf "MOUSE: %d,%d" !mouse_x !mouse_y);
  Launcher.Font.draw_text_color font renderer ~x:8 ~y:(600 - 16) ~r:120 ~g:180
    ~b:120 "ESC TO QUIT";
  Sdl.render_present renderer;
  Sdl.delay 16l

let render =
        in
      Sdl.log "Opened window";
      (* debug state *)
      let mouse_x = ref 0 in
      let mouse_y = ref 0 in
      let frames = ref 0 in
      let last_fps_update = ref (Sdl.get_ticks64 ()) in
      let fps = ref 0 in
      Launcher.Font.destroy font;
      Sdl.destroy_window window;
      Sdl.quit ()
*)
