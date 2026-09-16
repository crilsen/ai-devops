---
prd_number: "001"
status: rascunho
priority: alta
created: 2026-09-14
issue: ""
depends_on: []
references:
  - "docs/trd.md (a criar via escrever-trd)"
  - "docs/adrs/ (a criar via escrever-trd Modo Decision)"
  - "docs/prds/002-extensao-kubernetes.md"
---

# PRD 001: Conteinerização com Docker

## 1. Contexto

- **Produto/área**: docker-maker. É um serviço web local que recebe um repositório do GitHub e devolve os artefatos de conteinerização do projeto, validados e entregues numa branch nova do próprio repositório. É um MVP e vai ser construído numa aula ao vivo.
- **Estado atual**: não existe produto. Hoje, conteinerizar um projeto é trabalho manual. É preciso ler o código, descobrir a stack, as portas, as variáveis de ambiente e as dependências (banco, cache, broker), escrever Dockerfile e compose, e testar até funcionar.
- **Problema**: o difícil não é escrever um Dockerfile. É **descobrir do que a aplicação precisa para rodar**. Um erro nisso só aparece quando se tenta subir a aplicação. Artefatos gerados sem validação dão uma falsa sensação de pronto, e artefatos sem explicação não dizem ao revisor o que foi comprovado e o que ainda falta preencher.

> **Contexto técnico** (stack, agente, modelo, orquestração) vive no TRD (`docs/trd.md`) e nos ADRs, ainda a criar. Veja o §8.

## 2. Solução Proposta

### Visão de produto

- O usuário informa a URL de um repositório do GitHub e, se quiser, observações que direcionam a geração. Um agente autônomo faz o resto.
- O agente analisa o projeto, **mapeia as dependências com base em evidência** e gera Dockerfile e docker compose que já trazem essas dependências.
- Os artefatos são **validados de verdade** na máquina local: build, execução e subida do compose. O agente corrige o que falhar, e o status final é atestado por uma validação independente do agente.
- O resultado vai para uma **branch nova no GitHub**, com um **relatório em markdown na raiz** que separa o que foi comprovado do que foi deduzido e do que o usuário precisa preencher.
- Se o repositório já tem artefatos Docker, o agente os **melhora** em vez de ignorar ou sobrescrever às cegas.

### Decisões de produto

1. **Serviço web local, de um usuário só.** Usa as credenciais git da própria máquina para clonar e fazer push. Motivo: é um MVP, e a credencial local elimina login e gestão de tokens.
2. **Entrega por push de branch nova, sem abrir PR.** Motivo: a revisão humana acontece na branch; abrir PR fica para depois.
3. **O push acontece mesmo quando a validação falha.** O relatório registra a falha. Motivo: um resultado parcial com diagnóstico tem valor para o revisor, e perder o trabalho não tem.
4. **A validação é real, com o Docker local.** Gerar sem validar não entrega o valor do produto.
5. **O agente mapeia as dependências e as inclui nos artefatos.** Motivo: compose sem o banco que a aplicação exige não sobe.
6. **Observações do usuário direcionam a geração.** Motivo: o usuário tem informação que o repositório não revela (porta, imagem base preferida, variáveis).
7. **Artefatos existentes são analisados e melhorados.** Motivo: ignorá-los desperdiça conhecimento do projeto, e sobrescrevê-los às cegas destrói o que funcionava.

### Fora do escopo

- Abrir pull request automaticamente. Motivo: decisão do MVP, o push da branch basta.
- Monorepo com várias aplicações. Motivo: o MVP trata uma aplicação por repositório *(premissa — confirme ou corrija)*
- Manifestos Kubernetes e validação em cluster. Motivo: estão no PRD 002.
- Multiusuário, login e credencial por usuário. Motivo: MVP local de um usuário.
- Defesa contra prompt injection vinda do conteúdo do repositório. Motivo: decisão explícita do MVP.
- Isolamento em sandbox da validação. Motivo: o MVP roda na máquina do usuário, com repositórios que ele escolhe *(premissa — confirme ou corrija)*
- Publicar a imagem em registry. Motivo: a imagem existe só localmente, para validação *(premissa — confirme ou corrija)*
- Rodar de novo um job sobre a mesma branch para refinar o resultado. Motivo: cada job gera uma branch nova *(premissa — confirme ou corrija)*

