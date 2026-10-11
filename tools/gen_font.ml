let () =
  if Array.length Sys.argv <> 2 then begin
    prerr_endline "usage: gen_font <font-file>";
    exit 1
  end;
  let ic = open_in_bin Sys.argv.(1) in
  let len = in_channel_length ic in
  let data = really_input_string ic len in
  close_in ic;
  print_string "let data = \"";
  String.iter
    (fun c ->
      match c with
      | '"' -> print_string "\\\""
      | '\\' -> print_string "\\\\"
      | c ->
          let code = Char.code c in
          if code >= 0x20 && code < 0x7f then print_char c
          else Printf.printf "\\x%02x" code)
    data;
  print_string "\"\n"
