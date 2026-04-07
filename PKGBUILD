# Maintainer: Tu Nombre <tu@email.com>

_gitname=CoreOS-Settings
pkgname=coreos-settings
pkgver=1.0.0
pkgrel=1
pkgdesc="CoreOS optimizations based on CachyOS-Settings - ZRAM, sysctl, udev rules"
arch=('any')
url="https://github.com/tu-usuario/CoreOS-Settings"
license=('GPL-3.0-or-later')
depends=(
    'systemd'
    'zram-generator'
)
optdepends=(
    'lua: for Lua scripts'
    'hdparm: for HDD optimization'
)
makedepends=('git')
provides=('coreos-optimizations')
conflicts=()
replaces=()
backup=()
install=
sha256sums=('SKIP')

prepare() {
    cd "$srcdir"
    if [ -d "$_gitname" ]; then
        cd "$_gitname"
        git pull
    fi
}

build() {
    cd "$srcdir/$_gitname"
}

package() {
    # sysctl
    install -dm755 "$pkgdir/etc/sysctl.d"
    install -m644 usr/lib/sysctl.d/*.conf "$pkgdir/etc/sysctl.d/"

    # udev rules
    install -dm755 "$pkgdir/etc/udev/rules.d"
    install -m644 usr/lib/udev/rules.d/*.rules "$pkgdir/etc/udev/rules.d/"

    # tmpfiles
    install -dm755 "$pkgdir/etc/tmpfiles.d"
    install -m644 usr/lib/tmpfiles.d/*.conf "$pkgdir/etc/tmpfiles.d/"

    # modprobe
    install -dm755 "$pkgdir/etc/modprobe.d"
    install -m644 usr/lib/modprobe.d/*.conf "$pkgdir/etc/modprobe.d/"

    # security limits
    install -dm755 "$pkgdir/etc/security/limits.d"
    install -m644 etc/security/limits.d/*.conf "$pkgdir/etc/security/limits.d/"

    # systemd system.conf.d
    install -dm755 "$pkgdir/etc/systemd/system.conf.d"
    install -m644 usr/lib/systemd/system.conf.d/*.conf "$pkgdir/etc/systemd/system.conf.d/"

    # systemd journald.conf.d
    install -dm755 "$pkgdir/etc/systemd/journald.conf.d"
    install -m644 usr/lib/systemd/journald.conf.d/*.conf "$pkgdir/etc/systemd/journald.conf.d/"

    # zram-generator
    install -dm755 "$pkgdir/etc/systemd/zram-generator.conf.d"
    install -m644 usr/lib/systemd/zram-generator.conf.d/*.conf \
        "$pkgdir/etc/systemd/zram-generator.conf.d/"
}
