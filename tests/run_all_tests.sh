#!/bin/bash

# Master test runner - executa todos os testes do repositório

echo "======================================"
echo "Executando Testes de Automação DataOps"
echo "======================================"
echo ""

# Contador de testes
TESTS_PASSED=0
TESTS_FAILED=0

# Função para executar um teste
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo "Executando: $test_name..."
    if bash "$test_script"; then
        echo "✓ $test_name: PASSOU"
        ((TESTS_PASSED++))
    else
        echo "✗ $test_name: FALHOU"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Executar todos os testes
cd "$(dirname "$0")/.." || exit 1

run_test "Teste de Data Pipeline" "tests/test_data_pipeline.sh"
run_test "Teste de Log Analyzer" "tests/test_log_analyzer.sh"

# Resumo dos resultados
echo "======================================"
echo "Resumo dos Testes"
echo "======================================"
echo "Testes executados: $((TESTS_PASSED + TESTS_FAILED))"
echo "Testes que passaram: $TESTS_PASSED"
echo "Testes que falharam: $TESTS_FAILED"
echo "======================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ Todos os testes passaram!"
    exit 0
else
    echo "✗ Alguns testes falharam."
    exit 1
fi
