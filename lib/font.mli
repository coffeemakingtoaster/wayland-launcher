(** Font management and text rendering. *)

val setup : unit -> unit
(** Initialize the TTF library and load the default embedded font. *)

val draw_text : renderer:Tsdl.Sdl.renderer -> x:int -> y:int -> string -> unit
(** Draw [text] in white at ([x], [y]). *)

val draw_text_color :
  renderer:Tsdl.Sdl.renderer ->
  x:int ->
  y:int ->
  r:int ->
  g:int ->
  b:int ->
  string ->
  unit
(** Draw [text] tinted with the given RGB color at ([x], [y]). *)

val get_text_size : string -> int * int
(** Return the [(width, height)] of [text] when rendered with the default font.
*)

val teardown : unit -> unit
(** Release all loaded fonts and reset the font cache. *)
