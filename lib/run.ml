type internal_command = FULLSCREEN

let to_internal_command (s : string) : (internal_command, string) result =
  match s with
  | "FULLSCREEN" -> Ok FULLSCREEN
  | _ -> Error (Printf.sprintf "Unknown command: %s" s)

let launch ~(config : Config.config) ~(active_index : int) () =
  let has_internal_command_prefix =
    String.starts_with ~prefix:Config.internal_command_prefix
  in
  let prefix_length = String.length Config.internal_command_prefix in
  let internal_command ~(panel : Config.config_panel) () =
    match
      to_internal_command
        (String.sub panel.command prefix_length
           (String.length panel.command - prefix_length))
    with
    | Ok FULLSCREEN ->
        Render.set_fullscreen true ();
        Ok ()
    | Error e -> Error (`Msg e)
  in
  let open Unix in
  match List.nth_opt config.panels active_index with
  | None ->
      let msg = Printf.sprintf "launch: no panel at index %d" active_index in
      Printf.eprintf "Could not start panel: %s" msg;
      Error (`Msg msg)
  | Some panel ->
      Printf.printf "Running %s\n%!" panel.command;
      if has_internal_command_prefix panel.command then
        internal_command ~panel ()
      else
        begin match system panel.command with
        | exception Unix_error (errno, _, arg) ->
            let msg =
              Printf.sprintf "launch %s failed: %s: %s" panel.command arg
                (Unix.error_message errno)
            in
            Printf.eprintf "Error with running process: %s" msg;
            Error (`Msg msg)
        | _ ->
            Printf.printf "Process launched succesfully\n";
            Ok ()
        end
