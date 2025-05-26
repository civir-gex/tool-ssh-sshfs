# ssh_sshfs.sh

Este script permite:

- Establecer conexión SSH sin contraseña usando llave pública
- Montar carpetas remotas mediante `sshfs`
- Crear servicios `systemd` para montajes persistentes
- Desmontar y limpiar servicios
- Todo desde una sola herramienta automatizada

---

## 🚀 Uso

```bash
./ssh_sshfs.sh usuario@servidor[:puerto]
```

- Inicia una conexión SSH sin contraseña (genera y copia llave si no existe)

```bash
./ssh_sshfs.sh usuario@servidor[:puerto] /ruta/remota
```

- Monta la carpeta remota en `/mnt/SSHFS/<servidor>`

```bash
./ssh_sshfs.sh usuario@servidor[:puerto] /ruta/remota nombre_local
```

- Monta la carpeta remota en `/mnt/SSHFS/nombre_local`

```bash
./ssh_sshfs.sh usuario@servidor[:puerto] [nombre_local] --cleanup
```

- Desmonta y elimina el punto de montaje, el servicio y la carpeta

---

## 📦 Requisitos

- Linux con `systemd`
- `ssh` y `ssh-copy-id`
- `sshfs` (se instalará automáticamente si no está)
- Permisos para crear servicios `systemd` (`sudo` requerido)

---

## 📁 Archivos y Rutas Utilizadas

| Ruta                                                | Descripción                                  |
|-----------------------------------------------------|----------------------------------------------|
| `~/.ssh/id_rsa`                                     | Clave SSH generada si no existe              |
| `/mnt/SSHFS/<servidor>`                             | Carpeta local de montaje por defecto         |
| `/mnt/SSHFS/<nombre_local>`                         | Carpeta local de montaje personalizada       |
| `/etc/systemd/system/sshfs-<nombre_local>.service`  | Servicio `systemd` generado                  |

---

## 🧪 Ejemplos

### 1. Conexión SSH sin contraseña

```bash
./ssh_sshfs.sh jorge@192.168.1.100
```

### 2. Montaje de carpeta remota en el puerto 22

```bash
./ssh_sshfs.sh jorge@192.168.1.100 /home/jorge/datos
```

### 3. Montaje con puerto SSH personalizado

```bash
./ssh_sshfs.sh jorge@192.168.1.100:2222 /home/jorge/datos datos-local
```

> Montará `/home/jorge/datos` del servidor `192.168.1.100` vía puerto `2222` en `/mnt/SSHFS/datos-local`.

---

## 🧹 Modo Limpieza

```bash
./ssh_sshfs.sh jorge@192.168.1.100:2222 datos-local --cleanup
```

Acciones que realiza:

- Desmonta la carpeta si está montada
- Elimina el servicio `systemd` si existe
- Borra el punto de montaje local

---

## ⚠️ Notas

- **No ejecutes este script directamente como `root`**: usa `sudo` para preservar la identidad del usuario real.
- Este script usa: `ping`, `ssh`, `sshfs`, `ssh-copy-id`, `systemd`
- Todos los montajes se almacenan bajo `/mnt/SSHFS/`

---

## 📬 Autor

**Jorge Borja Rojas**
