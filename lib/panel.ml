type t = {
  name : string;
  size : Config.size;
  x : int;
  y : int;
  width : int;
  height : int;
  color : Color.t;
}

let from_config ~config () =
  let from_config_panel ~(config_panel : Config.panel) ~(config : Config.t)
      ~(index : int) () =
    {
      name = config_panel.name;
      size = config.panel_dimension;
      x =
        int_of_float
          (floor (float_of_int index /. float_of_int config.panel_count.height))
        * (config.panel_dimension.width + config.panel_padding.width);
      y =
        index mod config.panel_count.height
        * (config.panel_dimension.height + config.panel_padding.height);
      width = config.panel_dimension.width;
      height = config.panel_dimension.height;
      color = config_panel.color;
    }
  in
  List.mapi
    (fun i p -> from_config_panel ~config_panel:p ~config ~index:i ())
    config.panels
