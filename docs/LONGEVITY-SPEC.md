# LONGEVITY — Master-Spezifikation

Version 1.0 · Stand 09.09.2026 · Studentisches MVP, DHBW

Diese Datei ist die verbindliche Referenz für das Gesamtsystem. Zwei ergänzende Dokumente
beschreiben die Teilsysteme im Detail: `SPEC-backend.md` und `SPEC-frontend.md`.
Bei Widersprüchen gilt diese Datei.

---

## 1. Was gebaut wird

Eine Web-App, die Gesundheitsdaten aus mehreren Quellen zu einem einzigen, erklärbaren
Score von 0 bis 100 verdichtet, daraus ein Vitalitätsalter und konkrete Hebel ableitet, und
dem Nutzer erlaubt, ausschließlich ein Score-Band an Partner weiterzugeben — ohne Rohdaten.

Der Score ist das Produkt. Alles andere ist Rahmen. Wenn eine Entscheidung zwischen
"mehr Features" und "Score bleibt nachvollziehbar" steht, gewinnt der Score.

### Nicht-Ziele des MVP

- Kein Medizinprodukt. Keine Diagnose, keine Therapieempfehlung, keine Grenzwertwarnung.
- Keine native App, kein App-Store-Release.
- Keine echte Versicherungsanbindung. Die Verifikationsroute funktioniert vollständig,
  die Partner dahinter sind Seed-Daten.
- Keine Zahlungsabwicklung, kein Abo, keine Mehrsprachigkeit.

---

## 2. Repository-Struktur

Superprojekt `LONGEVITY` mit zwei Submodules:

```
LONGEVITY/
├─ .gitmodules
├─ frontend/                 → Submodule: longevity-frontend
├─ backend/                  → Submodule: longevity-backend
├─ infra/
│  ├─ compose.yml
│  ├─ compose.dev.yml
│  ├─ Caddyfile
│  └─ backup.sh
├─ docs/
│  ├─ LONGEVITY-SPEC.md
│  ├─ SPEC-backend.md
│  └─ SPEC-frontend.md
├─ .github/workflows/
│  ├─ ci.yml
│  └─ deploy.yml
└─ README.md
```

Einrichtung:

```bash
mkdir LONGEVITY && cd LONGEVITY && git init
git submodule add git@github.com:<org>/longevity-frontend.git frontend
git submodule add git@github.com:<org>/longevity-backend.git backend
git commit -m "Submodules eingehängt"
```

Klonen:

```bash
git clone --recurse-submodules git@github.com:<org>/LONGEVITY.git
```

### Regeln für die Submodule-Arbeit

- Das Superprojekt pinnt exakte Commit-SHAs der Submodules. Ein Deployment ist immer ein
  Superprojekt-Commit — damit ist jeder Stand reproduzierbar.
- Gearbeitet wird **im** Submodule-Verzeichnis auf einem Branch, nie im Detached-HEAD.
  Vor jeder Änderung: `git -C frontend checkout main && git -C frontend pull`.
- Nach dem Push im Submodule den neuen Pointer im Superprojekt committen:
  `git add frontend && git commit -m "frontend: <was>"`.
- CI checkt immer mit `submodules: recursive` aus.
- Ein Pre-Push-Hook im Superprojekt verhindert das Pushen von Pointern auf Commits, die
  noch nicht im Remote des Submodules liegen (`git push --recurse-submodules=check`).

### Der API-Vertrag ist die Naht

Frontend und Backend teilen keinen Code. Der Vertrag ist die OpenAPI-Datei, die das
Backend unter `/api/openapi.json` ausliefert und als `backend/openapi.json` eincheckt.
Das Frontend generiert daraus seine Typen (`pnpm gen:api`). Ändert sich der Vertrag,
ändert sich diese Datei — Reviewer sehen den Diff.

---

## 3. Technologie

Der Stack ist bewusst langweilig, weil der interessante Teil die Score-Engine ist.

