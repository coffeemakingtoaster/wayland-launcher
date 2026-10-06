package panel

import (
	"log"

	"github.com/coffeemakingtoaster/wayland-launcher/pkg/config"
)

type Panel struct {
	top    *Panel
	down   *Panel
	left   *Panel
	right  *Panel
	launch int //TODO
	Name   string
	Width  int
	Height int
}

func (p *Panel) returnOrSelf(primary *Panel) *Panel {
	if primary == nil {
		return p
	}
	return primary
}

func (p *Panel) Down() *Panel {
	return p.returnOrSelf(p.down)
}

func (p *Panel) Top() *Panel {
	return p.returnOrSelf(p.top)
}

func (p *Panel) Left() *Panel {
	return p.returnOrSelf(p.left)
}

func (p *Panel) Right() *Panel {
	return p.returnOrSelf(p.right)
}

func (p *Panel) Launch() {
	log.Println("LAUNCHING...")
}

func constructGridFromConfig(c *config.Config) *Panel {
	log.Printf("Building internal panel grid")
	panels := c.Panels
	var root *Panel
	var prevRoot *Panel
	idx := 0
	for idx <= len(panels) {
		r := buildPanelCol(panels, idx, c.GridYCount, prevRoot)
		if root == nil {
			root = r
		}
		prevRoot = r
		idx += c.GridYCount
	}
	log.Printf("Built internal panel grid row")

	return root
}

func buildPanelCol(ccp []*config.ConfigPanel, idx int, cHeight int, leftNeighbor *Panel) *Panel {
	log.Printf("Building internal panel grid column")

	var rowStart *Panel
	var previousPanel *Panel
	i := idx
	for i-idx < cHeight && i < len(ccp) {
		curr := buildPanel(ccp[i])
		if rowStart == nil {
			rowStart = curr
		}
		if previousPanel != nil {
			previousPanel.down = curr
			curr.top = previousPanel
		}

		if leftNeighbor != nil {
			leftNeighbor.right = curr
			curr.left = leftNeighbor
			leftNeighbor = leftNeighbor.down
		}

		previousPanel = curr
		i = i + 1
	}

	return rowStart
}

func buildPanel(ccp *config.ConfigPanel) *Panel {
	return &Panel{
		top:    nil,
		down:   nil,
		left:   nil,
		right:  nil,
		launch: 0,
		Name:   ccp.Name,
	}
}
