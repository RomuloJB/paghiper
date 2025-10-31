# Projeto: Leitura e Consulta de Contratos Sociais

### Resumo
Solução de extração automática de informações de contratos sociais de empresas (em PDF digital ou escaneado), retornando um JSON padronizado com campos como CNPJ, razão social, sócios (nome, CPF/CNPJ, participação), administradores, capital social, endereço da sede, objeto social, entre outros. O sistema oferece API para processamento síncrono/assíncrono, dashboard de revisão humana e validação automática (checksums de CPF/CNPJ, normalização e consistência).

### Objetivos
- Ler contratos sociais em PDF (nativo e digitalizados) e extrair dados estruturados com alta precisão.
- Padronizar a saída em um JSON validado por schema, com confidences por campo.
- Permitir consulta e auditoria posterior, com trilha de acesso e versão.
- Minimizar retrabalho via aprendizado ativo (human-in-the-loop) para melhoria contínua.

### Tecnologias para Desenvolvimento
- Flutter
- Python
- MySQL

### Riscos e Mitigações
- Baixa qualidade de scans: aplicar pré-processamento (deskew/denoise/binarização); fallback humano.
- Variedade extrema de layouts: abordagem híbrida (regras + NER + LLM) e aprendizado contínuo.
- LGPD/segurança: execução on-prem/VPC e minimização de dados; controles de acesso fortes.
- Tabelas complexas de quotas: combinação de detecção tabular e heurísticas de somatório/validadores.

### Plano de Ataque (MVP pragmático)
1) Começar pelo simples
- PDFs nativos: extração por texto + regex (CNPJ, CPF, CEP, datas, valores) e heurísticas para “Razão Social” e “Objeto Social”.
- JSON Schema + validação e normalização.
2) Preparar o difícil
- Estrutura do pipeline com interfaces para OCR/NER e detecção de tabelas plugáveis.
- Registro de confidences e fontes (página/trecho/bbox).
