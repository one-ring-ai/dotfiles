#!/bin/bash

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi colorati
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENZIONE]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRORE]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  SETUP OPENCODE - CONFIGURAZIONE${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funzione per creare la directory .secrets
create_secrets_dir() {
    if [ ! -d ".secrets" ]; then
        print_message "Creazione directory .secrets..."
        mkdir -p .secrets
        print_message "Directory .secrets creata con successo!"
    else
        print_message "Directory .secrets già esistente."
    fi
}

# Funzione per richiedere input utente
get_user_input() {
    local prompt="$1"
    local default_value="$2"
    local input
    
    if [ -n "$default_value" ]; then
        echo -n "$prompt [$default_value]: " >&2
    else
        echo -n "$prompt: " >&2
    fi
    
    read -s input
    echo >&2
    
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        echo "$default_value"
    else
        echo "$input"
    fi
}

# Funzione per creare file token
create_token_file() {
    local filename="$1"
    local description="$2"
    local token
    
    echo ""
    print_message "Configurazione $description"
    print_warning "Inserisci il tuo token per $description"
    print_warning "Premi INVIO per saltare questo token (potrai configurarlo successivamente)"
    
    token=$(get_user_input "Token $description")
    
    if [ -n "$token" ]; then
        echo -n "$token" > ".secrets/$filename"
        chmod 600 ".secrets/$filename"
        print_message "$description configurato con successo!"
    else
        print_warning "$description saltato."
        touch ".secrets/$filename"
        chmod 600 ".secrets/$filename"
    fi
}

# Funzione per creare .gitignore se non esiste
create_gitignore() {
    if [ ! -f ".gitignore" ]; then
        print_message "Creazione file .gitignore..."
        cat > .gitignore << EOF
# Directory secrets
.secrets/

# File di configurazione sensibili
*.env
.env.local
.env.production

# Log files
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
EOF
        print_message "File .gitignore creato con successo!"
    else
        print_message "File .gitignore già esistente."
    fi
}

# Funzione per verificare la configurazione
verify_setup() {
    echo ""
    print_message "Verifica configurazione..."
    
    if [ -d ".secrets" ]; then
        print_message "✓ Directory .secrets creata"
    else
        print_error "✗ Directory .secrets non trovata"
        return 1
    fi
    
    local files=("figma-token" "groq-key" "openai-key" "openrouter-key")
    local descriptions=("Figma Token" "Groq API Key" "OpenAI API Key" "OpenRouter API Key")
    
    for i in "${!files[@]}"; do
        if [ -f ".secrets/${files[$i]}" ]; then
            local size=$(wc -c < ".secrets/${files[$i]}")
            if [ "$size" -gt 0 ]; then
                print_message "✓ ${descriptions[$i]} configurato"
            else
                print_warning "⚠ ${descriptions[$i]} presente ma vuoto"
            fi
        else
            print_error "✗ ${descriptions[$i]} non trovato"
        fi
    done
}

# Funzione principale
main() {
    print_header
    
    print_message "Benvenuto nel setup di OpenCode!"
    print_message "Questo script ti guiderà nella configurazione dei token necessari."
    echo ""
    
    if [ ! -f "config.json" ]; then
        print_error "Errore: config.json non trovato. Assicurati di essere nella directory corretta del progetto."
        exit 1
    fi
    
    create_secrets_dir
    create_gitignore
    
    print_message "Iniziamo la configurazione dei token..."
    
    create_token_file "figma-token" "Figma API Token"
    create_token_file "groq-key" "Groq API Key"
    create_token_file "openai-key" "OpenAI API Key"
    create_token_file "openrouter-key" "OpenRouter API Key"
    
    verify_setup
    
    echo ""
    print_message "Setup completato con successo!"
    print_message "I tuoi token sono stati salvati nella directory .secrets/"
    print_warning "Ricorda: la directory .secrets è già inclusa in .gitignore per sicurezza"
    echo ""
    print_message "Ora puoi utilizzare OpenCode!"
}

# Esegui la funzione principale
main "$@"
