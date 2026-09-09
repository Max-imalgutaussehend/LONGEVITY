# LONGEVITY — Claude Code Guidelines

## Repository-Überblick

Monorepo-Superprojekt mit zwei Submodulen:
- `backend/` → `longevity-backend` (Fastify, TypeScript, Drizzle, PostgreSQL)
- `frontend/` → `longevity-frontend` (Vite, React 19, TypeScript)
- `infra/` → Docker Compose, Caddyfile, deploy-Skripte
- `docs/` → Spezifikationen (`LONGEVITY-SPEC.md`, `SPEC-backend.md`, `SPEC-frontend.md`)

**Spezifikationen sind verbindlich.** Vor jeder Implementierung die relevanten Abschnitte lesen.

---

## Git-Workflow

### Branches

```
main       ← production, nur per PR
dev        ← integration branch, Basis für alle Feature-Branches
feat/*     ← ein Feature / ein Issue
fix/*      ← Bugfix
chore/*    ← Infrastruktur, Dependencies, ohne Logik-Änderung
```

**Jedes Feature bekommt einen eigenen Branch von `dev`:**
```bash
git checkout dev && git pull
git checkout -b feat/issue-42-score-levers
```

**Niemals direkt auf `main` oder `dev` committen.**

### Pull Requests

- Feature-Branch → `dev` (kein direkter PR auf `main`)
- `dev` → `main` per PR mit mindestens einem Review (Victor oder Max)
- PR-Titel folgt Conventional Commits: `feat(score): add lever calculation`
- PR-Beschreibung: Was, Warum, Wie testen
- CI muss grün sein bevor Merge

### Commit-Messages (Conventional Commits)

```
feat(scope): kurze Beschreibung
fix(auth): session cookie not sent behind Cloudflare
chore(deps): bump drizzle-orm to 0.37
test(score): add golden tests for smoker profile
```

Scopes: `auth`, `score`, `sources`, `share`, `verify`, `infra`, `deps`, `api`

### Submodul-Pointer

Nach jedem Push im Submodul den Pointer im Superprojekt committen:
```bash
git add backend   # oder frontend
git commit -m "chore: update backend submodule to <sha> (<was geändert>)"
git push
```

---

## Issue-basierte Entwicklung

- **Alle Aufgaben laufen über GitHub Issues.** Kein Code ohne Issue.
- Meldet der User etwas (Bug, Feature-Wunsch, Feedback) → zuerst ein Issue anlegen, dann bearbeiten.
- Immer nur Issues der eigenen Person bearbeiten, es sei denn explizit anders vereinbart.
- Branch-Name enthält Issue-Nummer: `feat/issue-42-score-levers`
- PR linkt das Issue: `Closes #42` in der Beschreibung

---

## Test-Driven Development (TDD)

**Red → Green → Refactor** für alle nicht-trivialen Logik.

### Backend
```bash
cd backend
pnpm test          # Vitest, alle Tests
pnpm test:watch    # Watch-Modus
```

- Unit-Tests für Score-Engine (`src/score/__tests__/`)
- Integrations-Tests für Route-Handler mit echtem DB-Client (kein Mock)
- Golden Tests: Fixtures als JSON unter `__tests__/__fixtures__/`, Snapshot der Score-Ausgabe
- **Kein Mocking der Datenbank.** Testet gegen eine echte Postgres-Instanz (via Docker Compose in CI).

### Frontend
```bash
cd frontend
pnpm test          # Vitest + jsdom
pnpm test:e2e      # Playwright (3 kritische Flows: Register→Dashboard, Login, Verify)
```

- Unit-Tests für Berechnungslogik und Utility-Funktionen
- E2E-Tests für: Registrierung → Dashboard zeigt Score, Login/Logout, Public Verify-Page

### Reihenfolge

1. Test schreiben (schlägt fehl)
2. Minimale Implementierung (Test wird grün)
3. Refactoren ohne Tests rot zu machen
4. Kein Code committen der Tests rot lässt

---

## Code-Qualität

### Allgemein

