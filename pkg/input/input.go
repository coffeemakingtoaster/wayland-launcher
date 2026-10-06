package input

import (
	"log"

	"github.com/Zyko0/go-sdl3/sdl"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/notifications"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/panel"
)

func HandleInput(n *notifications.Notifier, g *panel.Grid) bool {
	var event sdl.Event

	for sdl.PollEvent(&event) {
		if event.Type == sdl.EVENT_QUIT {
			return false
		}
		if event.Type == sdl.EVENT_WINDOW_CLOSE_REQUESTED {
			return false
		}
		if event.Type == sdl.EVENT_KEY_DOWN {
			// TODO: bind this to controller vs whatever
			n.Notify(notifications.NewNotification("Key pressed"))
			switch event.KeyboardEvent().Key {
			case sdl.K_DOWN:
				log.Println("Down")
				g.ActivePanel = g.ActivePanel.Down()
				break
			case sdl.K_UP:
				log.Println("Up")
				g.ActivePanel = g.ActivePanel.Top()
				break
			case sdl.K_LEFT:
				log.Println("Left")
				g.ActivePanel = g.ActivePanel.Left()
				break
			case sdl.K_RIGHT:
				log.Println("Right")
				g.ActivePanel = g.ActivePanel.Right()
				break
			case sdl.K_KP_ENTER:
				log.Println("Enter")
				g.ActivePanel.Launch()
			}
		}
	}
	return true
}
