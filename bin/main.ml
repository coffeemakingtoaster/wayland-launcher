match Launcher.Render.preflight_check () with
| Error (`Msg e) ->
    Printf.printf "Preflight check failed: %s" e;
    exit 1
| _ -> (
    ();

    match Launcher.Render.setup () with
    | Error e ->
        Printf.printf "Could not create window due to an error: %s" e;
        exit 1
    | Ok (window, renderer, font) ->
        let rec main_loop () =
          match Launcher.Input.handle_input () with
          | true ->
              Launcher.Render.tick ~renderer ~font ();
              main_loop ()
          | _ ->
              Printf.printf "Execution finished";
              Launcher.Render.teardown ~window ~font ();

              exit 0
        in
        main_loop ())
