open Tsdl
open Tsdl_ttf

let size = 10
let embedded_font = "embedded"
let default_font = embedded_font
let loaded_fonts : (string * int, Ttf.font) Hashtbl.t = Hashtbl.create 4

let open_source font_path ptsize =
  if String.equal font_path embedded_font then
    match Sdl.rw_from_const_mem Font_data.data with
    | Error (`Msg e) -> Error (`Msg e)
    | Ok rw -> Ttf.open_font_rw rw 1 ptsize
  else Ttf.open_font font_path ptsize

let load_font ?(ptsize = size) (font_path : string) () =
  let key = (font_path, ptsize) in
  match Hashtbl.find_opt loaded_fonts key with
  | Some font -> Ok font
  | None -> (
      match open_source font_path ptsize with
      | Error (`Msg e) ->
          Error
            (`Msg (Printf.sprintf "Could not load font '%s': %s\n" font_path e))
      | Ok font ->
          Hashtbl.add loaded_fonts key font;
          Ok font)

let setup () =
  match Ttf.init () with
  | Error (`Msg e) -> Error (`Msg e)
  | Ok () -> load_font default_font ()

let draw_text_color ~renderer ~x ~y ~r ~g ~b (text : string) : unit =
  let fg = Sdl.Color.create ~r ~g ~b ~a:255 in
  match load_font default_font () with
  | Error (`Msg e) ->
      Printf.eprintf "Failed to draw text: %s" e
      (*Do not make this a notification, notification uses this function -> loop*)
  | Ok font -> (
      match Ttf.render_utf8_solid font text fg with
      | Error (`Msg e) -> Printf.eprintf "Could not render text: %s" e
      | Ok surface -> (
          (* upload the CPU surface to a GPU texture via the renderer *)
          match Sdl.create_texture_from_surface renderer surface with
          | Error (`Msg e) -> Printf.eprintf "Could not create texture: %s" e
          | Ok texture ->
              (let w, h = Sdl.get_surface_size surface in
               let dst = Sdl.Rect.create ~x ~y ~w ~h in
               (match Sdl.render_copy ~dst renderer texture with
               | Error (`Msg e) -> Printf.eprintf "Could not draw text: %s" e
               | Ok () -> ());
               Sdl.destroy_texture texture);
              Sdl.free_surface surface))

let draw_text ~renderer ~x ~y (text : string) : unit =
  draw_text_color ~renderer ~x ~y ~r:255 ~g:255 ~b:255 text

let get_text_size (text : string) =
  match load_font default_font () with
  | Error (`Msg e) ->
      Printf.eprintf "Failed to get text size: %s" e;
      (0, 0)
  | Ok font -> (
      match Ttf.size_text font text with
      | Error _ -> (0, 0)
      | Ok (text_width, text_height) -> (text_width, text_height))

let teardown () =
  Hashtbl.iter (fun _ font -> Ttf.close_font font) loaded_fonts;
  Hashtbl.reset loaded_fonts
