# Guidelines de módulo

Um módulo bem desenhado é o que torna possível reaproveitá-lo em outro projeto sem reescrever nada — esse é o objetivo por trás de cada regra abaixo, não a regra em si.

## Nunca usar módulos de comunidade

Todo módulo consumido por um `environments/<ambiente>/main.tf` vem de `modules/` dentro do próprio projeto — nunca do Terraform Registry público ou de um repositório de terceiros. Se um módulo de comunidade resolveria bem o problema, tudo bem usá-lo como referência de desenho, mas a implementação final é própria. Isso mantém o time no controle total do que está em produção, sem depender de manutenção, versionamento ou mudanças de comportamento de alguém de fora.

## Responsabilidade única

Um módulo deve provisionar uma coisa coesa (ex: "rede", "cluster de banco", "fila de mensagens"), não "toda a infraestrutura do ambiente X". Se um módulo está crescendo para cobrir responsabilidades muito diferentes entre si, é sinal de que deveria virar dois módulos.

## Contrato explícito (inputs/outputs)

- Toda variável de entrada tem `type` e `description`. Variáveis obrigatórias (sem as quais o módulo não faz sentido) não têm `default`; variáveis genuinamente opcionais podem ter um default sensato.
- `outputs.tf` expõe só o que quem consome o módulo realmente precisa — não exponha atributos internos "por via das dúvidas".
- Nada hardcoded dentro do módulo: nomes, regiões, CIDRs, contagens, tamanhos — tudo isso é variável. Um módulo com valor fixo só funciona no contexto onde foi escrito pela primeira vez, o que anula o ganho de reuso.

## `versions.tf` do módulo

Cada módulo declara seu próprio `required_providers`, com a mesma versão travada usada nos ambientes que o consomem (evita o módulo silenciosamente exigir uma versão diferente da que o root module usa).

## `README.md` do módulo

Todo módulo tem um README curto com:
1. Propósito (uma ou duas frases: o que ele provisiona e por quê)
2. Tabela de inputs (nome, tipo, descrição, se é obrigatório)
3. Tabela de outputs (nome, descrição)
4. Um exemplo mínimo de uso (`module "..." { source = "../../modules/<nome>" ... }`)

Isso é o que permite a alguém decidir se um módulo serve para outro projeto sem precisar ler o `main.tf` inteiro.

## Tags

Módulos que criam recursos taggable devem aceitar uma variável `tags` (mapa, opcional, default `{}`) e mesclá-la com as tags padrão do projeto antes de aplicar aos recursos — ver `naming-e-tagging.md`.
