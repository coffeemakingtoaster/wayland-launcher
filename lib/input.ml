open Tsdl

type movement = UP | DOWN | LEFT | RIGHT

let open_controllers : (Sdl.joystick_id, Sdl.game_controller) Hashtbl.t =
  Hashtbl.create 4

(* module level, next to open_controllers *)
let deadzone = 12000
let stick_armed_x = ref false
let stick_armed_y = ref false

let handle_input ~current_active_index ~(config : Config.config) () =
  Sdl.joystick_set_event_state Sdl.enable |> ignore;
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
    let register_controller () =
      let device_id =
        Int32.to_int (Sdl.Event.get ev Sdl.Event.controller_device_which)
      in
      match Sdl.game_controller_open device_id with
      | Ok c -> (
          match Sdl.game_controller_get_joystick c with
          | Ok js -> (
              match Sdl.joystick_instance_id js with
              | Ok id ->
                  Hashtbl.add open_controllers id c;
                  loop ()
              | Error (`Msg msg) ->
                  Printf.eprintf "Failed to init controller: %s" msg;
                  loop ())
          | Error (`Msg msg) ->
              Printf.eprintf "Failed to init controller: %s" msg;
              loop ())
      | Error (`Msg msg) ->
          Printf.eprintf "Failed to init controller: %s" msg;
          loop ()
    in
    let remove_controller () =
      let device_id = Sdl.Event.get ev Sdl.Event.controller_device_which in
      match Hashtbl.find_opt open_controllers device_id with
      | Some c ->
          Sdl.game_controller_close c;
          Hashtbl.remove open_controllers device_id;
          loop ()
      | None ->
          Printf.eprintf "Could not cleanup controller (it did not exist?)";
          loop ()
    in
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
      | `Controller_device_added -> register_controller ()
      | `Controller_device_removed -> remove_controller ()
      | `Controller_button_down -> (
          match Sdl.Event.get ev Sdl.Event.controller_button_button with
          | code when code = Sdl.Controller.button_b ->
              (true, current_active_index)
          | code when code = Sdl.Controller.button_dpad_up ->
              (true, update_active_index UP)
          | code when code = Sdl.Controller.button_dpad_down ->
              (true, update_active_index DOWN)
          | code when code = Sdl.Controller.button_dpad_left ->
              (true, update_active_index LEFT)
          | code when code = Sdl.Controller.button_dpad_right ->
              (true, update_active_index RIGHT)
          | code when code = Sdl.Controller.button_a ->
              Result.iter_error
                (fun (`Msg e) -> Printf.eprintf "Launch failed: %s" e)
                (Run.launch ~config ~active_index:current_active_index ());
              (true, current_active_index)
          | _ -> loop ())
      | `Controller_axis_motion -> (
          let value = Sdl.Event.get ev Sdl.Event.controller_axis_value in
          match Sdl.Event.get ev Sdl.Event.controller_axis_axis with
          | axis when axis = Sdl.Controller.axis_left_x ->
              if (not !stick_armed_x) && abs value > deadzone then begin
                stick_armed_x := true;
                (true, update_active_index (if value < 0 then LEFT else RIGHT))
              end
              else if abs value <= deadzone then begin
                stick_armed_x := false;
                loop ()
              end
              else loop ()
          | axis when axis = Sdl.Controller.axis_left_y ->
              if (not !stick_armed_y) && abs value > deadzone then begin
                stick_armed_y := true;
                (true, update_active_index (if value < 0 then UP else DOWN))
              end
              else if abs value <= deadzone then begin
                stick_armed_y := false;
                loop ()
              end
              else loop ()
          | _ -> loop ())
      | _ -> (true, current_active_index)
    else (true, current_active_index)
  in
  loop ()
