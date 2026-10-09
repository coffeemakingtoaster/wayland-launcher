let launch ~(config : Config.config) ~(active_index : int) () =
  let open Unix in
  match List.nth_opt config.panels active_index with
  | None ->
      let msg = Printf.sprintf "launch: no panel at index %d" active_index in
      Printf.eprintf "Could not start panel: %s" msg;
      Error (`Msg msg)
  | Some panel -> (
      Printf.printf "Running %s\n%!" panel.command;
      match system panel.command with
      | exception Unix_error (errno, _, arg) ->
          let msg =
            Printf.sprintf "launch %s failed: %s: %s" panel.command arg
              (Unix.error_message errno)
          in
          Printf.eprintf "Error with running process: %s" msg;
          Error (`Msg msg)
      | proc ->
          Printf.printf "Process launched succesfully\n";
          Ok proc)
