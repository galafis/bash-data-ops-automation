#!/bin/bash

# Bash DataOps Automation - Data Pipeline Example
# Author: Gabriel Demetrios Lafis
# Year: 2025

# Este script demonstra uma pipeline de dados mais robusta usando Bash.
# Ele simula a extração, validação, transformação e carregamento de dados
# com tratamento de erros aprimorado, logging detalhado, configuração externa
# e simulação de notificações.

set -o pipefail # Garante que o script falhe se qualquer comando no pipeline falhar

# --- Configurações Padrão ---
CONFIG_FILE="./config/pipeline_config.conf"
LOG_FILE="./logs/data_pipeline.log"
SOURCE_DIR="./data/raw"
STAGING_DIR="./data/staging"
PROCESSED_DIR="./data/processed"
LOOKUP_DIR="./data/lookup"
ERROR_DIR="./data/errors"
NOTIFICATION_EMAIL="admin@example.com"
NOTIFICATION_ENABLED="false"

# --- Funções de Utilidade ---

# Função para logar mensagens com timestamp
log_message() {
    local type="INFO"
    local message="$1"
    if [[ "$message" == "ERRO:"* ]]; then
        type="ERROR"
    elif [[ "$message" == "AVISO:"* ]]; then
        type="WARN"
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

# Função para enviar notificação (simulada)
send_notification() {
    if [ "$NOTIFICATION_ENABLED" = "true" ]; then
        local subject="Data Pipeline Alert: $1"
        local body="$2"
        log_message "Simulando envio de notificação para $NOTIFICATION_EMAIL. Assunto: '$subject'. Mensagem: '$body'"
        # Em um ambiente real, usaria um comando como 'mail' ou 'sendmail'
        # echo "$body" | mail -s "$subject" "$NOTIFICATION_EMAIL"
    else
        log_message "Notificações desabilitadas. Não foi possível enviar alerta: $1"
    fi
}

# Função para tratamento de erros
handle_error() {
    local exit_code=$?
    local step_name="$1"
    local error_message="ERRO: A pipeline falhou na etapa '$step_name' com o código de saída $exit_code."
    log_message "$error_message"
    send_notification "Falha na Pipeline de Dados" "$error_message Veja o log em $LOG_FILE para detalhes."
    exit $exit_code
}

# Função para carregar configurações de um arquivo
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_message "Carregando configurações de $CONFIG_FILE..."
        # Ler o arquivo de configuração linha por linha
        while IFS=\= read -r key value; do
            # Ignorar linhas vazias ou comentários
            [[ -z "$key" || "${key:0:1}" == "#" ]] && continue
            # Remover espaços em branco e aspas
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//')
            
            # Atribuir valores às variáveis globais
            case "$key" in
                SOURCE_DIR) SOURCE_DIR="$value" ;;
                STAGING_DIR) STAGING_DIR="$value" ;;
                PROCESSED_DIR) PROCESSED_DIR="$value" ;;
                LOOKUP_DIR) LOOKUP_DIR="$value" ;;
                ERROR_DIR) ERROR_DIR="$value" ;;
                LOG_FILE) LOG_FILE="$value" ;;
                NOTIFICATION_EMAIL) NOTIFICATION_EMAIL="$value" ;;
                NOTIFICATION_ENABLED) NOTIFICATION_ENABLED="$value" ;;
            esac
        done < "$CONFIG_FILE"
    else
        log_message "AVISO: Arquivo de configuração $CONFIG_FILE não encontrado. Usando configurações padrão."
    fi
    
    # Criar diretórios se não existirem
    mkdir -p "$SOURCE_DIR" || handle_error "Criação de diretório $SOURCE_DIR"
    mkdir -p "$STAGING_DIR" || handle_error "Criação de diretório $STAGING_DIR"
    mkdir -p "$PROCESSED_DIR" || handle_error "Criação de diretório $PROCESSED_DIR"
    mkdir -p "$LOOKUP_DIR" || handle_error "Criação de diretório $LOOKUP_DIR"
    mkdir -p "$ERROR_DIR" || handle_error "Criação de diretório $ERROR_DIR"
    mkdir -p "$(dirname "$LOG_FILE")" || handle_error "Criação de diretório de log"
}

