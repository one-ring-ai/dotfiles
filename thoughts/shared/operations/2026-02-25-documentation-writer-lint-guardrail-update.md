---
status: completed
created_at: 2026-02-25
files_edited:
  - .config/opencode/agent/documentation-writer.md
  - thoughts/shared/status/2026-02-25-documentation-writer-preexisting-change.md
  - thoughts/shared/operations/2026-02-25-documentation-writer-lint-guardrail-update.md
rationale:
  - Rendere deterministico il comportamento del subagent prima del lint markdown.
  - Garantire allineamento certo dei file di configurazione lint con la fonte canonica.
supporting_docs:
  - https://raw.githubusercontent.com/one-ring-ai/dotfiles/refs/heads/main/.markdownlint.json
  - https://raw.githubusercontent.com/one-ring-ai/dotfiles/refs/heads/main/.markdownlintignore
---

## Summary of changes

- Aggiornata la sezione **Lint Config Guardrail** in
  `.config/opencode/agent/documentation-writer.md` con una sequenza operativa
  obbligatoria e non ambigua.
- Inserito vincolo esplicito: prima di ogni esecuzione `markdownlint-cli`, il
  subagent deve scaricare e sovrascrivere `.markdownlint.json` e
  `.markdownlintignore` dalla repository canonica.
- Aggiunto comando consigliato `curl` per implementazione consistente.
- Registrato lo stato iniziale delle modifiche preesistenti in
  `thoughts/shared/status/2026-02-25-documentation-writer-preexisting-change.md`.

## Technical reasoning

La formulazione precedente lasciava spazio a interpretazioni sul controllo di
allineamento. La nuova formulazione impone una strategia idempotente e sicura:
**overwrite sempre prima del lint**. In questo modo si elimina il rischio di
lint eseguito con configurazioni locali obsolete o divergenti.

## Impact assessment

- Riduzione dei falsi negativi/positivi di lint dovuti a config locale non
  sincronizzata.
- Comportamento più prevedibile del subagent `documentation-writer`.
- Nessun impatto funzionale sul codice applicativo: modifica limitata a policy
  documentale e processuale.

## Validation steps

1. Sincronizzati i file di configurazione lint dalla fonte canonica:
   - `.markdownlint.json`
   - `.markdownlintignore`
2. Eseguito:
   `npx markdownlint-cli "**/*.md" --config .markdownlint.json --ignore-path .markdownlintignore --dot --fix`
3. Nessun errore bloccante restituito dal comando.
