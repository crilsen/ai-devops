#!/usr/bin/env bash
set -euo pipefail

# Cria o esqueleto de um módulo novo dentro de modules/ (skill terraform-boas-praticas).
#
# Uso: novo-modulo.sh <diretorio-raiz-do-projeto> <nome-do-modulo>

ROOT="${1:?uso: novo-modulo.sh <diretorio-raiz-do-projeto> <nome-do-modulo>}"
NAME="${2:?uso: novo-modulo.sh <diretorio-raiz-do-projeto> <nome-do-modulo>}"

DIR="$ROOT/modules/$NAME"
mkdir -p "$DIR"

cat > "$DIR/main.tf" <<EOF
# Recursos do módulo "$NAME".
EOF

: > "$DIR/variables.tf"
: > "$DIR/outputs.tf"

cat > "$DIR/versions.tf" <<'EOF'
terraform {
  required_providers {
    # TODO: mesmo provider e mesma versão travada usada nos environments/ que vão consumir este módulo
  }
}
EOF

cat > "$DIR/README.md" <<EOF
# Módulo \`$NAME\`

## Propósito

TODO: descrever o que este módulo provisiona e por quê.

## Inputs

| Nome | Tipo | Descrição | Obrigatório |
|---|---|---|---|
| | | | |

## Outputs

| Nome | Descrição |
|---|---|
| | |

## Exemplo de uso

\`\`\`hcl
module "$NAME" {
  source = "../../modules/$NAME"

  # ...
}
\`\`\`
EOF

echo "Módulo '$NAME' criado em $DIR"
