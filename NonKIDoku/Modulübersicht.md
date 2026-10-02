# Modulübersicht

## Backend-Domänenstruktur

Unser Backend basiert auf einer domänenbasierten Struktur (DDA) und trennt strikt nach Verantwortlichkeiten.

### Scoreberechnung ([backend/src/score](../backend/src/score))

- [`backend/src/score`](../backend/src/score) beinhaltet die gesamte Berechnungslogik für den Health Score basierend auf den zur Verfügung stehenden Gesundheitsdaten
- Dazu nutzen wir Referenzwerte für verschiedene Altersgruppen, Geschlechter etc. [`reference.ts`](../backend/src/score/reference.ts) und verwenden diese, um mithilfe statistischer Standardmethoden in [`stats.ts`](../backend/src/score/stats.ts) mit den tatsächlichen Messwerten zu korrelieren und daraus letztendlich den Score zu ermitteln
- Zudem implementieren wir eine Plausibilitätsprüfung der Werte in [`plausibility.ts`](../backend/src/score/plausibility.ts) sowie eine Berechnung, über welchen Zeitraum Werte gehalten werden [`holdingPeriod.ts`](../backend/src/score/holdingPeriod.ts), um die Aussagekraft des Scores zu gewährleisten

### Datenkonnektoren ([backend/src/adapters/](../backend/src/adapters/))

- Die Domäne der Datenkonnektoren implementiert die gesamte Kommunikation mit Gesundheitsapps, Wearableanbietern etc. und fungiert als zentrale Schnittstelle für unsere Datenerfassung
- Aktuell finden sich hier Anbindungen an Apple Health [`appleHealth.ts`](../backend/src/adapters/appleHealth.ts), Oura [`oura.ts`](../backend/src/adapters/oura.ts), Strava [`strava.ts`](../backend/src/adapters/strava.ts), Withings [`withings.ts`](../backend/src/adapters/withings.ts) und Google Fit [`googleFit.ts`](../backend/src/adapters/googleFit.ts)
- Zusätzlich dazu implementiert [`fhir.ts`](../backend/src/adapters/fhir.ts) eine Schnittstelle, welche es ermöglicht, standardisierte FHIR-Laborbefunde in unsere intern verwendeten Vitalmesswerte umzuwandeln und somit auch diese nutzbar zu machen

### Sicherheit ([backend/src/lib](../backend/src/lib))

- In [`signing.ts`](../backend/src/lib/signing.ts) ist unsere auf ED25519 basierende Signierung von Score-Nachweisen implementiert, welche es den Krankenkassen ermöglicht, die Richtigkeit und Authentizität des Scores sicherzustellen und somit gegen Betrugsversuche zu härten
- [`password.ts`](../backend/src/lib/password.ts) beinhaltet das auf dem kryptografisch sicheren Argon2-Verfahren basierte Passworthashing, um die Datensicherheit unserer Kunden zu gewährleisten
- Auch die Krankenversichertennummern werden datenschutzkonform gehasht und zudem bedarf es hier einer Verifizierungslogik. Beides findet sich in [`kvnr.ts`](../backend/src/lib/kvnr.ts)
- [`csrf.ts`](../backend/src/lib/csrf.ts) und [`oauthState.ts`](../backend/src/lib/oauthState.ts) implementieren zusätzlich eine timingsichere Validierung gegen Login- und Callback-CSRF als zusätzliche Absicherung der Kundendaten
- [`pgSessionStore.ts`](../backend/src/lib/pgSessionStore.ts) implementiert die Verwaltung der aktiven Nutzersitzung

### API ([backend/src/routes](../backend/src/routes))

- [`auth.ts`](../backend/src/routes/auth.ts) beinhaltet die Logik für Registrierung, Login, E-Mail-Bestätigung und Passwortzurücksetzung und fungiert somit als zentraler Einstiegspunkt für unsere Backend-API
- Die weiteren Dateien in diesem Ordner stellen die API-Endpunkte in logisch voneinander abgegrenzten Dateien bereit

## Frontend

### Layout Shells ([frontend/src/routes](../frontend/src/routes))

Um eine übersichtliche UI für Interessierte, Kunden und Versicherer bereitzustellen, trennt unser Frontend drei Ansichten in Form von getrennten Anwendungsshells.

1. [`AppShell.tsx`](../frontend/src/routes/AppShell.tsx) - beinhaltet das Dashboard für angemeldete Benutzer und ist somit die zentrale Oberfläche unserer B2C-Kunden
2. [`PublicShell.tsx`](../frontend/src/routes/PublicShell.tsx) - fungiert als zentrale Landingpage im Browser, die Interessierten einen Überblick über unsere App verschafft und den Anmeldebereich für Bestandskunden und Versicherer anbietet. Sie fungiert somit zeitgleich als Navigationsoberfläche für verschiedene Zielgruppen unserer App
3. [`InsurerShell.tsx`](../frontend/src/routes/InsurerShell.tsx) - diese Oberfläche implementiert die zentrale Übersicht und Konfigurationsumgebung für unsere B2B-Kunden und ermöglicht die Pflege neuer Bonusanträge, Einsicht von Statistiken etc.

### State und Datalayer ([frontend/src/api](../frontend/src/api))

Unser State- und Datalayer ist das Gegenstück zur API-Schicht im Backend und implementiert auch die Kommunikation mit diesem.
Dazu nutzen wir [`client.ts`](../frontend/src/api/client.ts) als zentralen HTTP-Client für die Kommunikation mit der Backend-API in Kombination mit [`generated.ts`](../frontend/src/api/generated.ts), welches typisierte Interfaces für die API-Kommunikation bereitstellt und vollständig auf unserer OpenAPI-Spezifikation basiert

### Design System ([tokens.css](../frontend/src/styles/tokens.css))

Diese Schicht des Frontends ist das Zentrum unserer Brand Identity und implementiert das gesamte optische Erscheinungsbild in Form unserer Farbpalette, Schriftarten etc.

## Schnellübersicht