# --- Etapa 1: Extração (Simulada) ---
extract_data() {
    log_message "Iniciando etapa de Extração..."
    local raw_file="$SOURCE_DIR/raw_sales_$(date +%Y%m%d%H%M%S).csv"
    
    # Simula a criação de um arquivo de dados brutos com mais colunas e alguns erros
    echo "transaction_id,customer_id,product_name,quantity,price,transaction_date,region" > "$raw_file"
    echo "1,C001,Laptop,1,1200.00,2025-01-01,North" >> "$raw_file"
    echo "2,C002,Mouse,2,25.00,2025-01-01,South" >> "$raw_file"
    echo "3,C001,Keyboard,1,75.00,2025-01-02,North" >> "$raw_file"
    echo "4,C003,Monitor,1,300.00,2025-01-02,East" >> "$raw_file"
    echo "5,C002,Webcam,1,50.00,2025-01-03,South" >> "$raw_file"
    echo "6,C004,Headphones,1,150.00,2025-01-03,West" >> "$raw_file"
    echo "7,C005,Speaker,1,100.00,2025-01-04,North" >> "$raw_file"
    echo "8,C001,Laptop,1,1200.00,2025-01-04,North" >> "$raw_file"
    echo "9,C006,Printer,1,200.00,2025-01-05,East" >> "$raw_file"
    echo "10,C007,Scanner,1,180.00,2025-01-05,South" >> "$raw_file"
    echo "11,C008,InvalidProduct,A,100.00,2025-01-06,North" >> "$raw_file" # Erro: quantidade não numérica
    echo "12,C009,Keyboard,1,-50.00,2025-01-06,West" >> "$raw_file" # Erro: preço negativo
    echo "13,C010,Mouse,1,20.00,2025-01-07,East" >> "$raw_file"
    echo "14,C001,Laptop,1,1200.00,2025-01-07,North" >> "$raw_file"
    
    log_message "Extração concluída. Arquivo gerado em $raw_file"
    echo "$raw_file" # Retorna o nome do arquivo gerado
}

# --- Etapa 2: Validação de Dados ---
validate_data() {
    log_message "Iniciando etapa de Validação de Dados..."
    local raw_file="$1"
    local valid_file="$STAGING_DIR/valid_data_$(basename "$raw_file")"
    local invalid_file="$ERROR_DIR/invalid_data_$(basename "$raw_file")"
    local header=$(head -n 1 "$raw_file")
    
    if [ ! -f "$raw_file" ]; then
        log_message "ERRO: Arquivo bruto '$raw_file' não encontrado para validação."
        return 1
    fi

    # Limpar arquivos de saída anteriores
    > "$valid_file"
    > "$invalid_file"
    echo "$header" > "$valid_file"
    echo "$header,validation_error" > "$invalid_file"

    # Validação de cada linha
    tail -n +2 "$raw_file" | while IFS=, read -r transaction_id customer_id product_name quantity price transaction_date region;
    do
        is_valid=true
        error_msg=""

        # Validação 1: quantity deve ser um número inteiro positivo
        if ! [[ "$quantity" =~ ^[0-9]+$ ]] || (( quantity <= 0 )); then
            is_valid=false
            error_msg="$error_msg;InvalidQuantity"
        fi

        # Validação 2: price deve ser um número positivo
        if ! [[ "$price" =~ ^[0-9]+(\\.[0-9]+)?$ ]] || (( $(echo "$price <= 0" | bc -l) )); then
            is_valid=false
            error_msg="$error_msg;InvalidPrice"
        fi

        # Validação 3: transaction_date deve ser no formato YYYY-MM-DD
        if ! date -d "$transaction_date" >/dev/null 2>&1; then
            is_valid=false
            error_msg="$error_msg;InvalidDate"
        fi

        # Validação 4: product_name não pode ser vazio
        if [ -z "$product_name" ]; then
            is_valid=false
            error_msg="$error_msg;EmptyProductName"
        fi

        if $is_valid; then
            echo "$transaction_id,$customer_id,$product_name,$quantity,$price,$transaction_date,$region" >> "$valid_file"
        else
            echo "$transaction_id,$customer_id,$product_name,$quantity,$price,$transaction_date,$region,${error_msg:1}" >> "$invalid_file"
        fi
    done

    if [ -s "$invalid_file" ]; then
        log_message "Validação concluída. Registros inválidos encontrados e movidos para $invalid_file."
        send_notification "Registros Inválidos na Pipeline" "Foram encontrados registros inválidos no arquivo $(basename "$raw_file"). Veja $invalid_file para detalhes."
    else
        log_message "Validação concluída. Todos os registros são válidos. Arquivo gerado em $valid_file."
        rm "$invalid_file"
    fi
    echo "$valid_file" # Retorna o nome do arquivo validado
}

