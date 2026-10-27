(** Temporary on-screen notifications. *)

type level = Info | Warn | Error  (** Severity level of a notification. *)

type t = {
  start_time_ms : int64;
  message : string;
  level : level;
  wanted_ttl_ms : int64;
  fade_out_time_ms : int64;
}
(** A notification. *)

val add_notification : message:string -> level:level -> unit
(** Add a notification with the given [message] and [level]. *)

val get_notifications : unit -> t list
(** Return all notifications that have not yet expired. *)

val get_fade_out_progress : notification:t -> float
(** Return the fade-out progress of [notification] as a value in [0.0, 1.0]. *)

val color_from_severity : notification:t -> int * int * int
(** Return an RGB tuple suitable for rendering the given severity level. *)
