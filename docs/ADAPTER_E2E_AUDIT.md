# Adapter End-to-End-Audit & Account-Verifikation (#19)

Dieses Dokument fasst die Ergebnisse des End-to-End-Checks aller 8 Datenquellen-Adapter in LONGEVITY zusammen. Es dokumentiert den Integrationsstatus, unterstützte Metriken, API-Beschränkungen, Rate-Limits, gefundene Edge-Cases sowie den Status bezüglich echter Developer-Accounts und OAuth-Registrierungen.

---

## 1. Übersichtstabelle

| # | Adapter / Anbieter | Typ / Transport | OAuth- / Dev-App Status | E2E-Pipeline Verifikation | Unterstützte Metriken | Rate Limits | Status & Einschränkungen |
|---|-------------------|----------------|-------------------------|--------------------------|-------------|-------------|--------------------------|
| **1** | **Apple Health (XML)** | Direkter XML-Upload (`/api/sources/apple-health/upload`) | Kein Dev-Account nötig (lokaler iOS-Export) | **Verifiziert** (E2E Test) | `steps`, `resting_hr`, `sleep_duration`, `systolic_bp`, `hrv_rmssd`, `vo2max`, `waist`, `zone2_minutes`, `strength_sessions` | Durch Fastify Multipart Limit (500 MB) begrenzt | Funktioniert vollständig. Benötigt Geburtsdatum für HRmax-Berechnung (Zone 2). |
| **2** | **Apple Health ZIP** | Archiv-Upload (`.zip` mit `Export.xml`) | Kein Dev-Account nötig (Standard iOS Health Export) | **Verifiziert** (E2E Test) | Identisch zu Apple Health XML | 500 MB ZIP-Größe | Extrahiert `apple_health_export/Export.xml` via Streaming (`yauzl`). Vollständig kompatibel mit Original-iOS-Archiven. |
| **3** | **Health Auto Export** | JSON Webhook (`/api/sources/health-auto-export/webhook`) | Kein Dev-Account nötig (App-basierte Webhook-Konfiguration) | **Verifiziert** (E2E Test) | `steps`, `resting_hr`, `hrv_rmssd`, `vo2max`, `systolic_bp`, `sleep_duration`, `sleep_consistency`, `waist`, `zone2_minutes`, `strength_sessions` | Webhook-Frequenz vom Nutzer in App steuerbar | Unterstützt sowohl flaches als auch verschachteltes JSON-Format. Berechnet Schlaf-Konsistenz zirkulär ab 12:00 Uhr mittags. |
| **4** | **FHIR (Laborwerte)** | JSON Resource/Bundle Upload (`/api/sources/fhir/upload`) | Kein Dev-Account nötig (Standard FHIR R4 Bundle) | **Verifiziert** (E2E Test) | `ldl`, `hdl`, `hba1c`, `hscrp`, `systolic_bp` | 5 MB Body Limit | Erkennt LOINC-Codes `13457-7`, `2085-9`, `4548-4`, `30522-7`, `8480-6`. Automatische Einheitenkonvertierung (`mmol/L` → `mg/dL`, `mmol/mol` IFCC → `%` DCCT). |
| **5** | **Withings** | OAuth 2.0 + REST API (`getmeas`, `getactivity`, `sleep/get`) | Developer-App erforderlich (`WITHINGS_CLIENT_ID/SECRET`, Ref #20) | **Verifiziert** (E2E Mock/Pipeline) | `systolic_bp`, `resting_hr`, `steps`, `sleep_duration` | 120 Anfragen / Minute | Nutzt exponentielle Einheiten-Skalierung (`value * 10^unit`). Token-Refresh und Fehlerklassifikation implementiert (#21). |
| **6** | **Google Fit & Health Connect** | OAuth 2.0 + REST API / Health Connect v4 | Google Cloud Console OAuth App erforderlich (`GOOGLE_FIT_CLIENT_ID/SECRET`) | **Verifiziert** (E2E Test mit Multi-Tracker Deduplizierung) | `steps`, `resting_hr`, `sleep_duration`, `zone2_minutes`, `vo2max`, `strength_sessions` | Standard Google API Quota (z.B. 10.000 Q/Tag) | Umfassende Deduplizierung gleichzeitiger Trackersignale (Fitbit vs. Google Fit vs. Health Connect Daemon) implementiert (#73). |
| **7** | **Oura Ring** | OAuth 2.0 + API v2 (`daily_sleep`, `daily_readiness`, `daily_activity`) | Oura Developer Account erforderlich (`OURA_CLIENT_ID/SECRET`, Ref #20) | **Verifiziert** (E2E Mock/Pipeline & Bugfix) | `sleep_duration`, `sleep_consistency`, `hrv_rmssd`, `resting_hr`, `steps`, `zone2_minutes` | 5.000 Anfragen / 5 Minuten | **Bugfix vorgenommen**: Schlaf-Einschlafzeiten wurden bei Mitternacht-Wechsel (z.B. 23:45 auf 00:15) verzerrt; jetzt normalisiert auf Minuten ab 12:00 Uhr mittags. |
| **8** | **Strava** | OAuth 2.0 + API v3 (`activities`, `activities/{id}/zones`) | Strava API Application erforderlich (`STRAVA_CLIENT_ID/SECRET`, Ref #20) | **Verifiziert** (E2E Mock/Pipeline) | `strength_sessions`, `zone2_minutes` | 100 Anfragen / 15 Min, 1.000 / Tag | **Achtung**: Zone-2-Ermittlung benötigt Detail-Aufruf pro Aktivität (`/zones`). Kann bei Viel-Trainierern an das 100-Requests-Limit stoßen. |

---

## 2. Detaillierte Adapter-Befunde & Edge-Cases

### 2.1 Apple Health XML & ZIP
- **Funktionsweise**: Streaming-Parser liest zeilenweise XML-Tags (`<Record>`, `<Workout>`, `<Correlation>`, `<Me>`), wodurch auch 2–4 GB große Exportdateien ohne Memory-Overflow verarbeitet werden.
- **Validierung**:
  - `steps` und `resting_hr` werden direkt aus HKQuantityTypes gelesen.
  - Blutdruck-Messungen aus `<Correlation>`-Tags werden als `systolic_bp` erfasst.
  - Workouts (`TraditionalStrengthTraining`, `CrossTraining`, etc.) werden als Krafttrainings-Einheiten erkannt.
  - Zone 2 wird dynamisch über die Herzfrequenz und das Alter (`220 - Alter`) im Pulsbereich 60–70% HRmax berechnet.
- **Besonderheiten**: ZIP-Import (`appleHealthZip.ts`) öffnet das Archiv mit `yauzl` und sucht gezielt nach `apple_health_export/Export.xml`.

### 2.2 Health Auto Export
- **Funktionsweise**: Nimmt strukturierte JSON-Paylods via HTTP-Webhook von der iOS-App *Health Auto Export* entgegen.
- **Validierung**:
  - Parst sowohl das ältere Array-Format (`[{name: "HeartRate", data: [...]}]`) als auch das neuere Format (`{ metrics: [...], workouts: [...] }`).
  - Berechnet `sleep_consistency` als Standardabweichung der Einschlafzeit. Die Einschlafzeiten werden relativ zu 12:00 Uhr mittags gemessen, sodass Schlaf nach Mitternacht (z.B. 01:00) nahtlos an 23:30 anschließt.
  - Zone-2-Minuten werden aus Workouts mit durchschnittlicher Herzfrequenz im Bereich 60–70% von `220 - Alter` summiert.

### 2.3 FHIR (Fast Healthcare Interoperability Resources)
- **Funktionsweise**: Importiert Labor- und Vitalwertberichte im FHIR R4 JSON-Format (z.B. aus Krankenhaus-Portalen oder Labor-Systemen).
- **Validierung**:
  - Erkennt LOINC-Standardcodes:
    - `13457-7`: LDL-Cholesterin (`mg/dL`, Umrechnung von `mmol/L` via Faktor 38.67)
    - `2085-9`: HDL-Cholesterin (`mg/dL`, Umrechnung von `mmol/L`)
    - `4548-4`: HbA1c (`%`, Umrechnung von `mmol/mol` via `(x / 10.929) + 2.15`)
    - `30522-7`: hsCRP (`mg/L`, Umrechnung von `mg/dL` oder `µg/L`)
    - `8480-6`: Systolischer Blutdruck (`mmHg`)
  - Unterstützt sowohl einzelne `Observation`-Ressourcen als auch verschachtelte `Bundle`-Ressourcen.

### 2.4 Withings
- **OAuth-Status**: Endpunkte und Callbacks implementiert (`/api/sources/withings/connect`, `/api/oauth/callback/withings`). Für Produktivbetrieb müssen Withings Developer Credentials beschafft werden (siehe Issue #20).
- **API-Payload**:
  - `measuregrps`: Liest `type 9` (Systolischer Blutdruck) und `type 11` (Puls) aus. Skalierung: `value * 10^unit`.
  - `activities`: Liest tägliche Schritte (`steps`) aus.
  - `series`: Berechnet Schlafdauer aus `enddate - startdate`.

### 2.5 Google Fit & Health Connect
- **OAuth-Status**: Unterstützt Google OAuth 2.0 mit Google Health Connect Scopes.
- **Besonderheit**:
  - Behandelt sowohl historische Google Fit REST Aggregate Buckets als auch moderne Google Health Connect v4 Intraday DataPoints.
  - Multi-Tracker-Deduplizierung: Wenn Nutzer gleichzeitig Fitbit, eine Wearable-App und den Health Connect Smartphone-Hintergrunddienst aktiv haben, priorisiert der Adapter zuverlässige Tracker (`com.google.android.apps.fitness` > `fitbit` > `healthdata`) und verhindert eine Mehrfach-Zählung der Schritte.

### 2.6 Oura Ring
- **OAuth-Status**: OAuth v2 Endpunkte vorhanden (`cloud.ouraring.com/oauth/authorize`). Benötigt Oura API App (Issue #20).
- **Behobener Bug**:
  - In `backend/src/adapters/oura.ts` wurde die Einschlafzeit zuvor als `hour * 60 + minute` erfasst. Ging ein Nutzer an Tag 1 um 23:45 Uhr schlafen (1425 Min) und an Tag 2 um 00:15 Uhr (15 Min), ergab sich fälschlicherweise eine Standardabweichung von über 10 Stunden (~700 Min).
  - Behoben durch Normalisierung der Einschlafzeit relativ zu 12:00 Uhr mittags (`hour >= 12 ? (hour - 12) * 60 + minute : (hour + 12) * 60 + minute`), analog zu Apple Health.

### 2.7 Strava
- **OAuth-Status**: Strava API v3 OAuth implementiert. Benötigt Strava API Application (Issue #20).
- **Architektur & Rate-Limit-Befund**:
  - Strava liefert Herzfrequenzzonen nicht in der Hauptaktivitätsliste, sondern erfordert einen separaten API-Aufruf pro Aktivität (`/api/v3/activities/{id}/zones`).
  - **Identifiziertes Risiko**: Werden 50 Aktivitäten auf einmal synchronisiert, führt `Promise.all` zu 50 parallelen Requests. Strava limitiert auf 100 Requests pro 15 Minuten.
  - **Empfehlung**: Für Folge-Issue ein Batching/Rate-Limiting (z.B. p-limit mit max. 5 parallelen Requests) bzw. nur die letzten N Tage/Aktivitäten abzufragen.

---

## 3. Automatisierte E2E-Testsuite

Die neu erstellte Testsuite `backend/src/__tests__/sourcesE2E.integration.test.ts` führt alle 8 Adapter automatisiert gegen eine echte PostgreSQL-Datenbank aus:
1. Erstellen isolierter Test-Nutzer.
2. Parsen und Validieren der echten Rohdaten-Fixtures je Adapter.
3. Persistieren der Quellen und Samples in der Datenbank (`samples` & `sources`).
4. Berechnung des Scores und der Domain-Scores (`cardiometabolic`, `recovery`, `activity`, `risk`) via `computeScore()`.
5. Verifikation, dass alle Metriken korrekt in den Longevity-Score einfließen.
