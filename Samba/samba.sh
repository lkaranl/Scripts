#!/usr/bin/env bash

#####   NAME:               samba.sh
#####   VERSION:            0.1
#####   DESCRIPTION:        Adds new path and user to SAMBA
#####   DATE OF CREATION:   03/06/2019
#####   WRITTEN BY:         KARAN LUCIANO SILVA
#####   E-MAIL:             karanluciano1@gmail.com         
#####   DISTRO:             ARCH LINUX
#####   LICENSE:            GPLv3           
#####   PROJECT:            https://github.com/lkaranl/Scrits

###############################################################################
#                           CONFIGURAÇÕES PARAMETRIZÁVEIS                     #
#   Ajuste estas variáveis conforme necessário para facilitar manutenções    #
###############################################################################

# Caminhos de arquivos
SAMBA_CONFIG_FILE="/etc/samba/smb.conf"
SAMBA_BACKUP_DIR="/etc/samba"
SAMBA_BACKUP_PREFIX="smb.conf.backup"

# Configurações de interface gráfica (Zenity)
ZENITY_WIDTH_DIALOG="400"
ZENITY_WIDTH_ENTRY="350"
ZENITY_HEIGHT_DIALOG="150"
ZENITY_HEIGHT_ENTRY="50"
ZENITY_HEIGHT_QUESTION="50"

# Configurações padrão do compartilhamento Samba
SAMBA_SHARE_COMMENT="compartilhamento"
SAMBA_SHARE_BROWSEABLE="yes"
SAMBA_SHARE_WRITABLE="yes"
SAMBA_SHARE_VALID_USERS="%S"
SAMBA_SHARE_GUEST_OK="no"
SAMBA_SHARE_CREATE_MASK="0664"
SAMBA_SHARE_DIRECTORY_MASK="0775"

# Caracteres permitidos/não permitidos no nome do compartilhamento
# Caracteres a serem removidos do nome
SAMBA_NAME_FORBIDDEN_CHARS="[]"
# Caractere de substituição para espaços
SAMBA_NAME_SPACE_REPLACE="_"

# Mensagens de interface
MSG_TITLE_PATH="PATH"
MSG_TEXT_PATH="Qual caminho você deseja compartilhar?"
MSG_TITLE_NAME="NAME"
MSG_TEXT_NAME="Qual é o nome do compartilhamento?"
MSG_TITLE_SAMBA="SAMBA"
MSG_TEXT_ADD_USER="Deseja adicionar um novo usuário/senha ao SAMBA?"
MSG_TITLE_USER="USER"
MSG_TEXT_USER="Qual é o nome de usuário?"
MSG_TEXT_PASSWORD="Digite a senha no terminal"
MSG_TITLE_WARNING="Aviso"
MSG_TEXT_DUPLICATE_SHARE="Já existe um compartilhamento com o nome '%s'. Deseja continuar mesmo assim?"
MSG_TEXT_DUPLICATE_USER="O usuário '%s' já existe no Samba. Deseja alterar a senha?"
MSG_TITLE_SUCCESS="Sucesso"
MSG_TEXT_SUCCESS="Caminho alterado para: %s\nCompartilhamento: %s\nBackup salvo em: %s"
MSG_TITLE_ERROR="Erro"

