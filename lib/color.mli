(** RGBA color helpers. *)

type t = { r : int; g : int; b : int; a : int [@default 255] } [@@deriving yaml]
(** A color with red, green, blue and alpha components in the range 0..255. *)

val is_value_valid : int -> bool
(** [is_value_valid v] is [true] when [v] is in the range [0, 255]. *)

val is_color_valid : t -> bool
(** [is_color_valid c] is [true] when all components of [c] are valid. *)
