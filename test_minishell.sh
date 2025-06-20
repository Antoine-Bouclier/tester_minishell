#!/bin/bash

# Se place dans le dossier parent de celui où se trouve le script
cd "$(dirname "$0")/.."

# Gestion des arguments
TEST_FILE="tester/commands.txt"
SHOW_ALL=true

for arg in "$@"; do
    if [[ "$arg" == "--fail-only" ]]; then
        SHOW_ALL=false
    else
        TEST_FILE="tester/$arg"
    fi
done

# Définition des couleurs ANSI
YELLOW='\033[33m'
BLUE='\033[36m'
RESET='\033[0m'

MINISHELL=./minishell
MINI_OUTPUT_DIR=tester/outputs/minishell
BASH_OUTPUT_DIR=tester/outputs/bash

mkdir -p "$MINI_OUTPUT_DIR" "$BASH_OUTPUT_DIR"

echo "===== Lancement des tests ====="

passed=0
i=1

while IFS= read -r line || [ -n "$line" ]; do

    # --- MINISHELL ---
    output_minishell=$(echo "$line" | $MINISHELL 2>&1 | sed '/^minishell =>/d' | sed '/^$/d')
    
    # Si la ligne contient un echo -n, on enlève le minishell => à la fin
    if [[ "$line" == *"echo -n"* ]]; then
        output_minishell=$(echo "$output_minishell" | sed 's/minishell => *//g')
    fi

    echo "$output_minishell" > "$MINI_OUTPUT_DIR/out_$i.txt"
    mini_status=$?

    # --- BASH ---
    output_bash=$(echo "$line" | bash --posix 2>&1 | sed 's/^bash: line 1: //')
    echo "$output_bash" > "$BASH_OUTPUT_DIR/out_$i.txt"
    bash_status=$?

    # Comparaison des résultats
    output_diff=false
    code_diff=false

    if ! diff -q "$MINI_OUTPUT_DIR/out_$i.txt" "$BASH_OUTPUT_DIR/out_$i.txt" > /dev/null; then
        output_diff=true
    fi

    if [ $mini_status -ne $bash_status ]; then
        code_diff=true
    fi

    # Affichage des résultats des tests
    if [ "$output_diff" = false ] && [ "$code_diff" = false ]; then
        ((passed++))
        if [ "$SHOW_ALL" = true ]; then
            printf "${YELLOW}Test %3d:${RESET} ✅ ${BLUE}%s${RESET} [code: %d]\n" "$i" "$line" "$mini_status"
        fi
    else
        printf "${YELLOW}Test %3d:${RESET} ❌ ${BLUE}%s${RESET}\n" "$i" "$line"
        echo "Code minishell: $mini_status | Code bash: $bash_status"
        echo "--- Sortie minishell:"
        cat "$MINI_OUTPUT_DIR/out_$i.txt"
        echo "--- Sortie bash:"
        cat "$BASH_OUTPUT_DIR/out_$i.txt"
    fi

    ((i++))
done < "$TEST_FILE"

total=$((i - 1))
echo -e "\nTests validés : $passed / $total"
