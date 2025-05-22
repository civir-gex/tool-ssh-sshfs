# ssh_without_passwd.sh

## 📄 Descripción General

Este script automatiza la conexión y montaje de carpetas remotas usando **SSHFS** (SSH File System), sin necesidad de ingresar la contraseña cada vez.

### Características:

- Configura el acceso por clave SSH.
- Monta carpetas remotas mediante `sshfs`.
- Genera un servicio persistente con `systemd` para montaje automático al arranque.
- Desmonta y elimina el montaje con una opción de limpieza (`--cleanup`).

---

## 🚀 Uso

```bash
sudo ./ssh_without_passwd.sh usuario@servidor                # Solo conexión SSH
sudo ./ssh_without_passwd.sh usuario@servidor /ruta/remota   # Montaje SSHFS interactivo
sudo ./ssh_without_passwd.sh usuario@servidor --cleanup      # Desmonta y elimina configuración persistente
```

---

## 📦 Requisitos

- Linux con systemd
- SSH y `ssh-copy-id`
- `sshfs` (se instalará automáticamente si no está)

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
sudo ./ssh_without_passwd.sh root@192.168.1.100 /data/compartida
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
- Pregunta si deseas borrar el punto de montaje local.

---

## ⚠️ Notas

- Usa `sudo`, **no lo ejecutes directamente como root**.
- Si el servidor no permite login como `root`, usa otro usuario.
- Este script utiliza: `ping`, `ssh`, `sshfs`, `ssh-copy-id`, `systemd`.

---

## 📬 Autor

Jorge Borja  
Generado con asistencia de ChatGPT · OpenAI