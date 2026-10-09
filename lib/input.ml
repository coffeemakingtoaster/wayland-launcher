open Tsdl

type movement = UP | DOWN | LEFT | RIGHT

let handle_input ~current_active_index ~(config : Config.config) () =
  let update_active_index = function
    | UP ->
        if current_active_index mod config.panel_count.height = 0 then
          current_active_index
        else current_active_index - 1
    | DOWN ->
        let row = current_active_index mod config.panel_count.height in
        if
          row = config.panel_count.height - 1
          || current_active_index + 1 >= List.length config.panels
        then current_active_index
        else current_active_index + 1
    | LEFT ->
        let column =
          int_of_float
            (floor
               (float_of_int current_active_index
               /. float_of_int config.panel_count.height))
        in
        if column = 0 then current_active_index
        else current_active_index - config.panel_count.height
    | RIGHT ->
        let new_index = current_active_index + config.panel_count.height in
        if new_index >= List.length config.panels then current_active_index
        else new_index
  in
  let ev = Sdl.Event.create () in
  let rec loop () =
    if Sdl.poll_event (Some ev) then
      match Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ) with
      | `Quit -> (false, current_active_index)
      | `Key_down -> (
          match Sdl.Event.get ev Sdl.Event.keyboard_keycode with
          | code when code = Sdl.K.escape -> (false, current_active_index)
          | code when code = Sdl.K.up -> (true, update_active_index UP)
          | code when code = Sdl.K.down -> (true, update_active_index DOWN)
          | code when code = Sdl.K.left -> (true, update_active_index LEFT)
          | code when code = Sdl.K.right -> (true, update_active_index RIGHT)
          | code
            when code = Sdl.K.kp_enter || code = Sdl.K.space
                 || code = Sdl.K.return ->
              Result.iter_error
                (fun (`Msg e) -> Printf.eprintf "Launch failed: %s" e)
                (Run.launch ~config ~active_index:current_active_index ());
              (true, current_active_index)
          | _ -> loop ())
      | _ -> (true, current_active_index)
    else (true, current_active_index)
  in
  loop ()