## 3. Funcionalidades

### US01: Submeter repositório com observações

Como desenvolvedor, quero informar a URL de um repositório do GitHub e observações opcionais, para receber os artefatos de conteinerização sem escrevê-los à mão.

**Rules:**
- A interface pede a URL de um repositório do GitHub (obrigatória) e um campo livre de observações (opcional).
- A submissão cria um job assíncrono: a interface não fica bloqueada esperando o fim.
- Só um job roda por vez *(premissa — confirme ou corrija)*
- Antes de criar o job, a interface avisa que o conteúdo do repositório vai ser enviado a um provedor de LLM externo *(premissa — confirme ou corrija)*

**Edge cases:**
- URL malformada ou fora do GitHub → recusada antes de criar o job, com mensagem clara.
- Repositório inexistente ou inacessível com a credencial local → o job termina em erro na etapa de clone, nada é enviado, e a interface mostra o motivo.
- Já existe um job em andamento → a nova submissão é recusada com aviso *(premissa — confirme ou corrija)*
- Observações vazias → o job segue apenas com as escolhas padrão do agente.

### US02: Acompanhar o progresso e ver o resultado

Como desenvolvedor, quero acompanhar em tempo real em que etapa o job está e ver o resultado ao final, para saber o que está acontecendo durante um processo que leva minutos.

**Rules:**
- A interface mostra as etapas do job conforme avançam: clone, análise, geração, validação, relatório e entrega.
- Ao final, a interface mostra o status por etapa, o link da branch no GitHub e o conteúdo do relatório.
- O estado do job existe enquanto o serviço está no ar; reiniciar o serviço perde o job em andamento *(premissa — confirme ou corrija)*

**Edge cases:**
- O push falhou → a interface mostra o relatório completo e o motivo da falha, para o trabalho não se perder.
- O job estourou o limite de tempo → a interface mostra o status "interrompido por limite", com o que foi possível concluir *(premissa — confirme ou corrija)*
- O serviço reiniciou no meio do job → o job aparece como perdido e o usuário precisa submeter de novo *(premissa — confirme ou corrija)*

### US03: Analisar a stack e mapear as dependências

Como desenvolvedor, quero que o agente descubra a stack e as dependências de runtime da aplicação, para que os artefatos já nasçam com tudo o que ela precisa para subir.

**Rules:**
- O agente identifica linguagem, framework, versão de runtime, comando de execução, portas e as variáveis de ambiente que a aplicação lê.
- **Toda dependência precisa de evidência no repositório**: driver ou biblioteca declarada, `.env.example`, arquivo de configuração, compose existente ou documentação. Sem evidência, a dependência não entra.
- Só vira componente conteinerizado o que roda localmente em container: banco de dados, cache, broker de mensagens, storage compatível com S3 *(premissa — confirme ou corrija)*
- Serviço SaaS externo (pagamento, e-mail, API de terceiros) não vira container. Vira variável de ambiente com placeholder, citada no relatório *(premissa — confirme ou corrija)*
- Segredo real encontrado no repositório (chave, token, senha) nunca é copiado para os artefatos. Vira placeholder e é apenas mencionado no relatório, sem o valor *(premissa — confirme ou corrija)*
- A versão de cada dependência segue o que o repositório indicar. Sem indicação, usa uma tag estável da versão principal *(premissa — confirme ou corrija)*
- O mapeamento de dependências é a **fonte única** usada por todos os artefatos, inclusive os do PRD 002.

**Edge cases:**
- Repositório com várias aplicações (monorepo) → o agente conteineriza a aplicação principal que conseguir identificar e registra no relatório que as demais ficaram de fora *(premissa — confirme ou corrija)*
- Nenhuma aplicação reconhecível (repositório só de docs ou de biblioteca) → o job termina sem artefatos, nada é enviado, e a interface explica o motivo.
- Dependência mencionada só no README, sem nenhum uso no código → entra com evidência marcada como fraca no relatório *(premissa — confirme ou corrija)*
- A aplicação exige migration para subir → a migration entra como parte da subida; se não der para automatizar, o relatório registra e a validação fica parcial *(premissa — confirme ou corrija)*

