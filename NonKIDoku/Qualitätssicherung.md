# Tests- und Qualitätssicherungskonzept

## Tests

In vielen Webpanwendungen werden Mocks genutzt, um Komponenten isoliert zu testen. Dabei werden Schnittstellen wie Datenbankabfragen durch falsche "Dummy-Objekte" ersetzt. Das beschleunigt die Ausführung, bringt aber auch Nachteile: Tests laufen zwar grün durch, aber wenn in der echten PostgreSQL-Datenbank ein abweichender Datentyp, ein fehlender Index oder ein Constraint existiert, treten Fehler erst im Produktivbetrieb auf.

Daher ist eine klare Trennung gegeben:

- Jeder der Backend-Integrationstests läuft gegen eine reale PostgreSQL-16-Instanz (lokal mittels Docker Compose, in GitHub Actions über einen Service-Container).
- Der zentrale Aspekt der gesamten Webapp – die Score-Engine – benötigt, wie früher erwähnt, keine Datenbank. Sie wird im Rahmen von sogenannten Golden Master Tests (`backend/src/score/__tests__/golden.test.ts`) mit JSON-Datensätzen gefüttert. Da das mathematische Ergebnis deterministisch ist, fallen falsche Abweichungen sofort auf. Ein Monotonie-Test stellt zudem sicher, dass eine Verbesserung eines Einzelwerts den Gesamtscore niemals senken kann.
- Mit Vitest und jsdom testen wir Berechnungs- und Formatierungsfunktionen im Interface (z. B. die Punkteberechnung bis zum nächsten Score-Band) sowie Labels an Schiebereglern und Formularen (`formLabelA11y`, `sliderA11y`), um Screenreader-Kompatibilität zu garantieren.
- Da vollständige Browser-Tests ressourcen- und zeitintensiv sind, werden nur gezielt die wichtigsten Benutzerreisen im echten Headless-Browser abgedeckt.

## Qualitätssicherung

Da im Entwicklungsprozess auch Künstliche Intelligenz als Hilfe eingesetzt wurde, war ein Qualitätssicherungskonzept sehr wichtig. Halluzinationen oder unsicherer Code soll ausgeschlossen sein. Dafür reichen keine bloßen Bitten (z.B. in einer CLAUDE.md) an Sprachmodelle, sondern nur deterministische Prüfungen, um wirklich sicher zu sein.

Unsere CI/CD-Pipeline in GitHub Actions erzwingt vor jedem Merge auf `dev` oder `main` vier feste Qualitäts-Gates:

1. TypeScript wird im Strict-Mode betrieben; implizite `any`-Typen sind verboten. Typinkonsistenzen zwischen Frontend und Backend werden abgelehnt
2. ESLint(mit `@typescript-eslint`) erzwingt gleiche Formatierung, verbietet ungenutzte Imports/Variablen und sichert Architektur-Grenzen ab (z. B. dass die Score-Engine keine Datenbankmodule importieren darf).
3. Drizzle-SQL-Migrationen laufen fehlerfrei auf der PostgreSQL-Testinstanz durch.
4. Alle Unit- und Integrationstests rennen auf grün durch.

Jeder selbst überprüft Änderungen der KI und jeder Pull Request erfordert mindestens ein Code-Review durch ein anderes Teammitglied, um sicherzugehen, dass Anforderungen, die in den Issues genannt waren, erfüllt werden, und um die Systemarchitektur gegenzuprüfen.
