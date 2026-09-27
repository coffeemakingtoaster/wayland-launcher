package render

import (
	"fmt"
	"log"
	"math"

	"github.com/Zyko0/go-sdl3/sdl"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/config"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/notifications"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/panel"
)

const NOTIFICATION_RING_SIZE = 3

type renderNotification struct {
	notification *notifications.Notification
	next         *renderNotification
}

type Renderer struct {
	sdlRenderer *sdl.Renderer
	sdlWindow   *sdl.Window
}

func Performpreflightchecks() error {
	if err := sdl.Init(sdl.INIT_VIDEO); err != nil {
		return err
	}

	return nil
}

func NewRenderer() *Renderer {
	window, renderer, err := sdl.CreateWindowAndRenderer("wayland-launcher", 800, 600, 0)
	if err != nil {
		panic(err)
	}

	return &Renderer{
		sdlRenderer: renderer,
		sdlWindow:   window,
	}
}

func (r *Renderer) applyConfig(c *config.Config) {

	r.sdlRenderer.SetDrawColor(30, 30, 30, 255)
	r.sdlWindow.SetFullscreen(c.IsFullScreen)
	r.sdlWindow.SetAlwaysOnTop(c.AlwaysOnTop)
}

func (r *Renderer) Run(c *config.Config, n *notifications.Notifier) {
	r.applyConfig(c)
	// init panels
	rootPanel := panel.BuildPanelGrid(c)
	var prevPanel, currPanel *panel.Panel
	currPanel = rootPanel
	rects, activeIdx := buildPanelArray(rootPanel, currPanel, c)
	log.Printf("Starting at %s\n", rootPanel.Name)

	// init notifications
	currNotificationRingRoot := &renderNotification{}
	curr := currNotificationRingRoot
	for range NOTIFICATION_RING_SIZE - 1 {
		newNot := &renderNotification{}
		curr.next = newNot
		curr = newNot
	}
	curr.next = currNotificationRingRoot
	log.Printf("Initialized notification ring of %d\n", NOTIFICATION_RING_SIZE)

	sdl.RunLoop(func() error {
		var event sdl.Event

		for sdl.PollEvent(&event) {
			if event.Type == sdl.EVENT_QUIT {
				return sdl.EndLoop
			}
			if event.Type == sdl.EVENT_WINDOW_CLOSE_REQUESTED {
				return sdl.EndLoop
			}
			if event.Type == sdl.EVENT_KEY_DOWN {
				// TODO: bind this to controller vs whatever
				n.Notify(notifications.NewNotification("Key pressed"))
				prevPanel = currPanel
				switch event.KeyboardEvent().Key {
				case sdl.K_DOWN:
					log.Println("Down")
					currPanel = currPanel.Down()
					break
				case sdl.K_UP:
					log.Println("Up")
					currPanel = currPanel.Top()
					break
				case sdl.K_LEFT:
					log.Println("Left")
					currPanel = currPanel.Left()
					break
				case sdl.K_RIGHT:
					log.Println("Right")
					currPanel = currPanel.Right()
					break
				}

				rects, activeIdx = buildPanelArray(rootPanel, currPanel, c)

				fmt.Printf("Now at %s\n", currPanel.Name)

				if prevPanel == currPanel {
					prevPanel = nil
				}
			}
		}

		newNotification := n.GetOldestNotification()
		if newNotification != nil {
			// replace "last" in ring
			// move head to new entry
			curr := currNotificationRingRoot
			for curr.next != currNotificationRingRoot {
				curr = curr.next
			}
			curr.notification = newNotification
			currNotificationRingRoot = curr
			newNotification.Start()
		}
		r.sdlRenderer.SetDrawColor(0, 0, 0, 255)
		r.sdlRenderer.Clear()
		// draw panels
		for i := range len(rects) {
			if i == activeIdx {
				r.sdlRenderer.SetDrawColor(255, 0, 0, 255)
			} else {
				r.sdlRenderer.SetDrawColor(255, 255, 255, 255)
			}
			r.sdlRenderer.DebugText(rects[i].X, rects[i].Y, fmt.Sprintf("%d", i))

			r.sdlRenderer.RenderRect(&rects[i])
		}

		//. draw notifications
		curr := currNotificationRingRoot
		i := 0
		for {
			if curr.notification == nil {
				break
			}

			deadSeconds := curr.notification.DeceseadTimer()
			log.Printf("dead: %v\n", math.Max(float64(deadSeconds), float64(1)))

			r.sdlRenderer.SetDrawColor(
				uint8(math.Floor(255/math.Max(float64(deadSeconds), 1))),
				uint8(math.Floor(255/math.Max(float64(deadSeconds), 1))),
				uint8(math.Floor(255/math.Max(float64(deadSeconds), 1))),
				255,
			)

			x := float32(600)
			y := float32((i+1)*50 + i*50) // padding (plus top) + already existing noticiations

			r.sdlRenderer.DebugText(x+10, y+10, fmt.Sprintf("%s (%d)", curr.notification.Message, i))

			// TODO: calculate pixel values instead of hardcode
			r.sdlRenderer.RenderRect(&sdl.FRect{
				X: x,
				Y: y,
				W: float32(99),
				H: float32(50),
			})

			if deadSeconds > 5 {
				log.Println("Clearing notification")
				curr.notification = nil
			}
			curr = curr.next
			i = i + 1

			if curr == currNotificationRingRoot {
				break
			}
		}

		r.sdlRenderer.Present()

		return nil
	})
}

// TODO: every frame?
func buildPanelArray(rootPanel *panel.Panel, activePanel *panel.Panel, c *config.Config) ([]sdl.FRect, int) {
	result := make([]sdl.FRect, len(c.Panels))
	x := c.PanelPadding
	y := c.PanelPadding
	colRoot := rootPanel
	activeIndex := 0
	idx := 0
	for {
		curr := colRoot
		for {
			result[idx].X, result[idx].Y, result[idx].W, result[idx].H = float32(x), float32(y), float32(c.PanelSize), float32(c.PanelSize)
			y = y + c.PanelPadding + c.PanelSize
			if curr == activePanel {
				activeIndex = idx
			}
			idx += 1
			if curr == curr.Down() {
				break
			}
			curr = curr.Down()
		}
		if colRoot.Right() == colRoot {
			break
		}
		colRoot = colRoot.Right()
		y = c.PanelPadding
		x = x + c.PanelSize + c.PanelPadding
	}

	return result, activeIndex
}

func (r *Renderer) Destroy() {
	sdl.Quit()
	r.sdlRenderer.Destroy()
	r.sdlRenderer.Destroy()

}
