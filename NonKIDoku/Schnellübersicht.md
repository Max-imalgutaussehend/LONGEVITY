### Infra

| Datei           | Kurzbeschreibung                            |
| --------------- | ------------------------------------------- |
| [start.sh](../start.sh)        | Setupskript für die lokale Entwicklung      |
| [compose.dev.yml](../infra/compose.dev.yml) | Docker Compose für DB, Mailpit, API und Web |
| [Caddyfile](../infra/Caddyfile)       | Reverse-Proxy                               |
| [index.ts](../backend/src/index.ts)        | Server-Einstiegspunkt                       |
| [app.ts](../backend/src/app.ts)          | Fastify, Security und Routenregistrierung   |
| [env.ts](../backend/src/env.ts)          | Umgebungsvariablen                          |

---

### Backend: Core

| Datei            | Kurzbeschreibung                                         |
| ---------------- | -------------------------------------------------------- |
| [index.ts](../backend/src/score/index.ts)         | Score-Berechnung (0–100), Vitalitätsalter & Hebel-Finder |
| [metrics.ts](../backend/src/score/metrics.ts)       | Katalog der 15 Vitalmetriken mit Gewichtungen            |
| [reference.ts](../backend/src/score/reference.ts)     | Klinische Referenztabellen nach Alter und Geschlecht     |
| [stats.ts](../backend/src/score/stats.ts)         | Gaußsche Fehlerfunktion erf, CDF Φ(z) & Clamping         |
| [plausibility.ts](../backend/src/score/plausibility.ts)  | Physiologische Grenzwert- & Plausibilitätsprüfungen      |
| [holdingPeriod.ts](../backend/src/score/holdingPeriod.ts) | Validierung stabiler Score-Halteperioden (z. B. 60 Tage) |
| [types.ts](../backend/src/score/types.ts)         | Domänen-Typen für Messwerte, Domänen und Scores          |

---

### Backend: Datenkonnektoren und Adapter

| Datei             | Kurzbeschreibung              |
| ----------------- | ----------------------------- |
| [appleHealth.ts](../backend/src/adapters/appleHealth.ts)    | Apple Health Datenimport      |
| [appleHealthZip.ts](../backend/src/adapters/appleHealthZip.ts) | Apple Health Datenimport      |
| [oura.ts](../backend/src/adapters/oura.ts)           | Oura Ring API-Adapter         |
| [withings.ts](../backend/src/adapters/withings.ts)       | Withings API-Adapter          |
| [strava.ts](../backend/src/adapters/strava.ts)         | Strava API-Adapter            |
| [googleFit.ts](../backend/src/adapters/googleFit.ts)      | Google Fit API-Adapter        |
| [fhir.ts](../backend/src/adapters/fhir.ts)           | Parsing von Laborwertimporten |
|                   |                               |

---

### Backend: Sicherheit

| Datei             | Kurzbeschreibung                                   |
| ----------------- | -------------------------------------------------- |
| [signing.ts](../backend/src/lib/signing.ts)        | Health Score Signatur                              |
| [password.ts](../backend/src/lib/password.ts)       | Passworthashing                                    |
| [csrf.ts](../backend/src/lib/csrf.ts)           | Genereller CSRF-Schutz                             |
| [oauthState.ts](../backend/src/lib/oauthState.ts)     | Schutz gegen Login-CSRF                            |
| [pgSessionStore.ts](../backend/src/lib/pgSessionStore.ts) | Nutzersession-Persistierung                        |
| [kvnr.ts](../backend/src/lib/kvnr.ts)           | Validierung und Sicherung von Krankenkassennummern |
| [sampleImport.ts](../backend/src/lib/sampleImport.ts)   | Testdatenimport                                    |
| [mail.ts](../backend/src/lib/mail.ts)           | Client für die E-Mail-Kommunikation                |
|                   |                                                    |

---

### Backend: API

