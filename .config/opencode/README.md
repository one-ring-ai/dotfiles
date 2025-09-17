# OpenCode

Un progetto per la gestione di agenti AI e configurazioni di sviluppo.

## Installazione

### Prerequisiti
- Git installato sul sistema
- Accesso a terminale/bash

### Setup iniziale

1. Naviga nella directory di configurazione:
```bash
cd ~/.config
```

2. Clona il repository:
```bash
git clone https://github.com/one-ring-ai/opencode
```

3. Entra nella directory del progetto:
```bash
cd opencode
```

4. Esegui lo script di setup per configurare i token necessari:
```bash
chmod +x setup.sh
./setup.sh
```

## Struttura del Progetto

```
opencode/
├── agent/                 # Definizioni degli agenti AI
├── plugin/               # Plugin e estensioni
├── config.json          # Configurazione principale
└── setup.sh            # Script di setup automatico
```

## Configurazione

Dopo aver eseguito lo script di setup, verrà creata automaticamente la cartella `.secrets` con i seguenti file di configurazione:

- `figma-token` - Token per l'integrazione con Figma
- `groq-key` - Chiave API per Groq
- `openai-key` - Chiave API per OpenAI
- `openrouter-key` - Chiave API per OpenRouter

## Utilizzo

Una volta completata la configurazione, il progetto è pronto per l'uso. Consulta la documentazione specifica per ogni agente nella cartella `agent/`.

## Supporto

Per problemi o domande, apri una issue su GitHub o contatta il team di sviluppo.
