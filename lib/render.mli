(** Window, renderer and drawing orchestration. *)

val preflight_check : unit -> (unit, [ `Msg of string ]) result
(** Check that required SDL subsystems can be initialized. *)

val setup : config:Config.t -> unit -> (unit, string) result
(** Create the window and renderer, initialize fonts and load the background
    image if configured. *)

val calculate_panel_offset :
  config:Config.t -> panel_list:Panel.t list -> int * int
(** Calculate the top-left offset that centers the panel block. *)

val set_fullscreen : bool -> unit -> unit
(** Toggle fullscreen / windowed mode. *)

val tick :
  config:Config.t ->
  panel_list:Panel.t list ->
  active_index:int ->
  panel_offset_x:int ->
  panel_offset_y:int ->
  unit
(** Draw one frame and present it. *)

val teardown : unit -> unit
(** Free SDL resources and shut down subsystems. *)
