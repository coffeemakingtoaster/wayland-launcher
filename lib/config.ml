type size = { width : int; height : int } [@@deriving yaml]
type config_panel = { name : string; command : string } [@@deriving yaml]

let default_screen_size = { height = 600; width = 800 }
let default_panel_size = { height = 50; width = 100 }
let default_grid_size = { height = 2; width = 6 }
let default_grid_padding = { height = 25; width = 50 }
let internal_command_prefix = "~~~"

let fullscreen_panel : config_panel =
  { name = "Fullscreen"; command = internal_command_prefix ^ "FULLSCREEN" }

type config = {
  panels : config_panel list; [@default []]
  is_fullscreen : bool; [@default false]
  screen : size; [@default default_screen_size]
  panel_dimension : size; [@default default_panel_size]
  panel_count : size; [@default default_grid_size]
  panel_padding : size; [@default default_grid_padding]
}
[@@deriving yaml]

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
