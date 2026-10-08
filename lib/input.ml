open Tsdl

let handle_input () =
  let ev = Sdl.Event.create () in
  while Sdl.poll_event (Some ev) do
    match Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ) with
    | `Quit -> () (*quit := true*)
    | `Key_down -> (
        match Sdl.Event.get ev Sdl.Event.keyboard_keycode with
        | code when code = Sdl.K.escape -> () (*quit := true*)
        | _ -> ())
    | _ -> ()
  done
