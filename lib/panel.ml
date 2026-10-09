type render_panel = {
  name : string;
  size : Config.size;
  x : int;
  y : int;
  width : int;
  height : int;
}

let from_config ~config () =
  let from_config_panel ~(config_panel : Config.config_panel)
      ~(config : Config.config) ~(index : int) () =
    {
      name = config_panel.name;
      size = config.panel_dimension;
      x =
        config.panel_padding.width
        + int_of_float
            (floor
               (float_of_int index /. float_of_int config.panel_count.height))
          * (config.panel_dimension.width + config.panel_padding.width);
      y =
        config.panel_padding.height
        + index mod config.panel_count.height
          * (config.panel_dimension.height + config.panel_padding.height);
      width = config.panel_dimension.width;
      height = config.panel_dimension.height;
    }
  in
  List.mapi
    (fun i p -> from_config_panel ~config_panel:p ~config ~index:i ())
    config.panels