| Ebene | Wahl | Grund |
|---|---|---|
| Backend | Node 22, TypeScript, Fastify | Schnell, wenig Magie, gute OpenAPI-Integration |
| ORM / Migrationen | Drizzle | Migrationen sind SQL-Dateien, im Diff lesbar |
| Datenbank | PostgreSQL 16 | — |
| Frontend | Vite, React 19, TypeScript, React Router | Kein Server-Rendering nötig, klare Repo-Trennung |
| Styling | Tailwind mit eigenem Token-Layer | Tokens siehe `SPEC-frontend.md` |
| Charts | Recharts | Nur Linien- und Balkendiagramme nötig |
| Tests | Vitest (beide Repos), Playwright (Frontend, 3 Flows) | — |
| Auth | Session-Cookie, Argon2id | Keine JWTs im LocalStorage |
| Reverse Proxy | Caddy | Automatisches TLS |
| CI/CD | GitHub Actions, GHCR, SSH-Deploy | — |

Node-Version in beiden Repos über `.nvmrc` und `engines` gepinnt. Paketmanager: pnpm.

---

## 4. Domänenmodell

Sieben Tabellen. Details und Migrations-DDL in `SPEC-backend.md`.

- `users` — Konto, Geburtsdatum, Geschlecht (für die Referenzkurven), Passwort-Hash
- `sessions` — Session-Cookie-Store
- `sources` — Datenquelle pro Nutzer (`apple_health`, `oura`, `lab`, `questionnaire`),
  mit `enabled`, `adapter`, `last_sync_at`
- `samples` — append-only Messwerte: `(user_id, source_id, metric, value, unit, measured_at)`
- `score_snapshots` — tägliche berechnete Scores inklusive Aufschlüsselung als JSONB
- `share_tokens` — signierte Score-Nachweise mit Ablauf und Widerrufsstatus
- `partner_offers` — Seed-Katalog der Vorteile

Zentrale Invariante: **`samples` ist append-only.** Kein Update, kein Löschen einzelner
Werte außer bei Quellen-Deaktivierung oder Kontolöschung. Unique-Constraint auf
`(user_id, metric, measured_at)` macht Re-Importe idempotent.

---

## 5. Die Score-Engine

Lebt in `backend/src/score/` als **reine Funktion ohne I/O**. Sie bekommt Samples, ein
Profil und einen Zeitpunkt, und gibt ein Ergebnis zurück. Kein Datenbankzugriff, kein
`Date.now()`, kein Zufall. Das ist die Voraussetzung dafür, dass Golden Tests funktionieren.

```ts
computeScore(input: {
  profile: { birthDate: string; sex: 'm' | 'f' };
  samples: Sample[];
  now: Date;
}): ScoreResult
```

### 5.1 Metrikkatalog

Vier Domänen. `dir` ist die Richtung: `higher` = mehr ist besser, `lower` = weniger ist
besser, `target` = Abweichung vom Zielwert zählt.

**Kardiometabolik — Domänengewicht 0,38**

| Metrik | Einheit | dir | μ(alter, sex) | σ | w |
|---|---|---|---|---|---|
| `vo2max` | ml/kg/min | higher | m: 48 − 0,33·(a−25) · f: 40 − 0,30·(a−25) | 8 / 7 | 0,34 |
| `resting_hr` | bpm | lower | m: 66 · f: 70 | 9 | 0,12 |
| `systolic_bp` | mmHg | lower | m: 118 + 0,35·(a−25) · f: 112 + 0,45·(a−25) | 12 | 0,16 |
| `ldl` | mg/dL | lower | 110 + 0,5·(a−25) | 30 | 0,12 |
| `hdl` | mg/dL | higher | m: 48 · f: 58 | 12 / 14 | 0,08 |
| `hba1c` | % | lower | 5,2 + 0,008·(a−25) | 0,35 | 0,12 |
| `waist` | cm | lower | m: 88 + 0,25·(a−25) · f: 78 + 0,28·(a−25) | 11 | 0,06 |

**Regeneration — Domänengewicht 0,24**

| Metrik | Einheit | dir | μ | σ | w |
|---|---|---|---|---|---|
| `sleep_duration` | h | target 7,5 | — | 0,9 | 0,34 |
| `sleep_consistency` | min (SD der Einschlafzeit) | lower | 55 | 25 | 0,33 |
| `hrv_rmssd` | ms | higher | 55 − 0,5·(a−25) | 20 | 0,33 |

**Aktivität — Domänengewicht 0,26**