# Mensagens de erro
ERR_NOT_ROOT="Seu usuário é %s. É necessário ser root para executar este script."
ERR_ZENITY_NOT_INSTALLED="zenity não está instalado. Por favor, instale com: sudo pacman -S zenity"
ERR_SAMBA_NOT_INSTALLED="Samba não está instalado. Por favor, instale com: sudo pacman -S samba"
ERR_CONFIG_NOT_FOUND="Arquivo %s não encontrado. Verifique se o Samba está instalado corretamente."
ERR_USER_CANCELED="Operação cancelada pelo usuário."
ERR_PATH_NOT_EXISTS="O caminho '%s' não existe ou não é um diretório."
ERR_PATH_NOT_ABSOLUTE="O caminho deve ser absoluto (começar com /)."
ERR_PATH_NO_PERMISSIONS="O diretório '%s' não tem permissões de leitura/escrita adequadas."
ERR_INVALID_SHARE_NAME="Nome do compartilhamento inválido."
ERR_BACKUP_FAILED="Não foi possível criar backup do arquivo de configuração."
ERR_CONFIG_WRITE_FAILED="Não foi possível adicionar configuração ao smb.conf. Restaurando backup..."
ERR_USER_NOT_EXISTS="O usuário '%s' não existe no sistema."
ERR_SAMBA_USER_ADD_FAILED="Erro ao adicionar usuário ao Samba."
ERR_SERVICE_ENABLE_FAILED="Erro ao habilitar serviços do Samba."
ERR_SERVICE_RESTART_FAILED="Erro ao reiniciar serviços do Samba."
ERR_SERVICE_NOT_RUNNING="Os serviços do Samba (%s e %s) não estão rodando corretamente."
ERR_SERVICES_DETECT_FAILED="Não foi possível detectar os serviços do Samba. Distribuição detectada: %s"

# Comandos de instalação (variam por distribuição)
INSTALL_ZENITY_UBUNTU="sudo apt-get install zenity"
INSTALL_ZENITY_DEBIAN="sudo apt-get install zenity"
INSTALL_ZENITY_FEDORA="sudo dnf install zenity"
INSTALL_ZENITY_ARCH="sudo pacman -S zenity"
INSTALL_SAMBA_UBUNTU="sudo apt-get install samba"
INSTALL_SAMBA_DEBIAN="sudo apt-get install samba"
INSTALL_SAMBA_FEDORA="sudo dnf install samba"
INSTALL_SAMBA_ARCH="sudo pacman -S samba"

# Configurações de distribuições
# IDs de distribuição reconhecidos (separados por |)
DISTRO_UBUNTU_DEBIAN="ubuntu|debian"
DISTRO_FEDORA_ARCH="fedora|arch|archlinux"

# Configurações de serviços
# Serviços para Ubuntu/Debian
SERVICE_SMBD_UBUNTU="smbd"
SERVICE_NMBD_UBUNTU="nmbd"
# Serviços para Fedora/Arch
SERVICE_SMBD_FEDORA="smb"
SERVICE_NMBD_FEDORA="nmb"

###############################################################################
#                           FIM DAS CONFIGURAÇÕES                             #
###############################################################################

_checks=`id -u`
_currentuser=`whoami`

# Função para exibir mensagens de erro
show_error() {
    zenity --error --title="$MSG_TITLE_ERROR" --text="$1" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_ENTRY" 2>/dev/null || echo "ERRO: $1"
}

# Função para validar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Variável global para armazenar a distribuição detectada
DETECTED_DISTRO=""

# Função para detectar a distribuição e definir nomes dos serviços
detect_samba_services() {
    local distro_id=""
    
    # Detectar distribuição
    if [ -f /etc/os-release ]; then
        distro_id=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/debian_version ]; then
        distro_id="debian"
    elif [ -f /etc/fedora-release ]; then
        distro_id="fedora"
    elif [ -f /etc/arch-release ]; then
        distro_id="arch"
    fi
    
    # Armazenar distribuição detectada globalmente
    DETECTED_DISTRO="$distro_id"
    
    # Definir nomes dos serviços baseado na distribuição
    case "$distro_id" in
        ubuntu|debian)
            SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
            SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
            ;;
        fedora|arch|archlinux)
            SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
            SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
            ;;
        *)
            # Tentar detectar automaticamente qual serviço existe
            if systemctl list-unit-files | grep -q "smbd.service"; then
                SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
            elif systemctl list-unit-files | grep -q "smb.service"; then
                SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
                SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
            else
                # Fallback padrão
                SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
            fi
            ;;
    esac
    
    # Verificar se os serviços existem (pelo menos um deve existir)
    if ! systemctl list-unit-files 2>/dev/null | grep -qE "(${SAMBA_SERVICE_1}|${SAMBA_SERVICE_2})\.service"; then
        # Tentar verificar se os serviços existem de outra forma
        if ! systemctl cat "${SAMBA_SERVICE_1}" &>/dev/null && ! systemctl cat "${SAMBA_SERVICE_2}" &>/dev/null; then
            printf "ERRO: ${ERR_SERVICES_DETECT_FAILED}\n" "${distro_id:-desconhecida}" >&2
            exit 1
        fi
    fi
}