### US04: Gerar Dockerfile e docker compose

Como desenvolvedor, quero receber um Dockerfile e um docker compose prontos, com as dependências mapeadas, para subir a aplicação completa com um comando.

**Rules:**
- O Dockerfile constrói e executa a aplicação identificada na US03.
- O compose sobe a aplicação e todas as dependências conteinerizáveis mapeadas, com a conexão entre elas configurada nas variáveis que a aplicação realmente lê.
- A aplicação só sobe depois que as dependências estão prontas para receber conexão.
- Toda imagem usa tag fixa, nunca `:latest` nem imagem sem tag.
- As credenciais das dependências (senha do banco de dev, por exemplo) usam valores fictícios, são commitadas e aparecem no relatório como credenciais de desenvolvimento *(premissa — confirme ou corrija)*

**Edge cases:**
- A aplicação lê uma variável obrigatória sem valor dedutível → placeholder nos artefatos e item na lista de lacunas do relatório.
- A mesma porta é usada por duas dependências → o agente resolve o conflito e registra a escolha no relatório *(premissa — confirme ou corrija)*
- A imagem de uma dependência indicada pelo repositório não existe mais → o agente escolhe a versão mais próxima disponível e registra a troca *(premissa — confirme ou corrija)*

### US05: Validar em Docker com ciclo de correção

Como desenvolvedor, quero que os artefatos sejam testados de verdade e corrigidos quando falharem, para receber algo que funciona, e não algo que só parece certo.

**Rules:**
- A validação acontece no Docker local, em degraus *(premissa — confirme ou corrija)*
  1. a imagem é construída;
  2. o container fica de pé por um período mínimo sem reiniciar;
  3. se a aplicação expõe porta, ela responde a uma requisição;
  4. o compose sobe e todos os serviços ficam saudáveis.
- Quando um degrau falha, o agente lê o erro, corrige os artefatos e tenta de novo, até passar ou atingir o limite de tentativas e de tempo *(premissa — confirme ou corrija)*
- **O status registrado no relatório vem de uma validação independente**, feita depois que o agente termina, e não do que o agente declara *(premissa — confirme ou corrija)*
- O status final é **validado**, **parcial** (passou em parte dos degraus) ou **falhou**, sempre com o degrau em que parou.
- Todos os containers, volumes e redes criados na validação são removidos ao final, inclusive quando o job falha.
- A validação não ocupa portas da máquina do usuário *(premissa — confirme ou corrija)*

**Edge cases:**
- A aplicação exige um segredo real para subir (chave de API de terceiro) → o status é "não validável sem segredo", distinto de falha do artefato, e o relatório diz qual segredo falta *(premissa — confirme ou corrija)*
- Aplicação sem porta (worker, consumidor de fila) → o critério de sucesso é ficar de pé sem reiniciar *(premissa — confirme ou corrija)*
- Limite de tentativas atingido → o job segue para o relatório e a entrega com status "falhou" e o último erro registrado.
- Docker indisponível na máquina → o job termina em erro de ambiente antes da geração, com instrução na interface *(premissa — confirme ou corrija)*

### US06: Melhorar artefatos Docker existentes

Como desenvolvedor, quero que o agente melhore o Dockerfile e o compose que o projeto já tem, para aproveitar o que existe sem perder o que já funciona.

**Rules:**
- Artefatos existentes são analisados, e as melhorias identificadas são aplicadas. Exemplos: build em estágios, usuário não-root, tag fixa, healthcheck, `.dockerignore`.
- Contratos existentes são preservados: caminhos dos arquivos, nomes de serviço, portas e build args, salvo instrução contrária nas observações *(premissa — confirme ou corrija)*
- **Nunca entregar pior do que havia.** Se a versão melhorada não passar na validação e a original passar, a original é mantida, e o relatório registra a melhoria tentada e por que foi revertida *(premissa — confirme ou corrija)*
- O relatório lista cada mudança feita num artefato existente, com a justificativa. O histórico da branch mostra o diff contra o original.