- **YAGNI**: Nur was das Issue verlangt. Keine spekulativen Abstraktionen.
- **Single Responsibility**: Eine Funktion, eine Aufgabe.
- **Explizit statt implizit**: Lieber einen Parameter mehr als ein cleveres Default.
- **Keine Kommentare die erklären was der Code tut** — nur wenn das Warum nicht offensichtlich ist.
- **Keine toten Code-Pfade, keine auskommentierten Blöcke.**

### TypeScript

- Strict Mode (`"strict": true`) — keine `any`, keine `as unknown as`.
- Typen nah an der Domäne halten (`Metric`, `Domain`, `Sex` statt `string`).
- Zod für alle externen Inputs (Request Bodies, env vars).
- `pnpm typecheck` muss immer grün sein.

### Backend-spezifisch

- Route-Handler sind dünn: validieren, delegieren, antworten.
- Geschäftslogik (Score, Lever, Freshness) gehört in `src/score/`, nicht in den Handler.
- DB-Queries direkt mit Drizzle — kein Repository-Pattern, kein ORM-Magic.
- Neue Tabellen / Schema-Änderungen immer per `pnpm db:generate`, nie manuell SQL schreiben.
- Migrations sind committet und idempotent.

### Frontend-spezifisch

- Kein globaler State (kein Zustand/Redux). React Query für Server-State.
- Komponenten bleiben unter 150 Zeilen. Aufteilen wenn größer.
- Inline-Styles für Layout, CSS-Variablen für Tokens (siehe `SPEC-frontend.md`).
- `apiClient` für alle API-Calls — nie direkt `fetch`.

### API-Vertrag

Der Vertrag zwischen Frontend und Backend ist `backend/openapi.json`:
1. Backend ändert eine Route → `pnpm gen:openapi` → `openapi.json` committen
2. Frontend führt `pnpm gen:api` aus → `src/api/generated.ts` aktualisieren
3. Beide Änderungen in denselben PR

---

## Sicherheit

- Keine Secrets in Git. Secrets gehören in GitHub Secrets oder `/opt/life-server/.env`.
- `.github_master_token`, `.claude/`, Signing-Keys → in `.gitignore`.
- SQL-Queries immer parametrisiert (Drizzle garantiert das).
- Session-Cookie: `httpOnly: true`, `sameSite: 'lax'`. Kein JWT im LocalStorage.
- Nutzereingaben werden an der API-Grenze mit Zod validiert — nie im Handler per Hand.

---

## Infra / Deployment

- **Deployment = Push auf `main`.** CI baut Images, pusht zu GHCR, deployt via SSH.
- Hotfixes auf `main` nur wenn `dev` nicht geht und Production brennt.
- Caddy-Konfiguration auf dem Server liegt in `/opt/life-server/compose/generated/caddy/Caddyfile`.
- LONGEVITY läuft isoliert auf `longevity-edge` Network — nicht `prod-net-edge`.
- Neue Infra-Änderungen (Networks, Volumes, Secrets) immer dokumentieren.

---

## Lokale Entwicklung

```bash
# Setup (einmalig)
git clone --recurse-submodules https://github.com/Max-imalgutaussehend/LONGEVITY.git
cd LONGEVITY/infra && docker compose -f compose.dev.yml up --build -d
docker compose -f compose.dev.yml exec api pnpm db:migrate
docker compose -f compose.dev.yml exec api pnpm seed:demo

# Täglich
docker compose -f compose.dev.yml up -d
# Frontend: http://localhost:5173
# API:      http://localhost:3000/api/healthz
# Mailpit:  http://localhost:8025
# Demo-Login: demo@longevity.app / demo-longevity-2026
```

---

## Was Claude hier wissen muss

- Server: `deploy@62.238.4.64`, SSH-Key: `/tmp/longevity_deploy` (Ed25519, ephemeral)
- Details zu Server-Pfaden und Netzwerkarchitektur: siehe Memory `reference_server_access.md`
- GH Token für Push: `GH_TOKEN=$(cat ~/.github_master_token) git push` — Token niemals in `.git/config`
- Submodul-Pointer immer committen nach Push im Submodul
- CI deployt automatisch bei Push auf `main`
