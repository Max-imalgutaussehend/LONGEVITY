### Infra

| Datei           | Kurzbeschreibung                            |
| --------------- | ------------------------------------------- |
| [start.sh](../start.sh)        | Setupskript für die lokale Entwicklung      |
| [compose.dev.yml](../infra/compose.dev.yml) | Docker Compose für DB, Mailpit, API und Web |
| [Caddyfile](../infra/Caddyfile)       | Reverse-Proxy                               |
| [index.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/index.ts)        | Server-Einstiegspunkt                       |
| [app.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/app.ts)          | Fastify, Security und Routenregistrierung   |
| [env.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/env.ts)          | Umgebungsvariablen                          |

---

### Backend: Core

| Datei            | Kurzbeschreibung                                         |
| ---------------- | -------------------------------------------------------- |
| [index.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/index.ts)         | Score-Berechnung (0–100), Vitalitätsalter & Hebel-Finder |
| [metrics.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/metrics.ts)       | Katalog der 15 Vitalmetriken mit Gewichtungen            |
| [reference.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/reference.ts)     | Klinische Referenztabellen nach Alter und Geschlecht     |
| [stats.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/stats.ts)         | Gaußsche Fehlerfunktion erf, CDF Φ(z) & Clamping         |
| [plausibility.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/plausibility.ts)  | Physiologische Grenzwert- & Plausibilitätsprüfungen      |
| [holdingPeriod.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/holdingPeriod.ts) | Validierung stabiler Score-Halteperioden (z. B. 60 Tage) |
| [types.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/types.ts)         | Domänen-Typen für Messwerte, Domänen und Scores          |

---

### Backend: Datenkonnektoren und Adapter

| Datei             | Kurzbeschreibung              |
| ----------------- | ----------------------------- |
| [appleHealth.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/appleHealth.ts)    | Apple Health Datenimport      |
| [appleHealthZip.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/appleHealthZip.ts) | Apple Health Datenimport      |
| [oura.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/oura.ts)           | Oura Ring API-Adapter         |
| [withings.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/withings.ts)       | Withings API-Adapter          |
| [strava.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/strava.ts)         | Strava API-Adapter            |
| [googleFit.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/googleFit.ts)      | Google Fit API-Adapter        |
| [fhir.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/fhir.ts)           | Parsing von Laborwertimporten |
|                   |                               |

---

### Backend: Sicherheit

| Datei             | Kurzbeschreibung                                   |
| ----------------- | -------------------------------------------------- |
| [signing.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/signing.ts)        | Health Score Signatur                              |
| [password.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/password.ts)       | Passworthashing                                    |
| [csrf.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/csrf.ts)           | Genereller CSRF-Schutz                             |
| [oauthState.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/oauthState.ts)     | Schutz gegen Login-CSRF                            |
| [pgSessionStore.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/pgSessionStore.ts) | Nutzersession-Persistierung                        |
| [kvnr.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/kvnr.ts)           | Validierung und Sicherung von Krankenkassennummern |
| [sampleImport.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/sampleImport.ts)   | Testdatenimport                                    |
| [mail.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/mail.ts)           | Client für die E-Mail-Kommunikation                |
|                   |                                                    |

---

### Backend: API

| Datei      | Kurzbeschreibung                                       |
| ---------- | ------------------------------------------------------ |
| [auth.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/auth.ts)    | Login, Registrierung, Verifikation & Passwort-Reset    |
| [score.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/score.ts)   | Endpunkte für aktuellen Score, Verlauf & Simulation    |
| [sources.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/sources.ts) | Quellen-Status, OAuth-Verbindung & Upload-Endpunkte    |
| [share.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/share.ts)   | Generierung von Freigabe-Tokens & QR-Codes             |
| [insurer.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/insurer.ts) | Krankenkassenportal, Mitgliedervorteile & Bonusanträge |
| [reports.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/reports.ts) | Berichte und Auswertungen                              |
| [account.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/account.ts) | Datenexport und Accountverwaltung                      |

---

### Backend: Datenbank

| Datei      | Kurzbeschreibung               |
| ---------- | ------------------------------ |
| [schema.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/db/schema.ts)  | Drizzle ORM Schemata           |
| [client.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/db/client.ts)  | Datenbankclient für PostgreSQL |
| [migrate.ts](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/db/migrate.ts) | Datenbankmigrationen           |
|            |                                |

---

### Frontend: Shells

| Datei            | Kurzbeschreibung                                    |
| ---------------- | --------------------------------------------------- |
| [router.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/router.tsx)        | Routing auf Clientseite und Authentifizierungslogik |
| [client.ts](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/api/client.ts)        | HTTP-Client für die Backendkommunikation            |
| [generated.ts](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/api/generated.ts)     | Interfaces basierend auf der OpenAPI-Spezifikation  |
| [tokens.css](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/styles/tokens.css)       | Look and Feel in Form von Designtoken               |
| [AppShell.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/AppShell.tsx)     | Nutzerdashboard                                     |
| [PublicShell.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/PublicShell.tsx)  | Landingpage                                         |
| [InsurerShell.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/InsurerShell.tsx) | Krankenkassendashboard                              |
| [AdminShell.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/AdminShell.tsx)   | Admindashboard                                      |
|                  |                                                     |

---

### Frontend: Seiten

| Datei                    | Kurzbeschreibung                         |
| ------------------------ | ---------------------------------------- |
| [Dashboard.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Dashboard.tsx)            | Score, Vitalitätsalter, Trend und Hebel  |
| [Hebel.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Hebel.tsx)                | Hebelsimulator                           |
| [Daten.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Daten.tsx)                | Datenübersicht                           |
| [Freigabe.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Freigabe.tsx)             | Datenfreigabe für Krankenkassen          |
| [Vorteile.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Vorteile.tsx)             | Krankenkassenboniübersicht und Einlösung |
| [Verify.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Verify.tsx)               | Zertifikatsprüfung                       |
| [Landing.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Landing.tsx)              | Landingpage                              |
| [Login.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Login.tsx) / [Register.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Register.tsx) | Authentifizierung & Onboarding           |
| [Report.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/Report.tsx)               | Export der Gesundheitsübersicht          |
| [InsurerOverview.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/InsurerOverview.tsx)      | Kassen-Dashboard                         |
| [InsurerOffers.tsx](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/InsurerOffers.tsx)        | Verwaltung der Vorteile                  |
