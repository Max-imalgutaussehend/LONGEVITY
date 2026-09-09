# LONGEVITY — Backend-Spezifikation

Repo `longevity-backend`, eingehängt als Submodule unter `backend/`.
Ergänzt `LONGEVITY-SPEC.md`; die Score-Formeln stehen dort in Abschnitt 5 und werden
hier nicht wiederholt.

---

## 1. Ordnerstruktur

```
src/
├─ index.ts                Fastify-Bootstrap, Plugin-Registrierung
├─ env.ts                  Zod-validierte Umgebungsvariablen, wirft beim Start
├─ db/
│  ├─ schema.ts            Drizzle-Schema
│  ├─ client.ts
│  └─ migrations/          generierte SQL-Dateien, eingecheckt
├─ score/
│  ├─ index.ts             computeScore, simulate, suggestLevers
│  ├─ reference.ts         NUR Referenzwerte, sonst nichts
│  ├─ metrics.ts           Metrikkatalog, Gewichte, Richtungen
│  ├─ stats.ts             erf, Phi, clamp
│  ├─ types.ts
│  └─ __tests__/
│     ├─ golden.test.ts
│     └─ __fixtures__/*.json
├─ mock/
│  └─ generate.ts          seeded AR(1)-Generator
├─ adapters/
│  ├─ mock.ts
│  ├─ healthExportXml.ts
│  ├─ autoExportWebhook.ts
│  └─ manual.ts
├─ routes/
│  ├─ auth.ts  me.ts  ingest.ts  sources.ts  score.ts
│  ├─ share.ts  verify.ts  offers.ts  report.ts  account.ts  health.ts
├─ lib/
│  ├─ signing.ts           Ed25519 Sign/Verify für Score-Nachweise
│  ├─ password.ts          Argon2id
│  └─ session.ts
└─ seed/
   └─ demo.ts
```

Regel: `src/score/` importiert nichts außerhalb von `src/score/`. Kein DB-Import, kein
Fastify-Import, kein `Date.now()`. Ein ESLint-Boundary-Rule erzwingt das.

---

## 2. Datenbankschema

```sql
create table users (
  id            uuid primary key default gen_random_uuid(),
  email         citext unique not null,
  password_hash text not null,
  birth_date    date not null,
  sex           text not null check (sex in ('m','f')),
  display_name  text,
  created_at    timestamptz not null default now()
);

create table sessions (
  id         text primary key,
  user_id    uuid not null references users(id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index on sessions (user_id);

create table sources (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  kind           text not null check (kind in
                   ('apple_health','oura','lab','questionnaire')),
  adapter        text not null check (adapter in
                   ('mock','health_export_xml','auto_export_webhook','manual')),
  enabled        boolean not null default true,
  consent_at     timestamptz,
  last_sync_at   timestamptz,
  created_at     timestamptz not null default now(),
  unique (user_id, kind)
);

create table samples (
  id          bigserial primary key,
  user_id     uuid not null references users(id) on delete cascade,
  source_id   uuid not null references sources(id) on delete cascade,
  metric      text not null,
  value       double precision not null,
  unit        text not null,
  measured_at timestamptz not null,
  created_at  timestamptz not null default now(),
  unique (user_id, metric, measured_at)
);
create index on samples (user_id, metric, measured_at desc);

create table score_snapshots (
  id          bigserial primary key,
  user_id     uuid not null references users(id) on delete cascade,
  computed_for date not null,
  score       double precision not null,
  coverage    double precision not null,
  bio_age     double precision not null,
  breakdown   jsonb not null,
  engine_version text not null,
  created_at  timestamptz not null default now(),
  unique (user_id, computed_for)
);

create table share_tokens (
  id          text primary key,
  user_id     uuid not null references users(id) on delete cascade,
  band_low    int not null,
  band_high   int not null,
  issued_at   timestamptz not null default now(),
  expires_at  timestamptz not null,
  revoked_at  timestamptz,
  partner_ref text,
  signature   text not null
);
create index on share_tokens (user_id);

create table partner_offers (
  id            uuid primary key default gen_random_uuid(),
  partner_name  text not null,
  title         text not null,
  description   text not null,
  min_band      int not null,
  value_label   text not null,
  is_demo       boolean not null default true,
  sort_order    int not null default 0
);
```