**Edge cases:**
- O artefato original já não funcionava → a versão melhorada é entregue mesmo que também falhe, e o relatório registra que o original também falhava *(premissa — confirme ou corrija)*
- O compose existente declara dependências → ele é a evidência principal para o mapeamento da US03.
- O repositório tem vários Dockerfiles → o agente melhora o que corresponde à aplicação principal e registra os demais no relatório *(premissa — confirme ou corrija)*

### US07: Aplicar as observações do usuário

Como desenvolvedor, quero que as minhas observações direcionem a geração, para impor regras e fornecer informações que o repositório não revela.

**Rules:**
- As observações têm precedência sobre as escolhas padrão do agente (imagem base, porta, versão de dependência, nomes) *(premissa — confirme ou corrija)*
- As observações não sobrepõem as regras fixas do produto: não commitar segredo real, não usar `:latest`, não entregar pior do que havia *(premissa — confirme ou corrija)*
- O relatório lista cada observação recebida e diz se foi seguida, seguida em parte ou não seguida, com o motivo.

**Edge cases:**
- Observação que conflita com uma regra fixa → não é seguida, e o relatório explica o conflito.
- Observação que quebra a validação (por exemplo, uma imagem base incompatível) → o agente tenta atender; se não conseguir, reverte a escolha e registra *(premissa — confirme ou corrija)*
- Observação ambígua → o agente adota a interpretação mais conservadora e a registra no relatório *(premissa — confirme ou corrija)*

### US08: Relatório de conteinerização na raiz

Como desenvolvedor revisando a branch, quero um relatório em markdown na raiz do projeto, para entender o que foi feito, o que foi comprovado e o que falta eu preencher.

**Rules:**
- O relatório fica na raiz do repositório, com um nome fixo da ferramenta *(premissa — confirme ou corrija)*
- O relatório abre com o **status por etapa** (análise, geração, validação Docker) e é **extensível**: outras etapas, como a de Kubernetes do PRD 002, acrescentam linhas sem mudar as existentes.
- Conteúdo mínimo:
  - stack identificada;
  - dependências, cada uma com a evidência;
  - variáveis de ambiente;
  - decisões tomadas e por quê;
  - observações e se foram seguidas;
  - mudanças em artefatos existentes;
  - **lacunas que o usuário precisa preencher**;
  - resultado da validação;
  - versões das ferramentas usadas;
  - arquitetura de CPU em que a validação rodou *(premissa — confirme ou corrija)*
- O relatório nunca contém o valor de um segredo.

**Edge cases:**
- O repositório já tem um arquivo com o nome do relatório → o arquivo é sobrescrito, porque é o relatório da própria ferramenta, e isso é registrado *(premissa — confirme ou corrija)*
- A validação foi pulada por erro de ambiente → o status mostra "não executada", e não "falhou".

### US09: Entregar no GitHub

Como desenvolvedor, quero o resultado numa branch nova do meu repositório, para revisar com as ferramentas de sempre, sem risco para a branch principal.

**Rules:**
- Cada job cria uma branch nova, com prefixo fixo da ferramenta e identificador único *(premissa — confirme ou corrija)*
- A branch recebe um commit com os artefatos e o relatório, e é enviada ao GitHub com a credencial git da máquina.
- A mensagem de commit reflete o status da validação *(premissa — confirme ou corrija)*
- **O push acontece mesmo quando a validação falha.**
- A branch padrão do repositório nunca é alterada.
- A cópia temporária do repositório é removida ao final, com sucesso ou falha.

**Edge cases:**
- O job falhou antes de existir qualquer artefato (clone, repositório sem aplicação, erro de ambiente) → nada é enviado, e o erro aparece só na interface.
- A credencial local não tem permissão de escrita → o push falha e o relatório é exibido na interface (ver US02).
- Já existe uma branch com o mesmo nome → isso não ocorre, porque o identificador é único; se ocorrer, o job falha sem sobrescrever *(premissa — confirme ou corrija)*

