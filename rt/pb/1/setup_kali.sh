#!/bin/bash

# ==============================================================================
# Script: setup_kali.sh
# Objetivo: Automatizar a preparação do ambiente Kali Linux para laboratório
# Autor: EF
# Data: 25/02/2026
# ==============================================================================

# --- CONFIGURAÇÕES GLOBAIS --- 
ARQUIVO_LOG="setup_log.txt"

# Esse código limpar o log antigo se ele existir, para começar do zero
> "$ARQUIVO_LOG"

# --- FUNÇÕES AUXILIARES ---
log_msg() {
  local mensagem="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $mensagem | tee -a $ARQUIVO_LOG"
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



