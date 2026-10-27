(** Panel layout derived from configuration. *)

type t = {
  name : string;
  size : Config.size;
  x : int;
  y : int;
  width : int;
  height : int;
  color : Color.t;
}
(** A positioned panel ready for rendering. *)

val from_config : config:Config.t -> unit -> t list
(** Build positioned panels from [config]. *)
