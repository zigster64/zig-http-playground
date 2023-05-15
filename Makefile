all:
	@echo Make options
	@cat Makefile

clean: zig-clean rust-clean

zig-clean:
	rm -rf zig-out zig-cache

rust-clean:
	rm -rf rust-server/target

zig-build:
	zig build -freference-trace -Doptimize=ReleaseFast
	ls -ltra zig-out/bin

rust-build:
	cd rust-server && cargo build && cargo build --release && ls -ltra target/debug/rust-server target/release/rust-server

run-single: zig-build
	zig-out/bin/zig-http-playground singlethread code 8080

run-pool2: zig-build
	zig-out/bin/zig-http-playground threadpool2 code 8080

run-poolmax: zig-build
	zig-out/bin/zig-http-playground threadpoolmax code 8080

run-threads: zig-build
	zig-out/bin/zig-http-playground threadmadness code 8080

os-single: zig-build
	zig-out/bin/zig-http-playground singlethread os 8080

os-pool2: zig-build
	zig-out/bin/zig-http-playground threadpool2 os 8080

os-poolmax: zig-build
	zig-out/bin/zig-http-playground threadpoolmax os 8080

os-threads: zig-build
	zig-out/bin/zig-http-playground threadmadness os 8080

siege:
	scripts/siege-std

siege-keepalive:
	scripts/siege-keepalive
