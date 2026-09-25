package main

import (
	"github.com/Zyko0/go-sdl3/bin/binsdl"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/config"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/notifications"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/render"
)

func main() {

	// Setup must be done here
	defer binsdl.Load().Unload()

	if err := render.Performpreflightchecks(); err != nil {
		panic(err)
	}

	notifier := notifications.NewNotifier(10)

	renderer := render.NewRenderer()
	defer renderer.Destroy()

	config, _ := config.LoadConfig("") // TODO: proper path

	renderer.Run(config, notifier)

}