`citext` und `pgcrypto` als Extensions in der ersten Migration anlegen.

`breakdown` in `score_snapshots` speichert das vollständige `ScoreResult`, damit die
Aufschlüsselung historischer Tage ohne Neuberechnung angezeigt werden kann.

---

## 3. Typen der Engine

```ts
type Metric =
  | 'vo2max' | 'resting_hr' | 'systolic_bp' | 'ldl' | 'hdl' | 'hba1c' | 'waist'
  | 'sleep_duration' | 'sleep_consistency' | 'hrv_rmssd'
  | 'zone2_minutes' | 'steps' | 'strength_sessions'
  | 'smoking' | 'alcohol_units' | 'hscrp';

type Domain = 'cardiometabolic' | 'recovery' | 'activity' | 'risk';

interface Sample {
  metric: Metric;
  value: number;
  unit: string;
  measuredAt: string;      // ISO 8601
  sourceKind: 'apple_health' | 'oura' | 'lab' | 'questionnaire';
}

interface MetricResult {
  metric: Metric;
  domain: Domain;
  value: number | null;
  unit: string;
  percentile: number | null;   // 0..100, = 100 * Phi(z)
  z: number | null;
  ageDays: number | null;
  freshness: number;           // 0..1
  effectiveWeight: number;
  contribution: number;        // Punkte am Gesamtscore
  available: boolean;
}

interface DomainResult {
  domain: Domain;
  weight: number;
  score: number;               // 0..100, ohne Shrinkage
  metrics: MetricResult[];
}

interface ScoreResult {
  score: number;               // 0..100, eine Nachkommastelle
  coverage: number;            // 0..1
  bioAge: number;
  chronoAge: number;
  band: { low: number; high: number };
  domains: DomainResult[];
  engineVersion: string;       // semver, bei jeder Gewichtsänderung erhöhen
  computedAt: string;
}

interface Lever {
  metric: Metric;
  currentValue: number | null;
  targetValue: number;
  delta: number;               // Score-Punkte
  horizonWeeks: number;        // fest 8 im MVP
}
```

`engineVersion` wird bei jeder Änderung an `metrics.ts` oder `reference.ts` erhöht und in
jedem Snapshot mitgeschrieben. Sonst vergleicht man später Äpfel mit Birnen.

---

## 4. API-Vertrag

Basis-Pfad `/api`. Antworten immer JSON. Fehler nach RFC 9457 (`application/problem+json`)
mit `type`, `title`, `status`, `detail`.

Auth per `HttpOnly`-Session-Cookie, `SameSite=Lax`, `Secure` in Produktion.
Alle Routen außer den markierten benötigen eine Session.

### Auth und Konto

| Methode | Pfad | Body / Query | Antwort |
|---|---|---|---|
| POST | `/auth/register` | `{ email, password, birthDate, sex, displayName? }` | `201` `{ user }`, setzt Cookie |
| POST | `/auth/login` | `{ email, password }` | `200` `{ user }` |
| POST | `/auth/logout` | — | `204` |
| GET | `/me` | — | `{ id, email, displayName, birthDate, sex, chronoAge }` |
| POST | `/account/export` | — | `200` JSON-Dump aller eigenen Daten |
| DELETE | `/account` | `{ password }` | `204`, löscht hart |

Passwortregeln: mindestens 10 Zeichen, gegen die Top-10k-Liste geprüft. Argon2id mit
`m=19456, t=2, p=1`. Rate-Limit auf `/auth/login`: 10 Versuche pro 15 Minuten pro IP.

### Datenquellen und Ingest

| Methode | Pfad | Body | Antwort |
|---|---|---|---|
| GET | `/sources` | — | `Source[]` mit `lastSyncAt`, `sampleCount`, `adapter` |
| PATCH | `/sources/:id` | `{ enabled }` | `Source`, setzt `consentAt` beim Aktivieren |
| POST | `/sources/:id/regenerate` | `{ seed? }` | `202`, nur für `adapter = mock` |
| POST | `/ingest` | `{ sourceKind, samples: SampleInput[] }` | `{ accepted, duplicates }` |
| POST | `/ingest/health-export` | `multipart`, Feld `file` (ZIP oder XML) | `{ accepted, duplicates }` |
| POST | `/ingest/webhook/:secret` | Health-Auto-Export-JSON | `{ accepted }`, **ohne Session** |
| POST | `/labs` | `{ entries: [{ metric, value, unit, measuredAt }] }` | `{ accepted }` |

