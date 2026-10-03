# Modulübersicht

## Backend-Domänenstruktur

Unser Backend basiert auf einer domänenbasierten Struktur (DDA) und trennt strikt nach Verantwortlichkeiten.

### Scoreberechnung ([backend/src/score](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/score))

- [`backend/src/score`](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/score) beinhaltet die gesamte Berechnungslogik für den Health Score basierend auf den zur Verfügung stehenden Gesundheitsdaten
- Dazu nutzen wir Referenzwerte für verschiedene Altersgruppen, Geschlechter etc. [`reference.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/reference.ts) und verwenden diese, um mithilfe statistischer Standardmethoden in [`stats.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/stats.ts) mit den tatsächlichen Messwerten zu korrelieren und daraus letztendlich den Score zu ermitteln
- Zudem implementieren wir eine Plausibilitätsprüfung der Werte in [`plausibility.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/plausibility.ts) sowie eine Berechnung, über welchen Zeitraum Werte gehalten werden [`holdingPeriod.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/holdingPeriod.ts), um die Aussagekraft des Scores zu gewährleisten

### Datenkonnektoren ([backend/src/adapters/](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/adapters))

- Die Domäne der Datenkonnektoren implementiert die gesamte Kommunikation mit Gesundheitsapps, Wearableanbietern etc. und fungiert als zentrale Schnittstelle für unsere Datenerfassung
- Aktuell finden sich hier Anbindungen an Apple Health [`appleHealth.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/appleHealth.ts), Oura [`oura.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/oura.ts), Strava [`strava.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/strava.ts), Withings [`withings.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/withings.ts) und Google Fit [`googleFit.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/googleFit.ts)
- Zusätzlich dazu implementiert [`fhir.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/adapters/fhir.ts) eine Schnittstelle, welche es ermöglicht, standardisierte FHIR-Laborbefunde in unsere intern verwendeten Vitalmesswerte umzuwandeln und somit auch diese nutzbar zu machen

### Sicherheit ([backend/src/lib](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/lib))

- In [`signing.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/signing.ts) ist unsere auf Ed25519 basierende Signierung von Score-Nachweisen implementiert, welche es den Krankenkassen ermöglicht, die Richtigkeit und Authentizität des Scores sicherzustellen und somit gegen Betrugsversuche zu härten
- [`password.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/password.ts) beinhaltet das auf dem kryptografisch sicheren Argon2-Verfahren basierte Passworthashing, um die Datensicherheit unserer Kunden zu gewährleisten
- Auch die Krankenversichertennummern werden datenschutzkonform gehasht und zudem bedarf es hier einer Verifizierungslogik. Beides findet sich in [`kvnr.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/kvnr.ts)
- [`csrf.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/csrf.ts) und [`oauthState.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/oauthState.ts) implementieren zusätzlich eine timingsichere Validierung gegen Login- und Callback-CSRF als zusätzliche Absicherung der Kundendaten
- [`pgSessionStore.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/lib/pgSessionStore.ts) implementiert die Verwaltung der aktiven Nutzersitzung

### API ([backend/src/routes](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/routes))

- [`auth.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/routes/auth.ts) beinhaltet die Logik für Registrierung, Login, E-Mail-Bestätigung und Passwortzurücksetzung und fungiert somit als zentraler Einstiegspunkt für unsere Backend-API
- Die weiteren Dateien in diesem Ordner stellen die API-Endpunkte in logisch voneinander abgegrenzten Dateien bereit

## Frontend

### Layout Shells ([frontend/src/routes](https://github.com/Max-imalgutaussehend/longevity-frontend/tree/main/src/routes))

Um eine übersichtliche UI für Interessierte, Kunden und Versicherer bereitzustellen, trennt unser Frontend drei Ansichten in Form von getrennten Anwendungsshells.

1. [`AppShell.tsx`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/AppShell.tsx) - beinhaltet das Dashboard für angemeldete Benutzer und ist somit die zentrale Oberfläche unserer B2C-Kunden
2. [`PublicShell.tsx`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/PublicShell.tsx) - fungiert als zentrale Landingpage im Browser, die Interessierten einen Überblick über unsere App verschafft und den Anmeldebereich für Bestandskunden und Versicherer anbietet. Sie fungiert somit zeitgleich als Navigationsoberfläche für verschiedene Zielgruppen unserer App
3. [`InsurerShell.tsx`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/routes/InsurerShell.tsx) - diese Oberfläche implementiert die zentrale Übersicht und Konfigurationsumgebung für unsere B2B-Kunden und ermöglicht die Pflege neuer Bonusanträge, Einsicht von Statistiken etc.

### State und Datalayer ([frontend/src/api](https://github.com/Max-imalgutaussehend/longevity-frontend/tree/main/src/api))

Unser State- und Datalayer ist das Gegenstück zur API-Schicht im Backend und implementiert auch die Kommunikation mit diesem.
Dazu nutzen wir [`client.ts`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/api/client.ts) als zentralen HTTP-Client für die Kommunikation mit der Backend-API in Kombination mit [`generated.ts`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/api/generated.ts), welches typisierte Interfaces für die API-Kommunikation bereitstellt und vollständig auf unserer OpenAPI-Spezifikation basiert.

### Design System ([tokens.css](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/styles/tokens.css))

Diese Schicht des Frontends ist das Zentrum unserer Brand Identity und implementiert das gesamte optische Erscheinungsbild in Form unserer Farbpalette, Schriftarten etc.