| Metrik | Einheit | dir | μ | σ | w |
|---|---|---|---|---|---|
| `zone2_minutes` | min/Woche | higher | 90 | 60 | 0,45 |
| `steps` | Schritte/Tag | higher | 7500 | 3000 | 0,30 |
| `strength_sessions` | /Woche, gekappt bei 4 | higher | 1,0 | 1,0 | 0,25 |

**Risiko — Domänengewicht 0,12**

| Metrik | Einheit | dir | μ | σ | w |
|---|---|---|---|---|---|
| `smoking` | kategorial | fester z | — | — | 0,45 |
| `alcohol_units` | Einheiten/Woche | lower | 8 | 6 | 0,25 |
| `hscrp` | mg/L | lower | 1,6 | 1,2 | 0,30 |

Feste z-Werte für `smoking`: `never` = +0,6 · `former_gt_1y` = +0,2 · `former_lt_1y` = −0,4 ·
`current` = −2,5.

> **Wichtig:** Diese Referenzwerte sind aus der Literatur genäherte Startwerte, keine
> validierten Normdaten. Sie liegen als einzelne Datei `backend/src/score/reference.ts`
> vor und dürfen nur dort geändert werden. Vor jeder Verwendung außerhalb der
> Lehrveranstaltung müssen sie gegen eine benannte Kohorte (z. B. NHANES) geprüft und
> mit Quellenangabe versehen werden. Die Engine ist so gebaut, dass ein Austausch der
> Referenzdatei ausreicht.

### 5.2 Berechnung

Für jede Metrik mit vorhandenem Wert:

```
z_higher = (v − μ) / σ
z_lower  = (μ − v) / σ
z_target = −|v − target| / σ
z        = clamp(z, −3, +3)
metricScore = 100 · Φ(z)
```

Φ ist die Standardnormalverteilungsfunktion, implementiert über die
Abramowitz-Stegun-Näherung von `erf` (7.1.26), absoluter Fehler < 1,5·10⁻⁷.

Frischefaktor pro Sample, mit Halbwertszeit nach Quellentyp
(Wearable 14 Tage, Labor 180 Tage, Fragebogen 365 Tage):

```
Δt = Tage zwischen measured_at und now
a  = 2^(−Δt / halfLife),   a < 0,05 ⇒ Metrik gilt als nicht vorhanden
```

Effektives Gewicht: `w' = w_domain · w_metric · a`.

```
coverage    = Σ w'(vorhanden) / Σ w(alle Metriken)      ∈ [0, 1]
raw         = Σ (w' · metricScore) / Σ w'
finalScore  = 50 + coverage · (raw − 50)
```

Die Shrinkage ist bewusst: fehlende Daten sollen den Score zur Kohortenmitte ziehen,
nicht bestrafen. Wer nichts hochlädt, bekommt 50, nicht 0.

Domänen-Sub-Scores werden analog innerhalb der Domäne berechnet und ohne Shrinkage
ausgewiesen — sie sind Diagnostik, nicht die Kennzahl.

### 5.3 Abgeleitete Größen

```
Vitalitätsalter = clamp(chronoAlter − (finalScore − 50) / 10,
                        chronoAlter − 15, chronoAlter + 15)
Band            = [floor(finalScore / 10) · 10, +9]
```

### 5.4 Simulation

`simulate(input, overrides: Partial<Record<Metric, number>>)` ersetzt Werte, setzt deren
Frischefaktor auf 1,0 und rechnet neu. Rückgabe enthält den Delta-Beitrag je überschriebener
Metrik. Die Hebel-Ansicht ruft nichts anderes auf — es gibt keine zweite Formel.

Die drei vorgeschlagenen Hebel entstehen aus einer Suche: für jede Metrik wird der
Score bei einer realistisch erreichbaren Verbesserung (definiert als `+0,5 σ`,
bei `smoking` der Sprung auf die nächstbessere Stufe) berechnet; die drei mit dem
größten Delta gewinnen. Keine handgepflegte Liste.

### 5.5 Golden Tests

`backend/src/score/__tests__/golden.test.ts` mit mindestens diesen Fixtures:

1. `empty` — keine Samples ⇒ Score exakt 50,0, coverage 0
2. `demo` — der geseedete Demo-Nutzer ⇒ Score 78 ± 0,5, coverage 0,82 ± 0,02
3. `perfect` — alle Metriken auf μ + 2σ ⇒ Score > 92
4. `stale` — Demo-Samples 400 Tage in der Vergangenheit ⇒ coverage < 0,1, Score nahe 50
5. `smoker` — Demo plus `smoking: current` ⇒ Score fällt um mehr als 4 Punkte
6. `monotonie` — für jede `higher`-Metrik: Wert erhöhen darf den Score nie senken
7. `determinismus` — zweimaliger Aufruf mit identischem Input liefert identisches Ergebnis