Ingest-Regeln:

- Batchgröße maximal 5000 Samples pro Request, sonst `413`.
- Unbekannte Metriken werden verworfen, nicht abgelehnt; die Anzahl steht in
  `{ ignored }` der Antwort.
- Duplikate laufen in den Unique-Constraint und werden per `on conflict do nothing`
  gezählt, nicht als Fehler behandelt.
- `measuredAt` in der Zukunft ⇒ `422`.
- Nach erfolgreichem Ingest wird der heutige Snapshot invalidiert und neu berechnet.

Der Webhook-Pfad enthält ein pro Nutzer generiertes Geheimnis (32 Byte, base64url), das
in `/daten` als kopierbare URL angezeigt wird. Rate-Limit 60 Requests pro Stunde.

### Score

| Methode | Pfad | Query | Antwort |
|---|---|---|---|
| GET | `/score/current` | — | `ScoreResult` |
| GET | `/score/history` | `days=90` | `{ date, score, coverage }[]` |
| GET | `/score/breakdown` | `date?` | `ScoreResult` des Tages |
| POST | `/score/simulate` | Body `{ overrides: Partial<Record<Metric, number>> }` | `{ base, simulated, perMetric: { metric, delta }[] }` |
| GET | `/score/levers` | — | `Lever[]`, drei Stück |

`/score/simulate` ist idempotent und schreibt nichts. Rate-Limit 30 pro Minute, damit ein
Slider-Drag nicht zum Lastproblem wird — das Frontend debounct zusätzlich auf 120 ms.

Snapshots werden lazy erzeugt: ein Request auf `/score/current` prüft, ob für heute ein
Snapshot mit der aktuellen `engineVersion` existiert, und berechnet ihn sonst.
Kein Cronjob nötig.

### Freigabe und Verifikation

| Methode | Pfad | Body | Antwort |
|---|---|---|---|
| GET | `/share-tokens` | — | `ShareToken[]` ohne Signatur |
| POST | `/share-tokens` | `{ partnerRef?, validDays }` (max. 180) | `{ id, url, expiresAt }` |
| DELETE | `/share-tokens/:id` | — | `204`, setzt `revokedAt` |
| GET | `/verify/:id` | — | **ohne Session**: `{ band, issuedAt, expiresAt, valid, reason? }` |

Token-Format: `id` sind 22 Zeichen base58 aus 16 zufälligen Bytes. Signiert wird mit
Ed25519 über den kanonischen String

```
`${id}|${bandLow}|${bandHigh}|${issuedAt}|${expiresAt}`
```

`/verify/:id` prüft in dieser Reihenfolge: Existenz, Signatur, `revokedAt` leer,
`expiresAt` in der Zukunft. Bei Fehlschlag `valid: false` mit `reason` aus
`not_found | invalid_signature | revoked | expired` — immer HTTP 200, damit die
öffentliche Seite einen ordentlichen Zustand rendern kann statt einer Fehlerseite.

Die Antwort enthält **niemals** den exakten Score, eine Metrik oder die Nutzer-ID.

Der öffentliche Schlüssel wird unter `GET /verify/public-key` ausgeliefert, damit ein
Partner theoretisch selbst prüfen könnte. Das kostet nichts und ist im Pitch ein Satz.

### Vorteile und Bericht

| Methode | Pfad | Antwort |
|---|---|---|
| GET | `/offers` | `PartnerOffer[]` plus `qualified: boolean` je Angebot |
| GET | `/report/weekly` | `{ weekStart, scoreStart, scoreEnd, delta, bestMetric, worstMetric, streakDays }` |
| POST | `/report/send` | `202`, Versand über SMTP an Mailpit im Dev-Stack |

`streakDays`: Anzahl aufeinanderfolgender Tage bis heute mit mindestens einem Sample aus
einer Wearable-Quelle. Das ist die gesamte Gamification — kein Punktesystem, keine Badges.

### Betrieb