# --- Etapa 3: Transformação (Complexa) ---
transform_data() {
    log_message "Iniciando etapa de Transformação..."
    local input_file="$1"
    local transformed_file="$STAGING_DIR/transformed_$(basename "$input_file")"
    local lookup_file="$LOOKUP_DIR/product_categories.csv"
    
    if [ ! -f "$input_file" ]; then
        log_message "ERRO: Arquivo válido '$input_file' não encontrado para transformação."
        return 1
    fi

    # Criar arquivo de lookup de categorias de produtos (se não existir)
    if [ ! -f "$lookup_file" ]; then
        log_message "Criando arquivo de lookup de categorias: $lookup_file"
        echo "product_name,category" > "$lookup_file"
        echo "Laptop,Electronics" >> "$lookup_file"
        echo "Mouse,Peripherals" >> "$lookup_file"
        echo "Keyboard,Peripherals" >> "$lookup_file"
        echo "Monitor,Electronics" >> "$lookup_file"
        echo "Webcam,Peripherals" >> "$lookup_file"
        echo "Headphones,Audio" >> "$lookup_file"
        echo "Speaker,Audio" >> "$lookup_file"
        echo "Printer,Office" >> "$lookup_file"
        echo "Scanner,Office" >> "$lookup_file"
    fi

    # 1. Calcular total_amount (quantity * price)
    # 2. Adicionar categoria do produto (join com lookup)
    # 3. Agrupar por categoria e data para sumarizar vendas
    
    # Usando `awk` para calcular total_amount e adicionar categoria
    # e depois `sort` e `datamash` para agregação.
    
    # Adicionar total_amount e categoria
    awk -F, 'BEGIN {OFS=","} NR==1 {print $0, "total_amount", "category"} NR>1 {
        product=$3;
        # Simula lookup de categoria
        category="Unknown";
        while (getline < "'$lookup_file'") {
            if ($1 == product) { category=$2; break; }
        }
        close("'$lookup_file'");
        print $0, ($4 * $5), category
    }' "$input_file" > "$STAGING_DIR/temp_enriched_$(basename "$input_file")"

    # Agregação: vendas totais por categoria e data
    # Colunas: transaction_id,customer_id,product_name,quantity,price,transaction_date,region,total_amount,category
    # Agrupar por transaction_date e category
    log_message "Realizando agregação por data e categoria..."
    (head -n 1 "$STAGING_DIR/temp_enriched_$(basename "$input_file")" | sed 's/transaction_id,customer_id,product_name,quantity,price,region,total_amount,category/transaction_date,category,total_sales_amount,total_items_sold,num_transactions/';
    tail -n +2 "$STAGING_DIR/temp_enriched_$(basename "$input_file")" |
    sort -t, -k6,6 -k9,9 |
    datamash -t, -g 6,9 sum 8 sum 4 count 1)
    > "$transformed_file"

    rm "$STAGING_DIR/temp_enriched_$(basename "$input_file")"

    log_message "Transformação concluída. Arquivo gerado em $transformed_file"
    echo "$transformed_file" # Retorna o nome do arquivo transformado
}

# --- Etapa 4: Carregamento (Simulada) ---
load_data() {
    log_message "Iniciando etapa de Carregamento..."
    local transformed_file="$1"
    local final_file="$PROCESSED_DIR/final_aggregated_$(basename "$transformed_file")"
    
    if [ ! -f "$transformed_file" ]; then
        log_message "ERRO: Arquivo transformado '$transformed_file' não encontrado. Pulando carregamento."
        return 1
    fi

    # Simula o carregamento: copia o arquivo transformado para o diretório final
    cp "$transformed_file" "$final_file" || handle_error "Cópia do arquivo final"
    
    log_message "Carregamento concluído. Arquivo final em $final_file"
    send_notification "Pipeline de Dados Concluída" "A pipeline de dados foi concluída com sucesso. Arquivo processado: $final_file"
}

# --- Execução da Pipeline Principal ---
main_pipeline() {
    log_message "========================================="
    log_message "Iniciando pipeline de dados principal..."
    log_message "========================================="

    # Carregar configurações
    load_config

    # Definir traps para tratamento de erros
    trap 'handle_error "Extração"' ERR
    RAW_DATA_FILE=$(extract_data)

    trap 'handle_error "Validação"' ERR
    VALID_DATA_FILE=$(validate_data "$RAW_DATA_FILE")

    trap 'handle_error "Transformação"' ERR
    TRANSFORMED_DATA_FILE=$(transform_data "$VALID_DATA_FILE")

    trap 'handle_error "Carregamento"' ERR
    load_data "$TRANSFORMED_DATA_FILE"

    log_message "========================================="
    log_message "Pipeline de dados concluída com sucesso!"
    log_message "========================================="
}

# Executar a pipeline
main_pipeline

