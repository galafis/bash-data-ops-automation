#!/bin/bash

# Arquivo de teste para o script data_pipeline.sh

# --- Configurações de Teste ---
TEST_DIR="./test_pipeline_run"
SCRIPT_PATH="../src/data_pipeline.sh"

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

# Criar diretório de configuração e arquivo de configuração de teste
mkdir -p config
cat <<EOF > config/pipeline_config.conf
SOURCE_DIR=./data/raw
STAGING_DIR=./data/staging
PROCESSED_DIR=./data/processed
LOOKUP_DIR=./data/lookup
ERROR_DIR=./data/errors
LOG_FILE=./logs/test_data_pipeline.log
NOTIFICATION_ENABLED=false
EOF

# --- Execução do Pipeline ---
log_test_message "INFO" "Executando o script da pipeline..."
# O script data_pipeline.sh agora usa `set -o pipefail` e `handle_error`
# Então, se houver um erro, ele sairá com um código diferente de 0.
# Redirecionamos stderr para stdout para capturar todas as mensagens de log.
OUTPUT=$(bash "$SCRIPT_PATH" 2>&1)
STATUS=$?

log_test_message "INFO" "--- Resultados do Teste do Pipeline de Automação de Dados ---"

# --- Verificações ---

# 1. Verificar o status de saída do script
if [ $STATUS -eq 0 ]; then
    log_test_message "SUCCESS" "Teste de status de saída: SUCESSO (código de saída 0)"
else
    log_test_message "FAILURE" "Teste de status de saída: FALHA (código de saída $STATUS)"
    log_test_message "DEBUG" "Saída do pipeline:\n$OUTPUT"
    exit 1
fi

# 2. Verificar se a mensagem de sucesso final está presente na saída
if echo "$OUTPUT" | grep -q "Pipeline de dados concluída com sucesso!"; then
    log_test_message "SUCCESS" "Teste de mensagem de sucesso: SUCESSO"
else
    log_test_message "FAILURE" "Teste de mensagem de sucesso: FALHA (mensagem final não encontrada)"
    log_test_message "DEBUG" "Saída do pipeline:\n$OUTPUT"
    exit 1
fi

# 3. Verificar a criação de arquivos de dados válidos
VALID_DATA_FILE=$(find data/staging -name "valid_data_raw_sales_*.csv" | head -n 1)
if [ -f "$VALID_DATA_FILE" ]; then
    log_test_message "SUCCESS" "Teste de arquivo de dados válidos: SUCESSO ($VALID_DATA_FILE encontrado)"
    # Verificar conteúdo do arquivo válido (ex: número de linhas)
    VALID_LINES=$(wc -l < "$VALID_DATA_FILE")
    # Esperamos 14 linhas (1 cabeçalho + 13 registros válidos)
    if [ "$VALID_LINES" -eq 13 ]; then
        log_test_message "SUCCESS" "Teste de contagem de linhas válidas: SUCESSO (Esperado 13, Encontrado $VALID_LINES)"
    else
        log_test_message "FAILURE" "Teste de contagem de linhas válidas: FALHA (Esperado 13, Encontrado $VALID_LINES)"
        log_test_message "DEBUG" "Conteúdo de $VALID_DATA_FILE:\n$(cat "$VALID_DATA_FILE")"
        exit 1
    fi
else
    log_test_message "FAILURE" "Teste de arquivo de dados válidos: FALHA (Nenhum arquivo valid_data_raw_sales_*.csv encontrado)"
    log_test_message "DEBUG" "Conteúdo do diretório staging:\n$(ls -F data/staging)"
    exit 1
fi

