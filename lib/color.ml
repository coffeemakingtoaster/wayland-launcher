type color = { r : int; g : int; b : int; a : int [@default 255] }
[@@deriving yaml]

let is_value_valid v = v >= 0 && v < 256

let is_color_valid c =
  is_value_valid c.r && is_value_valid c.g && is_value_valid c.b
  && is_value_valid c.a
