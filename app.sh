CPPFLAGS="${CPPFLAGS} -I${DEST}/include"

### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEST}"
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### LIBFFI ###
_build_libffi() {
local VERSION="3.2.1"
local FOLDER="libffi-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://sourceware.org/pub/libffi/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

# required by glib's native compilation below
if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  ./configure --prefix="${DEPS}-native"
  make
  make install )
fi

pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEST}" --disable-static
make
make install
cp -v "${DEST}/lib/${FOLDER}/include"/* "${DEST}/include/"
popd
}

### GLIB ###
_build_glib() {
local MAJOR="2.47"
local VERSION="${MAJOR}.4"
local FOLDER="glib-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnome.org/pub/gnome/sources/glib/${MAJOR}/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"

if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  PKG_CONFIG_PATH="${DEPS}-native/lib/pkgconfig" \
    ./configure --prefix="${DEPS}-native"
  make
  make install )
fi

pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
PATH="${DEPS}-native/bin:${PATH}" \
  ./configure --host="${HOST}" --prefix="${DEST}" --disable-static \
    glib_cv_stack_grows=no \
    glib_cv_uscore=no \
    ac_cv_func_posix_getpwuid_r=yes \
    ac_cv_func_posix_getgrgid_r=yes
make
make install
popd
}

### GOBJECT-INTROSPECTION ###
_build_gobject() {
local MAJOR="1.47"
local VERSION="${MAJOR}.1"
local FOLDER="gobject-introspection-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnome.org/pub/gnome/sources/gobject-introspection/${MAJOR}/${FILE}"
local GLIBSRC="${PWD}/target/glib-2.47.4"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
cp src/ldd "target/${FOLDER}/"
pushd "target/${FOLDER}"
export PATH="${PWD}:${PATH}"
export PKG_CONFIG_PATH="${DEST}/lib/pkgconfig"
CPPFLAGS="${CPPFLAGS} -I${DEST}/lib" \
  ./configure --host="${HOST}" --prefix="${DEST}" --disable-static \
    --with-glib-src="${GLIBSRC}" \
    --without-cairo --with-python="${XPYTHON}/bin/python"
make
make install
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_libffi
  _build_glib
  _build_gobject
  _package
}