## 4. Fluxo de Negócio

```
URL + observações submetidas
   │
   ▼
URL válida e repositório acessível? ── não ──▶ Erro na interface (nada enviado)
   │ sim
   ▼
Analisa a stack e mapeia as dependências (só com evidência)
   │
   ▼
Aplicação reconhecível? ── não ──▶ Erro na interface (nada enviado)
   │ sim
   ▼
Já existem Dockerfile/compose? ── sim ──▶ Melhora, preservando contratos ──┐
   │ não                                                                  │
   ▼                                                                      │
Gera Dockerfile + compose ◀───────────────────────────────────────────────┘
   │
   ▼
Valida e corrige, até passar ou atingir o limite
   │
   ▼
Validação independente atesta o status
   ├── validado
   ├── parcial / não validável sem segredo
   └── falhou ── a melhoria quebrou um original que funcionava? ── sim ──▶ restaura o original
   │
   ▼
Relatório na raiz com status por etapa
   │
   ▼
Branch nova + commit + push (sempre)
   ├── push ok ────────▶ Link da branch + relatório na interface
   └── push falhou ────▶ Relatório + motivo na interface
```

## 5. Critérios de Aceite

### 5a. Critérios de aceite da feature

| Critério | Razão de negócio | Como verificar (observável) |
|----------|------------------|-----------------------------|
| C01. Uma URL válida submetida cria um job e a interface mostra as etapas avançando | O usuário precisa saber que algo está acontecendo num processo de minutos | Submeter um repositório de exemplo e observar a interface |
| C02. Uma URL malformada ou fora do GitHub é recusada sem criar job | Evitar jobs que falham sempre | Submeter `https://gitlab.com/x/y` e um texto qualquer |
| C03. Num repositório de exemplo com Postgres, o compose gerado inclui o Postgres e a aplicação se conecta a ele | A dependência mapeada precisa funcionar, não só constar no arquivo | Rodar o compose da branch e ver todos os serviços saudáveis |
| C04. Toda dependência listada no relatório aponta a evidência no repositório | Sem evidência não há como o revisor confiar no mapeamento | Conferir no relatório, dependência por dependência |
| C05. Nenhum segredo real presente no repositório aparece em arquivo commitado | Propagar segredo é dano irreversível | Plantar uma chave falsa num repositório de teste e procurá-la na branch |
| C06. Nenhuma imagem nos artefatos usa `:latest` ou fica sem tag | Build reprodutível | Inspecionar o Dockerfile e o compose da branch |
| C07. Um artefato propositalmente quebrado resulta em status "falhou" no relatório, mesmo que o agente declare sucesso | O status precisa refletir a realidade, não a declaração do agente | Cenário de teste com uma dependência impossível de subir |
| C08. Num repositório de exemplo com uma armadilha conhecida (por exemplo, dependência de sistema ausente), o ciclo de correção chega a "validado" *(premissa — confirme ou corrija)* | É o valor central do agente autônomo | Rodar o job no repositório-armadilha |
| C09. Ao atingir o limite, o job termina com relatório e push, com status "falhou" e o último erro | Resultado parcial com diagnóstico é melhor que nada | Forçar um limite baixo num repositório difícil |
| C10. Cada job cria uma branch nova no GitHub, com artefatos e relatório, **inclusive quando a validação falha** | Decisão de produto: o push acontece sempre | Conferir a branch no GitHub nos cenários C07 e C09 |
| C11. A branch padrão do repositório nunca muda | Segurança do repositório do usuário | Comparar o commit da branch padrão antes e depois |
| C12. A observação "usar a porta 8080" aparece nos artefatos e o relatório registra que foi seguida | As observações precisam ter efeito verificável | Job com essa observação num repositório de exemplo |
| C13. Num repositório com Dockerfile funcional, se a melhoria quebrar a validação, a branch entrega o original e o relatório explica | Nunca entregar pior do que havia | Cenário de teste com uma observação que força a quebra |
| C14. Ao fim do job, não sobram containers, volumes, redes nem cópia temporária do repositório, com sucesso ou falha | A máquina do usuário não pode acumular lixo a cada job | Listar os recursos Docker e o diretório temporário depois de jobs com sucesso e com falha |
| C15. Um job num repositório de exemplo pequeno termina em até 10 minutos *(premissa — confirme ou corrija)* | Na aula ao vivo, tempo morto longo quebra a demo | Cronometrar três execuções no repositório de exemplo |

