package config

type ConfigPanel struct {
	Name string
}

type Config struct {
	IsFullScreen bool
	AlwaysOnTop  bool
	Panels       []*ConfigPanel
	ScreenWidth  int
	ScreenHeight int
	GridXCount   int
	GridYCount   int
	PanelSize    int
	PanelPadding int
}

func Validate(path string) error {
	return nil
}

func LoadConfig(path string) (*Config, error) {
	return &Config{
		IsFullScreen: false,
		AlwaysOnTop:  false,
		Panels:       []*ConfigPanel{{"test1"}, {"test2"}, {"test3"}},
		ScreenWidth:  800,
		ScreenHeight: 600,
		GridXCount:   4,
		GridYCount:   2,
		PanelSize:    75,
		PanelPadding: 10,
	}, nil
}
