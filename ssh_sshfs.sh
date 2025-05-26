#!/bin/bash

function msg(){
    echo -ne "\033[2K$1\r"
}

function montar(){
    if [ ! -d "$MNT_LOCAL" ]; then
        if ! sudo mkdir -p "$MNT_LOCAL"; then
            msg "❌ Error: Falló al ejecutar sudo. Cancelando...\n"
            exit 1
        fi
        sudo chmod 755 "$MNT_LOCAL"
    fi
    msg "Preparando el montaje de $USR@$HOST:$MNT_REMOTO en $MNT_LOCAL\n"

    if mount | grep -q "on $MNT_LOCAL type fuse.sshfs"; then
        MONTADO="true"
    else
        MONTADO="false"
    fi

    msg "Requiere que sea persistente y se cree un servicio (s/n)\n"
    read -r RESP

    if [[ "$RESP" == "s" ]]; then
        if [[ "$MONTADO" == "true" ]]; then
            echo "Desmontando $MNT_LOCAL..."
            sudo umount "$MNT_LOCAL"
            if [ $? -ne 0 ]; then
                echo "❌ Error al desmontar $MNT_LOCAL. Detén procesos que lo estén usando e inténtalo de nuevo."
                exit 1
            fi
        fi
        msg "Generando $SERVICE_PATH...\n"
        cat <<EOF | sudo tee "$SERVICE_PATH"
[Unit]
Description=Montaje SSHFS para $HOST
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=sshfs -o reconnect,allow_other,ServerAliveInterval=15,ServerAliveCountMax=3,port=$PORT $USR@$HOST:$MNT_REMOTO $MNT_LOCAL
ExecStop=umount $MNT_LOCAL
User=$USER

[Install]
WantedBy=multi-user.target
EOF
        sudo chown $USER:$USER $MNT_LOCAL
        sudo systemctl daemon-reexec
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        sudo systemctl start "$SERVICE_NAME"
    else
        if [[ "$MONTADO" == "false" ]]; then
            echo "Montando carpeta remota..."
            sudo chown $USER:$USER $MNT_LOCAL
            sshfs -o allow_other,port=$PORT "$USR@$HOST:$MNT_REMOTO" "$MNT_LOCAL"
            if [ $? -ne 0 ]; then
                echo "Error al montar la carpeta remota."
                exit 1
            fi
        fi
    fi
    mount | grep "on $MNT_LOCAL type fuse.sshfs"
    msg
    exit $?
}

function limpiar(){
    msg "Eliminando el servicio $SERVICE_NAME ..."
    if systemctl list-units --all | grep -q "$SERVICE_NAME"; then
        msg "🔌 Deteniendo servicio systemd..."
        sudo systemctl stop "$SERVICE_NAME"
        sudo systemctl disable "$SERVICE_NAME"
        sudo rm /etc/systemd/system/"$SERVICE_NAME"
    else
        msg "ℹ️  El servicio $SERVICE_NAME no está activo o no existe."
    fi
    msg "Servicio $SERVICE_NAME eliminado\n"
    msg "Desmontando $MNT_LOCAL ..."
        sudo umount "$MNT_LOCAL"
    msg "Desmontado $MNT_LOCAL\n"
    msg "Eliminando carpeta $MNT_LOCAL"
    if [ -d "$MNT_LOCAL" ]; then
        msg
        if ! sudo rmdir "$MNT_LOCAL"; then
            echo "❌ Error: Falló al ejecutar sudo. Cancelando..."
            exit 1
        fi
    fi
    msg "Carpeta $MNT_LOCAL eliminada\n"
    exit $?
}

clear

# Detectar argumentos
ARGS=("$@")
NUM_ARGS=$#

