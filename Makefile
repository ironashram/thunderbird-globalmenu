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

.PHONY: repo-add
repo-add:
	cp $$(ls -Art *.pkg.tar.zst | tail -n 1) ~/arch-local-repo/x86_64
	cd ~/arch-local-repo/x86_64 && repo-add arch-local-repo.db.tar.gz *.pkg.tar.zst

.PHONY: upload
upload:
	s3cmd --config ~/.s3cfg.minio sync --delete-removed --follow-symlinks --acl-public ~/arch-local-repo/ s3://arch-local-repo/

.PHONY: all
all: clean get_src build repo-add upload
