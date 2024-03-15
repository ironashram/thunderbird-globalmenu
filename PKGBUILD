# Maintainer: Michele Palazzi <sysdadmin@m1k.cloud>
# Contributor: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Jan Alexander Steffens (heftig) <jan.steffens@gmail.com>
# Contributor: Ionut Biru <ibiru@archlinux.org>
# Contributor: Alexander Baldeck <alexander@archlinux.org>
# Contributor: Dale Blount <dale@archlinux.org>
# Contributor: Anders Bostrom <anders.bostrom@home.se>

pkgbase=thunderbird
pkgname=($pkgbase-globalmenu-m1k)
pkgver=115.8.1
pkgrel=1
pkgdesc='Standalone mail and news reader from mozilla.org'
url='https://www.thunderbird.net/'
arch=(x86_64)
license=('MPL-2.0' 'GPL-2.0-only' 'LGPL-2.1-only')
depends=(
  glibc
  gtk3 libgdk-3.so libgtk-3.so
  mime-types
  dbus libdbus-1.so
  dbus-glib
  alsa-lib
  nss
  hunspell
  sqlite
  ttf-font
  libvpx libvpx.so
  zlib
  bzip2 libbz2.so
  botan2
  libwebp libwebp.so libwebpdemux.so
  libevent
  libjpeg-turbo
  libffi libffi.so
  nspr
  gcc-libs
  libx11
  libxrender
  libxfixes
  libxext
  libxcomposite
  libxdamage
  pango libpango-1.0.so
  cairo
  gdk-pixbuf2
  freetype2 libfreetype.so
  fontconfig libfontconfig.so
  glib2 libglib-2.0.so
  pixman libpixman-1.so
  gnupg
  json-c
  libcanberra
  ffmpeg
  icu libicui18n.so libicuuc.so
)
makedepends=(
  unzip zip diffutils python nasm mesa libpulse libice libsm
  rust clang llvm cbindgen nodejs lld
  gawk perl findutils libotr wasi-compiler-rt wasi-libc wasi-libc++ wasi-libc++abi
)
options=(!emptydirs !makeflags !lto)
source=(https://archive.mozilla.org/pub/thunderbird/releases/$pkgver/source/thunderbird-$pkgver.source.tar.xz{,.asc}
        vendor-prefs.js
        distribution.ini
        mozconfig.cfg
        metainfo.patch
        org.mozilla.Thunderbird.desktop) # https://bugzilla.mozilla.org/show_bug.cgi?id=1862601
validpgpkeys=(
  14F26682D0916CDD81E37B6D61B7B526D98F0353 # Mozilla Software Releases <release@mozilla.com>
  4360FE2109C49763186F8E21EBE41E90F6F12F6D # Mozilla Software Releases <release@mozilla.com>
)

# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
# Note: These are for Arch Linux use ONLY. For your own distribution, please
# get your own set of keys. Feel free to contact foutrelis@archlinux.org for
# more information.
_google_api_key=AIzaSyDwr302FpOSkGRpLlUpPThNTDPbXcIn_FM

# Mozilla API keys (see https://location.services.mozilla.com/api)
# Note: These are for Arch Linux use ONLY. For your own distribution, please
# get your own set of keys. Feel free to contact heftig@archlinux.org for
# more information.
_mozilla_api_key=16674381-f021-49de-8622-3021c5942aff

prepare() {
  cd $pkgbase-$pkgver

  echo "${noextract[@]}"

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done
  sed -e 's|73114a5c28472e77082ad259113ffafb418ed602c1741f26da3e10278b0bf93e|a88d6cc10ec1322b53a8f4c782b5133135ace0fdfcf03d1624b768788e17be0f|' \
    -i third_party/rust/mp4parse/.cargo-checksum.json

  # Make icon transparent
  sed -i '/^<rect/d' comm/mail/branding/thunderbird/TB-symbolic.svg

  printf "%s" "$_google_api_key" >google-api-key
  printf "%s" "$_mozilla_api_key" >mozilla-api-key
  cp ../mozconfig.cfg .mozconfig
  sed "s|@PWD@|${PWD@Q}|g" -i .mozconfig
}

build() {
  cd $pkgbase-$pkgver
  if [[ -n "${SOURCE_DATE_EPOCH}" ]]; then
    export MOZ_BUILD_DATE=$(date --date "@${SOURCE_DATE_EPOCH}" "+%Y%m%d%H%M%S")
  fi
  export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none
  export MOZBUILD_STATE_PATH="${srcdir}/mozbuild"

  # malloc_usable_size is used in various parts of the codebase
  CFLAGS="${CFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"
  CXXFLAGS="${CXXFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"

  ./mach configure
  ./mach build
  ./mach buildsymbols
}

