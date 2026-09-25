.PHONY: run build clean tidy

run:
	go run .

run-fullscreen:
	WAYLAND_LAUNCHER_FULLSCREEN=true go run .

build:
	go build -o wayland-launcher .

tidy:
	go mod tidy

clean:
	rm -f wayland-launcher