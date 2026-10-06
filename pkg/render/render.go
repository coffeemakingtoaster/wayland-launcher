package render

import (
	"fmt"
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
	sdlRenderer         *sdl.Renderer
	sdlWindow           *sdl.Window
	notifier            *notifications.Notifier
	config              *config.Config
	notifcationRingRoot *renderNotification // TODO: this & ring logic should likely life in notifier
}

func Performpreflightchecks() error {
	if err := sdl.Init(sdl.INIT_VIDEO); err != nil {
		return err
	}

	return nil
}

func NewRenderer(n *notifications.Notifier, c *config.Config) *Renderer {
	window, renderer, err := sdl.CreateWindowAndRenderer("wayland-launcher", 800, 600, 0)
	if err != nil {
		panic(err)
	}

	result := &Renderer{
		sdlRenderer: renderer,
		sdlWindow:   window,
		notifier:    n,
		config:      c,
	}
	result.applyConfig()

	return result
}

func (r *Renderer) applyConfig() {
	r.sdlRenderer.SetDrawColor(30, 30, 30, 255)
	r.sdlWindow.SetFullscreen(r.config.IsFullScreen)
	r.sdlWindow.SetAlwaysOnTop(r.config.AlwaysOnTop)
}

func (r *Renderer) Tick(grid *panel.Grid) bool {
	rects, activeIdx := buildPanelArray(grid.RootPanel, grid.ActivePanel, r.config)

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
	notifications := r.notifier.GetNotificationsInOrder()
	for i, curr := range notifications {

		if curr.HasFullyDied() {
			continue
		}

		deadSeconds := curr.DeceseadTimer()

		desiredColor := curr.DesiredColor()

		r.sdlRenderer.SetDrawColor(
			uint8(math.Floor(float64(desiredColor.R)/math.Max(float64(deadSeconds), 1))), // these conversions are dumb
			uint8(math.Floor(float64(desiredColor.G)/math.Max(float64(deadSeconds), 1))), // these conversions are dumb
			uint8(math.Floor(float64(desiredColor.B)/math.Max(float64(deadSeconds), 1))), // these conversions are dumb
			uint8(desiredColor.A),
		)

		x := float32(600)
		y := float32((i+1)*50 + i*50) // padding (plus top) + already existing noticiations

		r.sdlRenderer.DebugText(x+10, y+10, fmt.Sprintf("%s (%d)", curr.Message, i))

		// TODO: calculate pixel values instead of hardcode
		r.sdlRenderer.RenderRect(&sdl.FRect{
			X: x,
			Y: y,
			W: float32(99),
			H: float32(50),
		})
	}

	r.sdlRenderer.Present()

	return true
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
