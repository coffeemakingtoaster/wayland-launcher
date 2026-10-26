let default_background_color : Color.t = { r = 24; g = 24; b = 32; a = 255 }

type size = { width : int; height : int } [@@deriving yaml]

type panel = {
  name : string;
  command : string;
  color : Color.t; [@default default_background_color]
}
[@@deriving yaml]

let default_screen_size = { height = 600; width = 800 }
let default_panel_size = { height = 50; width = 100 }
let default_grid_size = { height = 2; width = 6 }
let default_grid_padding = { height = 25; width = 50 }
let internal_command_prefix = "~~~"

let fullscreen_panel : panel =
  {
    name = "Fullscreen";
    command = internal_command_prefix ^ "FULLSCREEN";
    color = default_background_color;
    (*TODO: this is ugly*)
  }

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

let validate_background_image ~(config : t) =
  match config.background_image_path with
  | "" -> []
  | path ->
      if Sys.file_exists path then []
      else [ "Background image path configured could not be resolved" ]

let validate_background_color ~(config : t) =
  if config.background_color = default_background_color then []
  else if Color.is_color_valid config.background_color then []
  else [ "Background image path configured could not be resolved" ]

let validate_background_precedence ~(config : t) =
  let is_background_image_set = config.background_image_path <> "" in
  let is_background_color_set =
    config.background_color <> default_background_color
  in
  (if is_background_color_set && is_background_image_set then
     [
       "Both background image and color are set in the config. The image will \
        take precedence";
     ]
   else [])
  @ (if is_background_image_set then validate_background_image ~config else [])
  @ if is_background_color_set then validate_background_color ~config else []

let validate_config ~(config : t) =
  List.iter
    (fun v ->
      Notifications.add_notification ~message:v ~level:Notifications.Warn)
    (validate_background_precedence ~config)

let load_config ~filename =
  let filepath = Fpath.v filename in
  let yaml = Yaml_unix.of_file filepath in
  match yaml with
  | Ok yaml -> (
      match of_yaml yaml with
      | Ok config ->
          Ok { config with panels = config.panels @ [ fullscreen_panel ] }
      | Error (`Msg msg) -> Error (`Msg msg))
  | Error (`Msg msg) -> Error (`Msg msg)
