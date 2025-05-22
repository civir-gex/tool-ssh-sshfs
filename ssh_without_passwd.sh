#!/bin/bash

clear

# Verifica si al menos se pasó 1 argumento
if [ "$#" -lt 1 ]; then
    echo "Uso:"
    echo "  Para conexión SSH: $0 usuario@servidor"
    echo "  Para montar SSHFS: $0 usuario@servidor carpeta_remota [nombre_personalizado]"
    echo "  Para desmontar y limpiar: $0 usuario@servidor --cleanup [nombre_personalizado]"
    exit 1
fi

USR_SRV=$1
SrvRemoto=$(echo "$USR_SRV" | cut -d@ -f2)

# Si solo hay 1 argumento, abre conexión SSH y termina
if [ "$#" -eq 1 ]; then
    echo "Verificando conectividad con $USR_SRV..."
    ping -c 1 -W 2 "$SrvRemoto" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: No se puede contactar al servidor $USR_SRV"
        exit 1
    fi

    KEY_PATH="$HOME/.ssh/id_rsa"
    if [ ! -f "$KEY_PATH" ]; then
        echo "No existe clave SSH, creando una..."
        ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
    fi

    echo "Verificando si se puede conectar sin contraseña..."
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$USR_SRV" 'exit' 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "No se puede conectar sin contraseña. Copiando clave pública al servidor..."
        ssh-copy-id "$USR_SRV"
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo copiar la clave pública. Verifica acceso SSH y vuelve a intentar."
            exit 1
        fi
    else
        echo "Conexión sin contraseña verificada correctamente."
    fi

    echo "✅ Validaciones completadas correctamente."
    echo "Conectando a $USR_SRV..."
    ssh "$USR_SRV"
    exit $?
fi

REMOTE_DIR=$2
CUSTOM_NAME=$3

if [[ "$REMOTE_DIR" == "--cleanup" ]]; then
    CUSTOM_NAME=$2
    REMOTE_DIR=""
fi

if [ -z "$CUSTOM_NAME" ]; then
    read -p "📂 Ingresa el nombre para la carpeta de montaje (Enter para usar '$SrvRemoto'): " INPUT_NAME
    if [ -z "$INPUT_NAME" ]; then
        MOUNT_NAME="$SrvRemoto"
    else
        MOUNT_NAME="$INPUT_NAME"
    fi
else
    MOUNT_NAME="$CUSTOM_NAME"
fi

MOUNT_POINT="/mnt/SSHFS/$MOUNT_NAME"
SERVICE_NAME="sshfs-$MOUNT_NAME.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# Modo cleanup
if [[ "$2" == "--cleanup" ]]; then
    echo "🧹 Iniciando limpieza para $MOUNT_NAME..."

    if systemctl list-units --all | grep -q "$SERVICE_NAME"; then
        echo "🔌 Deteniendo servicio systemd..."
        sudo systemctl stop "$SERVICE_NAME"
        sudo systemctl disable "$SERVICE_NAME"
    else
        echo "ℹ️  El servicio $SERVICE_NAME no está activo o no existe."
    fi

    if mount | grep -q "on $MOUNT_POINT type fuse.sshfs"; then
        echo "📤 Desmontando $MOUNT_POINT..."
        sudo umount "$MOUNT_POINT"
    else
        echo "ℹ️  $MOUNT_POINT no está montado."
    fi

    if [ -f "$SERVICE_PATH" ]; then
        echo "🗑️  Eliminando archivo de servicio $SERVICE_PATH..."
        sudo rm "$SERVICE_PATH"
        sudo systemctl daemon-reload
        sudo systemctl reset-failed
    else
        echo "ℹ️  No se encontró $SERVICE_PATH para eliminar."
    fi

    read -p "¿Deseas eliminar la carpeta local $MOUNT_POINT? (s/n): " BORRAR
    if [[ "$BORRAR" == "s" ]]; then
        sudo rm -rf "$MOUNT_POINT"
        echo "📁 Carpeta eliminada."
    else
        echo "📁 Carpeta conservada."
    fi

    echo "✅ Limpieza finalizada."
    exit 0
fi

echo "Verificando conectividad con $USR_SRV..."
ping -c 1 -W 2 "$SrvRemoto" > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: No se puede contactar al servidor $USR_SRV"
    exit 1
fi

KEY_PATH="$HOME/.ssh/id_rsa"
if [ ! -f "$KEY_PATH" ]; then
    echo "No existe clave SSH, creando una..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
fi

echo "Verificando si se puede conectar sin contraseña..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "$USR_SRV" 'exit' 2>/dev/null
if [ $? -ne 0 ]; then
    echo "No se puede conectar sin contraseña. Copiando clave pública al servidor..."
    ssh-copy-id "$USR_SRV"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo copiar la clave pública. Verifica acceso SSH y vuelve a intentar."
        exit 1
    fi
else
    echo "Conexión sin contraseña verificada correctamente."
fi

echo "✅ Validaciones completadas correctamente."

if [ "$#" -eq 1 ]; then
    echo "Conectando a $USR_SRV..."
    ssh "$USR_SRV"
    exit $?
fi

if ! command -v sshfs &> /dev/null; then
    echo "sshfs no está instalado. Intentando instalarlo..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y sshfs
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y sshfs
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy sshfs --noconfirm
    else
        echo "Error: No se pudo instalar sshfs automáticamente. Instálalo manualmente."
        exit 1
    fi
fi

if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creando punto de montaje en $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo chmod 777 "$MOUNT_POINT"
else
    echo "El punto de montaje $MOUNT_POINT ya existe."
fi

if mount | grep -q "on $MOUNT_POINT type fuse.sshfs"; then
    MONTADO="true"
else
    MONTADO="false"
fi

echo "¿Deseas generar el montaje persistente ahora? (s/n)"
read -r RESP

if [[ "$RESP" == "s" ]]; then
    if [[ "$MONTADO" == "true" ]]; then
        echo "Desmontando $MOUNT_POINT..."
        sudo umount "$MOUNT_POINT"
        if [ $? -ne 0 ]; then
            echo "❌ Error al desmontar $MOUNT_POINT. Detén procesos que lo estén usando e inténtalo de nuevo."
            exit 1
        fi
    fi

    echo "Generando $SERVICE_PATH..."

    cat <<EOF | sudo tee "$SERVICE_PATH"
[Unit]
Description=Montaje SSHFS para $MOUNT_NAME
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=sshfs -o reconnect,allow_other,ServerAliveInterval=15,ServerAliveCountMax=3 "$USR_SRV:$REMOTE_DIR" "$MOUNT_POINT"
ExecStop=umount $MOUNT_POINT
User=$USER

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"

else
    if [[ "$MONTADO" == "false" ]]; then
        echo "Montando carpeta remota..."
        sshfs -o allow_other "$USR_SRV:$REMOTE_DIR" "$MOUNT_POINT"
        if [ $? -ne 0 ]; then
            echo "Error al montar la carpeta remota."
            exit 1
        fi
    fi
fi

mount | grep "on $MOUNT_POINT type fuse.sshfs"
echo ""
exit 0