package panel

import "github.com/coffeemakingtoaster/wayland-launcher/pkg/config"

type Grid struct {
	RootPanel   *Panel
	ActivePanel *Panel
}

func NewGrid(c *config.Config) *Grid {
	rootPanel := constructGridFromConfig(c)
	return &Grid{
		RootPanel:   rootPanel,
		ActivePanel: rootPanel,
	}
}