# Detectar serviços do Samba
detect_samba_services

# Verificar se é root
if [ $_checks != 0 ]; then
    show_error "$(printf "$ERR_NOT_ROOT" "$_currentuser")"
    exit 1
fi

# Função para obter comando de instalação baseado na distribuição
get_install_command() {
    local package="$1"
    local distro="${DETECTED_DISTRO:-unknown}"
    local install_cmd=""
    
    case "$distro" in
        ubuntu)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_UBUNTU"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_UBUNTU"
            fi
            ;;
        debian)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_DEBIAN"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_DEBIAN"
            fi
            ;;
        fedora)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_FEDORA"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_FEDORA"
            fi
            ;;
        arch|archlinux)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_ARCH"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_ARCH"
            fi
            ;;
        *)
            # Fallback padrão (Arch)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_ARCH"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_ARCH"
            fi
            ;;
    esac
    
    echo "$install_cmd"
}

# Verificar se zenity está instalado
if ! command_exists zenity; then
    INSTALL_CMD=$(get_install_command "zenity")
    echo "ERRO: zenity não está instalado. Por favor, instale com: $INSTALL_CMD"
    exit 1
fi

# Verificar se samba está instalado
if ! command_exists smbpasswd; then
    INSTALL_CMD=$(get_install_command "samba")
    show_error "Samba não está instalado. Por favor, instale com: $INSTALL_CMD"
    exit 1
fi

# Verificar se o arquivo de configuração existe
if [ ! -f "$SAMBA_CONFIG_FILE" ]; then
    show_error "$(printf "$ERR_CONFIG_NOT_FOUND" "$SAMBA_CONFIG_FILE")"
    exit 1
fi