| Methode | Pfad | Antwort |
|---|---|---|
| GET | `/healthz` | `{ ok, db, engineVersion, commit }`, ohne Session |
| GET | `/openapi.json` | OpenAPI 3.1, ohne Session |

---

## 5. Adapter

Alle Adapter implementieren dieselbe Signatur:

```ts
type Adapter = (raw: unknown, ctx: { userId: string; sourceId: string })
  => Promise<SampleInput[]>;
```

**mock** — ruft `generate(seed, days)` aus `src/mock/` auf und schreibt 90 Tage.
Beim Regenerieren werden die bisherigen Samples dieser Quelle gelöscht und neu erzeugt.

**healthExportXml** — streamt die XML mit einem SAX-Parser (nicht in den Speicher laden,
Exporte werden schnell 200 MB groß). Gemappt werden:
`HKQuantityTypeIdentifierVO2Max → vo2max`,
`HKQuantityTypeIdentifierRestingHeartRate → resting_hr`,
`HKQuantityTypeIdentifierHeartRateVariabilitySDNN → hrv_rmssd`,
`HKQuantityTypeIdentifierStepCount → steps` (Tagessumme),
`HKCategoryTypeIdentifierSleepAnalysis → sleep_duration` und daraus
`sleep_consistency` als Standardabweichung der Einschlafzeit über 14 Tage.
Alles andere wird ignoriert. ZIP wird serverseitig entpackt, maximal 500 MB.

**autoExportWebhook** — nimmt das JSON-Schema der App entgegen
(`{ data: { metrics: [{ name, units, data: [{ date, qty }] }] } }`) und mappt über
dieselbe Tabelle wie oben.

**manual** — validiert gegen den Metrikkatalog inklusive plausibler Wertebereiche
(z. B. `hba1c` zwischen 3 und 15) und lehnt Ausreißer mit `422` ab.

---

## 6. Seed

`pnpm seed:demo` legt an:

- Nutzer `demo@longevity.app` / `demo-longevity-2026`, geboren am 14.03.1997, `sex: 'm'`
- vier Quellen: `apple_health` und `oura` mit Adapter `mock`, `lab` und `questionnaire`
  mit `manual`
- 90 Tage Wearable-Verlauf mit festem Seed `20260909`
- drei Laborzeitpunkte, der jüngste 122 Tage alt, `hscrp` bewusst fehlend
- Fragebogen: `smoking: never`, `alcohol_units: 6`
- sechs `partner_offers`, Bänder 70 / 80 / 90

Ergebnis muss ein Score von 78 ± 0,5 bei coverage 0,82 ± 0,02 sein. Der Golden Test
`demo` deckt genau das ab — weicht der Seed-Output ab, ist der Generator kaputt.

`pnpm seed:offers` lädt nur den Katalog, für Produktionsdeployments.

---

## 7. Tests

| Ebene | Umfang |
|---|---|
| Score-Engine | die sieben Golden Tests aus dem Master-Spec, plus Property-Test für Monotonie über 500 zufällige Eingaben |
| Adapter | je ein Fixture pro Adapter, inklusive einer echten (gekürzten) Apple-Health-XML |
| Routen | Integrationstests gegen Testcontainers-Postgres: Registrierung, Ingest-Idempotenz, Simulate, Token-Lebenszyklus (gültig → widerrufen → abgelehnt), Kontolöschung |
| Datenschutz | ein Test, der nach `DELETE /account` jede Tabelle auf verbliebene `user_id` prüft |

Coverage-Ziel: `src/score/` bei 100 % Zeilen, Rest bei 60 %. Der Rest darf lückenhaft sein,
die Engine nicht.

---

## 8. Konfiguration

```
DATABASE_URL
SESSION_SECRET              32 Byte base64
SIGNING_KEY_PRIVATE         Ed25519, PKCS#8 PEM
SIGNING_KEY_PUBLIC          Ed25519, SPKI PEM
PUBLIC_BASE_URL             für die Nachweis-URLs
SMTP_URL                    im Dev-Stack Mailpit
NODE_ENV
COMMIT_SHA                  vom Build injiziert, für /healthz
```

`src/env.ts` validiert das beim Start mit Zod und beendet den Prozess bei fehlenden Werten.
Ein Container, der ohne Signaturschlüssel startet, ist ein stiller Fehler — genau der Typ,
der erst im Pitch auffällt.