package() {
  optdepends=(
    'hunspell-en_us: Spell checking, American English'
    'libotr: OTR support for active one-to-one chats'
    'libnotify: Notification integration'
  )

  cd $pkgbase-$pkgver
  DESTDIR="$pkgdir" ./mach install

  install -Dm 644 ../vendor-prefs.js -t "$pkgdir/usr/lib/$pkgbase/defaults/pref"
  install -Dm 644 ../distribution.ini -t "$pkgdir/usr/lib/$pkgbase/distribution"
  install -Dm 644 ../org.mozilla.Thunderbird.desktop -t "$pkgdir/usr/share/applications"
  install -Dm 644 comm/mail/branding/thunderbird/net.thunderbird.Thunderbird.appdata.xml \
    "$pkgdir/usr/share/metainfo/net.thunderbird.Thunderbird.appdata.xml"

  for i in 16 22 24 32 48 64 128 256; do
    install -Dm644 comm/mail/branding/thunderbird/default${i}.png \
      "$pkgdir/usr/share/icons/hicolor/${i}x${i}/apps/org.mozilla.Thunderbird.png"
  done
  install -Dm644 comm/mail/branding/thunderbird/TB-symbolic.svg \
    "$pkgdir/usr/share/icons/hicolor/symbolic/apps/thunderbird-symbolic.svg"

  # Use system-provided dictionaries
  ln -Ts /usr/share/hunspell "$pkgdir/usr/lib/$pkgbase/dictionaries"
  ln -Ts /usr/share/hyphen "$pkgdir/usr/lib/$pkgbase/hyphenation"

  # Install a wrapper to avoid confusion about binary path
  install -Dm755 /dev/stdin "$pkgdir/usr/bin/$pkgbase" <<END
#!/bin/sh
exec /usr/lib/$pkgbase/thunderbird "\$@"
END

  # Replace duplicate binary with wrapper
  # https://bugzilla.mozilla.org/show_bug.cgi?id=658850
  ln -srf "$pkgdir/usr/bin/$pkgbase" \
    "$pkgdir/usr/lib/$pkgbase/thunderbird-bin"
}

sha512sums=('4d28f865f482a0d4c91f26ef26709a00f78955699b4ca191f960bcdb8d2c0c95c2a8e8782129d5660e192c605cba021fac553b13868861086a608f0c50aa5da7'
            'SKIP'
            '6918c0de63deeddc6f53b9ba331390556c12e0d649cf54587dfaabb98b32d6a597b63cf02809c7c58b15501720455a724d527375a8fb9d757ccca57460320734'
            '5cd3ac4c94ef6dcce72fba02bc18b771a2f67906ff795e0e3d71ce7db6d8a41165bd5443908470915bdbdb98dddd9cf3f837c4ba3a36413f55ec570e6efdbb9f'
            'a34dd97954f415a5ffe956ca1f10718bd164950566ceba328805c2ccbb54ed9081df07f2e063479bf932c4a443bb5b7443cca2f82eea3914465ed6e4863e0c0e'
            '7e43b1f25827ddae615ad43fc1e11c6ba439d6c2049477dfe60e00188a70c0a76160c59a97cc01d1fd99c476f261c7cecb57628b5be48874be7cf991c22db290'
            'fffeb73e2055408c5598439b0214b3cb3bb4e53dac3090b880a55f64afcbc56ba5d32d1187829a08ef06d592513d158ced1fde2f20e2f01e967b5fbd3b2fafd4'
            )

provides=(thunderbird)
conflicts=(thunderbird)
source+=(assert.patch
         unity-menubar.patch
         thunderbird-system-icu-74.patch)
sha512sums+=(7c9b126992bd5010a6c038c015eb0114d72e061e023de2a80adeded53f2db40115ebad2ed48394b1be3d5734cd3a244bc4c359cb7f44ab026c564424e3a5e5cb
             485c6396c7100d0f2b9d7dc327dc9ffd86199b15420b6bde556f90dfcbd34b29e35b669462031c15cac0b530bff0d06af42602aceb161a5fe1867ecacb54fef6
             9897cb0ababc8e1a0001c4e1f70e0b39f5cdb9c08c69e3afd42088dfd001aa1fc6996cd83df0db1fb57ee0a80686c35c8df783108408dbe9191602cddd1e3c65)
