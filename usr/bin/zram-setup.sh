#!/bin/bash
# zram-setup.sh - Configuración de zram sin zram-generator
# Autor: Basado en CachyOS-Settings

set -e

ZRAM_DEV="/dev/zram0"
ALGORITHM="${1:-zstd}"
PRIORITY=100

setup_zram() {
    modprobe zram num_devices=1
    
    echo "$ALGORITHM" > /sys/block/zram0/comp_algorithm
    
    local ram_size=$(free -b | awk 'NR==2{print $2}')
    local zram_size=$((ram_size / 2))
    echo "$zram_size" > /sys/block/zram0/disksize
    
    mkswap -L "zram-swap" "$ZRAM_DEV"
    swapon "$ZRAM_DEV" -p "$PRIORITY"
    
    echo 150 > /proc/sys/vm/swappiness
    
    if [ -w /sys/module/zswap/parameters/enabled ]; then
        echo N > /sys/module/zswap/parameters/enabled
    fi
    
    echo "ZRAM configurado:"
    echo "  - Algoritmo: $ALGORITHM"
    echo "  - Tamaño: $((zram_size / 1024 / 1024 / 1024))G"
    echo "  - Prioridad: $PRIORITY"
    zramctl "$ZRAM_DEV"
}

teardown_zram() {
    swapoff "$ZRAM_DEV" 2>/dev/null || true
    modprobe -r zram 2>/dev/null || true
}

case "${1:-setup}" in
    setup)
        setup_zram
        ;;
    teardown)
        teardown_zram
        ;;
    *)
        echo "Uso: $0 {setup|teardown}"
        exit 1
        ;;
esac
