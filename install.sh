#!/bin/zsh
# Instalador do asaas-deck — painel local do backend Asaas.
set -e

DEST="$HOME/.local/bin"
SRC="$(cd "$(dirname "$0")" && pwd)/asaas-deck"

if [[ ! -f "$SRC" ]]; then
	echo "Erro: asaas-deck não encontrado ao lado deste instalador." >&2
	exit 1
fi

if ! command -v python3 > /dev/null; then
	echo "Erro: python3 não encontrado. Instale com: brew install python3" >&2
	exit 1
fi

mkdir -p "$DEST"
install -m 755 "$SRC" "$DEST/asaas-deck"
echo "✅ Instalado em $DEST/asaas-deck"

if ! print -r -- "$PATH" | grep -q "$DEST"; then
	RC="$HOME/.zshrc"
	if ! grep -q 'HOME/.local/bin' "$RC" 2>/dev/null; then
		printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$RC"
		echo "✅ ~/.local/bin adicionado ao PATH em $RC"
	fi
	echo "ℹ️  Abra um terminal novo (ou rode: source $RC) para o comando ficar disponível."
fi

echo ""
echo "Para usar:  asaas-deck     depois abra http://localhost:7070"
