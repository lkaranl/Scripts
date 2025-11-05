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
# ============================================================================
# DISTRIBUIÇÕES PRINCIPAIS
# ============================================================================
# Ubuntu
INSTALL_ZENITY_UBUNTU="sudo apt-get install zenity"
INSTALL_SAMBA_UBUNTU="sudo apt-get install samba"
# Debian
INSTALL_ZENITY_DEBIAN="sudo apt-get install zenity"
INSTALL_SAMBA_DEBIAN="sudo apt-get install samba"
# Fedora
INSTALL_ZENITY_FEDORA="sudo dnf install zenity"
INSTALL_SAMBA_FEDORA="sudo dnf install samba"
# Arch Linux
INSTALL_ZENITY_ARCH="sudo pacman -S zenity"
INSTALL_SAMBA_ARCH="sudo pacman -S samba"

# ============================================================================
# DISTRIBUIÇÕES SECUNDÁRIAS
# ============================================================================
# CachyOS (baseada em Arch) - usa os mesmos comandos do Arch
INSTALL_ZENITY_CACHYOS="sudo pacman -S zenity"
INSTALL_SAMBA_CACHYOS="sudo pacman -S samba"

# Configurações de distribuições
# ============================================================================
# DISTRIBUIÇÕES PRINCIPAIS (Topo da hierarquia)
# ============================================================================
# Ubuntu
DISTRO_MAIN_UBUNTU="ubuntu"
# Debian
DISTRO_MAIN_DEBIAN="debian"
# Fedora
DISTRO_MAIN_FEDORA="fedora"
# Arch Linux
DISTRO_MAIN_ARCH="arch"

# ============================================================================
# DISTRIBUIÇÕES SECUNDÁRIAS (Baseadas nas principais)
# ============================================================================
# Baseadas em Arch Linux
DISTRO_SECONDARY_ARCH_CACHYOS="cachyos"
# Lista completa de distribuições baseadas em Arch (separadas por |)
DISTRO_ALL_ARCH="arch|archlinux|cachyos"

# Baseadas em Ubuntu/Debian (separadas por |)
DISTRO_ALL_UBUNTU_DEBIAN="ubuntu|debian"

# Baseadas em Fedora (separadas por |)
DISTRO_ALL_FEDORA="fedora"

# Configurações de serviços
# Serviços para Ubuntu/Debian
SERVICE_SMBD_UBUNTU="smbd"
SERVICE_NMBD_UBUNTU="nmbd"
# Serviços para Fedora/Arch (incluindo CachyOS)
SERVICE_SMBD_FEDORA="smb"
SERVICE_NMBD_FEDORA="nmb"

###############################################################################
#                           FIM DAS CONFIGURAÇÕES                             #
###############################################################################

_checks=`id -u`
_currentuser=`whoami`

# Função para validar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --cli    Modo linha de comando (CLI)"
    echo "  --tui    Modo interface de terminal (TUI)"
    echo "  --help   Mostra esta ajuda"
    echo ""
    echo "Se nenhuma opção for fornecida, tentará usar interface gráfica (GUI)"
    exit 0
}

# Parse de argumentos
USE_CLI_MODE=false
USE_TUI_MODE=false

for arg in "$@"; do
    case "$arg" in
        --cli)
            USE_CLI_MODE=true
            ;;
        --tui)
            USE_TUI_MODE=true
            USE_CLI_MODE=true
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Opção desconhecida: $arg" >&2
            echo "Use --help para ver as opções disponíveis" >&2
            exit 1
            ;;
    esac
done

# Se nenhum modo foi especificado, tentar usar GUI
if [ "$USE_CLI_MODE" = false ]; then
    # Verificar se GUI está disponível
    if [ -z "$DISPLAY" ] || ! command_exists zenity || ! zenity --version >/dev/null 2>&1; then
        echo "AVISO: Interface gráfica não disponível. Use --cli ou --tui para modo terminal." >&2
        USE_CLI_MODE=true
    fi
fi

# ============================================================================
# FUNÇÕES DE INTERFACE (GUI ou CLI)
# ============================================================================

