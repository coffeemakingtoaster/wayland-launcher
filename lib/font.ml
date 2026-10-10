open Tsdl
open Tsdl_ttf

let size = 10
let default_font = "./assets/font.ttf"
let loaded_fonts : (string, Ttf.font) Hashtbl.t = Hashtbl.create 4

let load_font font_path () =
  match Hashtbl.find_opt loaded_fonts font_path with
  | Some font -> font
  | None -> (
      match Tsdl_ttf.Ttf.open_font default_font size with
      | Error (`Msg e) ->
          Printf.eprintf "Could not load font: %s" e;
          Hashtbl.find loaded_fonts default_font
      | Ok font ->
          Hashtbl.add loaded_fonts font_path font;
          font)

let setup () =
  Tsdl_ttf.Ttf.init () |> ignore;
  load_font default_font () |> ignore

let draw_text_color ~renderer ~x ~y ~r ~g ~b (text : string) : unit =
  let font = load_font default_font () in
  let fg = Sdl.Color.create ~r ~g ~b ~a:255 in
  match Ttf.render_utf8_solid font text fg with
  | Error (`Msg e) -> Printf.eprintf "Could not render text: %s" e
  | Ok surface -> (
      (* upload the CPU surface to a GPU texture via the renderer *)
      match Sdl.create_texture_from_surface renderer surface with
      | Error (`Msg e) -> Printf.eprintf "Could not create texture: %s" e
      | Ok texture ->
          (let w, h = Sdl.get_surface_size surface in
           let dst = Sdl.Rect.create ~x ~y ~w ~h in
           (* draw it like any other texture *)
           (match Sdl.render_copy ~dst renderer texture with
           | Error (`Msg e) -> Printf.eprintf "Could not draw text: %s" e
           | Ok () -> ());
           Sdl.destroy_texture texture);
          Sdl.free_surface surface)

let draw_text ~renderer ~x ~y (text : string) : unit =
  draw_text_color ~renderer ~x ~y ~r:255 ~g:255 ~b:255 text

let teardown () = Hashtbl.iter (fun _ font -> Ttf.close_font font) loaded_fonts