# Solicitar o caminho
_path=$(zenity --title="$MSG_TITLE_PATH" --text "$MSG_TEXT_PATH" --entry --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY")

# Verificar se o usuário cancelou
if [ -z "$_path" ]; then
    show_error "$ERR_USER_CANCELED"
    exit 0
fi

# Validar caminho
if [ ! -d "$_path" ]; then
    show_error "$(printf "$ERR_PATH_NOT_EXISTS" "$_path")"
    exit 1
fi

# Verificar se o caminho é absoluto
if [[ ! "$_path" =~ ^/ ]]; then
    show_error "$ERR_PATH_NOT_ABSOLUTE"
    exit 1
fi

# Verificar permissões do diretório
if [ ! -r "$_path" ] || [ ! -w "$_path" ]; then
    show_error "$(printf "$ERR_PATH_NO_PERMISSIONS" "$_path")"
    exit 1
fi

# Solicitar o nome do compartilhamento
_name=$(zenity --title="$MSG_TITLE_NAME" --text "$MSG_TEXT_NAME" --entry --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY")

# Verificar se o usuário cancelou
if [ -z "$_name" ]; then
    show_error "$ERR_USER_CANCELED"
    exit 0
fi

# Validar nome (remover caracteres especiais que podem causar problemas)
_name=$(echo "$_name" | tr -d "$SAMBA_NAME_FORBIDDEN_CHARS" | tr ' ' "$SAMBA_NAME_SPACE_REPLACE")

if [ -z "$_name" ]; then
    show_error "$ERR_INVALID_SHARE_NAME"
    exit 1
fi

# Verificar se já existe um compartilhamento com esse nome
if grep -q "^\[$_name\]" "$SAMBA_CONFIG_FILE" 2>/dev/null; then
    zenity --question --title="$MSG_TITLE_WARNING" --text "$(printf "$MSG_TEXT_DUPLICATE_SHARE" "$_name")" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_QUESTION"
    if [ $? -ne 0 ]; then
        exit 0
    fi
fi

# Criar backup do arquivo de configuração
_backup_file="${SAMBA_BACKUP_DIR}/${SAMBA_BACKUP_PREFIX}.$(date +%Y%m%d_%H%M%S)"
cp "$SAMBA_CONFIG_FILE" "$_backup_file" 2>/dev/null
if [ $? -ne 0 ]; then
    show_error "$ERR_BACKUP_FAILED"
    exit 1
fi

# Adicionar configuração ao smb.conf
cat >> "$SAMBA_CONFIG_FILE" << EOF

[$_name]
comment = $SAMBA_SHARE_COMMENT
path = $_path
browseable = $SAMBA_SHARE_BROWSEABLE
writable = $SAMBA_SHARE_WRITABLE
valid users = $SAMBA_SHARE_VALID_USERS
guest ok = $SAMBA_SHARE_GUEST_OK
create mask = $SAMBA_SHARE_CREATE_MASK
directory mask = $SAMBA_SHARE_DIRECTORY_MASK
EOF

if [ $? -ne 0 ]; then
    show_error "$ERR_CONFIG_WRITE_FAILED"
    cp "$_backup_file" "$SAMBA_CONFIG_FILE" 2>/dev/null
    exit 1
fi

# Perguntar se deseja adicionar usuário
zenity --title="$MSG_TITLE_SAMBA" --question --text "$MSG_TEXT_ADD_USER" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_QUESTION"

if [ $? -eq 0 ]; then
    _user=$(zenity --title="$MSG_TITLE_USER" --text "$MSG_TEXT_USER" --entry --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY")
    
    # Verificar se o usuário cancelou
    if [ -z "$_user" ]; then
        show_error "$ERR_USER_CANCELED"
        exit 0
    fi
    
    # Verificar se o usuário existe no sistema
    if ! id "$_user" &>/dev/null; then
        show_error "$(printf "$ERR_USER_NOT_EXISTS" "$_user")"
        exit 1
    fi
    
    # Verificar se o usuário já existe no samba
    if pdbedit -L 2>/dev/null | grep -q "^$_user:"; then
        zenity --question --title="$MSG_TITLE_WARNING" --text "$(printf "$MSG_TEXT_DUPLICATE_USER" "$_user")" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_QUESTION"
        if [ $? -eq 0 ]; then
            zenity --info --text="$MSG_TEXT_PASSWORD" --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY"
            smbpasswd "$_user"
        fi
    else
        zenity --info --text="$MSG_TEXT_PASSWORD" --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY"
        smbpasswd -a "$_user"
        
        if [ $? -ne 0 ]; then
            show_error "$ERR_SAMBA_USER_ADD_FAILED"
            exit 1
        fi
    fi
fi

# Habilitar e reiniciar serviços
systemctl enable "${SAMBA_SERVICE_1}" "${SAMBA_SERVICE_2}" 2>/dev/null
if [ $? -ne 0 ]; then
    show_error "$ERR_SERVICE_ENABLE_FAILED"
    exit 1
fi

systemctl restart "${SAMBA_SERVICE_1}" "${SAMBA_SERVICE_2}" 2>/dev/null
if [ $? -ne 0 ]; then
    show_error "$ERR_SERVICE_RESTART_FAILED"
    exit 1
fi

# Verificar se os serviços estão rodando
if ! systemctl is-active --quiet "${SAMBA_SERVICE_1}" || ! systemctl is-active --quiet "${SAMBA_SERVICE_2}"; then
    show_error "$(printf "$ERR_SERVICE_NOT_RUNNING" "${SAMBA_SERVICE_1}" "${SAMBA_SERVICE_2}")"
    exit 1
fi

# Mensagem de sucesso
zenity --info --title="$MSG_TITLE_SUCCESS" --text="$(printf "$MSG_TEXT_SUCCESS" "$_path" "$_name" "$_backup_file")" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_DIALOG"