# Função para exibir mensagens de erro
show_error() {
    if [ "$USE_CLI_MODE" = true ]; then
        if [ "$USE_TUI_MODE" = true ]; then
            echo "╔═══════════════════════════════════════╗" >&2
            echo "║           ERRO                        ║" >&2
            echo "╠═══════════════════════════════════════╣" >&2
            echo "║ $1" >&2
            echo "╚═══════════════════════════════════════╝" >&2
        else
            echo "ERRO: $1" >&2
        fi
    else
        zenity --error --title="$MSG_TITLE_ERROR" --text="$1" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_ENTRY" 2>/dev/null || echo "ERRO: $1" >&2
    fi
}

# Função para exibir mensagens de informação
show_info() {
    if [ "$USE_CLI_MODE" = true ]; then
        if [ "$USE_TUI_MODE" = true ]; then
            echo ""
            echo "╔═══════════════════════════════════════╗"
            echo "║           INFORMAÇÃO                  ║"
            echo "╠═══════════════════════════════════════╣"
            # Substituir \n por quebras de linha reais e formatar
            local msg=$(echo -e "$1" | sed 's/\\n/\n/g')
            echo "$msg" | while IFS= read -r line || [ -n "$line" ]; do
                printf "║ %-37s ║\n" "$line"
            done
            echo "╚═══════════════════════════════════════╝"
            echo ""
        else
            echo "INFO: $1"
        fi
    else
        zenity --info --text="$1" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_ENTRY" 2>/dev/null || echo "INFO: $1"
    fi
}

# Função para listar diretórios e partições (modo CLI/TUI)
list_directories() {
    # Apenas no modo TUI mostrar lista formatada
    if [ "$USE_TUI_MODE" = true ]; then
        echo ""
        echo "╔═══════════════════════════════════════╗"
        echo "║    DIRETÓRIOS DISPONÍVEIS             ║"
        echo "╠═══════════════════════════════════════╣"
        echo ""
        
        # Listar pontos de montagem
        echo "📁 Pontos de Montagem:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        df -h | grep -E '^/dev/' | awk '{printf "  [%s] %s (%s livres de %s)\n", $6, $1, $4, $2}' | column -t
        echo ""
        
        # Listar diretórios comuns
        echo "📂 Diretórios Comuns:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        common_dirs=("/home" "/mnt" "/media" "/opt" "/srv" "/var" "/tmp")
        for dir in "${common_dirs[@]}"; do
            if [ -d "$dir" ]; then
                echo "  $dir"
            fi
        done
        echo ""
        
        # Listar subdiretórios do /home se existir
        if [ -d "/home" ]; then
            echo "👤 Diretórios em /home:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ls -1d /home/*/ 2>/dev/null | head -10 | sed 's|/$||' | sed 's/^/  /'
            echo ""
        fi
        
        # Listar subdiretórios do /mnt se existir
        if [ -d "/mnt" ] && [ "$(ls -A /mnt 2>/dev/null)" ]; then
            echo "💾 Diretórios em /mnt:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ls -1d /mnt/*/ 2>/dev/null | sed 's|/$||' | sed 's/^/  /'
            echo ""
        fi
        
        # Listar subdiretórios do /media se existir
        if [ -d "/media" ] && [ "$(ls -A /media 2>/dev/null)" ]; then
            echo "📀 Dispositivos em /media:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ls -1d /media/*/ 2>/dev/null | sed 's|/$||' | sed 's/^/  /'
            echo ""
        fi
        
        echo "╚═══════════════════════════════════════╝"
        echo ""
    fi
}

