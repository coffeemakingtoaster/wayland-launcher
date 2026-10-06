package notifications

import (
	"sync"
	"time"

	"github.com/coffeemakingtoaster/wayland-launcher/pkg/color"
	"github.com/coffeemakingtoaster/wayland-launcher/pkg/ds"
)

type Severity int

const NOTIFICATION_RING_SIZE = 3

const NOTIFICATION_ACTIVE_SECONDS = 3
const NOTIFICATION_DYING_SECONDS = 2

const (
	SEVERITY_INFO = iota
	SEVERITY_WARN
	SEVERITY_ERROR
)

type Notification struct {
	Message       string
	Severity      Severity
	startedAt     int64
	totalLifetime int64
	next          *Notification
}

func NewNotification(message string) Notification {
	return Notification{
		Message:       message,
		Severity:      SEVERITY_INFO,
		startedAt:     -1,
		totalLifetime: NOTIFICATION_ACTIVE_SECONDS,
	}
}

func (n *Notification) Start() {
	// already started
	if n.startedAt >= 0 {
		return
	}
	n.startedAt = time.Now().Unix()
}

func (n *Notification) DeceseadTimer() int64 {
	if n.startedAt < 0 {
		return 0
	}
	return time.Now().Unix() - n.startedAt - int64(n.totalLifetime)
}

func (n *Notification) HasFullyDied() bool {
	if n.startedAt < 0 {
		return false
	}
	return n.DeceseadTimer() > NOTIFICATION_DYING_SECONDS
}

func (n *Notification) DesiredColor() color.Color {
	switch n.Severity {
	case SEVERITY_WARN:
		return color.Color{125, 0, 0, 255}
	case SEVERITY_ERROR:
		return color.Color{255, 0, 0, 255}
	}

	return color.Color{255, 255, 255, 255}
}

type Notifier struct {
	ring  *ds.Ring[Notification]
	mutex sync.Mutex
}

func NewNotifier() (*Notifier, error) {
	ring, err := ds.NewRing[Notification](NOTIFICATION_RING_SIZE, NOTIFICATION_ACTIVE_SECONDS+NOTIFICATION_DYING_SECONDS)
	if err != nil {
		return nil, err
	}
	return &Notifier{
		ring: ring,
	}, nil
}

func (n *Notifier) Notify(newNotification Notification) {
	n.ring.Insert(&newNotification)
}

func (n *Notifier) GetNotificationsInOrder() []Notification {
	return n.ring.GetValuesInOrder()
}