# 4. Verificar a criação de arquivos de dados inválidos
INVALID_DATA_FILE=$(find data/errors -name "invalid_data_raw_sales_*.csv" | head -n 1)
if [ -f "$INVALID_DATA_FILE" ]; then
    log_test_message "SUCCESS" "Teste de arquivo de dados inválidos: SUCESSO ($INVALID_DATA_FILE encontrado)"
    # Verificar conteúdo do arquivo inválido (ex: número de linhas)
    INVALID_LINES=$(wc -l < "$INVALID_DATA_FILE")
    # Esperamos 3 linhas (1 cabeçalho + 2 registros inválidos)
    if [ "$INVALID_LINES" -eq 3 ]; then
        log_test_message "SUCCESS" "Teste de contagem de linhas inválidas: SUCESSO (Esperado 3, Encontrado $INVALID_LINES)"
        # Verificar se as mensagens de erro esperadas estão presentes
        if grep -q "InvalidQuantity" "$INVALID_DATA_FILE" && grep -q "InvalidPrice" "$INVALID_DATA_FILE"; then
            log_test_message "SUCCESS" "Teste de mensagens de erro em inválidos: SUCESSO"
        else
            log_test_message "FAILURE" "Teste de mensagens de erro em inválidos: FALHA (mensagens esperadas não encontradas)"
            log_test_message "DEBUG" "Conteúdo de $INVALID_DATA_FILE:\n$(cat "$INVALID_DATA_FILE")"
            exit 1
        fi
    else
        log_test_message "FAILURE" "Teste de contagem de linhas inválidas: FALHA (Esperado 3, Encontrado $INVALID_LINES)"
        log_test_message "DEBUG" "Conteúdo de $INVALID_DATA_FILE:\n$(cat "$INVALID_DATA_FILE")"
        exit 1
    fi
else
    log_test_message "FAILURE" "Teste de arquivo de dados inválidos: FALHA (Nenhum arquivo invalid_data_raw_sales_*.csv encontrado)"
    log_test_message "DEBUG" "Conteúdo do diretório errors:\n$(ls -F data/errors)"
    exit 1
fi

# 5. Verificar a criação do arquivo transformado
TRANSFORMED_FILE=$(find data/staging -name "transformed_valid_data_raw_sales_*.csv" | head -n 1)
if [ -f "$TRANSFORMED_FILE" ]; then
    log_test_message "SUCCESS" "Teste de arquivo transformado: SUCESSO ($TRANSFORMED_FILE encontrado)"
    # Verificar se o arquivo transformado contém as colunas esperadas (ex: category, total_amount)
    if head -n 1 "$TRANSFORMED_FILE" | grep -q "category" && head -n 1 "$TRANSFORMED_FILE" | grep -q "total_sales_amount"; then
        log_test_message "SUCCESS" "Teste de colunas transformadas: SUCESSO"
    else
        log_test_message "FAILURE" "Teste de colunas transformadas: FALHA (colunas esperadas não encontradas)"
        log_test_message "DEBUG" "Cabeçalho de $TRANSFORMED_FILE:\n$(head -n 1 "$TRANSFORMED_FILE")"
        exit 1
    fi
else
    log_test_message "FAILURE" "Teste de arquivo transformado: FALHA (Nenhum arquivo transformed_valid_data_raw_sales_*.csv encontrado)"
    log_test_message "DEBUG" "Conteúdo do diretório staging:\n$(ls -F data/staging)"
    exit 1
fi

# 6. Verificar a criação do arquivo final processado
FINAL_PROCESSED_FILE=$(find data/processed -name "final_aggregated_transformed_valid_data_raw_sales_*.csv" | head -n 1)
if [ -f "$FINAL_PROCESSED_FILE" ]; then
    log_test_message "SUCCESS" "Teste de arquivo final processado: SUCESSO ($FINAL_PROCESSED_FILE encontrado)"
else
    log_test_message "FAILURE" "Teste de arquivo final processado: FALHA (Nenhum arquivo final_aggregated_transformed_valid_data_raw_sales_*.csv encontrado)"
    log_test_message "DEBUG" "Conteúdo do diretório processed:\n$(ls -F data/processed)"
    exit 1
fi

log_test_message "INFO" "--- Todos os testes para data_pipeline.sh passaram com sucesso! ---"

