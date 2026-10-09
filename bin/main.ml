let () =
  match Launcher.Render.preflight_check () with
  | Error (`Msg e) ->
      Printf.eprintf "Preflight check failed: %s\n" e;
      exit 1
  | Ok () -> (
      let config =
        match Launcher.Config.load_config ~filename:"./config.yaml" with
        | Ok config ->
            Printf.printf "Loaded\n";
            config
        | Error (`Msg msg) ->
            Printf.eprintf "Could not load config: %s\n" msg;
            exit 1
      in
      let panel_list = Launcher.Panel.from_config ~config () in
      match Launcher.Render.setup () with
      | Error e ->
          Printf.eprintf "Could not create window due to an error: %s\n" e;
          exit 1
      | Ok (window, renderer, font) ->
          let rec main_loop ~(active_panel_index : int) () =
            let run, new_active_index =
              Launcher.Input.handle_input
                ~current_active_index:active_panel_index ~config ()
            in
            if run then begin
              Launcher.Render.tick ~renderer ~window ~font ~panel_list
                ~active_index:active_panel_index ();
              main_loop ~active_panel_index:new_active_index ()
            end
            else begin
              Printf.printf "Execution finished\n";
              Launcher.Render.teardown ~window ~font ();
              exit 0
            end
          in

          main_loop ~active_panel_index:0 ())
