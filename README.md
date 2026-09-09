LONGEVITY — Health Score Platform

## Setup (lokal)

```bash
# Repos klonen
git clone --recurse-submodules https://github.com/Max-imalgutaussehend/LONGEVITY.git
cd LONGEVITY

# Ed25519-Schlüsselpaar generieren (einmalig)
openssl genpkey -algorithm ed25519 -out signing_key.pem
openssl pkey -in signing_key.pem -pubout -out signing_key_pub.pem

# Docker Compose starten
cd infra
docker compose -f compose.dev.yml up --build -d

# Demo-Daten laden (in einem neuen Terminal)
docker compose -f compose.dev.yml exec api pnpm db:migrate
docker compose -f compose.dev.yml exec api pnpm seed:demo
```

Dann:
- Frontend: http://localhost:5173
- API: http://localhost:3000/api/healthz
- Mailpit: http://localhost:8025

Demo-Login: `demo@longevity.app` / `demo-longevity-2026`

## Submodule-Workflow

```bash
# Im Submodule arbeiten
git -C frontend checkout main && git -C frontend pull
# ... Änderungen ...
git -C frontend add . && git -C frontend commit -m "feat: ..."
git -C frontend push

# Pointer im Superprojekt aktualisieren
git add frontend && git commit -m "frontend: <was>"
git push
```

## Docs

- `docs/LONGEVITY-SPEC.md` — Master-Spezifikation
- `docs/SPEC-backend.md` — Backend-Details
- `docs/SPEC-frontend.md` — Frontend-Details