Fixtures liegen als JSON in `__fixtures__/`. Ändert jemand ein Gewicht, brechen 2–6.
Das ist der Zweck.

---

## 6. Mock-Strategie

Ein einziger Eingangspunkt, dahinter austauschbare Adapter:

```
POST /api/ingest  ←  { source, samples: [{ metric, value, unit, measuredAt }] }

Adapter:
  mock                seeded Generator, Default für alle Wearable-Quellen
  health_export_xml   Upload der Apple-Health-export.xml
  auto_export_webhook JSON-Push aus der iOS-App "Health Auto Export"
  manual              Formular für Laborwerte und Fragebogen
```

Die Score-Engine sieht nie, welcher Adapter geliefert hat. "An Apple Health andocken"
heißt später: einen Adapter ergänzen, sonst nichts.

**HealthKit ist aus dem Browser nicht erreichbar.** Es gibt keine Web-API dafür. Deshalb
sind die beiden echten Pfade der XML-Upload und der Webhook; beide sind im MVP
implementiert, aber im Demo-Modus nicht der Standardweg.

### Der Mock-Generator

`backend/src/mock/generate.ts`, deterministisch über einen Seed (Mulberry32 oder xoshiro,
kein `Math.random`). Erzeugt 90 Tage Verlauf mit:

- AR(1)-Prozess je Metrik, φ = 0,7, damit ein Trend entsteht statt Rauschen
- Wochenrhythmus: Freitag und Samstag ~50 Minuten später eingeschlafen, ~0,7 h kürzer
- leichter positiver Drift bei `vo2max` und `zone2_minutes`, damit der Verlauf steigt
- Laborwerte als drei Einzelmessungen (heute −122, −310, −480 Tage)

Der Demo-Nutzer hat einen festen Seed. In jedem Pitch sieht er identisch aus.

### Sichtbarkeit

Jede gemockte Quelle trägt in der Oberfläche ein neutrales Badge „Mock". Das wird nicht
versteckt — es zeigt, dass die Grenze bekannt ist.

---

## 7. Datenschutz

Gesundheitsdaten sind besondere Kategorien nach Art. 9 DSGVO. Das MVP verarbeitet sie
ausschließlich auf Grundlage der ausdrücklichen Einwilligung, die beim Aktivieren jeder
Quelle einzeln eingeholt und mit Zeitstempel in `sources` protokolliert wird.

Umzusetzen, nicht optional:

- VPS in der EU. Postgres-Port nicht nach außen exponiert, nur im Docker-Netz.
- Keine Messwerte, keine E-Mail-Adressen in Applikationslogs. Logger-Redaction auf
  `req.body`, `email`, `value`.
- `DELETE /api/account` löscht hart per `ON DELETE CASCADE`, kein Soft-Delete-Flag.
  Danach darf keine Zeile mit der `user_id` mehr existieren — es gibt einen Test dafür.
- `POST /api/account/export` liefert alle Daten des Nutzers als JSON.
- Nächtlicher `pg_dump`, 7 Tage Retention, Backup-Verzeichnis nicht im Web-Root.
- Der Score-Nachweis überträgt ausschließlich das Band und das Ausstelldatum.
  Nie einen Einzelwert, nie den exakten Score.

---

## 8. Deployment

### 8.1 Server-Layout

`/opt/longevity/` auf dem VPS:

```
compose.yml        aus infra/ kopiert
Caddyfile
.env               chmod 600, nur hier, nie im Repo
backups/           pg_dump-Ziel
```

Vier Services: `caddy`, `db`, `api`, `web`. Caddy terminiert TLS, routet `/api/*` an
`api:3000` und alles andere an `web:80`. Beide Anwendungs-Container laufen als Nicht-Root.

Healthcheck: `GET /api/healthz` prüft DB-Verbindung und gibt die Engine-Version zurück.
Antwortet innerhalb von 2 s mit HTTP 200 oder gilt als unhealthy.

### 8.2 Pipeline

