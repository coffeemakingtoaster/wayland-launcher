let default_background_color : Color.color = { r = 24; g = 24; b = 32; a = 255 }

type size = { width : int; height : int } [@@deriving yaml]

type config_panel = {
  name : string;
  command : string;
  color : Color.color; [@default default_background_color]
}
[@@deriving yaml]

let default_screen_size = { height = 600; width = 800 }
let default_panel_size = { height = 50; width = 100 }
let default_grid_size = { height = 2; width = 6 }
let default_grid_padding = { height = 25; width = 50 }
let internal_command_prefix = "~~~"

let fullscreen_panel : config_panel =
  {
    name = "Fullscreen";
    command = internal_command_prefix ^ "FULLSCREEN";
    color = default_background_color;
    (*TODO: this is ugly*)
  }

type config = {
  panels : config_panel list; [@default []]
  is_fullscreen : bool; [@default false]
  screen : size; [@default default_screen_size]
  panel_dimension : size; [@default default_panel_size]
  panel_count : size; [@default default_grid_size]
  panel_padding : size; [@default default_grid_padding]
  background_color : Color.color; [@default default_background_color]
  background_image_path : string; [@default ""]
}
[@@deriving yaml]

let validate_background_image ~(config : config) =
  match config.background_image_path with
  | "" -> []
  | path -> (
      match Sys.file_exists path with
      | false -> [ "Background image path configured could not be resolved" ]
      | _ -> [])

let validate_background_color ~(config : config) =
  match config.background_color = default_background_color with
  | true -> []
  | false -> (
      match Color.is_color_valid config.background_color with
      | false -> [ "Background image path configured could not be resolved" ]
      | _ -> [])

let validate_background_precedence ~(config : config) =
  match
    ( config.background_image_path <> "",
      config.background_color <> default_background_color )
  with
  | true, true ->
      "Both background image and color are set in the config. The image will \
       take precedence"
      :: validate_background_image ~config
  | true, false -> validate_background_image ~config
  | false, true -> validate_background_color ~config
  | _, _ -> []

let validate_config ~(config : config) =
  List.iter
    (fun v ->
      Notifications.add_notification ~message:v ~level:Notifications.WARN)
    (validate_background_precedence ~config)

let load_config ~filename =
  let filepath = Fpath.v filename in
  let yaml = Yaml_unix.of_file filepath in
  match yaml with
  | Ok yaml -> (
      match config_of_yaml yaml with
      | Ok config ->
          Ok { config with panels = config.panels @ [ fullscreen_panel ] }
      | Error (`Msg msg) -> Error (`Msg msg))
  | Error (`Msg msg) -> Error (`Msg msg)
