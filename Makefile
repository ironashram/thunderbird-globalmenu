export CC := sccache clang
export CXX := sccache clang++
export LIBGL_ALWAYS_SOFTWARE := true

.PHONY: clean
clean:
	rm -rf src/ pkg/

.PHONY: get_src
get_src:
	makepkg -o

.PHONY: build
build:
	makepkg -e

.PHONY: all
all: clean get_src build
