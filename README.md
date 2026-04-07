# CoreOS-Settings
Optimizaciones del sistema basadas en CachyOS-Settings para distribuciones Arch Linux.

## Contenido

### ZRAM Swap
- `usr/lib/systemd/zram.conf` - Configuración de zram-generator
- `usr/lib/udev/rules.d/30-zram.rules` - Reglas udev para zram

### Parámetros Kernel (sysctl)
- `usr/lib/sysctl.d/99-coreos.conf` - Parámetros de memoria, I/O y red

### Transparent HugePages
- `usr/lib/tmpfiles.d/thp.conf` - Configuración THP para tcmalloc
- `usr/lib/tmpfiles.d/thp-shrinker.conf` - THP shrinker (kernel 6.12+)

### Limpieza Sistema
- `usr/lib/tmpfiles.d/coredump.conf` - Limpieza de coredumps (3 días)

### Módulos del Kernel
- `usr/lib/modprobe.d/blacklist.conf` - Blacklist de watchdog modules

### Límites Audio
- `etc/security/limits.d/20-audio.conf` - RT priority para audio

### Systemd
- `usr/lib/systemd/system.conf.d/` - Timeouts y file limits

## Instalación

```bash
# Copiar archivos
cp -r usr/lib/sysctl.d/* /etc/sysctl.d/
cp -r usr/lib/udev/rules.d/* /etc/udev/rules.d/
cp -r usr/lib/tmpfiles.d/* /etc/tmpfiles.d/
cp -r usr/lib/modprobe.d/* /etc/modprobe.d/
cp -r etc/security/limits.d/* /etc/security/limits.d/
cp -r usr/lib/systemd/system.conf.d/* /etc/systemd/system.conf.d/

# ZRAM (requiere zram-generator)
cp usr/lib/systemd/zram.conf /etc/systemd/

# Habilitar servicios
systemctl enable systemd-zram-setup@zram0

# Aplicar cambios
sysctl --system
udevadm control --reload-rules
tmpfiles --create
```

## Requisitos

- `zram-generator` (para zram automático)
- `systemd` >= 256
- Kernel >= 6.12 (para thp-shrinker)
