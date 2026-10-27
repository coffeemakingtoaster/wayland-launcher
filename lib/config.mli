(** Application configuration parsed from YAML. *)

type size = { width : int; height : int } [@@deriving yaml]
(** A 2D size in pixels. *)

type panel = {
  name : string;
  command : string;
  color : Color.t; [@default default_background_color]
}
[@@deriving yaml]
(** A single launcher panel as defined in the configuration file. *)

type t = {
  panels : panel list; [@default []]
  is_fullscreen : bool; [@default false]
  screen : size; [@default default_screen_size]
  panel_dimension : size; [@default default_panel_size]
  panel_count : size; [@default default_grid_size]
  panel_padding : size; [@default default_grid_padding]
  background_color : Color.t; [@default default_background_color]
  background_image_path : string; [@default ""]
}
[@@deriving yaml]
(** Full application configuration. *)

val default_background_color : Color.t
(** Default background / panel color. *)

val default_screen_size : size
(** Default window size. *)

val default_panel_size : size
(** Default panel size. *)

val default_grid_size : size
(** Default number of rows and columns. *)

val default_grid_padding : size
(** Default spacing between panels. *)

val internal_command_prefix : string
(** Prefix identifying internal launcher commands. *)

val validate_config : config:t -> unit
(** Validate [config] and emit warnings via {!Notifications}. *)

val load_config : filename:string -> (t, [ `Msg of string ]) result
(** Load and parse a configuration file from disk. *)
