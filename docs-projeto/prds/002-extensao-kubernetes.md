---
prd_number: "002"
status: rascunho
priority: média
created: 2026-09-14
issue: ""
depends_on: ["001"]
references:
  - "docs/prds/001-conteinerizacao-docker.md"
  - "docs/trd.md (a criar via escrever-trd)"
  - "docs/adrs/ (a criar via escrever-trd Modo Decision)"
  - "https://kind.sigs.k8s.io/docs/user/quick-start"
  - "https://github.com/kubernetes-sigs/kind/issues/2371"
---

# PRD 002: Extensão para Kubernetes

## 1. Contexto

- **Produto/área**: docker-maker, o serviço web local que conteineriza repositórios do GitHub (PRD 001).
- **Estado atual**: com o PRD 001, o usuário recebe Dockerfile e compose validados, o relatório e uma branch no GitHub. Não recebe nada para rodar a aplicação em Kubernetes.
- **Problema**: levar a aplicação para Kubernetes exige escrever manifestos da aplicação e das dependências, e só se descobre se estão certos aplicando num cluster. Manifestos que nunca subiram num cluster têm o mesmo problema dos artefatos sem validação: parecem prontos e não estão.

> **Contexto técnico** vive no TRD (`docs/trd.md`) e nos ADRs, ainda a criar. Veja o §8.

## 2. Solução Proposta

### Visão de produto

- O mesmo job do PRD 001 passa a gerar também **manifestos Kubernetes**: os da aplicação e os das dependências, separados.
- Os manifestos usam **o mesmo mapeamento de dependências** do PRD 001, então o que sobe no compose é o que sobe no cluster.
- Os manifestos são **validados num cluster local (kind)** com a imagem já validada em Docker: aplicar, subir, ficar pronto e responder.
- O relatório e a interface ganham a etapa de Kubernetes. O que já existe no PRD 001 não muda.

### Decisões de produto

1. **A validação é real, com kind e kubectl locais.** O kind já está instalado na máquina do usuário. Motivo: manifestos não aplicados não dão garantia nenhuma.
2. **As dependências entram nos manifestos.** Motivo: a aplicação não sobe no cluster sem o banco que exige, e a validação precisa da aplicação completa.
3. **Os manifestos das dependências ficam separados dos da aplicação** e são marcados como de desenvolvimento. Motivo: quem for usar serviço gerenciado em produção descarta as dependências sem mexer na aplicação *(premissa — confirme ou corrija)*
4. **Os manifestos existentes são analisados e melhorados**, com a mesma regra de nunca entregar pior do que havia do PRD 001.

### Fora do escopo

- Gerar ou converter para Helm e Kustomize. Motivo: o MVP gera YAML puro *(premissa — confirme ou corrija)*
- Aplicar em cluster remoto ou de produção. Motivo: a validação é local e descartável.
- Publicar a imagem em registry. Motivo: a imagem é carregada direto no cluster local; o relatório orienta a troca pelo registry real *(premissa — confirme ou corrija)*
- Deixar as dependências prontas para produção (backup, alta disponibilidade). Motivo: os manifestos das dependências servem para desenvolvimento e validação.
- Ingress, TLS e exposição externa. Motivo: a validação usa acesso interno ao cluster *(premissa — confirme ou corrija)*

## 3. Funcionalidades

### US01: Gerar manifestos da aplicação

Como desenvolvedor, quero receber os manifestos Kubernetes da minha aplicação, para rodá-la num cluster sem escrevê-los à mão.

**Rules:**
- Os manifestos cobrem o necessário para a aplicação rodar e ser acessada dentro do cluster: workload, exposição interna e configuração *(premissa — confirme ou corrija)*
- Formato YAML puro *(premissa — confirme ou corrija)*
- **As dependências e variáveis vêm do mapeamento do PRD 001 (US03)**. Não há remapeamento. O que existe no compose existe no cluster, e vice-versa.
- A imagem é referenciada com tag fixa e com uma política de download que usa a imagem já carregada no cluster local. Nunca `:latest`.
- **O que é commitado é exatamente o que foi validado.** O relatório orienta a trocar a referência da imagem pelo registry real *(premissa — confirme ou corrija)*
- Segredos seguem as regras do PRD 001: segredo real vira placeholder, credencial de dev é fictícia e sinalizada.

**Edge cases:**
- A imagem não foi validada em Docker (build falhou no PRD 001) → os manifestos são gerados mesmo assim, e a etapa de Kubernetes fica como "não executada: imagem não validada" *(premissa — confirme ou corrija)*
- Aplicação sem porta (worker) → sem exposição interna; o critério de validação é o pod ficar pronto e estável *(premissa — confirme ou corrija)*
- Variável obrigatória sem valor dedutível → placeholder na configuração e item nas lacunas do relatório.