# Função para solicitar entrada de texto
ask_input() {
    local title="$1"
    local prompt="$2"
    local show_list="${3:-false}"
    local response=""
    
    if [ "$USE_CLI_MODE" = true ]; then
        # Se for para selecionar caminho e estiver em modo TUI, mostrar lista
        if [ "$USE_TUI_MODE" = true ] && ([ "$show_list" = true ] || [[ "$prompt" == *"caminho"* ]] || [[ "$prompt" == *"path"* ]]); then
            list_directories
        fi
        
        if [ "$USE_TUI_MODE" = true ]; then
            echo ""
            echo "╔═══════════════════════════════════════╗"
            echo "║ $title"
            echo "╠═══════════════════════════════════════╣"
            echo "║ $prompt"
            echo "╚═══════════════════════════════════════╝"
            echo -n "> "
        else
            echo ""
            echo "$prompt"
            echo -n "> "
        fi
        
        # Tentar ler do terminal - usar /dev/tty quando disponível (funciona com sudo)
        if [ -c /dev/tty ] && [ -r /dev/tty ]; then
            read -r response < /dev/tty
        else
            read -r response
        fi
        
        echo "$response"
    else
        zenity --title="$title" --text="$prompt" --entry --width="$ZENITY_WIDTH_ENTRY" --height="$ZENITY_HEIGHT_ENTRY" 2>/dev/null
    fi
}

# Função para fazer perguntas sim/não
ask_question() {
    local title="$1"
    local prompt="$2"
    
    if [ "$USE_CLI_MODE" = true ]; then
        if [ "$USE_TUI_MODE" = true ]; then
            echo ""
            echo "╔═══════════════════════════════════════╗"
            echo "║ $title"
            echo "╠═══════════════════════════════════════╣"
            echo "║ $prompt"
            echo "╚═══════════════════════════════════════╝"
            echo -n "(s/n): "
        else
            echo "$prompt"
            echo -n "(s/n): "
        fi
        
        while true; do
            # Tentar ler do terminal - usar /dev/tty quando disponível (funciona com sudo)
            if [ -c /dev/tty ] && [ -r /dev/tty ]; then
                read -r response < /dev/tty
            else
                read -r response
            fi
            case "$response" in
                [sS]|[sS][iI][mM]|[yY]|[yY][eE][sS])
                    return 0
                    ;;
                [nN]|[nN][ãÃ][oO]|[nN][oO])
                    return 1
                    ;;
                *)
                    echo -n "Por favor, responda 's' para sim ou 'n' para não: "
                    ;;
            esac
        done
    else
        zenity --title="$title" --question --text="$prompt" --width="$ZENITY_WIDTH_DIALOG" --height="$ZENITY_HEIGHT_QUESTION" 2>/dev/null
        return $?
    fi
}

# Variável global para armazenar a distribuição detectada
DETECTED_DISTRO=""

