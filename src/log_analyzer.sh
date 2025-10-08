#!/bin/bash

################################################################################
# Log Analyzer - Advanced Log Analysis and Monitoring
# Author: Gabriel Demetrios Lafis
# Year: 2025
#
# Este script demonstra análise avançada de logs com Bash, incluindo:
# - Análise de padrões e frequências
# - Detecção de anomalias
# - Geração de relatórios estatísticos
# - Alertas baseados em thresholds
################################################################################

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
LOG_DIR="${LOG_DIR:-./logs}"
OUTPUT_DIR="${OUTPUT_DIR:-./analysis}"
ALERT_THRESHOLD_ERROR=10
ALERT_THRESHOLD_WARNING=50

# Criar diretórios se não existirem
mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

################################################################################
# Funções Auxiliares
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Geração de Logs de Exemplo
################################################################################

generate_sample_logs() {
    local log_file="$LOG_DIR/application.log"
    local num_lines=${1:-1000}
    
    log_info "Gerando $num_lines linhas de logs de exemplo..."
    
    > "$log_file"  # Limpar arquivo
    
    local log_levels=("INFO" "WARNING" "ERROR" "DEBUG")
    local services=("api" "database" "cache" "queue" "auth")
    local messages=(
        "Request processed successfully"
        "Connection timeout"
        "Invalid credentials"
        "Cache miss"
        "Database query executed"
        "Rate limit exceeded"
        "Memory usage high"
        "Disk space low"
        "Service started"
        "Service stopped"
    )
    
    for ((i=1; i<=num_lines; i++)); do
        local timestamp=$(date -d "$((RANDOM % 24)) hours ago $((RANDOM % 60)) minutes ago" '+%Y-%m-%d %H:%M:%S')
        local level=${log_levels[$((RANDOM % ${#log_levels[@]}))]}
        local service=${services[$((RANDOM % ${#services[@]}))]}
        local message=${messages[$((RANDOM % ${#messages[@]}))]}
        local response_time=$((RANDOM % 5000))
        
        echo "$timestamp [$level] [$service] $message (${response_time}ms)" >> "$log_file"
    done
    
    log_success "Logs de exemplo gerados em $log_file"
}

################################################################################
# Análise de Logs
################################################################################

analyze_log_levels() {
    local log_file="$1"
    local output_file="$OUTPUT_DIR/log_levels_summary.txt"
    
    log_info "Analisando níveis de log..."
    
    {
        echo "========================================="
        echo "Resumo de Níveis de Log"
        echo "========================================="
        echo ""
        echo "Total de linhas: $(wc -l < "$log_file")"
        echo ""
        echo "Distribuição por nível:"
        grep -oP '\[(INFO|WARNING|ERROR|DEBUG)\]' "$log_file" | sort | uniq -c | sort -rn
        echo ""
        echo "Porcentagem por nível:"
        local total=$(wc -l < "$log_file")
        for level in INFO WARNING ERROR DEBUG; do
            local count=$(grep -c "\[$level\]" "$log_file" || echo 0)
            local percentage=$(awk "BEGIN {printf \"%.2f\", ($count/$total)*100}")
            echo "  $level: $count ($percentage%)"
        done
    } > "$output_file"
    
    log_success "Análise de níveis salva em $output_file"
    cat "$output_file"
}

analyze_services() {
    local log_file="$1"
    local output_file="$OUTPUT_DIR/services_summary.txt"
    
    log_info "Analisando serviços..."
    
    {
        echo "========================================="
        echo "Resumo de Serviços"
        echo "========================================="
        echo ""
        echo "Top 10 serviços com mais logs:"
        grep -oP '\]\s+\[\K[^\]]+' "$log_file" | sort | uniq -c | sort -rn | head -10
        echo ""
        echo "Erros por serviço:"
        grep '\[ERROR\]' "$log_file" | grep -oP '\]\s+\[\K[^\]]+' | sort | uniq -c | sort -rn
    } > "$output_file"
    
    log_success "Análise de serviços salva em $output_file"
    cat "$output_file"
}

analyze_response_times() {
    local log_file="$1"
    local output_file="$OUTPUT_DIR/response_times_summary.txt"
    
    log_info "Analisando tempos de resposta..."
    
    # Extrair tempos de resposta
    local temp_file=$(mktemp)
    grep -oP '\(\K[0-9]+(?=ms\))' "$log_file" > "$temp_file"
    
    if [ ! -s "$temp_file" ]; then
        log_warning "Nenhum tempo de resposta encontrado"
        rm "$temp_file"
        return
    fi
    
    {
        echo "========================================="
        echo "Análise de Tempos de Resposta"
        echo "========================================="
        echo ""
        echo "Estatísticas (em ms):"
        
        # Calcular estatísticas usando datamash se disponível, senão usar awk
        if command -v datamash &> /dev/null; then
            datamash -t, mean 1 median 1 min 1 max 1 sstdev 1 < "$temp_file" | \
                awk -F'\t' '{printf "  Média: %.2f\n  Mediana: %.2f\n  Mínimo: %.2f\n  Máximo: %.2f\n  Desvio Padrão: %.2f\n", $1, $2, $3, $4, $5}'
        else
            awk '{sum+=$1; sumsq+=$1*$1; if(NR==1){min=max=$1}} 
                 {if($1<min) min=$1; if($1>max) max=$1} 
                 END {
                     mean=sum/NR; 
                     stddev=sqrt(sumsq/NR - mean*mean);
                     printf "  Média: %.2f\n  Mínimo: %.2f\n  Máximo: %.2f\n  Desvio Padrão: %.2f\n", mean, min, max, stddev
                 }' "$temp_file"
        fi
        
        echo ""
        echo "Distribuição de tempos de resposta:"
        echo "  < 100ms: $(awk '$1<100' "$temp_file" | wc -l)"
        echo "  100-500ms: $(awk '$1>=100 && $1<500' "$temp_file" | wc -l)"
        echo "  500-1000ms: $(awk '$1>=500 && $1<1000' "$temp_file" | wc -l)"
        echo "  1000-2000ms: $(awk '$1>=1000 && $1<2000' "$temp_file" | wc -l)"
        echo "  > 2000ms: $(awk '$1>=2000' "$temp_file" | wc -l)"
    } > "$output_file"
    
    rm "$temp_file"
    
    log_success "Análise de tempos de resposta salva em $output_file"
    cat "$output_file"
}

analyze_time_patterns() {
    local log_file="$1"
    local output_file="$OUTPUT_DIR/time_patterns_summary.txt"
    
    log_info "Analisando padrões temporais..."
    
    {
        echo "========================================="
        echo "Padrões Temporais"
        echo "========================================="
        echo ""
        echo "Logs por hora:"
        grep -oP '^\d{4}-\d{2}-\d{2} \K\d{2}' "$log_file" | sort | uniq -c | sort -k2 -n
        echo ""
        echo "Top 5 horas com mais erros:"
        grep '\[ERROR\]' "$log_file" | grep -oP '^\d{4}-\d{2}-\d{2} \K\d{2}' | sort | uniq -c | sort -rn | head -5
    } > "$output_file"
    
    log_success "Análise de padrões temporais salva em $output_file"
    cat "$output_file"
}

detect_anomalies() {
    local log_file="$1"
    local output_file="$OUTPUT_DIR/anomalies_report.txt"
    
    log_info "Detectando anomalias..."
    
    local error_count=$(grep -c '\[ERROR\]' "$log_file" || echo 0)
    local warning_count=$(grep -c '\[WARNING\]' "$log_file" || echo 0)
    
    {
        echo "========================================="
        echo "Relatório de Anomalias"
        echo "========================================="
        echo ""
        echo "Thresholds configurados:"
        echo "  Erros: $ALERT_THRESHOLD_ERROR"
        echo "  Warnings: $ALERT_THRESHOLD_WARNING"
        echo ""
        echo "Contagens atuais:"
        echo "  Erros: $error_count"
        echo "  Warnings: $warning_count"
        echo ""
        
        if [ "$error_count" -gt "$ALERT_THRESHOLD_ERROR" ]; then
            echo "⚠️  ALERTA: Número de erros ($error_count) excede o threshold ($ALERT_THRESHOLD_ERROR)"
        else
            echo "✓ Número de erros dentro do threshold"
        fi
        
        if [ "$warning_count" -gt "$ALERT_THRESHOLD_WARNING" ]; then
            echo "⚠️  ALERTA: Número de warnings ($warning_count) excede o threshold ($ALERT_THRESHOLD_WARNING)"
        else
            echo "✓ Número de warnings dentro do threshold"
        fi
        
        echo ""
        echo "Top 5 mensagens de erro mais frequentes:"
        grep '\[ERROR\]' "$log_file" | grep -oP '\]\s+\[[^\]]+\]\s+\K[^(]+' | sort | uniq -c | sort -rn | head -5
    } > "$output_file"
    
    log_success "Relatório de anomalias salvo em $output_file"
    cat "$output_file"
}

generate_summary_report() {
    local output_file="$OUTPUT_DIR/summary_report.txt"
    
    log_info "Gerando relatório resumido..."
    
    {
        echo "========================================="
        echo "Relatório Resumido de Análise de Logs"
        echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================="
        echo ""
        echo "Arquivos analisados:"
        ls -lh "$LOG_DIR"/*.log 2>/dev/null || echo "  Nenhum arquivo de log encontrado"
        echo ""
        echo "Arquivos de análise gerados:"
        ls -lh "$OUTPUT_DIR"/*.txt 2>/dev/null || echo "  Nenhum arquivo de análise encontrado"
        echo ""
        echo "========================================="
    } > "$output_file"
    
    log_success "Relatório resumido salvo em $output_file"
    cat "$output_file"
}

################################################################################
# Função Principal
################################################################################

main() {
    echo ""
    echo "========================================="
    echo "Log Analyzer - Advanced Log Analysis"
    echo "========================================="
    echo ""
    
    # Gerar logs de exemplo
    generate_sample_logs 1000
    
    local log_file="$LOG_DIR/application.log"
    
    # Executar análises
    echo ""
    analyze_log_levels "$log_file"
    echo ""
    analyze_services "$log_file"
    echo ""
    analyze_response_times "$log_file"
    echo ""
    analyze_time_patterns "$log_file"
    echo ""
    detect_anomalies "$log_file"
    echo ""
    generate_summary_report
    
    echo ""
    log_success "Análise completa! Todos os relatórios foram salvos em $OUTPUT_DIR/"
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
