### Infra

| Datei           | Kurzbeschreibung                            |
| --------------- | ------------------------------------------- |
| start.sh        | Setupslkript für die lokale Entwicklung     |
| compose.dev.yml | Docker Compose für DB, Mailpit, API und Web |
| Caddyfile       | Reverse-Proxy                               |
| index.ts        | Server-Einstiegspunkt                       |
| app.ts          | Fastify, Security und Routenregistierung    |
| env.ts          | Umgebungsvariablen                          |

---

### Backend: Core

| Datei            | Kurzbeschreibung                                         |
| ---------------- | -------------------------------------------------------- |
| index.ts         | Score-Berechnung (0–100), Vitalitätsalter & Hebel-Finder |
| metrics.ts       | Katalog der 15 Vitalmetriken mit Gewichtungen            |
| reference.ts     | Klinische Referenztabellen nach Alter und Geschlecht     |
| stats.ts         | Gaußsche Fehlerfunktion erf, CDF Φ(z) & Clamping         |
| plausibility.ts  | Physiologische Grenzwerte- & Plausibilitätsprüfungen     |
| holdingPeriod.ts | Validierung stabiler Score-Halteperioden (z. B. 60 Tage) |
| types.ts         | Domänen-Typen für Messwerte, Domänen und Scores          |

---

### Backend: Datenkonnektoren und Adapter

| Datei             | Kurzbeschreibung              |
| ----------------- | ----------------------------- |
| appleHealth.ts    | Apple Health Datenimport      |
| appleHealthZip.ts | Apple Health Datenimport      |
| oura.ts           | Oura Ring API-Adapter         |
| withings.ts       | Withings API-Adapter          |
| strava.ts         | Strava API-Adapter            |
| googleFit.ts      | Google Fit API-Adapter        |
| fhir.ts           | Parsing von Laborwertimporten |
|                   |                               |

---

### Backend: Sicherheit

| Datei             | Kurzbeschreibung                                   |
| ----------------- | -------------------------------------------------- |
| signing.ts        | Health Score Signatur                              |
| password.ts       | Passworthashing                                    |
| csrf.ts           | Genereller CSRF Schutz                             |
| oauthState.ts     | Schutz gegen Login CSRF                            |
| pgSessionStore.ts | Nutzensession Persistierung                        |
| kvnr.ts           | Validierung und Sicherung von Krankenkassennummern |
| sampleImport.ts   | Testdatenimport                                    |
| mail.ts           | Client für die E-Mail Kommunikation                |
|                   |                                                    |

---

### Backend: API

| Datei      | Kurzbeschreibung                                       |
| ---------- | ------------------------------------------------------ |
| auth.ts    | Login, Registrierung, Verifikation & Passwort-Reset    |
| score.ts   | Endpunkte für aktuellen Score, Verlauf & Simulation    |
| sources.ts | Quellen-Status, OAuth-Verbindung & Upload-Endpunkte    |
| share.ts   | Generierung von Freigabe-Tokens & QR-Codes             |
| insurer.ts | Krankenkassenprotal, Mitgliedervorteile & Bonusanträge |
| reports.ts | Berichte und Auswertungen                              |
| account.ts | Datenexport und Accountverwaltung                      |

---

### Backend: Datenbank

| Datei      | Kurzbeschreibung               |
| ---------- | ------------------------------ |
| schema.ts  | Drizzle ORM Schemata           |
| client.ts  | Datenbankclient für PostgreSQL |
| migrate.ts | Datenbankmigrationen           |
|            |                                |

---

### Frontend: Shells

| Datei            | Kurzbeschreibung                                    |
| ---------------- | --------------------------------------------------- |
| router.ts        | Routing auf Clientseite und Authentifizierungslogik |
| client.ts        | HTTP-Client für die Backendkommunikation            |
| generated.ts     | Interfaces basierend auf der OpenAPI-Spezifikation  |
| tokens.css       | Look and Feel in Form von Designtoken               |
| AppShell.tsx     | Nutzerdashboard                                     |
| PublicShell.tsx  | Landingpage                                         |
| InsurerShell.tsx | Krankenkassendashboard                              |
| AdminShell.tsx   | Admindashboard                                      |
|                  |                                                     |

---

### Frontend: Seiten

| Datei                    | Kurzbeschreibung                         |
| ------------------------ | ---------------------------------------- |
| Dashboard.tsx            | Score, Vitalitätsalter, Trend und Hebel  |
| Hebel.tsx                | Hebelsimulator                           |
| Daten.tsx                | Datenübersicht                           |
| Freigabe.tsx             | Datenfreigabe für Krankenkassen          |
| Vorteile.tsx             | Krankenkassenboniübersicht und Einlösung |
| Verify.tsx               | Zertifikatprüfung                        |
| Landing.tsx              | Landingpage                              |
| Login.tsx / Register.tsx | Authentifizierung & Onboarding           |
| Report.tsx               | Export der Gesundheitsübersicht          |
| InsurerOverview.tsx      | Kassen-Dashboard                         |
| InsurerOffers.tsx        | Verwaltung der Vorteile                  |