# Função para detectar a distribuição e definir nomes dos serviços
detect_samba_services() {
    local distro_id=""
    local distro_base=""
    
    # Detectar distribuição
    if [ -f /etc/os-release ]; then
        distro_id=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        # Verificar ID_LIKE para distribuições baseadas em outras
        if grep -qi "^ID_LIKE=" /etc/os-release; then
            distro_base=$(grep -i "^ID_LIKE=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -d' ' -f1)
        fi
    elif [ -f /etc/debian_version ]; then
        distro_id="debian"
    elif [ -f /etc/fedora-release ]; then
        distro_id="fedora"
    elif [ -f /etc/arch-release ]; then
        distro_id="arch"
    fi
    
    # Armazenar distribuição detectada globalmente
    DETECTED_DISTRO="$distro_id"
    
    # ========================================================================
    # DISTRIBUIÇÕES PRINCIPAIS (Topo da hierarquia)
    # ========================================================================
    case "$distro_id" in
        # Ubuntu
        ubuntu)
            SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
            SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
            ;;
        # Debian
        debian)
            SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
            SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
            ;;
        # Fedora
        fedora)
            SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
            SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
            ;;
        # Arch Linux
        arch|archlinux)
            SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
            SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
            ;;
        
        # ====================================================================
        # DISTRIBUIÇÕES SECUNDÁRIAS (Baseadas nas principais)
        # ====================================================================
        # CachyOS (baseada em Arch)
        cachyos)
            SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
            SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
            ;;
        
        # ====================================================================
        # Fallback: Tentar detectar pela ID_LIKE ou automaticamente
        # ====================================================================
        *)
            # Se tiver ID_LIKE, usar como base
            if [ -n "$distro_base" ]; then
                case "$distro_base" in
                    arch|archlinux)
                        SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
                        SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
                        ;;
                    debian|ubuntu)
                        SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                        SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
                        ;;
                    fedora)
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
                            # Fallback padrão (Ubuntu/Debian)
                            SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                            SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
                        fi
                        ;;
                esac
            else
                # Tentar detectar automaticamente qual serviço existe
                if systemctl list-unit-files | grep -q "smbd.service"; then
                    SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                    SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
                elif systemctl list-unit-files | grep -q "smb.service"; then
                    SAMBA_SERVICE_1="$SERVICE_SMBD_FEDORA"
                    SAMBA_SERVICE_2="$SERVICE_NMBD_FEDORA"
                else
                    # Fallback padrão (Ubuntu/Debian)
                    SAMBA_SERVICE_1="$SERVICE_SMBD_UBUNTU"
                    SAMBA_SERVICE_2="$SERVICE_NMBD_UBUNTU"
                fi
            fi
            ;;
    esac
    
    # Verificar se os serviços existem (apenas se o Samba estiver instalado)
    # Se o Samba não estiver instalado, não há problema - os serviços serão criados na instalação
    if command_exists smbpasswd; then
        # Samba está instalado, verificar se os serviços existem
        local service_found=false
        
        # Tentar múltiplas formas de verificar
        if systemctl list-unit-files 2>/dev/null | grep -qE "(${SAMBA_SERVICE_1}|${SAMBA_SERVICE_2})\.service"; then
            service_found=true
        elif systemctl cat "${SAMBA_SERVICE_1}" &>/dev/null || systemctl cat "${SAMBA_SERVICE_2}" &>/dev/null; then
            service_found=true
        elif systemctl list-units --type=service 2>/dev/null | grep -qE "(${SAMBA_SERVICE_1}|${SAMBA_SERVICE_2})"; then
            service_found=true
        fi
        
        # Se não encontrou os serviços, mas o Samba está instalado, pode ser um problema de configuração
        # Mas não vamos bloquear - apenas avisar que pode ser necessário instalar/ativar os serviços
        if [ "$service_found" = false ]; then
            # Não bloquear, apenas definir os serviços baseado na distribuição
            # O usuário pode instalar o Samba depois
            :
        fi
    fi
    # Se o Samba não estiver instalado, não há problema - apenas definimos os serviços corretos
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
    
    # ========================================================================
    # DISTRIBUIÇÕES PRINCIPAIS (Topo da hierarquia)
    # ========================================================================
    case "$distro" in
        # Ubuntu
        ubuntu)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_UBUNTU"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_UBUNTU"
            fi
            ;;
        # Debian
        debian)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_DEBIAN"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_DEBIAN"
            fi
            ;;
        # Fedora
        fedora)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_FEDORA"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_FEDORA"
            fi
            ;;
        # Arch Linux
        arch|archlinux)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_ARCH"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_ARCH"
            fi
            ;;
        
        # ====================================================================
        # DISTRIBUIÇÕES SECUNDÁRIAS (Baseadas nas principais)
        # ====================================================================
        # CachyOS (baseada em Arch)
        cachyos)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_CACHYOS"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_CACHYOS"
            fi
            ;;
        
        # ====================================================================
        # Fallback padrão (Arch)
        # ====================================================================
        *)
            if [ "$package" = "zenity" ]; then
                install_cmd="$INSTALL_ZENITY_ARCH"
            elif [ "$package" = "samba" ]; then
                install_cmd="$INSTALL_SAMBA_ARCH"
            fi
            ;;
    esac
    
    echo "$install_cmd"
}

# Informar modo de operação
if [ "$USE_CLI_MODE" = true ]; then
    if [ "$USE_TUI_MODE" = true ]; then
        echo ""
        echo "╔═══════════════════════════════════════╗"
        echo "║    MODO TUI ATIVADO                   ║"
        echo "║    Interface de Terminal              ║"
        echo "╚═══════════════════════════════════════╝"
        echo ""
    else
        echo ""
        echo "╔═══════════════════════════════════════╗"
        echo "║    MODO CLI ATIVADO                   ║"
        echo "║    Interface de Linha de Comando     ║"
        echo "╚═══════════════════════════════════════╝"
        echo ""
    fi
