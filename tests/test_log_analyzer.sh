#!/bin/bash

# Arquivo de teste para o script log_analyzer.sh

# --- Configurações de Teste ---
TEST_DIR="./test_log_analyzer_run"
SCRIPT_PATH="../src/log_analyzer.sh"

# Função para limpar o ambiente de teste
cleanup() {
    log_test_message "INFO" "Iniciando limpeza do ambiente de teste..."
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        log_test_message "INFO" "Diretório de teste $TEST_DIR removido."
    fi
    log_test_message "INFO" "Limpeza concluída."
}

# Função para logar mensagens de teste
log_test_message() {
    local type="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message"
}

# Garantir que a limpeza seja feita ao sair, mesmo em caso de erro
trap cleanup EXIT

# --- Preparação do Ambiente de Teste ---
log_test_message "INFO" "Preparando ambiente de teste em $TEST_DIR..."
mkdir -p "$TEST_DIR" || { log_test_message "ERROR" "Falha ao criar diretório de teste."; exit 1; }
cd "$TEST_DIR" || { log_test_message "ERROR" "Falha ao entrar no diretório de teste."; exit 1; }

# Criar diretórios necessários
mkdir -p logs analysis

# --- Execução do Log Analyzer ---
log_test_message "INFO" "Executando o script log_analyzer..."
OUTPUT=$(bash "$SCRIPT_PATH" 2>&1)
STATUS=$?

log_test_message "INFO" "--- Resultados do Teste do Log Analyzer ---"

# --- Verificações ---

# 1. Verificar o status de saída do script
if [ $STATUS -eq 0 ]; then
    log_test_message "SUCCESS" "Teste de status de saída: SUCESSO (código de saída 0)"
else
    log_test_message "FAILURE" "Teste de status de saída: FALHA (código de saída $STATUS)"
    log_test_message "DEBUG" "Saída do log analyzer:\n$OUTPUT"
    exit 1
fi

# 2. Verificar se o arquivo de log foi gerado
if [ -f "logs/application.log" ]; then
    log_test_message "SUCCESS" "Teste de geração de log: SUCESSO"
    # Verificar que tem o número esperado de linhas (1000)
    LOG_LINES=$(wc -l < logs/application.log)
    if [ "$LOG_LINES" -eq 1000 ]; then
        log_test_message "SUCCESS" "Teste de contagem de linhas de log: SUCESSO (Esperado 1000, Encontrado $LOG_LINES)"
    else
        log_test_message "FAILURE" "Teste de contagem de linhas de log: FALHA (Esperado 1000, Encontrado $LOG_LINES)"
        exit 1
    fi
else
    log_test_message "FAILURE" "Teste de geração de log: FALHA (arquivo não encontrado)"
    exit 1
fi

# 3. Verificar se os arquivos de análise foram criados
EXPECTED_FILES=(
    "analysis/log_levels_summary.txt"
    "analysis/services_summary.txt"
    "analysis/response_times_summary.txt"
    "analysis/time_patterns_summary.txt"
    "analysis/anomalies_report.txt"
    "analysis/summary_report.txt"
)

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_test_message "SUCCESS" "Teste de arquivo de análise: SUCESSO ($file encontrado)"
    else
        log_test_message "FAILURE" "Teste de arquivo de análise: FALHA ($file não encontrado)"
        log_test_message "DEBUG" "Conteúdo do diretório analysis:\n$(ls -F analysis)"
        exit 1
    fi
done

# 4. Verificar conteúdo do resumo de níveis de log
if grep -q "Total de linhas: 1000" analysis/log_levels_summary.txt; then
    log_test_message "SUCCESS" "Teste de conteúdo de níveis de log: SUCESSO"
else
    log_test_message "FAILURE" "Teste de conteúdo de níveis de log: FALHA"
    log_test_message "DEBUG" "Conteúdo de log_levels_summary.txt:\n$(cat analysis/log_levels_summary.txt)"
    exit 1
fi

# 5. Verificar que o resumo de serviços contém os serviços esperados
for service in api database cache queue auth; do
    if grep -qi "$service" analysis/services_summary.txt; then
        log_test_message "SUCCESS" "Teste de serviço no resumo: SUCESSO ($service encontrado)"
    else
        log_test_message "FAILURE" "Teste de serviço no resumo: FALHA ($service não encontrado)"
        log_test_message "DEBUG" "Conteúdo de services_summary.txt:\n$(cat analysis/services_summary.txt)"
        exit 1
    fi
done

# 6. Verificar que a análise de tempos de resposta contém estatísticas
if grep -q "Estatísticas" analysis/response_times_summary.txt && \
   grep -qi "média" analysis/response_times_summary.txt; then
    log_test_message "SUCCESS" "Teste de estatísticas de tempos de resposta: SUCESSO"
else
    log_test_message "FAILURE" "Teste de estatísticas de tempos de resposta: FALHA"
    log_test_message "DEBUG" "Conteúdo de response_times_summary.txt:\n$(cat analysis/response_times_summary.txt)"
    exit 1
fi

# 7. Verificar padrões temporais
if grep -q "Logs por hora:" analysis/time_patterns_summary.txt; then
    log_test_message "SUCCESS" "Teste de padrões temporais: SUCESSO"
else
    log_test_message "FAILURE" "Teste de padrões temporais: FALHA"
    log_test_message "DEBUG" "Conteúdo de time_patterns_summary.txt:\n$(cat analysis/time_patterns_summary.txt)"
    exit 1
fi

# 8. Verificar relatório de anomalias
if grep -q "Relatório de Anomalias" analysis/anomalies_report.txt; then
    log_test_message "SUCCESS" "Teste de relatório de anomalias: SUCESSO"
else
    log_test_message "FAILURE" "Teste de relatório de anomalias: FALHA"
    log_test_message "DEBUG" "Conteúdo de anomalies_report.txt:\n$(cat analysis/anomalies_report.txt)"
    exit 1
fi

# 9. Verificar que a mensagem de sucesso foi exibida
if echo "$OUTPUT" | grep -q "Análise completa"; then
    log_test_message "SUCCESS" "Teste de mensagem de conclusão: SUCESSO"
else
    log_test_message "FAILURE" "Teste de mensagem de conclusão: FALHA"
    log_test_message "DEBUG" "Saída do analyzer:\n$OUTPUT"
    exit 1
fi

log_test_message "INFO" "--- Todos os testes para log_analyzer.sh passaram com sucesso! ---"
