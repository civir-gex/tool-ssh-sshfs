# ssh_sshfs.sh

Este script permite:

- Establecer conexión SSH sin contraseña usando llave pública
- Montar carpetas remotas mediante `sshfs`
- Crear servicios `systemd` para montajes persistentes
- Desmontar y limpiar servicios
- Todo desde una sola herramienta automatizada

## 🚀 Uso

```bash
/usr/bin/ssh_sshfs.sh usuario@servidor
```

- Inicia una conexión SSH sin contraseña (genera y copia llave si no existe)

```bash
/usr/bin/ssh_sshfs.sh usuario@servidor /ruta/remota
```

- Monta la carpeta remota en `/mnt/SSHFS/servidor`

```bash
/usr/bin/ssh_sshfs.sh usuario@servidor /ruta/remota nombre_local
```

- Monta la carpeta remota en `/mnt/SSHFS/nombre_local`

```bash
/usr/bin/ssh_sshfs.sh usuario@servidor [nombre_local] --cleanup
```

- Desmonta y elimina el punto de montaje, el servicio y la carpeta

---

## 📦 Requisitos

- Linux con systemd
- SSH y `ssh-copy-id`
- `sshfs` (se instalará automáticamente si no está)
- Permisos para crear servicios `systemd` (con `sudo`)

---

## 📁 Archivos y Rutas Utilizadas

| Ruta                                    | Descripción                                  |
|-----------------------------------------|----------------------------------------------|
| `~/.ssh/id_rsa`                         | Clave SSH generada si no existe              |
| `/mnt/SSHFS/<servidor>`                | Carpeta local de montaje                     |
| `/etc/systemd/system/sshfs-<servidor>.service` | Servicio systemd generado                    |

---

## 🧪 Ejemplo de Uso

```bash
./ssh_without_passwd.sh root@192.168.1.100 /data/compartida
```

Al ejecutar, preguntará:

```
¿Deseas generar el montaje persistente ahora? (s/n)
```

Si respondes `s`:

- Crea o desmonta el montaje si ya está activo.
- Genera y habilita el servicio `systemd`.
- Lo activa sin necesidad de reiniciar.

---

## 🧹 Modo Limpieza

```bash
sudo ./ssh_without_passwd.sh root@192.168.1.100 --cleanup
```

Acciones que realiza:

- Desmonta la carpeta si está montada.
- Elimina el servicio `systemd` si existe.
- Borrar el punto de montaje local.

---

## ⚠️ Notas

- **no lo ejecutes directamente como root**.
- Este script utiliza: `ping`, `ssh`, `sshfs`, `ssh-copy-id`, `systemd`.

---

## 📬 Autor

Jorge Borja Rojas