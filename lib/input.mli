(** Input handling: keyboard, controller and joystick events. *)

type direction =
  | Up
  | Down
  | Left
  | Right  (** Direction for navigating the panel grid. *)

val handle_input :
  current_active_index:int -> config:Config.t -> unit -> bool * int
(** Process pending SDL events.

    Returns a pair [(continue, new_active_index)] where [continue] is [false]
    when the user requested to quit, and [new_active_index] is the updated panel
    selection. *)
