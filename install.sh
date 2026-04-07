#!/bin/bash
# install.sh - Script de instalación para CoreOS-Settings
# Autor: Basado en CachyOS-Settings

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "     CoreOS-Settings - Instalador"
echo "============================================"
echo ""

# Verificar que se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root${NC}"
    echo "Uso: sudo $0"
    exit 1
fi

# Función para verificar e instalar paquete
check_install() {
    local pkg="$1"
    local desc="$2"
    
    if pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $pkg (ya instalado)"
        return 0
    else
        echo -e "${YELLOW}[?]${NC} $pkg (no instalado)"
        return 1
    fi
}

# Función para instalar paquete
install_pkg() {
    local pkg="$1"
    local desc="$2"
    
    echo -e "${YELLOW}[→]${NC} Instalando $pkg..."
        if pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $pkg instalado"
        return 0
    else
        echo -e "${RED}[✗]${NC} Error instalando $pkg"
        return 1
    fi
}

# Verificar dependencia
check_command() {
    command -v "$1" &>/dev/null
}

echo "=== Verificando dependencias ==="
echo ""

# Paquetes requeridos (ya vienen con el sistema base)
REQUIRED_PKGS=(
    "systemd"
    "systemd-sysvcompat"
)

# Paquetes opcionales
OPTIONAL_PKGS=(
    "zram-generator:Configuración automática de zram"
    "lua:Scripts Lua (topmem)"
    "hdparm:Optimización de discos HDD"
)

MISSING_OPTIONAL=()
USE_ZRAM_GENERATOR=false

echo "Paquetes requeridos:"
for pkg in "${REQUIRED_PKGS[@]}"; do
    check_install "$pkg"
done

echo ""
echo "Paquetes opcionales:"
for entry in "${OPTIONAL_PKGS[@]}"; do
    pkg="${entry%%:*}"
    desc="${entry##*:}"
    if check_install "$pkg"; then
        if [ "$pkg" = "zram-generator" ]; then
            USE_ZRAM_GENERATOR=true
        fi
    else
        MISSING_OPTIONAL+=("$pkg:$desc")
    fi
done

echo ""
echo "=== Instalando dependencias opcionales ==="
if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    echo "Los siguientes paquetes opcionales no están instalados:"
    for entry in "${MISSING_OPTIONAL[@]}"; do
        pkg="${entry%%:*}"
        desc="${entry##*:}"
        echo "  - $pkg: $desc"
    done
    echo ""
    read -p "¿Deseas instalarlos? (s/n, default=n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        for entry in "${MISSING_OPTIONAL[@]}"; do
            pkg="${entry%%:*}"
            desc="${entry##*:}"
            install_pkg "$pkg" "$desc"
        done
        if [ -f "/usr/bin/zram-generator" ]; then
            USE_ZRAM_GENERATOR=true
        fi
    fi
else
    echo -e "${GREEN}Todos los paquetes opcionales ya están instalados${NC}"
fi

echo ""
echo "=== Directorios de destino ==="

SYSCTL_DIR="/etc/sysctl.d"
UDEV_DIR="/etc/udev/rules.d"
TMPFILES_DIR="/etc/tmpfiles.d"
MODPROBE_DIR="/etc/modprobe.d"
LIMITS_DIR="/etc/security/limits.d"
SYSTEMD_CONF_DIR="/etc/systemd/system.conf.d"

mkdir -p "$SYSCTL_DIR" "$UDEV_DIR" "$TMPFILES_DIR" "$MODPROBE_DIR" "$LIMITS_DIR" "$SYSTEMD_CONF_DIR"

echo "  - $SYSCTL_DIR"
echo "  - $UDEV_DIR"
echo "  - $TMPFILES_DIR"
echo "  - $MODPROBE_DIR"
echo "  - $LIMITS_DIR"
echo "  - $SYSTEMD_CONF_DIR"

echo ""
echo "=== Copiando archivos de configuración ==="

cp -v usr/lib/sysctl.d/*.conf "$SYSCTL_DIR/"
cp -v usr/lib/udev/rules.d/*.rules "$UDEV_DIR/"
cp -v usr/lib/tmpfiles.d/*.conf "$TMPFILES_DIR/"
cp -v usr/lib/modprobe.d/*.conf "$MODPROBE_DIR/"
cp -v etc/security/limits.d/*.conf "$LIMITS_DIR/"
cp -v usr/lib/systemd/system.conf.d/*.conf "$SYSTEMD_CONF_DIR/"

if [ -d "usr/lib/systemd/journald.conf.d" ]; then
    mkdir -p /etc/systemd/journald.conf.d
    cp -v usr/lib/systemd/journald.conf.d/*.conf /etc/systemd/journald.conf.d/
fi

echo ""
echo "=== Configuración de ZRAM ==="

if [ -f usr/lib/systemd/zram.conf ]; then
    read -p "¿Instalar configuración de zram? (s/n, default=s): " -n 1 -r
    echo
    : ${REPLY:=s}
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cp -v usr/lib/systemd/zram.conf /etc/systemd/
        
        if [ "$USE_ZRAM_GENERATOR" = true ] || check_command "systemd-zram-setup@zram0"; then
            echo -e "${GREEN}Usando zram-generator${NC}"
            systemctl enable systemd-zram-setup@zram0
        else
            echo -e "${YELLOW}zram-generator no disponible, usando script manual${NC}"
            read -p "¿Instalar script manual de zram? (s/n, default=s): " -n 1 -r
            echo
            : ${REPLY:=s}
            
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                cp -v usr/lib/systemd/system/zram-swap.service /etc/systemd/system/
                cp -v usr/bin/zram-setup.sh /usr/bin/
                chmod +x /usr/bin/zram-setup.sh
                systemctl enable zram-swap
                echo -e "${GREEN}Servicio zram-swap habilitado${NC}"
            fi
        fi
    fi
fi

echo ""
echo "=== Aplicando cambios ==="

echo "Aplicando parámetros sysctl..."
if sysctl --system &>/dev/null; then
    echo -e "${GREEN}[✓]${NC} Parámetros sysctl aplicados"
else
    for conf in "$SYSCTL_DIR"/*.conf; do
        if [ -f "$conf" ]; then
            sysctl -p "$conf" 2>/dev/null && echo -e "${GREEN}[✓]${NC} $(basename $conf)"
        fi
    done
fi

echo "Recargando reglas udev..."
if check_command "udevadm"; then
    udevadm control --reload-rules
    echo -e "${GREEN}[✓]${NC} Reglas udev recargadas"
fi

echo "Creando archivos tmpfiles..."
if check_command "systemd-tmpfiles"; then
    systemd-tmpfiles --create
    echo -e "${GREEN}[✓]${NC} tmpfiles creados"
fi

echo ""
echo "============================================"
echo -e "${GREEN}     Instalación completada${NC}"
echo "============================================"
echo ""
echo "Archivos instalados:"
echo "  - $SYSCTL_DIR/*.conf"
echo "  - $UDEV_DIR/*.rules"
echo "  - $TMPFILES_DIR/*.conf"
echo "  - $MODPROBE_DIR/*.conf"
echo "  - $LIMITS_DIR/*.conf"
echo ""
echo -e "${YELLOW}Importante: Reinicia el sistema para aplicar todos los cambios${NC}"
echo ""
