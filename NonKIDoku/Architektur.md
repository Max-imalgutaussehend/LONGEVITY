## High-Level-Architektur

Das Projekt ist als Monorepo mit jeweils zwei eigenständigen Submodulen für das Backend und das Frontend strukturiert.
Backend-Repository: `longevity-backend`
Frontend-Repository: `longevity-frontend`
Das Monorepo LONGEVITY beinhaltet außerdem einen Ordner `infra`, welcher die Infrastrukturkonfiguration für z. B. Docker enthält.

## Schichtenarchitektur

```mermaid
flowchart LR
    f[Frontend]
    api[Backend API]
    core[Core Logik]
    adap[Adapter & Ingestion]
    db[Datenbank]

    f-->api
    api-->core
    core-->adap
    core-->db
```

1. Frontend als Präsentationsschicht
2. Backend-API

- Diese Schicht bildet den Eingang unseres Backends und implementiert die eigentliche REST-API, welche die Anfragen des Frontends entgegennimmt
- Zudem sind hier Authentifizierung, Autorisierung und ein Rate-Limiting implementiert

3. Core-Logik

- Die Core-Logik beinhaltet hauptsächlich die Scoreberechnung und trennt externe Datenaufrufe klar von unserer mathematischen Berechnungsgrundlage
- Wir importieren hier keine externen Aufrufe, sondern sorgen für eine isolierte deterministische Berechnung des Health Scores

4. Konnektoren und Adapter

- Externe Datenformate und die Datenbeschaffung der Gesundheitsanbieter etc. sind in der Adapter- und Ingestionsschicht angesiedelt
- Hier sind sämtliche Kommunikationen mit externen Diensten implementiert, um die Daten für die im Core isolierte Scoreberechnung bereitzustellen

5. Datenbank

- Für die Persistenz der Daten verwenden wir eine PostgreSQL-Datenbank in Kombination mit Drizzle als ORM