### US02: Gerar manifestos das dependências

Como desenvolvedor, quero manifestos para as dependências da aplicação, para que ela suba completa no cluster e para que eu possa descartá-los ao usar serviços gerenciados.

**Rules:**
- Cada dependência conteinerizável do mapeamento do PRD 001 ganha seus manifestos, incluindo armazenamento persistente quando é stateful.
- Os manifestos das dependências ficam num local separado dos da aplicação e são identificados como de desenvolvimento *(premissa — confirme ou corrija)*
- O armazenamento persistente usa o modo de acesso exclusivo (ReadWriteOnce), o único suportado pelo storage padrão do cluster local.
- A aplicação encontra as dependências pelos mesmos nomes e variáveis usados no compose.

**Edge cases:**
- Uma dependência exige acesso compartilhado (ReadWriteMany) → o modo não é suportado no cluster local; a dependência é gerada com acesso exclusivo e o relatório registra a limitação *(premissa — confirme ou corrija)*
- Dependência SaaS (sem container) → não gera manifesto; vira placeholder na configuração da aplicação, como no PRD 001.
- A aplicação sobe antes da dependência ficar pronta → a aplicação precisa voltar sozinha quando a dependência fica disponível, e isso é verificado na validação *(premissa — confirme ou corrija)*

### US03: Validar no cluster local

Como desenvolvedor, quero que os manifestos sejam aplicados e testados num cluster Kubernetes local, para ter certeza de que funcionam antes de levá-los adiante.

**Rules:**
- A validação usa o kind, que já está instalado na máquina, e a imagem validada em Docker no PRD 001, carregada direto no cluster local.
- Critérios em degraus *(premissa — confirme ou corrija)*
  1. os manifestos são aceitos pelo cluster;
  2. o rollout conclui;
  3. todos os pods ficam prontos;
  4. se há porta, a aplicação responde a uma requisição feita de dentro do cluster ou por encaminhamento local.
- Quando um degrau falha, o agente corrige os manifestos e tenta de novo, dentro dos limites do job. O status final vem da validação independente, como no PRD 001.
- **Ciclo de vida do cluster:** um cluster efêmero criado e destruído a cada job, ou um cluster reutilizado com um namespace isolado por job *(premissa — confirme ou corrija: o cluster efêmero isola melhor; o reutilizado é mais rápido e favorece a aula ao vivo)*
- Tudo o que o job cria no cluster (ou o próprio cluster, se for efêmero) é removido ao final, inclusive quando o job falha.

**Edge cases:**
- Docker validado e Kubernetes falhou → o status é "parcial", com a etapa de Kubernetes marcada como falha; o push acontece normalmente (regra do PRD 001).
- O cluster local não pôde ser criado ou acessado → a etapa fica "não executada: erro de ambiente", distinta de falha dos manifestos *(premissa — confirme ou corrija)*
- A aplicação exige segredo real para subir → "não validável sem segredo", como no PRD 001.
- A imagem de uma dependência não pôde ser baixada → falha da etapa, com a dependência apontada no relatório.

### US04: Melhorar manifestos existentes

Como desenvolvedor, quero que o agente melhore os manifestos Kubernetes que o projeto já tem, para aproveitar o que existe sem perder o que já funciona.

**Rules:**
- Manifestos em YAML puro são analisados e melhorados. Exemplos: probes de saúde, limites de recursos, usuário não-root, tag fixa *(premissa — confirme ou corrija)*
- Aplica a regra do PRD 001: preservar contratos (nomes, portas, namespaces) e **nunca entregar pior do que havia**.
- Charts Helm e configurações Kustomize existentes ficam intocados e são citados no relatório *(premissa — confirme ou corrija)*
- O relatório lista cada mudança num manifesto existente, com a justificativa.

**Edge cases:**
- O repositório tem Helm ou Kustomize e nenhum YAML puro → nenhum manifesto da aplicação é gerado para não duplicar, e o relatório explica *(premissa — confirme ou corrija)*
- Os manifestos existentes referenciam uma imagem de registry privado → a referência é mantida no arquivo, e para validar usa-se a imagem construída localmente; o relatório registra a diferença *(premissa — confirme ou corrija)*
- O manifesto original já não funcionava → a versão melhorada é entregue mesmo que também falhe, e isso é registrado.

### US05: Relatório e progresso estendidos

Como desenvolvedor, quero ver a etapa de Kubernetes na interface e no relatório, para saber o que foi comprovado no cluster sem perder o que o PRD 001 já mostra.

