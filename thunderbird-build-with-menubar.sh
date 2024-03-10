#!/bin/sh

########################################################################################################################
# This script takes the Arch stable thunderbird PKGBUILD, revises it to add the appmenu/menubar patches, and optionally
# builds the modified thunderbird.
########################################################################################################################

# Download current PKGBUILD from Arch
wget -q -O- https://gitlab.archlinux.org/archlinux/packaging/packages/thunderbird/-/archive/main/thunderbird-main.tar.gz | \
  tar -xzf - --strip-components=1

# Download menubar patch from firefox-appmenu-112.0-1
wget -q -N https://raw.githubusercontent.com/archlinux/aur/1ab4aad0eaaa2f5313aee62606420b0b92c3d238/unity-menubar.patch

# Generate assert.patch
cat << EOF > assert.patch
--- a/xpcom/base/nsCOMPtr.h	2023-06-29 13:34:21.000000000 -0400
+++ b/xpcom/base/nsCOMPtr.h	2023-07-06 11:03:59.049048830 -0400
@@ -815,10 +815,6 @@
                                  const nsIID& aIID) {
   // Allow QIing to nsISupports from nsISupports as a special-case, since
   // SameCOMIdentity uses it.
-  static_assert(
-      std::is_same_v<T, nsISupports> ||
-          !(std::is_same_v<T, U> || std::is_base_of<T, U>::value),
-      "don't use do_QueryInterface for compile-time-determinable casts");
   void* newRawPtr;
   if (NS_FAILED(aQI(aIID, &newRawPtr))) {
     newRawPtr = nullptr;
EOF

# Save original PKGBUILD
cp PKGBUILD PKGBUILD.orig

# Revise maintainer string on PKGBUILD
printf "Enter maintainer string: "
read -r maintainer
if [[ -n $maintainer ]]; then
  sed -i "s/# Maintainer:/# Contributor:/g;
          1i # Maintainer: $maintainer" PKGBUILD
fi

# Get number of sources
n=$(sed -n '/^source/,/)/p' PKGBUILD | wc -l)

# Don't build language packs
sed -ni '/^_package_i18n()/,/^sha512sums/{/^sha512sums/!d};
         1,/^sha512sums/{/^sha512sums/!p};
         /^sha512sums/,+'$n'p' PKGBUILD
echo "            )" >> PKGBUILD

# Default to -appmenu suffix
printf "Append -appmenu to package name? [Y/n] "
read -r ans
if [[ "$ans" != n && "$ans" != no ]]; then
  sed -i 's/$pkgname/$pkgbase/g;
          s/pkgname=(thunderbird)/pkgname=($pkgbase-appmenu)/g;
          s/package_thunderbird()/package()/g' PKGBUILD
  printf "
provides=(thunderbird)
conflicts=(thunderbird)" >> PKGBUILD
fi

# Add menubar patches
echo "
source+=(assert.patch
         unity-menubar.patch)
sha512sums+=(7c9b126992bd5010a6c038c015eb0114d72e061e023de2a80adeded53f2db40115ebad2ed48394b1be3d5734cd3a244bc4c359cb7f44ab026c564424e3a5e5cb
             485c6396c7100d0f2b9d7dc327dc9ffd86199b15420b6bde556f90dfcbd34b29e35b669462031c15cac0b530bff0d06af42602aceb161a5fe1867ecacb54fef6)" \
>> PKGBUILD

# Build
printf "PKGBUILD generated. Continue with build? [y/N] "
read -r ans
if [[ "$ans" == y || "$ans" == yes ]]; then
  makepkg --skippgpcheck -s
fi
