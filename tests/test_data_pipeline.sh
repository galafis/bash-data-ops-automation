
#!/bin/bash

# Arquivo de teste para o script data_pipeline.sh

# Função para limpar arquivos gerados pelo pipeline
cleanup() {
    rm -f data.csv transformed_data.csv loaded_data.txt
}

# Garantir que a limpeza seja feita ao sair
trap cleanup EXIT

# Executar o pipeline
OUTPUT=$(bash ../src/data_pipeline.sh)
STATUS=$?

echo "--- Teste do Pipeline de Automação de Dados ---"

# Verificar o status de saída do script
if [ $STATUS -eq 0 ]; then
    echo "✓ Teste de status de saída: SUCESSO (código de saída 0)"
else
    echo "✗ Teste de status de saída: FALHA (código de saída $STATUS)"
    exit 1
fi

# Verificar se a mensagem de sucesso final está presente na saída
if echo "$OUTPUT" | grep -q "Pipeline completed successfully!"; then
    echo "✓ Teste de mensagem de sucesso: SUCESSO"
else
    echo "✗ Teste de mensagem de sucesso: FALHA (mensagem final não encontrada)"
    echo "Saída do pipeline:\n$OUTPUT"
    exit 1
fi

# Verificar se os arquivos intermediários foram criados (e limpos no final)
if [ -f data.csv ]; then
    echo "✗ Teste de arquivo intermediário data.csv: FALHA (não deveria existir após a limpeza)"
    exit 1
fi

if [ -f transformed_data.csv ]; then
    echo "✗ Teste de arquivo intermediário transformed_data.csv: FALHA (não deveria existir após a limpeza)"
    exit 1
fi

if [ -f loaded_data.txt ]; then
    echo "✗ Teste de arquivo intermediário loaded_data.txt: FALHA (não deveria existir após a limpeza)"
    exit 1
fi

echo "✓ Teste de limpeza de arquivos: SUCESSO"

echo "--- Todos os testes para data_pipeline.sh passaram com sucesso! ---"

