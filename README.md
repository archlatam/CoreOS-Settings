# CoreOS-Settings

Optimizaciones del sistema basadas en CachyOS-Settings para distribuciones Arch Linux.

## ZRAM Swap

- `usr/lib/systemd/zram-generator.conf.d/99-coreos.conf` - Configuración de zram-generator
- `usr/lib/udev/rules.d/99-coreos-zram.rules` - Reglas udev para zram

## Parámetros Kernel (sysctl)

- `usr/lib/sysctl.d/99-coreos.conf` - Parámetros de memoria, I/O y red

## Transparent HugePages

- `usr/lib/tmpfiles.d/thp.conf` - Configuración THP para tcmalloc
- `usr/lib/tmpfiles.d/thp-shrinker.conf` - THP shrinker (kernel 6.12+)

## Limpieza Sistema

- `usr/lib/tmpfiles.d/coredump.conf` - Limpieza de coredumps (3 días)

## Módulos del Kernel

- `usr/lib/modprobe.d/blacklist.conf` - Blacklist de watchdog modules

## Systemd

- `usr/lib/systemd/system.conf.d/99-coreos-timeout.conf` - Timeouts servicios
- `usr/lib/systemd/system.conf.d/99-coreos-limits.conf` - Límite file descriptors
- `usr/lib/systemd/journald.conf.d/99-coreos.conf` - Límite journal 50MB

## Límites Audio

- `etc/security/limits.d/20-audio.conf` - RT priority para audio

## Instalación

```bash
./install.sh
```

O manual:

```bash
# Copiar archivos
cp -r usr/lib/sysctl.d/* /etc/sysctl.d/
cp -r usr/lib/udev/rules.d/* /etc/udev/rules.d/
cp -r usr/lib/tmpfiles.d/* /etc/tmpfiles.d/
cp -r usr/lib/modprobe.d/* /etc/modprobe.d/
cp -r etc/security/limits.d/* /etc/security/limits.d/
cp -r usr/lib/systemd/system.conf.d/* /etc/systemd/system.conf.d/
cp -r usr/lib/systemd/journald.conf.d/* /etc/systemd/journald.conf.d/
cp -r usr/lib/systemd/zram-generator.conf.d/* /etc/systemd/zram-generator.conf.d/

# Aplicar cambios
sysctl --system
udevadm control --reload-rules
systemd-tmpfiles --create
```

## Requisitos

- `zram-generator` (para zram automático)
- `systemd` >= 256
- Kernel >= 6.12 (para thp-shrinker)
- Arch Linux o derivada

## Verificación

```bash
# Ver zram activo
zramctl

# Ver swap
swapon -s

# Ver swappiness
cat /proc/sys/vm/swappiness

# Ver zswap desactivado
cat /sys/module/zswap/parameters/enabled
```

## Configuración ZRAM

| Parámetro | Valor |
|-----------|-------|
| Algoritmo | zstd |
| Tamaño | 100% RAM |
| Prioridad | 100 |
| Swappiness | 150 |
| zswap | Desactivado |

## Desinstalación

```bash
rm /etc/sysctl.d/99-coreos.conf
rm /etc/udev/rules.d/99-coreos-zram.rules
rm /etc/tmpfiles.d/thp.conf
rm /etc/tmpfiles.d/thp-shrinker.conf
rm /etc/tmpfiles.d/coredump.conf
rm /etc/modprobe.d/blacklist.conf
rm /etc/security/limits.d/20-audio.conf
rm /etc/systemd/system.conf.d/99-coreos-*.conf
rm /etc/systemd/journald.conf.d/99-coreos.conf
rm /etc/systemd/zram-generator.conf.d/99-coreos.conf
```
