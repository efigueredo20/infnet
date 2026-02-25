#!/bin/bash

# ==============================================================================
# Script: setup_kali.sh
# Objetivo: Automatizar a preparação do ambiente Kali Linux para laboratório
# Autor: EF
# Data: 25/02/2026
# ==============================================================================

# --- CONFIGURAÇÕES GLOBAIS --- 
ARQUIVO_LOG="setup_log.txt"
USUARIO_LAB="aluno_lab"
GRUPO_LAB="lab_group"
SENHA_PADRAO="kali123"

# Esse código limpar o log antigo se ele existir, para começar do zero
> "$ARQUIVO_LOG"

# --- FUNÇÕES AUXILIARES ---
log_msg() {
  local mensagem="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $mensagem" | tee -a $ARQUIVO_LOG"
}

print_header() {
    local titulo="$1"
    echo "" | tee -a "$ARQUIVO_LOG"
    echo "============================================================" | tee -a "$ARQUIVO_LOG"
    echo "   $titulo" | tee -a "$ARQUIVO_LOG"
    echo "============================================================" | tee -a "$ARQUIVO_LOG"
}

check_status() {
    # $? é onde eu pego o status do último comando executado
    # -eq é o operador de igualdade
    if [ $? -eq 0 ]; then
        log_msg "[SUCESSO] Etapa concluída."
    else
        log_msg "[ERRO] Houve uma falha na etapa anterior."
        # Em scripts críticos, poderíamos usar 'exit 1' aqui para parar tudo.
    fi
}

# ==============================================================================
# Início da Execução
# ==============================================================================

print_header "INICIANDO CONFIGURAÇÃO DO KALI LINUX"
log_msg "Script iniciado pelo usuário: $USER"

# --- 1. Informações do Sistema ---
print_header "1. Coletando Informações do Sistema"
{
    echo "--- Versão do Sistema ---"
    cat /etc/os-release | grep PRETTY_NAME
    echo "--- Kernel ---"
    uname -r
    echo "--- Data da Instalação/Configuração ---"
    date
} > sistema_info.txt
log_msg "Informações salvas em 'sistema_info.txt'."


# --- 2. Atualização de Repositórios e Pacotes ---
print_header "2. Atualizando o Sistema (Isso pode demorar)"
log_msg "Executando apt update..."
# Redirecionamos stdout e stderr para o log específico
sudo apt-get update > update_log.txt 2>&1

log_msg "Executando apt full-upgrade..."
# DEBIAN_FRONTEND=noninteractive evita que janelas pop-up travem o script
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y >> update_log.txt 2>&1
check_status
log_msg "Logs de atualização salvos em 'update_log.txt'."


# --- 3. Diagnóstico de Rede ---
print_header "3. Verificando Conectividade de Rede"
{
    echo "--- Interfaces de Rede ---"
    ip a
    echo ""
    echo "--- Rotas de Rede ---"
    ip r
    echo ""
    echo "--- Teste de Ping (google.com) ---"
    ping -c 4 google.com
} > network_info.txt
log_msg "Diagnóstico de rede salvo em 'network_info.txt'."


# --- 4. Hostname e Timezone ---
print_header "4. Configurando Hostname e Fuso Horário"

# Configura Hostname
log_msg "Definindo hostname para 'kali-lab'..."
sudo hostnamectl set-hostname kali-lab

# Configura Timezone (Exemplo: São Paulo)
log_msg "Definindo timezone para 'America/Sao_Paulo'..."
sudo timedatectl set-timezone America/Sao_Paulo

# Documentação
{
    echo "Hostname configurado: $(hostname)"
    echo "Timezone configurado: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
} > config_system.txt
log_msg "Configurações salvas em 'config_system.txt'."


# --- 5. Usuários e Grupos ---
print_header "5. Gerenciamento de Usuários e Grupos"

# Criar Grupo
if ! getent group "$GRUPO_LAB" > /dev/null; then
    sudo groupadd "$GRUPO_LAB"
    log_msg "Grupo '$GRUPO_LAB' criado."
else
    log_msg "Grupo '$GRUPO_LAB' já existe."
fi

# Criar Usuário
if ! id -u "$USUARIO_LAB" > /dev/null 2>&1; then
    # -m cria home, -s define shell, -G adiciona ao grupo secundário
    sudo useradd -m -s /bin/bash -G "$GRUPO_LAB" "$USUARIO_LAB"
    # Define a senha (necessário para logar)
    echo "$USUARIO_LAB:$SENHA_PADRAO" | sudo chpasswd
    log_msg "Usuário '$USUARIO_LAB' criado com senha padrão."
else
    log_msg "Usuário '$USUARIO_LAB' já existe."
fi

echo "Usuário: $USUARIO_LAB | Grupo: $GRUPO_LAB" > users_groups.txt
log_msg "Detalhes salvos em 'users_groups.txt'."


# --- 6. Instalação de Ferramentas ---
print_header "6. Instalando Ferramentas de Laboratório"
FERRAMENTAS="curl git htop vim net-tools tree"

log_msg "Instalando: $FERRAMENTAS"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $FERRAMENTAS >> update_log.txt 2>&1
check_status

# Registra a lista instalada
dpkg -l $FERRAMENTAS > tools_installed.txt
log_msg "Lista de ferramentas salva em 'tools_installed.txt'."


# --- 7. Estrutura de Diretórios ---
print_header "7. Criando Estrutura de Diretórios"

# Diretório /opt (Requer root para criar, mas vamos dar permissão ao usuário atual)
if [ ! -d "/opt/labtools" ]; then
    sudo mkdir -p /opt/labtools
    # Muda o dono para o usuário que está rodando o script ($USER)
    sudo chown "$USER":"$USER" /opt/labtools
    chmod 755 /opt/labtools
    log_msg "Diretório /opt/labtools criado."
else
    log_msg "Diretório /opt/labtools já existe."
fi

# Diretório na Home do usuário
mkdir -p ~/lab_workspace
log_msg "Diretório ~/lab_workspace criado."


# --- 8. A Flag Final ---
print_header "8. Gerando a Flag de Conclusão"
# Usamos 'sudo tee' para conseguir escrever em /etc/
echo "Kali Linux pronto para atividades de laboratório autorizado" | sudo tee /etc/flag_kali.txt > /dev/null

if [ -f "/etc/flag_kali.txt" ]; then
    log_msg "Flag criada com sucesso em /etc/flag_kali.txt"
else
    log_msg "[ERRO] Falha ao criar a flag."
fi

# --- Finalização ---
print_header "CONFIGURAÇÃO FINALIZADA"
log_msg "Todos os passos foram executados."
log_msg "Verifique o arquivo '$ARQUIVO_LOG' para detalhes."
echo ""
