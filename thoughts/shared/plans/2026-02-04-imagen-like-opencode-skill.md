# Plan: skill OpenCode per generazione immagini (Replicate flux-2-max)

## Contesto e obiettivi

- Creare una skill OpenCode in `.config/opencode/skills/<name>/` che generi
  immagini via Replicate `black-forest-labs/flux-2-max` (input=python) con
  parametri fissi: `resolution=4MP`, `output_format=webp`,
  `output_quality=100`, `safety_tolerance=5`.
- Variabili controllate dall’agente: `prompt`, `aspect_ratio`; output salvato
  localmente (webp) in percorso scelto o di default.
- Runtime: Python, cross-platform. Aderenza a regole OpenCode skills (frontmatter
  `SKILL.md` con `name`/`description`, naming lower-kebab, descrizione ≤1024
  char, dir = name).

## Sintesi skill di riferimento (imagen) letta integralmente

- Contenuti: `README.md`, `SKILL.md`, `examples.md`, `reference.md`,
  `.env.example`, `.gitignore`, `scripts/generate_image.py` (Python stdlib, Google
  Gemini), doc con prompt tips/troubleshooting.
- Funzioni chiave: CLI con prompt/output/size/model, env obbligatoria per API key,
  request JSON, parsing inlineData, salvataggio PNG, messaggi di errore curati.

## Requisiti confermati (utente)

1. Runtime: Python.
2. Percorso skill: `.config/opencode/skills/<name>/` come da docs ufficiali.
3. Comando: `python scripts/generate_image.py ...`.
4. Parametri fissi: resolution 4MP, output_format webp, output_quality 100,
   safety_tolerance 5; variabili: prompt, aspect_ratio.
5. Limiti aggiuntivi: nessuno richiesto.
6. Token Replicate: usare secret file in `opencode.jsonc` come per OpenRouter
   (es. `{file:~/.config/opencode/.secrets/replicate-key}`) e variabile
   `REPLICATE_API_TOKEN`.

## Parametri del modello (schema Replicate flux-2-max)

- Obbligatorio: `prompt` (string).
- `aspect_ratio` (enum): `match_input_image`, `custom`, `1:1`, `16:9`, `3:2`,
  `2:3`, `4:5`, `5:4`, `9:16`, `3:4`, `4:3` (default `1:1`).
- `resolution` (enum): `match_input_image`, `0.5 MP`, `1 MP`, `2 MP`, `4 MP`
  (default `1 MP`). Nota: non usato se `aspect_ratio=custom`.
- `input_images` (array URI, max 8, jpg/png/gif/webp) per image-to-image.
- `width`/`height` (int 256-2048, multipli di 32, solo se `aspect_ratio=custom`).
- `seed` (int) per riproducibilità.
- Output: `output_format` enum webp/jpg/png (default webp), `output_quality` int
  0-100 (default 80), `safety_tolerance` int 1-5 (default 2).
- Nostri vincoli: forzeremo `resolution=4 MP`, `output_format=webp`,
  `output_quality=100`, `safety_tolerance=5`. Esporremo solo `prompt` e
  `aspect_ratio` dall’enum; non supporteremo `aspect_ratio=custom` (quindi
  nessun `width`/`height`) per restare coerenti con resolution fissa e semplificare
  la validazione.

## Deliverable atteso

- `SKILL.md` con frontmatter valido (name lower-kebab, description <1024) e
  sezioni: cosa fa, quando usarla, input (prompt, aspect_ratio), parametri fissi,
  comando Python da invocare.
- `README.md` sintetico: setup token Replicate, esempio di uso (prompt,
  aspect_ratio (solo enum, no custom), output path, note su safety_tolerance 5.
- `.env.example` con `REPLICATE_API_TOKEN` (e opzionale `REPLICATE_MODEL` se si
  vuole bloccare il model id) e `.gitignore` per `.env` e immagini generate.
- `scripts/generate_image.py` (CLI):
  - Argomenti: prompt (richiesto), output path opzionale (default
    `./generated-image.webp`), `--aspect_ratio` limitato all’enum non custom,
    magari `--timeout` opzionale.
  - Config fissa: resolution=4MP, output_format=webp, output_quality=100,
    safety_tolerance=5, model `black-forest-labs/flux-2-max`.
  - Auth: `REPLICATE_API_TOKEN` obbligatoria; messaggio chiaro se assente.
  - Chiamata: POST /v1/models/black-forest-labs/flux-2-max/predictions (Replicate),
    polling finché `status == succeeded`; scarico prima URL in `output`.
  - File output: crea directory, salva webp, stampa path e size; exit code >0 su
    errori.
- Facoltativo: `requirements.txt` se si usa SDK; altrimenti stdlib HTTP + polling.

## Piano operativo

1. Applicare regole OpenCode skills: name lower-kebab, frontmatter minima, descrizione
   <1024, posizionare in `.config/opencode/skills/<name>/SKILL.md`.
2. Definire nome skill (es. `replicate-flux-image`), creare struttura:
   - `SKILL.md`
   - `README.md`
   - `.env.example`
   - `.gitignore`
   - `scripts/generate_image.py`
   - (eventuale) `requirements.txt`
3. Implementare `generate_image.py`:
   - Parser argparse (prompt, output opzionale, `--aspect_ratio`, `--timeout`?),
     validazione aspect_ratio (se Replicate impone valori ammessi).
   - Gestione token da env; costruzione payload con parametri fissi; POST + polling
     su `/predictions/{id}` fino a succeeded/failed/canceled (timeout difensivo).
   - Download URL risultato (prima voce `output`), salvataggio webp, report size.
   - Messaggi per 401/402/429/422; exit code coerenti.
4. Scrivere `SKILL.md`: spiegare quando usarla (richieste immagini), cosa fa, come
   chiamare il comando, quali parametri sono ammessi (prompt, aspect_ratio, output
   path opzionale), quali sono fissati.
5. Scrivere `README.md`: setup token Replicate in `opencode.jsonc` con
   `{file:~/.config/opencode/.secrets/replicate-key}`, export manuale
   `REPLICATE_API_TOKEN`, esempi multi-OS.
6. Aggiornare `.env.example` e `.gitignore` (ignora `.env`, `*.webp`).
7. Verifica: eseguire script con prompt di prova, aspect_ratio diverso, controllare
   salvataggio webp e gestione errori; `markdownlint` su SKILL/README.

## Rischi e mitigazioni

- Costi/quote Replicate: aggiungere warning in README, messaggi chiari per 402/429.
- Polling/timeout: impostare timeout ragionevole e stato di fallimento chiaro.
- Permessi file: creare directory prima di scrivere; segnalare errori di I/O.
- Portabilità Windows: percorsi cross-platform e istruzioni PowerShell/CMD per token.

## Prossimi passi

- Confermare nome skill (kebab-case) e aspect_ratio consentiti dal modello (lista
  Replicate) per validazione.
- Implementare struttura file e script secondo il piano, quindi validare con
  `markdownlint` e test CLI.
