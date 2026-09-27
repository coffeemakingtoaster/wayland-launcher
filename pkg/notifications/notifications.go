package notifications

import "time"

type Severity int

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
}

func NewNotification(message string) Notification {
	return Notification{
		Message:       message,
		Severity:      SEVERITY_INFO,
		startedAt:     -1,
		totalLifetime: 3,
	}
}

func (n *Notification) Start() {
	n.startedAt = time.Now().Unix()
}

func (n *Notification) DeceseadTimer() int64 {
	if n.startedAt < 0 {
		return 0
	}
	return time.Now().Unix() - n.startedAt - int64(n.totalLifetime)
}

type Notifier struct {
	queue chan Notification
}

func NewNotifier(capacity int) *Notifier {
	return &Notifier{
		queue: make(chan Notification, capacity),
	}
}

func (n *Notifier) Notify(notification Notification) {
	n.queue <- notification
}

func (n *Notifier) GetOldestNotification() *Notification {
	select {
	case notification := <-n.queue:
		return &notification
	default:
		return nil
	}
}
