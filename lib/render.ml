open Tsdl
open Tsdl_image

let edge_padding = 8
let window_ref : Sdl.window option ref = ref None
let renderer_ref : Sdl.renderer option ref = ref None
let background_image_ref : Sdl.texture option ref = ref None

let preflight_check () =
  match Sdl.init Sdl.Init.(video + events + gamecontroller) with
  | Error (`Msg e) -> Error (`Msg e)
  | Ok () -> Ok ()

let set_fullscreen b () =
  match !window_ref with
  | Some window ->
      Sdl.set_window_fullscreen window
        (if b then Sdl.Window.fullscreen_desktop else Sdl.Window.windowed)
      |> Util.warn_notify_on_error "Could not set fullscreen"
  | None -> ()

let setup ~(config : Config.t) () =
  match
    Sdl.create_window_and_renderer ~w:config.screen.width
      ~h:config.screen.height Sdl.Window.opengl
  with
  | Error (`Msg e) -> Error e
  | Ok (window, renderer) -> (
      window_ref := Some window;
      renderer_ref := Some renderer;
      match Font.setup () with
      | Error (`Msg e) -> Error e
      | Ok _ ->
          if config.background_image_path <> "" then (
            Image.Init.(jpg + png) |> ignore;
            match Image.load_texture renderer config.background_image_path with
            | Ok background_image_texture ->
                background_image_ref := Some background_image_texture
            | Error (`Msg e) ->
                (*Do not fail if image cannot be loaded, just warn and fallback to color*)
                Notifications.add_notification
                  ~message:
                    (Printf.sprintf "Background image could not be loaded :%s" e)
                  ~level:Notifications.Error);
          Printf.printf "Setup completed successfully\n";
          set_fullscreen config.is_fullscreen ();
          Ok ())

let calculate_panel_offset ~(config : Config.t) ~(panel_list : Panel.t list) =
  let panel_block_width =
    (*TODO: This seems inefficient*)
    (List.hd (List.rev panel_list)).x + config.panel_dimension.width
  in
  let rec get_window () =
    match !window_ref with
    | None -> (
        Printf.printf "Window ref not populated, running setup\n";
        match setup ~config () with
        | Ok () -> get_window ()
        | Error e -> Error (`Msg e))
    | Some window -> Ok window
  in
  match get_window () with
  | Error (`Msg e) ->
      Printf.eprintf "Could not get screen due to an error:  %s\n" e;
      (0, 0)
  | Ok window ->
      let get_window_size =
        let window_width, window_height = Sdl.get_window_size window in
        (window_width, window_height)
      in
      let get_screen_size =
        match Sdl.get_window_display_index window with
        | Error (`Msg e) ->
            Printf.eprintf "Could not get screen due to an error:  %s\n" e;
            (0, 0)
        | Ok index -> (
            match Sdl.get_desktop_display_mode index with
            | Error (`Msg e) ->
                Printf.eprintf "Could not get display due to an error:  %s\n" e;
                (0, 0)
            | Ok display -> (display.Sdl.dm_w, display.Sdl.dm_h))
      in
      let width, height =
        if config.is_fullscreen then get_screen_size else get_window_size
      in
      ((width / 2) - (panel_block_width / 2), height / 3)

let draw_panel ~renderer ~(panel : Panel.t) ~(index : int) ~(is_active : bool)
    ~(panel_offset_x : int) ~(panel_offset_y : int) =
  let rect =
    Sdl.Rect.create ~x:(panel.x + panel_offset_x) ~y:(panel.y + panel_offset_y)
      ~w:panel.width ~h:panel.height
  in
  (let pc = panel.color in
   Sdl.set_render_draw_color renderer pc.r pc.g pc.b pc.a
   |> Util.warn_notify_on_error "Render initialization errror";
   Sdl.render_fill_rect renderer (Some rect)
   |> Util.warn_notify_on_error "Rectangle fill error";
   if is_active then
     Sdl.set_render_draw_color renderer 255 0 0 255
     |> Util.warn_notify_on_error "Set render color error"
   else
     Sdl.set_render_draw_color renderer 255 255 255 255
     |> Util.warn_notify_on_error "Set render color error";
   Sdl.render_draw_rect renderer (Some rect)
   |> Util.warn_notify_on_error "Draw rect error");
  Font.draw_text ~renderer ~x:(panel.x + panel_offset_x)
    ~y:(panel.y + panel_offset_y)
    (Printf.sprintf "%d" index);
  let text_width, text_height = Font.get_text_size panel.name in
  Font.draw_text ~renderer
    ~x:(panel.x + panel_offset_x + (panel.width / 2) - (text_width / 2))
    ~y:(panel.y + panel_offset_y + (panel.height / 2) - (text_height / 2))
    panel.name;
  ()

let draw_notification ~renderer ~(notification : Notifications.t) ~(index : int)
    =
  let r, g, b = Notifications.color_from_severity ~notification in
  Sdl.set_render_draw_color renderer r g b 255 |> Util.err_log_on_error;
  let text_width, text_height = Font.get_text_size notification.message in
  let fade_out_offset =
    Int.of_float
      (Notifications.get_fade_out_progress ~notification
      *. float_of_int (text_width + 8))
  in
  let rect =
    Sdl.Rect.create ~x:(0 - fade_out_offset)
      ~y:(index * (text_height + 10))
      ~w:(text_width + 8) ~h:(text_height + 8)
  in
  Sdl.render_draw_rect renderer (Some rect) |> Util.err_log_on_error;
  Font.draw_text ~renderer ~x:(4 - fade_out_offset)
    ~y:((index * (text_height + 10)) + 4)
    notification.message;
  ()

let draw_background (config : Config.t) renderer window =
  let bgc = config.background_color in
  Sdl.set_render_draw_color renderer bgc.r bgc.g bgc.b bgc.a
  |> Util.err_notify_on_error "Set render color error";
  Sdl.render_clear renderer |> Util.err_notify_on_error "Rect clear error";
  let window_width, window_height = Sdl.get_window_size window in
  match !background_image_ref with
  | Some background_image_texture ->
      let dst = Sdl.Rect.create ~x:0 ~y:0 ~w:window_width ~h:window_height in
      Sdl.render_copy ~dst renderer background_image_texture
      |> Util.err_notify_on_error "Render copy error"
  | None -> ()

let tick ~(config : Config.t) ~(panel_list : Panel.t list) ~(active_index : int)
    ~(panel_offset_x : int) ~(panel_offset_y : int) =
  match !window_ref with
  | None -> Printf.eprintf "Window not initialized"
  | Some window -> (
      match !renderer_ref with
      | None -> Printf.eprintf "Render not initialized"
      | Some renderer ->
          let window_width, window_height = Sdl.get_window_size window in
          draw_background config renderer window;
          List.mapi
            (fun i p ->
              draw_panel ~renderer ~panel:p ~index:i
                ~is_active:(i = active_index) ~panel_offset_x ~panel_offset_y)
            panel_list
          |> ignore;
          List.mapi
            (fun i n -> draw_notification ~renderer ~notification:n ~index:i)
            (Notifications.get_notifications ())
          |> ignore;
          let res = Sdl.set_render_draw_color renderer 24 24 32 255 in
          Result.iter_error
            (fun (`Msg e) -> Sdl.log "Draw color error: %s" e)
            res;
          (* Debug text *)
          if Build_config.profile = "dev" then begin
            let message_text = "WAYLAND LAUNCHER [DEV BUILD]" in
            let text_width, _ = Font.get_text_size message_text in

            Font.draw_text_color ~renderer
              ~x:((window_width / 2) - (text_width / 2))
              ~y:edge_padding ~r:255 ~g:200 ~b:80 message_text
          end;
          let now = Unix.localtime (Unix.time ()) in
          let date_text =
            Printf.sprintf "Unix time %d:%d:%d" now.tm_hour now.tm_min
              now.tm_sec
          in
          let text_width, text_height = Font.get_text_size date_text in
          Font.draw_text ~renderer
            ~x:(window_width - (text_width + edge_padding))
            ~y:(window_height - (text_height + edge_padding))
            date_text;
          Font.draw_text_color ~renderer ~x:8
            ~y:(window_height - (text_height + edge_padding))
            ~r:120 ~g:180 ~b:120 "ESC TO QUIT";
          Sdl.render_present renderer;
          Sdl.delay 16l)

let teardown () =
  Font.teardown ();
  match !window_ref with
  | None -> Printf.printf "Window not initialized"
  | Some window ->
      Sdl.destroy_window window;
      window_ref := None;
      Image.quit ();
      Sdl.quit ()
