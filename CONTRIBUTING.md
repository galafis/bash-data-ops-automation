# Guia de Contribuição / Contributing Guide

## 🇧🇷 Português

Obrigado por considerar contribuir para o projeto bash-data-ops-automation! 

### Como Contribuir

1. **Fork o Repositório**
   - Clique no botão "Fork" no canto superior direito

2. **Clone seu Fork**
   ```bash
   git clone https://github.com/seu-usuario/bash-data-ops-automation.git
   cd bash-data-ops-automation
   ```

3. **Crie uma Branch**
   ```bash
   git checkout -b feature/minha-nova-feature
   ```

4. **Faça suas Alterações**
   - Siga as boas práticas de shell scripting
   - Execute shellcheck para análise estática
   - Adicione testes para novas funcionalidades
   - Atualize a documentação conforme necessário

5. **Execute os Testes**
   ```bash
   # Instalar dependências (se necessário)
   sudo apt-get install -y shellcheck datamash bc
   
   # Executar todos os testes
   bash tests/run_all_tests.sh
   
   # Executar shellcheck
   shellcheck src/*.sh tests/*.sh
   ```

6. **Commit suas Mudanças**
   ```bash
   git add .
   git commit -m "feat: adiciona nova funcionalidade X"
   ```

7. **Push para seu Fork**
   ```bash
   git push origin feature/minha-nova-feature
   ```

8. **Abra um Pull Request**
   - Vá para o repositório original
   - Clique em "New Pull Request"
   - Descreva suas alterações detalhadamente

### Padrões de Código

- Use indentação de 4 espaços
- Adicione comentários explicativos
- Siga as convenções de nomenclatura existentes
- Use `set -o pipefail` para pipelines robustos
- Implemente tratamento de erros adequado
- Use variáveis locais em funções

### Mensagens de Commit

Use commits semânticos:
- `feat:` para novas funcionalidades
- `fix:` para correções de bugs
- `docs:` para alterações na documentação
- `test:` para adição/modificação de testes
- `refactor:` para refatoração de código
- `style:` para formatação de código
- `chore:` para tarefas de manutenção

### Testes

Todas as novas funcionalidades devem incluir testes:
- Testes unitários para funções individuais
- Testes de integração para fluxos completos
- Testes de casos de erro

### Documentação

- Atualize o README.md se necessário
- Documente novas funcionalidades
- Adicione comentários inline para código complexo
- Atualize diagramas se a arquitetura mudar

---

## 🇬🇧 English

Thank you for considering contributing to bash-data-ops-automation!

### How to Contribute

1. **Fork the Repository**
   - Click the "Fork" button in the upper right corner

2. **Clone your Fork**
   ```bash
   git clone https://github.com/your-username/bash-data-ops-automation.git
   cd bash-data-ops-automation
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

4. **Make your Changes**
   - Follow shell scripting best practices
   - Run shellcheck for static analysis
   - Add tests for new features
   - Update documentation as needed

5. **Run Tests**
   ```bash
   # Install dependencies (if needed)
   sudo apt-get install -y shellcheck datamash bc
   
   # Run all tests
   bash tests/run_all_tests.sh
   
   # Run shellcheck
   shellcheck src/*.sh tests/*.sh
   ```

6. **Commit your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature X"
   ```

7. **Push to your Fork**
   ```bash
   git push origin feature/my-new-feature
   ```

8. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Describe your changes in detail

### Code Standards

- Use 4-space indentation
- Add explanatory comments
- Follow existing naming conventions
- Use `set -o pipefail` for robust pipelines
- Implement proper error handling
- Use local variables in functions

### Commit Messages

Use semantic commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `test:` for adding/modifying tests
- `refactor:` for code refactoring
- `style:` for code formatting
- `chore:` for maintenance tasks

### Tests

All new features must include tests:
- Unit tests for individual functions
- Integration tests for complete flows
- Error case tests

### Documentation

- Update README.md if necessary
- Document new features
- Add inline comments for complex code
- Update diagrams if architecture changes

---

## Código de Conduta / Code of Conduct

Este projeto adere aos padrões de conduta da comunidade open source. Seja respeitoso e construtivo em todas as interações.

This project adheres to open source community conduct standards. Be respectful and constructive in all interactions.
