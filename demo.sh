#!/bin/bash

################################################################################
# Demo Script - Demonstra todas as funcionalidades do repositório
# Author: Gabriel Demetrios Lafis
# Year: 2025
#
# Este script executa uma demonstração completa de todas as funcionalidades
# do projeto bash-data-ops-automation, incluindo:
# - Pipeline completa de dados (ETL)
# - Análise avançada de logs
# - Validação e testes
################################################################################

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Demonstração - Bash DataOps Automation${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Navegar para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# ============================================
# Parte 1: Demonstração do Data Pipeline
# ============================================
echo -e "${GREEN}[1/3] Executando Data Pipeline${NC}"
echo "-------------------------------------------"

# Criar estrutura de diretórios
mkdir -p demo_run/config demo_run/data/{raw,staging,processed,lookup,errors} demo_run/logs

# Criar arquivo de configuração
cat > demo_run/config/pipeline_config.conf <<EOF
SOURCE_DIR=./demo_run/data/raw
STAGING_DIR=./demo_run/data/staging
PROCESSED_DIR=./demo_run/data/processed
LOOKUP_DIR=./demo_run/data/lookup
ERROR_DIR=./demo_run/data/errors
LOG_FILE=./demo_run/logs/data_pipeline.log
NOTIFICATION_ENABLED=false
EOF

# Executar o pipeline de dados
cd "$SCRIPT_DIR/demo_run" || exit 1
echo "Executando data_pipeline.sh..."
bash "$SCRIPT_DIR/src/data_pipeline.sh"

echo ""
echo -e "${YELLOW}Resultados do Data Pipeline:${NC}"
echo "- Logs: $(wc -l < logs/data_pipeline.log) linhas"
echo "- Dados válidos: $([ -f data/staging/valid_data_*.csv ] && wc -l < data/staging/valid_data_*.csv || echo 0) linhas"
echo "- Dados inválidos: $([ -f data/errors/invalid_data_*.csv ] && wc -l < data/errors/invalid_data_*.csv || echo 0) linhas"
echo "- Dados transformados: $([ -f data/staging/transformed_*.csv ] && wc -l < data/staging/transformed_*.csv || echo 0) linhas"
echo ""

cd "$SCRIPT_DIR" || exit 1

# ============================================
# Parte 2: Demonstração do Log Analyzer
# ============================================
echo -e "${GREEN}[2/3] Executando Log Analyzer${NC}"
echo "-------------------------------------------"

# Executar o log analyzer
mkdir -p demo_logs demo_analysis
export LOG_DIR=./demo_logs
export OUTPUT_DIR=./demo_analysis

echo "Executando log_analyzer.sh..."
bash src/log_analyzer.sh > /dev/null 2>&1

echo ""
echo -e "${YELLOW}Resultados do Log Analyzer:${NC}"
echo "- Logs analisados: $(wc -l < demo_logs/application.log) linhas"
echo "- Relatórios gerados: $(ls demo_analysis/*.txt 2>/dev/null | wc -l) arquivos"

if [ -f demo_analysis/anomalies_report.txt ]; then
    echo ""
    echo "Amostra do relatório de anomalias:"
    echo "-----------------------------------"
    head -20 demo_analysis/anomalies_report.txt
fi

echo ""

# ============================================
# Parte 3: Executar Testes
# ============================================
echo -e "${GREEN}[3/3] Executando Suite de Testes${NC}"
echo "-------------------------------------------"

bash tests/run_all_tests.sh

# ============================================
# Limpeza
# ============================================
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}Demonstração Concluída com Sucesso!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Para explorar mais:"
echo "- Verifique os logs em: demo_run/logs/"
echo "- Veja os dados processados em: demo_run/data/"
echo "- Analise os relatórios em: demo_analysis/"
echo ""
echo "Para limpar os arquivos de demonstração:"
echo "  rm -rf demo_run demo_logs demo_analysis test_*"
echo ""