| Datei      | Kurzbeschreibung                                       |
| ---------- | ------------------------------------------------------ |
| [auth.ts](../backend/src/routes/auth.ts)    | Login, Registrierung, Verifikation & Passwort-Reset    |
| [score.ts](../backend/src/routes/score.ts)   | Endpunkte für aktuellen Score, Verlauf & Simulation    |
| [sources.ts](../backend/src/routes/sources.ts) | Quellen-Status, OAuth-Verbindung & Upload-Endpunkte    |
| [share.ts](../backend/src/routes/share.ts)   | Generierung von Freigabe-Tokens & QR-Codes             |
| [insurer.ts](../backend/src/routes/insurer.ts) | Krankenkassenportal, Mitgliedervorteile & Bonusanträge |
| [reports.ts](../backend/src/routes/reports.ts) | Berichte und Auswertungen                              |
| [account.ts](../backend/src/routes/account.ts) | Datenexport und Accountverwaltung                      |

---

### Backend: Datenbank

| Datei      | Kurzbeschreibung               |
| ---------- | ------------------------------ |
| [schema.ts](../backend/src/db/schema.ts)  | Drizzle ORM Schemata           |
| [client.ts](../backend/src/db/client.ts)  | Datenbankclient für PostgreSQL |
| [migrate.ts](../backend/src/db/migrate.ts) | Datenbankmigrationen           |
|            |                                |

---

### Frontend: Shells

| Datei            | Kurzbeschreibung                                    |
| ---------------- | --------------------------------------------------- |
| [router.tsx](../frontend/src/router.tsx)        | Routing auf Clientseite und Authentifizierungslogik |
| [client.ts](../frontend/src/api/client.ts)        | HTTP-Client für die Backendkommunikation            |
| [generated.ts](../frontend/src/api/generated.ts)     | Interfaces basierend auf der OpenAPI-Spezifikation  |
| [tokens.css](../frontend/src/styles/tokens.css)       | Look and Feel in Form von Designtoken               |
| [AppShell.tsx](../frontend/src/routes/AppShell.tsx)     | Nutzerdashboard                                     |
| [PublicShell.tsx](../frontend/src/routes/PublicShell.tsx)  | Landingpage                                         |
| [InsurerShell.tsx](../frontend/src/routes/InsurerShell.tsx) | Krankenkassendashboard                              |
| [AdminShell.tsx](../frontend/src/routes/AdminShell.tsx)   | Admindashboard                                      |
|                  |                                                     |

---

### Frontend: Seiten

| Datei                    | Kurzbeschreibung                         |
| ------------------------ | ---------------------------------------- |
| [Dashboard.tsx](../frontend/src/routes/Dashboard.tsx)            | Score, Vitalitätsalter, Trend und Hebel  |
| [Hebel.tsx](../frontend/src/routes/Hebel.tsx)                | Hebelsimulator                           |
| [Daten.tsx](../frontend/src/routes/Daten.tsx)                | Datenübersicht                           |
| [Freigabe.tsx](../frontend/src/routes/Freigabe.tsx)             | Datenfreigabe für Krankenkassen          |
| [Vorteile.tsx](../frontend/src/routes/Vorteile.tsx)             | Krankenkassenboniübersicht und Einlösung |
| [Verify.tsx](../frontend/src/routes/Verify.tsx)               | Zertifikatsprüfung                       |
| [Landing.tsx](../frontend/src/routes/Landing.tsx)              | Landingpage                              |
| [Login.tsx](../frontend/src/routes/Login.tsx) / [Register.tsx](../frontend/src/routes/Register.tsx) | Authentifizierung & Onboarding           |
| [Report.tsx](../frontend/src/routes/Report.tsx)               | Export der Gesundheitsübersicht          |
| [InsurerOverview.tsx](../frontend/src/routes/InsurerOverview.tsx)      | Kassen-Dashboard                         |
| [InsurerOffers.tsx](../frontend/src/routes/InsurerOffers.tsx)        | Verwaltung der Vorteile                  |
