match Launcher.Render.preflight_check () with
| Error (`Msg e) ->
    Printf.printf "Preflight check failed: %s" e;
    exit 1
| Ok () -> ()

let quit = ref false

while !quit do 
        Launcher.Input.handle_input(quit)
done
