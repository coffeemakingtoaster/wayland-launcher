package main

import (
	"github.com/Zyko0/go-sdl3/bin/binsdl"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/config"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/input"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/notifications"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/panel"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/render"
)

func main() {

	// Setup must be done here
	defer binsdl.Load().Unload()

	if err := render.Performpreflightchecks(); err != nil {
		panic(err)
	}

	notifier, err := notifications.NewNotifier()
	if err != nil {
		panic(err)
	}
	config, _ := config.LoadConfig("") // TODO: proper path
	grid := panel.NewGrid(config)

	renderer := render.NewRenderer(notifier, config)
	defer renderer.Destroy()

	for input.HandleInput(notifier, grid) && renderer.Tick(grid) {
	}
}
