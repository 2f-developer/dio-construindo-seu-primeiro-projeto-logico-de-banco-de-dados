#!/usr/bin/env bash
# Cria o banco do zero, carrega os dados, roda as consultas e as verificações.
# Os argumentos vão direto para o cliente mysql. Exemplo: ./testar.sh -h 127.0.0.1 -u root -p
set -euo pipefail
cd "$(dirname "$0")"
for arquivo in sql/01_schema.sql sql/02_dados.sql sql/03_consultas.sql tests/verificacoes.sql; do
  echo "== $arquivo"
  if ! saida=$(mysql --default-character-set=utf8mb4 "$@" < "$arquivo" 2>&1); then
    echo "$saida"
    exit 1
  fi
  grep -E '^ok|passaram' <<< "$saida" || true
done