**Rules:**
- A interface mostra as etapas de Kubernetes (geração dos manifestos e validação no cluster) junto das etapas do PRD 001.
- O status por etapa do relatório ganha a linha de Kubernetes. As seções do PRD 001 não mudam.
- O relatório acrescenta:
  - a lista de manifestos gerados, separando aplicação e dependências;
  - o resultado de cada degrau da validação;
  - as versões do kind e do Kubernetes usadas;
  - a orientação para trocar a referência de imagem pelo registry real;
  - o aviso de que as dependências são de desenvolvimento.

**Edge cases:**
- A etapa de Kubernetes não foi executada (imagem não validada ou erro de ambiente) → a linha aparece com o motivo, nunca omitida.
- As observações do usuário mencionam Kubernetes (por exemplo, "usar namespace X") → são aplicadas e rastreadas como no PRD 001 (US07).

## 4. Fluxo de Negócio

```
Etapa Docker concluída (PRD 001)
   │
   ▼
Gera manifestos da aplicação + das dependências (mesmo mapeamento)
   │
   ▼
Imagem validada em Docker? ── não ──▶ Kubernetes "não executado: imagem não validada"
   │ sim
   ▼
Cluster local disponível? ── não ──▶ Kubernetes "não executado: erro de ambiente"
   │ sim
   ▼
Carrega a imagem → aplica → rollout → pods prontos → responde
   │ (falhou: corrige e tenta de novo, até o limite)
   ▼
Validação independente atesta a etapa de Kubernetes
   ├── validado
   ├── parcial / não validável sem segredo
   └── falhou
   │
   ▼
Limpa o cluster/namespace → relatório estendido → entrega do PRD 001 (push sempre)
```

## 5. Critérios de Aceite

### 5a. Critérios de aceite da feature

| Critério | Razão de negócio | Como verificar (observável) |
|----------|------------------|-----------------------------|
| K01. Num repositório de exemplo com Postgres, a branch traz os manifestos da aplicação e os das dependências em locais separados, e os das dependências estão marcados como dev | Permitir descartar as dependências ao usar serviço gerenciado | Inspecionar a branch |
| K02. O conjunto de dependências nos manifestos é idêntico ao do compose | Evitar divergência entre ambientes | Comparar os serviços do compose com os workloads de dependência |
| K03. Nenhum manifesto usa `:latest`, e o que foi commitado é o que foi aplicado na validação | O commitado precisa ser o comprovado | Comparar os manifestos da branch com o que o relatório diz ter aplicado |
| K04. No cluster local, o rollout conclui, os pods ficam prontos e a aplicação responde | É a prova de que os manifestos funcionam | Relatório com os degraus aprovados; reaplicar manualmente os manifestos da branch num kind e observar |
| K05. Com Docker validado e Kubernetes falhando, o status é "parcial" e o push acontece | Regra de entrega do PRD 001 | Cenário com um manifesto impossível de subir |
| K06. Um repositório com chart Helm tem o chart intocado, e o relatório o cita | Não destruir a forma de deploy existente | Diff da branch contra o original |
| K07. Ao fim do job, não sobra cluster (se efêmero) nem namespace e recursos do job (se reutilizado), com sucesso ou falha | A máquina do usuário não pode acumular lixo | Listar clusters kind e namespaces depois de jobs com sucesso e com falha |
| K08. As etapas de Kubernetes aparecem no progresso da interface | O usuário acompanha o processo inteiro | Observar a interface durante um job |
| K09. As seções do relatório definidas no PRD 001 continuam iguais com a extensão ativa | A extensão não pode quebrar o que existe | Comparar a estrutura do relatório antes e depois do PRD 002 |
| K10. A etapa de Kubernetes acrescenta no máximo 5 minutos ao job no repositório de exemplo *(premissa — confirme ou corrija)* | Tempo morto na aula ao vivo | Cronometrar três execuções |

### 5b. Métricas de sucesso

| Métrica | Baseline (fonte) | Meta | Prazo | Mín. aceitável | Responsável |
|---------|-------------------|------|-------|-----------------|-------------|
| Jobs com a etapa de Kubernetes "validada", entre os que passaram em Docker, nos repositórios de exemplo | A levantar (ensaio da aula) | ≥ 80% *(premissa — confirme ou corrija)* | Até a aula ao vivo | 60% | Autor do projeto |
| Tempo acrescentado pela etapa de Kubernetes | A levantar (ensaio da aula) | ≤ 5 min *(premissa — confirme ou corrija)* | Até a aula ao vivo | 8 min | Autor do projeto |

## 6. Milestones

