(* This reimplements some stuff in the stdlib just for the fun of it :)*)

let rec get_list_last_item l =
  match l with
  | [] -> raise Not_found
  | v :: r -> if r = [] then v else get_list_last_item r

(*let rec get_list_first_item l =
  match l with [] -> raise Not_found | v :: _ -> v*)
