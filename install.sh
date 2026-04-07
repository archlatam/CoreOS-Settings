#!/bin/bash
# install.sh - Script de instalación para CoreOS-Settings
# Usa la misma configuración que CachyOS-Settings

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "     CoreOS-Settings - Instalador"
echo "============================================"
echo ""

# Verificar root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root${NC}"
    echo "Uso: sudo $0"
    exit 1
fi

check_install() {
    if pacman -Q "$1" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $1 instalado"
        return 0
    else
        echo -e "${YELLOW}[?]${NC} $1 no instalado"
        return 1
    fi
}

install_pkg() {
    echo -e "${YELLOW}[→]${NC} Instalando $1..."
    if pacman -S --needed --noconfirm "$1" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $1 instalado"
        return 0
    else
        echo -e "${RED}[✗]${NC} Error instalando $1"
        return 1
    fi
}

check_command() {
    command -v "$1" &>/dev/null
}

echo "=== Verificando dependencias ==="
echo ""

MISSING_PKGS=()
ZRAM_GENERATOR=false

# Paquetes requeridos (ya vienen con el sistema)
echo "Paquetes del sistema:"
for pkg in systemd systemd-sysvcompat; do
    check_install "$pkg"
done

# zram-generator
if check_install "zram-generator"; then
    ZRAM_GENERATOR=true
else
    MISSING_PKGS+=("zram-generator:Configuración automática de zram")
fi

# Paquetes opcionales
OPTIONAL_PKGS=(
    "lua:Scripts Lua (topmem)"
    "hdparm:Optimización de discos HDD"
)

echo ""
echo "Paquetes opcionales:"
for entry in "${OPTIONAL_PKGS[@]}"; do
    pkg="${entry%%:*}"
    if check_install "$pkg"; then
        MISSING_PKGS+=("$pkg")
    fi
done

# Instalar zram-generator si no está
if [ "$ZRAM_GENERATOR" = false ]; then
    echo ""
    read -p "¿Instalar zram-generator para configuración automática de zram? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        install_pkg "zram-generator"
        ZRAM_GENERATOR=true
    fi
fi

echo ""
echo "=== Copiando archivos ==="

# Directorios
SYSCTL_DIR="/etc/sysctl.d"
UDEV_DIR="/etc/udev/rules.d"
TMPFILES_DIR="/etc/tmpfiles.d"
MODPROBE_DIR="/etc/modprobe.d"
LIMITS_DIR="/etc/security/limits.d"
SYSTEMD_CONF="/etc/systemd/system.conf.d"
JOURNALD_CONF="/etc/systemd/journald.conf.d"
ZRAMSWAP_CONF="/etc/systemd/zram-generator.conf.d"

mkdir -p "$SYSCTL_DIR" "$UDEV_DIR" "$TMPFILES_DIR" "$MODPROBE_DIR" \
         "$LIMITS_DIR" "$SYSTEMD_CONF" "$JOURNALD_CONF" "$ZRAMSWAP_CONF"

# sysctl
cp -v usr/lib/sysctl.d/99-coreos.conf "$SYSCTL_DIR/"

# udev
cp -v usr/lib/udev/rules.d/*.rules "$UDEV_DIR/"

# tmpfiles
cp -v usr/lib/tmpfiles.d/*.conf "$TMPFILES_DIR/"

# modprobe
cp -v usr/lib/modprobe.d/*.conf "$MODPROBE_DIR/"

# limits
cp -v etc/security/limits.d/*.conf "$LIMITS_DIR/"

# systemd system.conf.d
cp -v usr/lib/systemd/system.conf.d/*.conf "$SYSTEMD_CONF/"

# systemd journald.conf.d
cp -v usr/lib/systemd/journald.conf.d/*.conf "$JOURNALD_CONF/"

# zram-generator
if [ "$ZRAM_GENERATOR" = true ]; then
    echo ""
    echo "=== Configurando ZRAM ==="
    cp -v usr/lib/systemd/zram-generator.conf.d/*.conf "$ZRAMSWAP_CONF/"
    echo -e "${GREEN}zram-generator configurado${NC}"
fi

echo ""
echo "=== Aplicando cambios ==="

if check_command "sysctl"; then
    echo "Aplicando parámetros sysctl..."
    sysctl --system 2>/dev/null || true
fi

if check_command "udevadm"; then
    echo "Recargando reglas udev..."
    udevadm control --reload-rules
fi

if check_command "systemd-tmpfiles"; then
    echo "Creando archivos tmpfiles..."
    systemd-tmpfiles --create
fi

echo ""
echo "============================================"
echo -e "${GREEN}     Instalación completada${NC}"
echo "============================================"
echo ""
echo "Archivos instalados:"
echo "  - $SYSCTL_DIR/99-coreos.conf"
echo "  - $UDEV_DIR/99-coreos-zram.rules"
echo "  - $TMPFILES_DIR/*.conf"
echo "  - $MODPROBE_DIR/*.conf"
echo "  - $LIMITS_DIR/*.conf"
if [ "$ZRAM_GENERATOR" = true ]; then
echo "  - $ZRAMSWAP_CONF/99-coreos.conf (zram)"
fi
echo ""
echo -e "${YELLOW}Reinicia el sistema para aplicar todos los cambios${NC}"
echo ""
