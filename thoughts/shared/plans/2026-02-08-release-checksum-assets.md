# Plan: checksum + release assets for `setup.sh`

## Goal

Produrre automaticamente, ad ogni release semantic-release, l’asset
`.config/opencode/setup.sh` accompagnato da un checksum `.sha256` pubblicato
come asset della release GitHub. L’obiettivo è dare ai client uno URL stabile
per script e checksum firmati/immutabili, evitando `curl | bash` da `main`.

## Stato attuale (riferimenti)

- Workflow: `.github/workflows/release.yml` lancia semantic-release su push a
  `alpha`, `beta`, `main`.
- Config semantic-release: `.releaserc.json` usa commit-analyzer, release-notes
  generator, github plugin. Nessun asset attualmente allegato, nessuna fase
  `prepare` custom.

## Strategia

Integrare semantic-release per:

1) Generare il checksum in fase `prepare` (prima della pubblicazione).
2) Allegare a GitHub release due asset:
   - `setup.sh` (copiato dal repo per coerenza con la versione rilasciata).
   - `setup.sh.sha256` (generato nel job e coerente col file).

Non servono auto-commit su `main`; gli asset sono solo allegati alla release.

## Piano di modifica (alta priorità)

1) **Script di build/checksum**
   - Aggiungere uno script (es. `docs/scripts/build-setup-assets.sh`) che:
     - Copia `.config/opencode/setup.sh` in una cartella temporanea di output
       (es. `artifacts/`).
     - Genera `setup.sh.sha256` con `sha256sum setup.sh > setup.sh.sha256`.
     - Opzionale: verifica con `sha256sum --check` per fail-fast.
   - Lo script deve essere idempotente e compatibile con `ubuntu-latest`.

2) **Estendere `.releaserc.json`**
   - Aggiungere `@semantic-release/exec` in `plugins` per eseguire lo script in
     fase `prepare` (es. `{"prepareCmd": "bash docs/scripts/build-setup-assets.sh"}`).
   - Configurare `@semantic-release/github` con `assets` per allegare:
     - `artifacts/setup.sh`
     - `artifacts/setup.sh.sha256`
   - Assicurarsi che le path corrispondano all’output dello script.

3) **Aggiornare il workflow `release.yml`**
   - Nessun cambiamento sostanziale se i binari necessari sono già presenti
     (sha256sum è nel runner). Verificare solo che l’artefact path non venga
     pulito prima dell’upload (semantic-release usa la working dir attuale).

4) **Hardening e coerenza**
   - Usare checkout con `fetch-depth: 0` (già presente) per tag e changelog.
   - Fail-fast se lo script di build/checksum fallisce.
   - Assicurare che l’asset corrisponda esattamente al contenuto rilasciato
     (nessun passaggio che modifichi `setup.sh`).

## Opzioni/varianti

- **Aggiungere un job PR guard**: workflow separato su pull_request che
  rigenera il checksum e fallisce se `setup.sh` cambia senza aggiornare il
  `.sha256` nel diff. Pro: disciplina sugli autori; Contro: richiede commit del
  `.sha256` in repo. (Se preferiamo non versionare `.sha256`, si può usare
  solo la generazione in release.)
- **Firma aggiuntiva**: oltre al checksum, si può firmare gli asset con
  minisign/GPG; aumenta sicurezza, ma richiede gestione chiavi.

## Rischi e mitigazioni

- **Mismatch file/checksum**: mitigato da esecuzione nello stesso job e
  fail-fast sul check.
- **Asset mancanti**: mitigato da `assets` obbligatori in
  `@semantic-release/github`; se non trovati, il job fallisce.
- **Modifica di `setup.sh` fuori release**: non impatta asset già pubblicati;
  i client dovrebbero puntare sempre a release/tag, non a `main`.

## Deliverable attesi (per l’orchestrator)

- Script `build-setup-assets.sh` (o analogo) che produce `artifacts/setup.sh`
  e `artifacts/setup.sh.sha256`.
- `.releaserc.json` aggiornato con `@semantic-release/exec` e `assets` in
  `@semantic-release/github`.
- Nessun auto-commit su `main`; gli asset vivono nelle release generate.
