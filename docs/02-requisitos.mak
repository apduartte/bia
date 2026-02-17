2.1 Contexto Técnico

O objetivo deste projeto é estruturar uma oferta de n8n self-hosted na AWS, viável comercialmente, tecnicamente sustentável e replicável em múltiplas contas.
A solução deve atender dois níveis de maturidade operacional:
Modelo 1 – Implantação econômica
Modelo 2 – Implantação escalável e resiliente
Ambos os modelos devem manter consistência arquitetural, segurança básica e padronização de implantação.
2.2 Requisitos Funcionais
🔹 Modelo 1 — Single Instance (Baseline Econômico)
Requisitos obrigatórios:
Implantação do n8n em container Docker rodando em instância EC2.
Persistência de dados em banco PostgreSQL (preferencialmente RDS).
Exposição da aplicação via HTTPS (ALB + ACM ou proxy equivalente).
Correção adequada de geração de URLs de webhook:
Configuração de WEBHOOK_URL
Configuração de N8N_PROXY_HOPS
Execução bem-sucedida de workflow com trigger webhook.
Persistência das execuções no banco de dados.
Premissas técnicas:
Não há necessidade de alta disponibilidade neste modelo.
A falha da instância pode resultar em indisponibilidade temporária.
O objetivo é otimização de custo e simplicidade operacional.
🔹 Modelo 2 — Queue Mode (Arquitetura Escalável)
Requisitos obrigatórios:
Ativação do modo de execução EXECUTIONS_MODE=queue.
Implementação de Redis (ElastiCache) como backend de fila.
Separação lógica de papéis:
1 instância ou serviço “main” (editor/scheduler)
2 workers
2 webhook processors
Banco PostgreSQL configurado em Multi-AZ.
Balanceamento de carga configurado por path ou target group.
Teste de múltiplas requisições concorrentes validando:
Distribuição de carga
Execução assíncrona
Persistência consistente
Premissas técnicas:
A arquitetura deve suportar aumento de carga sem bloqueio do processo principal.
A ingestão de webhooks não pode degradar a interface de administração.
Deve existir desacoplamento entre entrada de requisição e execução.
2.3 Requisitos Não Funcionais
🔐 Segurança
Instâncias protegidas por Security Groups com princípio de menor privilégio.
Banco de dados acessível apenas por recursos internos.
HTTPS obrigatório.
Credenciais não hardcoded (variáveis parametrizadas).
📈 Escalabilidade
Modelo 1 → escalabilidade vertical.
Modelo 2 → escalabilidade horizontal via aumento de workers/webhooks.
🔄 Reprodutibilidade
Infraestrutura deve ser passível de automação via Terraform.
Deve ser possível replicar o ambiente em nova conta AWS sem alterações estruturais.
📊 Observabilidade
Logs acessíveis (Docker ou CloudWatch).
Validação de execução rastreável.
Evidência clara de funcionamento do workflow.
2.4 Critérios de Sucesso (Acceptance Criteria)
O projeto será considerado tecnicamente validado quando:
Para o Modelo 1:
Endpoint HTTPS público respondendo com status 200.
Webhook executando corretamente via domínio configurado.
Execuções persistidas no PostgreSQL.
Ambiente documentado com diagrama e prints.
Para o Modelo 2:
Execuções distribuídas via Redis.
Workers consumindo fila de forma concorrente.
Webhook processors recebendo requisições via ALB.
Banco Multi-AZ ativo.
Teste de carga simples validando desacoplamento.
2.5 Indicadores de Qualidade Técnica
Clareza arquitetural
Ausência de dependências implícitas
Separação de responsabilidades
Baixo acoplamento
Consistência entre modelos
Documentação completa
Esse texto posiciona você como alguém que:
Entende arquitetura distribuída
Entende critérios de aceitação
Sabe diferenciar requisito funcional e não funcional
Trabalha com visão de produção, não apenas PoC
Se quiser, posso agora elevar o Item 3 – Decisões Técnicas para o mesmo nível executivo.