`ci.yml` — bei jedem Push und PR in beiden Submodule-Repos:

1. `pnpm install --frozen-lockfile`
2. `pnpm typecheck`
3. `pnpm lint`
4. `pnpm test` — im Backend inklusive der Golden Tests gegen eine Postgres-Service-Instanz

`deploy.yml` — bei Push auf `main` **im Superprojekt**:

1. Checkout mit `submodules: recursive`
2. CI beider Submodules erneut ausführen (schnell durch Cache), Abbruch bei Fehler
3. Zwei Images bauen und in die GHCR pushen, getaggt mit dem Superprojekt-SHA
   und zusätzlich `latest`
4. SSH auf den VPS:
   ```
   docker compose pull
   docker compose run --rm api pnpm db:migrate
   docker compose up -d --wait
   curl -fsS --retry 6 --retry-delay 5 https://<domain>/api/healthz
   ```
5. Schlägt der Healthcheck fehl: vorheriges SHA-Tag als `latest` setzen,
   `docker compose up -d --wait`, Job als failed markieren

Migrationen sind forward-only und müssen additiv sein — kein Spaltenlöschen im selben
Deploy, in dem der Code die Spalte noch liest. Zwei Deploys statt einem.

Secrets liegen in GitHub Environments (`SSH_HOST`, `SSH_KEY`, `GHCR_TOKEN`) und auf dem
Server in `.env` (`DATABASE_URL`, `SESSION_SECRET`, `SIGNING_KEY_PRIVATE`,
`SIGNING_KEY_PUBLIC`). Nichts davon je im Repo.

---

## 9. Meilensteine

Jeder Meilenstein endet mit einem lauffähigen, deployten Stand.

**M0 — Gerüst.** Beide Repos, Submodules, Docker-Compose lokal, CI grün, `/api/healthz`
erreichbar, Caddy liefert eine leere Frontend-Seite über HTTPS aus.
*Fertig, wenn:* ein Push auf `main` automatisch auf dem VPS landet.

**M1 — Engine.** `packages`-loser Ordner `backend/src/score/` vollständig, alle sieben
Golden Tests grün, Referenzdatei getrennt. Noch keine HTTP-Route.
*Fertig, wenn:* `pnpm test` die Fixtures deckt und der Demo-Fixture 78 ergibt.

**M2 — Daten und Konto.** Schema, Migrationen, Auth, Ingest-Port, Mock-Generator,
Seed-Skript für den Demo-Nutzer.
*Fertig, wenn:* `pnpm seed:demo` einen Nutzer mit 90 Tagen Verlauf anlegt und
`GET /api/score/current` 78 liefert.

**M3 — Kernoberfläche.** Shell, `/dashboard`, `/score`, `/hebel` inklusive Simulator.
*Fertig, wenn:* der Simulator live rechnet und der Verlauf 90 Tage zeigt.

**M4 — Datenhoheit.** `/daten`, `/freigabe`, Token-Signatur, `/verify/:token` öffentlich,
Export, Kontolöschung.
*Fertig, wenn:* ein zweiter Browser ohne Login ein gültiges Band verifiziert und ein
widerrufener Token abgelehnt wird.

**M5 — Rest der Versprechen.** `/vorteile` mit Seed-Katalog, `/report` als Wochenbericht,
Band-Fortschritt und Datenstreak auf dem Dashboard.
*Fertig, wenn:* jedes Feature aus dem Pitch-Deck eine erreichbare Oberfläche hat.

**M6 — Politur.** Leerzustände, Fehlerzustände, Tastaturbedienung, drei
Playwright-Flows (Registrierung → Score, Simulation, Nachweis teilen → verifizieren),
Backup-Cron aktiv.

---

## 10. Definition of Done für das Gesamtsystem

- Jeder Punkt aus dem Pitch-Deck hat eine erreichbare Route.
- Kein Feature täuscht Funktion vor, die es nicht hat: gemockte Quellen sind als solche
  gekennzeichnet.
- Die Score-Engine ist ohne Datenbank testbar und ihre Golden Tests sind grün.
- Ein Deployment ist ein einziger Superprojekt-Commit und in unter 5 Minuten auf dem VPS.
- Ein fehlgeschlagener Healthcheck rollt automatisch zurück.
- Kontolöschung hinterlässt keine Zeile.
