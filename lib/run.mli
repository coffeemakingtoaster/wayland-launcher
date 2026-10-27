(** Command execution and internal launcher commands. *)

type command =
  | Fullscreen  (** Internal commands recognized by the launcher. *)

val launch :
  config:Config.t ->
  active_index:int ->
  unit ->
  (unit, [ `Msg of string ]) result
(** Launch the command associated with the panel at [active_index]. *)