### Milestone 1: Gerar manifestos Kubernetes

**Por que é um marco:** a aplicação conteinerizada ganha manifestos completos para Kubernetes, com as dependências, coerentes com o compose.

**Funcionalidades:** US01, US02

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] K01. Manifestos da aplicação e das dependências separados, e os das dependências marcados como dev
- [ ] K02. As mesmas dependências do compose
- [ ] K03. Sem `:latest`, e o commitado é o validado

**Aprovador:** Autor do projeto

### Milestone 2: Validar no cluster local

**Por que é um marco:** os manifestos são comprovados num cluster real. É a demo de "subiu no Kubernetes".

**Funcionalidades:** US03, US05

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] K04. Rollout concluído, pods prontos e aplicação respondendo
- [ ] K05. Falha só no Kubernetes gera status "parcial" e push
- [ ] K07. Não sobram recursos no cluster
- [ ] K08. Etapas de Kubernetes aparecem na interface
- [ ] K09. Relatório do PRD 001 inalterado
- [ ] K10. A etapa acrescenta no máximo 5 minutos

**Aprovador:** Autor do projeto

### Milestone 3: Melhorar manifestos existentes

**Por que é um marco:** projetos que já têm manifestos passam a ser atendidos sem que nada que funcionava piore, e sem mexer em Helm ou Kustomize.

**Funcionalidades:** US04

**Checklist de aceite** (marcado pelo Aprovador após a implementação):
- [ ] K06. Chart Helm intocado e citado no relatório

**Aprovador:** Autor do projeto

## 7. Riscos e Dependências

| Risco | Impacto | Mitigação | Status |
|-------|---------|-----------|--------|
| Criar o cluster e baixar imagens deixa a aula lenta | Alto | Decidir o ciclo de vida do cluster (US03); baixar antes a imagem do nó e as imagens de dependência | Pendente |
| Imagem carregada localmente ignorada pelo cluster, que tenta baixar do registry e falha | Alto | Tag fixa e política que usa a imagem local (US01) | Mitigado no requisito |
| Os manifestos das dependências são usados em produção como se estivessem prontos | Médio | Separação e marcação como dev (US02), com aviso no relatório (US05) | Pendente |
| Divergência entre compose e manifestos | Médio | Fonte única de dependências no PRD 001 (US03) | Mitigado no requisito |
| A aplicação falha no cluster por ordem de subida das dependências | Médio | Exigir recuperação automática quando a dependência fica disponível (US02) | Pendente |

**Dependências:**

| Dependência | Tipo | Status | Impacto se bloqueado |
|-------------|------|--------|----------------------|
| PRD 001: mapeamento de dependências, imagem validada, relatório extensível, entrega e interface | Interna | Rascunho | Todos os milestones |
| kind e kubectl instalados na máquina | Externa | kind instalado (confirmado); kubectl a confirmar | Milestone 2 |
| Decisão sobre o ciclo de vida do cluster (efêmero ou reutilizado) | Interna | Em aberto | Milestone 2 |

## 8. Referências

- [PRD 001: Conteinerização com Docker](001-conteinerizacao-docker.md): base de que este PRD depende
- `docs/trd.md` e `docs/adrs/` (a criar via `escrever-trd`): stack, agente e orquestração
- [kind: Quick Start, carregar imagem local e pull policy](https://kind.sigs.k8s.io/docs/user/quick-start): embasa a regra de tag fixa e da imagem local (consultado em 2026-09-14)
- [kind issue #2371: RWX não suportado](https://github.com/kubernetes-sigs/kind/issues/2371): embasa a limitação de storage da US02 (consultado em 2026-09-14)

## 9. Registro de Decisões

- **2026-09-14:** A validação de Kubernetes usa kind e kubectl locais; o kind já está instalado. Motivo: comprovar os manifestos num cluster real.
- **2026-09-14:** As dependências entram nos manifestos. Motivo: a aplicação só sobe completa no cluster.
- **2026-09-14:** Dependência de PRD: `depends_on: ["001"]`. Critério: este PRD pressupõe o mapeamento de dependências (001/US03), a imagem validada em Docker (001/US05), o relatório com status por etapa extensível (001/US08), a entrega no GitHub (001/US09) e a interface de progresso (001/US02).
- **2026-09-14:** Os manifestos consomem o mapeamento de dependências do PRD 001, sem remapear. Motivo: garantir coerência entre compose e cluster.
- **2026-09-14:** O ciclo de vida do cluster fica em aberto (efêmero ou reutilizado com namespace). Motivo: a tensão entre isolamento e velocidade na aula ao vivo; destrava com a decisão do usuário.