fi

# Verificar se zenity está instalado (apenas se não estiver em modo CLI)
if [ "$USE_CLI_MODE" = false ] && ! command_exists zenity; then
    INSTALL_CMD=$(get_install_command "zenity")
    echo "ERRO: zenity não está instalado. Por favor, instale com: $INSTALL_CMD" >&2
    echo "Ou execute sem display para usar o modo CLI" >&2
    exit 1
fi

# Verificar se samba está instalado
if ! command_exists smbpasswd; then
    INSTALL_CMD=$(get_install_command "samba")
    show_error "Samba não está instalado. Por favor, instale com: $INSTALL_CMD"
    if [ "$USE_CLI_MODE" = true ]; then
        echo ""
        echo -n "Deseja instalar o Samba agora? (s/n): "
        # Garantir leitura do terminal
        if [ -c /dev/tty ]; then
            read -r install_response < /dev/tty 2>/dev/null || read -r install_response
        else
            read -r install_response
        fi
        if [[ "$install_response" =~ ^[sS] ]]; then
            echo "Executando: $INSTALL_CMD"
            eval "$INSTALL_CMD"
            if [ $? -eq 0 ]; then
                show_info "Samba instalado com sucesso!"
            else
                show_error "Erro ao instalar Samba. Por favor, instale manualmente."
                exit 1
            fi
        else
            echo "Instalação cancelada. Por favor, instale o Samba manualmente antes de continuar."
            exit 1
        fi
    else
        exit 1
    fi
fi

# Função para criar arquivo de configuração básico do Samba
create_samba_config() {
    local config_file="$1"
    local config_dir=$(dirname "$config_file")
    
    # Criar diretório se não existir
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            show_error "Não foi possível criar o diretório $config_dir"
            return 1
        fi
    fi
    
    # Criar arquivo de configuração básico
    cat > "$config_file" << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/log.%m
   max log size = 50
   dns proxy = no
   security = user
   passdb backend = tdbsam
   map to guest = Bad User
EOF
    
    if [ $? -eq 0 ]; then
        # Definir permissões corretas
        chmod 644 "$config_file" 2>/dev/null
        return 0
    else
        return 1
    fi
}

# Verificar se o arquivo de configuração existe, criar se não existir
if [ ! -f "$SAMBA_CONFIG_FILE" ]; then
    # Tentar criar o arquivo de configuração
    if ! create_samba_config "$SAMBA_CONFIG_FILE"; then
        show_error "Não foi possível criar o arquivo de configuração $SAMBA_CONFIG_FILE"
        exit 1
    fi
    # Informar que o arquivo foi criado (apenas no modo TUI, no CLI simples apenas mostra mensagem)
    if [ "$USE_TUI_MODE" = true ]; then
        show_info "Arquivo de configuração do Samba criado em:\n$SAMBA_CONFIG_FILE"
    else
        echo "Arquivo de configuração do Samba criado em: $SAMBA_CONFIG_FILE"
    fi
fi

# Solicitar o caminho (com lista de diretórios no modo TUI)
_path=$(ask_input "$MSG_TITLE_PATH" "$MSG_TEXT_PATH" true)

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
_name=$(ask_input "$MSG_TITLE_NAME" "$MSG_TEXT_NAME")

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
    if ! ask_question "$MSG_TITLE_WARNING" "$(printf "$MSG_TEXT_DUPLICATE_SHARE" "$_name")"; then
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
if ask_question "$MSG_TITLE_SAMBA" "$MSG_TEXT_ADD_USER"; then
    _user=$(ask_input "$MSG_TITLE_USER" "$MSG_TEXT_USER")
    
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
        if ask_question "$MSG_TITLE_WARNING" "$(printf "$MSG_TEXT_DUPLICATE_USER" "$_user")"; then
            show_info "$MSG_TEXT_PASSWORD"
            smbpasswd "$_user"
        fi
    else
        show_info "$MSG_TEXT_PASSWORD"
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
show_info "$(printf "$MSG_TEXT_SUCCESS" "$_path" "$_name" "$_backup_file")"