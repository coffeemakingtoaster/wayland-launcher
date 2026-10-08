open Tsdl

let handle_input () =
  let ev = Sdl.Event.create () in
  let rec loop () =
    if Sdl.poll_event (Some ev) then
      match Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ) with
      | `Quit -> false
      | `Key_down -> (
          match Sdl.Event.get ev Sdl.Event.keyboard_keycode with
          | code when code = Sdl.K.escape -> false
          | _ -> loop ())
      | _ -> true
    else true
  in
  loop ()