# Validar argumentos
if [ "$#" -lt 1 ]; then
    msg "Conexión SSH sin contraseña a través de llave ssh\nTambien se puede montar una carpeta remota del servidor mediante SSHFS\n\n"
    msg "Uso:\n"
    msg "  Para conexión SSH: $0 usuario@servidor[:puerto]\n"
    msg "  Para montar SSHFS: $0 usuario@servidor[:puerto] /carpeta/remota [carpeta_local]\n"
    msg "  Para desmontar y limpiar: $0 usuario@servidor[:puerto] [carpeta_local] --cleanup\n\n"
    msg "  **Los montajes se realizan en /mnt/SSHFS/ y la carpeta será propiedad del usuario ejecutor del script\n\n\n"
    exit 1
fi

# Extraer usuario, host y puerto (si existe)
USR_HOST_PORT="$1"
USR=$(echo "$USR_HOST_PORT" | cut -d@ -f1)
HOST_PORT=$(echo "$USR_HOST_PORT" | cut -d@ -f2)
HOST=$(echo "$HOST_PORT" | cut -d: -f1)
PORT=$(echo "$HOST_PORT" | cut -s -d: -f2)
PORT=${PORT:-22}

SrvRemoto="$HOST"
MNT_REMOTO="$2"
MNT_LOCAL="/mnt/SSHFS/$SrvRemoto"

# Detectar si se desea limpiar
for arg in "${ARGS[@]}"; do
    ((i++))
    if [[ "$arg" == "--cleanup" ]]; then
        if [[ $i -ne $NUM_ARGS ]]; then
            msg "$arg debe ir al final.\n Ejecuta $0 sin parámetros para ayuda\n"
            exit 1
        fi
        if [[ $i -eq 3 ]]; then
            MNT_LOCAL="/mnt/SSHFS/$2"
        fi
        SERVICE_NAME="sshfs-${MNT_LOCAL#/mnt/SSHFS/}.service"
        SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
        limpiar
        break
    fi
done

# Verifica si el servidor está en línea
msg "Verificando conectividad con $HOST..."
ping -c 1 -W 2 "$HOST" > /dev/null
if [ $? -ne 0 ]; then
    msg "❌ Error: No se puede contactar al servidor $HOST\n"
    exit 1
fi

# Verifica si existe una clave SSH
msg "Verificando si existe una clave SSH..."
KEY_PATH="$HOME/.ssh/id_rsa"
if [ ! -f "$KEY_PATH" ]; then
    msg "No existe clave SSH, creando una..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
fi

# Verifica conexión sin contraseña
msg "Verificando si se puede conectar sin contraseña..."
ssh -p "$PORT" -o BatchMode=yes -o ConnectTimeout=5 "$USR@$HOST" 'exit' 2>/dev/null
if [ $? -ne 0 ]; then
    msg "No se puede conectar sin contraseña. Copiando clave pública al servidor..."
    ssh-copy-id -p "$PORT" "$USR@$HOST"
    if [ $? -ne 0 ]; then
        msg "❌ Error: No se pudo copiar la clave pública. Verifica acceso SSH y vuelve a intentar.\n"
        exit 1
    fi
else
    msg "Conexión sin contraseña verificada correctamente.\n"
    if [[ $NUM_ARGS -eq 1 ]]; then
        ssh -p "$PORT" "$USR@$HOST"
        clear
        exit $?
    fi
fi

# Verifica si sshfs está instalado
if ! command -v sshfs &> /dev/null; then
    msg "sshfs no está instalado. Intentando instalarlo...\n"
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y sshfs
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y sshfs
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy sshfs --noconfirm
    else
        msg "❌ Error: No se pudo instalar sshfs automáticamente. Instálalo manualmente.\n"
        exit 1
    fi
fi

# Si segundo argumento es ruta remota absoluta
if [[ "$2" =~ ^/ ]]; then
    if [[ $NUM_ARGS -eq 3 ]]; then
        MNT_LOCAL="/mnt/SSHFS/$3"
    fi
    SERVICE_NAME="sshfs-${MNT_LOCAL#/mnt/SSHFS/}.service"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
    montar "$USR@$HOST"
else 
    msg "Para poder montar el directorio remoto debes proporcionar el PATH completo (/carpeta/remota)\n"
    exit 1
fi