### 5b. Métricas de sucesso

| Métrica | Baseline (fonte) | Meta | Prazo | Mín. aceitável | Responsável |
|---------|-------------------|------|-------|-----------------|-------------|
| Jobs com status "validado" nos repositórios de exemplo da aula | A levantar (ensaio da aula) | ≥ 80% *(premissa — confirme ou corrija)* | Até a aula ao vivo | 60% | Autor do projeto |
| Tempo de job ponta a ponta no repositório de exemplo | A levantar (ensaio da aula) | ≤ 10 min *(premissa — confirme ou corrija)* | Até a aula ao vivo | 15 min | Autor do projeto |
| Lacunas do relatório que o revisor confirma como corretas | A levantar (revisão manual dos ensaios) | ≥ 90% *(premissa — confirme ou corrija)* | Até a aula ao vivo | 75% | Autor do projeto |

## 6. Milestones

### Milestone 1: Gerar artefatos a partir de um repositório

**Por que é um marco:** pela primeira vez, a ferramenta lê um repositório real e entrega Dockerfile, compose com as dependências e um relatório que explica cada escolha. É a demo de "o agente escreveu tudo sozinho".

**Funcionalidades:** US03, US04, US08

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] C04. Toda dependência do relatório aponta a evidência
- [ ] C05. Nenhum segredo real em arquivo commitado
- [ ] C06. Nenhuma imagem com `:latest` ou sem tag

**Aprovador:** Autor do projeto

### Milestone 2: Validar e corrigir em Docker

**Por que é um marco:** os artefatos deixam de "parecer certos" e passam a ser comprovados. O agente vê o build quebrar, corrige e chega ao funcionando. É o momento principal da aula.

**Funcionalidades:** US05

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] C03. O compose com Postgres sobe e a aplicação se conecta
- [ ] C07. O status reflete a validação independente, não a declaração do agente
- [ ] C08. O ciclo de correção resolve o repositório-armadilha
- [ ] C09. O limite atingido gera relatório com status "falhou"
- [ ] C14. Não sobram recursos Docker nem cópia temporária

**Aprovador:** Autor do projeto

### Milestone 3: Entregar no GitHub

**Por que é um marco:** o resultado sai da máquina e chega aonde o desenvolvedor trabalha: uma branch revisável no próprio repositório.

**Funcionalidades:** US09

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] C10. Branch nova com artefatos e relatório, inclusive com a validação falhando
- [ ] C11. A branch padrão não muda

**Aprovador:** Autor do projeto

### Milestone 4: Operar pela interface com observações

**Por que é um marco:** o fluxo inteiro passa a ser usado pela interface web, com acompanhamento em tempo real e direcionamento pelas observações. É o produto como foi pensado.

**Funcionalidades:** US01, US02, US07

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] C01. A submissão cria um job e mostra as etapas
- [ ] C02. URL inválida é recusada sem criar job
- [ ] C12. A observação de porta é aplicada e registrada
- [ ] C15. O job no repositório de exemplo termina em até 10 minutos

**Aprovador:** Autor do projeto

### Milestone 5: Melhorar artefatos existentes

**Por que é um marco:** a ferramenta passa a servir também projetos que já têm Docker, que são a maioria, sem nunca piorar o que funcionava.

**Funcionalidades:** US06

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] C13. A melhoria que quebra a validação é revertida para o original, com explicação

**Aprovador:** Autor do projeto

## 7. Riscos e Dependências

