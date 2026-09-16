# OAuth Developer App Registration Guide (#20)

Diese Anleitung beschreibt Schritt für Schritt, wie Developer-Apps und OAuth-Client-Credentials für **Oura Ring**, **Strava** und **Withings** registriert, konfiguriert und in LONGEVITY hinterlegt werden.

---

## 1. Übersicht der OAuth-Konfigurationen

| Anbieter | Developer-Portal | Benötigte Scopes | Production Redirect-URI | Lokale Dev Redirect-URI | Rate-Limits |
|---|---|---|---|---|---|
| **Withings** | [developer.withings.com](https://developer.withings.com/) | `user.metrics,user.activity` | `https://longevity.maxrommel.de/api/oauth/callback/withings` | `http://localhost:3000/api/oauth/callback/withings` | 120 Requests / Min |
| **Oura Ring** | [cloud.ouraring.com/oauth/developer](https://cloud.ouraring.com/oauth/developer) | `daily` (oder `daily email personal_info`) | `https://longevity.maxrommel.de/api/oauth/callback/oura` | `http://localhost:3000/api/oauth/callback/oura` | 5.000 Requests / 5 Min |
| **Strava** | [strava.com/settings/api](https://www.strava.com/settings/api) | `activity:read_all` | `https://longevity.maxrommel.de/api/oauth/callback/strava` | `http://localhost:3000/api/oauth/callback/strava` | 100 Requests / 15 Min, 1.000 / Tag |
| **Google Fit / Health** | [console.cloud.google.com](https://console.cloud.google.com/) | `googlehealth.activity_and_fitness.readonly`, `googlehealth.sleep.readonly`, `googlehealth.health_metrics_and_measurements.readonly` | `https://longevity.maxrommel.de/api/oauth/callback/google-fit` | `http://localhost:3000/api/oauth/callback/google-fit` | 10.000 Q / Tag |

---

## 2. Withings Developer App Registrierung

1. Navigiere zum [Withings Developer Portal](https://developer.withings.com/) und logge dich ein (oder erstelle einen Account).
2. Klicke auf **Create an application** / **Partner App**.
3. **App Details**:
   - **Application Name**: `LONGEVITY`
   - **Description**: `Biomarker & Health Score Tracking App`
   - **Application Type**: Server-to-Server / Partner Web App
4. **OAuth 2.0 URLs**:
   - **Callback URL / Redirect URI**:
     - `https://longevity.maxrommel.de/api/oauth/callback/withings`
     - Für lokales Testing zusätzlich: `http://localhost:3000/api/oauth/callback/withings`
5. **Credentials notieren**:
   - `Client ID`
   - `Consumer Secret` (Client Secret)

---

## 3. Oura Ring OAuth App Registrierung

1. Öffne das [Oura Cloud Developer Portal](https://cloud.ouraring.com/oauth/developer).
2. Klicke auf **Create New Application**.
3. **App Details**:
   - **App Name**: `LONGEVITY`
   - **Company / Developer Name**: `LONGEVITY Health`
   - **Website URL**: `https://longevity.maxrommel.de`
   - **Redirect URIs**:
     - `https://longevity.maxrommel.de/api/oauth/callback/oura`
     - Für lokales Testing: `http://localhost:3000/api/oauth/callback/oura`
4. **Scopes konfigurieren**:
   - Aktiviere mindestens den Scope `daily` (beinhaltet Daily Sleep, Daily Readiness, Daily Activity).
5. **Credentials notieren**:
   - `Client ID`
   - `Client Secret`

---

## 4. Strava API Application Registrierung

1. Navigiere zu [Strava API Settings](https://www.strava.com/settings/api).
2. Falls noch keine App existiert, erstelle eine neue Anwendung:
   - **Application Name**: `LONGEVITY`
   - **Category**: Health & Fitness
   - **Website**: `https://longevity.maxrommel.de`
   - **Authorization Callback Domain**: `longevity.maxrommel.de` (bzw. `localhost` für Dev)
3. **Redirect-URI**:
   - Strava verwendet Domain-Matching. Der Callback ist:
     `https://longevity.maxrommel.de/api/oauth/callback/strava`
4. **Scopes**:
   - Beim OAuth-Flow fordert LONGEVITY `scope=activity:read_all` an, um Krafttrainings- und Ausdauer-Aktivitäten inklusive Pulszonen zu synchronisieren.
5. **Credentials notieren**:
   - `Client ID`
   - `Client Secret`

---

## 5. Hinterlegung der Credentials

> [!CAUTION]
> Credentials niemals in Git committen!

### A. Auf dem Produktions-Server (`life-server`)
In `/opt/life-server/.env` folgende Zeilen ergänzen (oder in der LONGEVITY-Sektion eintragen):

```bash
# Withings
WITHINGS_CLIENT_ID="<withings_client_id>"
WITHINGS_CLIENT_SECRET="<withings_client_secret>"

# Oura Ring
OURA_CLIENT_ID="<oura_client_id>"
OURA_CLIENT_SECRET="<oura_client_secret>"

# Strava
STRAVA_CLIENT_ID="<strava_client_id>"
STRAVA_CLIENT_SECRET="<strava_client_secret>"
```

Beim nächsten GitHub Actions Deploy werden diese Werte automatisch aus `/opt/life-server/.env` ausgelesen und in den `longevity-api`-Container injiziert.

### B. Als GitHub Secrets (Repository-Ebene)
Alternativ können die Secrets direkt im GitHub Repository `Max-imalgutaussehend/LONGEVITY` unter **Settings** → **Secrets and variables** → **Actions** hinterlegt werden:

- `WITHINGS_CLIENT_ID`
- `WITHINGS_CLIENT_SECRET`
- `OURA_CLIENT_ID`
- `OURA_CLIENT_SECRET`
- `STRAVA_CLIENT_ID`
- `STRAVA_CLIENT_SECRET`

### C. Für lokale Entwicklung (`backend/.env`)
Im lokalen `backend/.env` eintragen:

```env
WITHINGS_CLIENT_ID=...
WITHINGS_CLIENT_SECRET=...
OURA_CLIENT_ID=...
OURA_CLIENT_SECRET=...
STRAVA_CLIENT_ID=...
STRAVA_CLIENT_SECRET=...
```
