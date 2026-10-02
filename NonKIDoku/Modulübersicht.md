# Modulübersicht

## Backend Domänenstruktur

Unser Backend basiert auf einer Domänenbasierten Sturktur (DDA) und trennt strukt nach Verantwortlichkeiten.

### Scoreberechnung (backend/src/score)

- `backend/src/score` beinhaltet die gesamte Berechnungslogik für den Health Score basierend auf den zur Verfügung stehenden Gesundheitsdaten
- Dazu nutzen wir Referenzwerte für verschiedene Altersgruppen, Geschlechter etc. `reference.ts` und verwenden dise um mithilfe statistischer Standardmethoden in `stats.ts` mit den tatsähclichen Messwerten zu korrelieren und daraus letzendlich den Score zu ermitteln
- Zudem implementieren wir eine Plausibilitätsprüfung der Werte in `plausibility.ts` sowie eine Berechnung über welchen Zeitraum Werte gehalten werden `holdingPeriod.ts` um die Aussagekraft des Scores zu gewärhleisten um die Aussagekraft des Scores zu gewärhleisten

### Datenkonnektoren (backend/src/adapters/)

- Die Domäne der Datenkonnektoren implementiert die gesamte Kommunikation mit Gesundheitsapps, Wearableanbietern etc und fungiert als zentrale Schnittstelle für unsere Datenerfassung
- aktuell finden sich hier anbindungen an Apple Health `appleHealth.ts`, Oura `oura.ts`, Strava `strava.ts`, Withings `withings.ts` und Google Fit `googleFit.ts`
- Zusätzlich dazu implementiert `fhir.ts` eine Schnittstelle welche es ermöglicht standardisierte FHIR-Laborbefunde in unsere intern verwendetetn Vitalmesswerte umzuwandeln und somit auch diese Nutzbar zu machen

### Sicherheit (backend/src/rlib)

- In `signing.ts` ist unsere auf ED25519 basierende Signierung von Score-Nachweisen implementiert, welche es den Krankenkassen ermöglicht die richtigkeit und authentizität des Scores sicherzustellen und somit gegen Betrugsversuche zu härten
- `password.ts` beinhaltet das auf dem kryptografisch sicheren Argon2 Verfahern basierte Passworthashing um die Datensicherheit unserer Kunden zu gewährleisten
- Auch die Krankenversichertennummern werden Datenschutzkonform gehashed und zudem bedarf es hier einer verifizierungslogik. Beides findet sich in `kvnr.ts`
- `csrf.rs` und `oauthstate.ts` implementieren zusätzlich eine timing sichere validierung gegen Login und Callback CSRF als zusätzliche Absicherung der Kundendaten
- `pgSessionsStore.ts` implementiert die Verwaltung der aktiven Nutzersitzung

### API (backend/api/routes)

- `auth.ts` beinhaltet die Logik für Registrierung, Login, E-Mail bestätigung und Passwortzurücksetzung und fungiert somit als zentraler Einstiegspunkt für unsere Backend API
- die weiteren Dateien in diesem Ordner Stellen die API Endpunkte in logisch voneinander abgegrenzten Dateien bereit

## Frontend

### Layout Shells (drontend/src/routes)

Um eine übersichtliche UI für Interessierte, Kunden und Versicherer bereitzustellen trennt unser Frontend drei Ansichten in Form von getrennten Anwendungsshells.

1. `AppShell.tsx` - beinhlatet das Dashboard für angemeldete Benutzer und ist somit die zentrale Oberfläche unserer B2C-Kunden
2. `PublicShell.tsx` - fungiert als zentrale Landingspage im Browser die Interessierten einen Überblick über unsere App verschaft und den Anmeldebereich für Bestandskunden und Versicherer anbietet. Sie fungiert somit zeitgleioch als Navigationspoberfläche für Verschiedene Zielgruppen unserer App
3. `InsurerShell.tsx` - diese Oberfläche implementiert die zentrale Übersicht und Konfigurationsumgebung für unsere B2B Kunden und ermöglicht die Pflege neuer Bonusanträge, einsicht von Statistiken etc

### State und Datalayer (frontend/src/api)

Unsere State und Datalayer ist das Gegenstück zur API Schicht im Backend und implementiert auch die Kommunikation mit diesem.
Dazu nutzen wir `client.ts` als zentralen http-client für die Kommunikation mit der Backend API in Kombination mit `generated.ts`, welches typisierte Interfaces für die API Kommunikation bereitstellt und vollständig auf unserer OpenAPI-Spezifikation basiert

### Design System (tokens.css)

Diese Schicht des Frontend ist das zentrum unserer Brand Identity und implementiert das gesamte optische Erscheinungsbild in Form unserer Farbpalette, Schriftarten etc.

## Schnellübersicht