| Risco | Impacto | Mitigação | Status |
|-------|---------|-----------|--------|
| Não determinismo: o mesmo repositório gera resultados diferentes, e a demo ao vivo sai diferente do ensaio | Alto | Ensaiar com os mesmos repositórios de exemplo e ter um resultado de ensaio gravado como plano B | Pendente |
| Tempo morto na aula: o job leva minutos | Médio | Progresso em tempo real (US02); repositórios de exemplo pequenos; imagens base baixadas antes | Pendente |
| O agente inventa dependência ou variável | Alto | Regra de evidência obrigatória (US03) e validação real (US05) | Pendente |
| A validação na arquitetura local (arm64) não garante produção (amd64) | Médio | O relatório registra a arquitetura da validação (US08) | Pendente |
| O agente executa comandos na máquina do usuário, sem isolamento | Médio | Risco aceito no MVP: repositórios escolhidos pelo próprio usuário | Monitorando |
| Aplicações que exigem segredo real não validam | Médio | Status "não validável sem segredo" (US05) e lacuna no relatório | Pendente |
| Conteúdo de repositório privado enviado a um provedor de LLM externo | Médio | Aviso na submissão (US01) | Pendente |

**Dependências:**

| Dependência | Tipo | Status | Impacto se bloqueado |
|-------------|------|--------|----------------------|
| Credencial git local com permissão de escrita no repositório | Externa | Configurada pelo usuário | Milestone 3 |
| Docker instalado e em execução na máquina | Externa | Pré-requisito | Milestones 2, 4 e 5 |
| Acesso ao provedor de LLM | Externa | A definir no TRD | Todos |
| TRD e ADRs com stack e arquitetura | Interna | A criar | Todos (contexto de implementação) |
| Repositórios de exemplo para a aula (com Postgres, com armadilha, com Dockerfile existente) | Interna | A preparar | Validação dos critérios C03, C08 e C13 |

## 8. Referências

- `docs/trd.md` (a criar via `escrever-trd`): stack e arquitetura do projeto
- `docs/adrs/` (a criar via `escrever-trd` Modo Decision): decisões técnicas do brainstorm que viram ADR:
  - camada de agente com LangChain `create_agent`;
  - ferramentas de arquivo e bash via `deepagents` (só as ferramentas);
  - modelo `claude-sonnet-5`;
  - orquestrador determinístico responsável por clone, commit, push e atestado da validação;
  - credencial git do host
- `docs/prds/002-extensao-kubernetes.md`: extensão para Kubernetes, que depende deste PRD

## 9. Registro de Decisões

- **2026-09-14:** Serviço web local, de um usuário só, usando a credencial git da máquina. Motivo: MVP, sem login nem gestão de tokens.
- **2026-09-14:** Entrega por push de branch nova, sem PR. Motivo: a revisão humana acontece na branch; PR fica para depois.
- **2026-09-14:** Push mesmo com a validação falhando, com a falha registrada no relatório. Motivo: o resultado parcial com diagnóstico tem valor, e perder o trabalho não tem.
- **2026-09-14:** Validação real com Docker local. Motivo: sem validação, o agente autônomo não entrega mais que um gerador de templates.
- **2026-09-14:** O agente mapeia as dependências e as inclui nos artefatos, e esse mapeamento é a fonte única para todos os artefatos. Motivo: evitar que o compose e os manifestos divirjam.
- **2026-09-14:** Campo de observações na interface para direcionar a geração. Motivo: o usuário tem informação que o repositório não revela.
- **2026-09-14:** Artefatos existentes são analisados e melhorados. Motivo: aproveitar o conhecimento do projeto sem descartar o que funciona.
- **2026-09-14:** Defesa contra prompt injection fora do escopo. Motivo: decisão explícita do MVP.
- **2026-09-14:** Divisão em dois PRDs por tecnologia (Docker e Kubernetes). Motivo: construir numa aula ao vivo, com este PRD fechando sozinho uma demo completa e o 002 como extensão cortável.
- **2026-09-14:** O status do relatório é por etapa e extensível desde este PRD. Motivo: o PRD 002 acrescenta a etapa de Kubernetes sem alterar as regras daqui.
