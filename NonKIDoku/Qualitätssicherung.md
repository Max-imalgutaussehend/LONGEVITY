# Test- und Qualitätssicherungskonzept

## Tests

In vielen Webanwendungen werden Mocks genutzt, um Komponenten isoliert zu testen. Dabei werden Schnittstellen wie Datenbankabfragen durch falsche "Dummy-Objekte" ersetzt. Das beschleunigt die Ausführung, bringt aber auch Nachteile: Tests laufen zwar grün durch, aber wenn in der echten PostgreSQL-Datenbank ein abweichender Datentyp, ein fehlender Index oder ein Constraint existiert, treten Fehler erst im Produktivbetrieb auf.

Daher ist eine klare Trennung gegeben:

- Jeder der Backend-Integrationstests läuft gegen eine reale PostgreSQL-16-Instanz (lokal mittels Docker Compose, in [GitHub Actions](https://github.com/Max-imalgutaussehend/LONGEVITY/blob/main/.github/workflows/ci.yml) über einen Service-Container).
- Der zentrale Aspekt der gesamten Webapp – die Score-Engine – benötigt, wie früher erwähnt, keine Datenbank. Sie wird im Rahmen von sogenannten Golden Master Tests ([`backend/src/score/__tests__/golden.test.ts`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/score/__tests__/golden.test.ts)) mit JSON-Datensätzen gefüttert. Da das mathematische Ergebnis deterministisch ist, fallen falsche Abweichungen sofort auf. Ein Monotonie-Test stellt zudem sicher, dass eine Verbesserung eines Einzelwerts den Gesamtscore niemals senken kann.
- Mit Vitest und jsdom testen wir Berechnungs- und Formatierungsfunktionen im Interface (z. B. die Punkteberechnung bis zum nächsten Score-Band) sowie Labels an Schiebereglern und Formularen ([`formLabelA11y`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/__tests__/formLabelA11y.test.ts), [`sliderA11y`](https://github.com/Max-imalgutaussehend/longevity-frontend/blob/main/src/__tests__/sliderA11y.test.ts)), um Screenreader-Kompatibilität zu garantieren.
- Da vollständige Browser-Tests ressourcen- und zeitintensiv sind, werden nur die wichtigsten Benutzerreisen im echten Headless-Browser abgedeckt.

## Qualitätssicherung

Da im Entwicklungsprozess auch Künstliche Intelligenz als Hilfe eingesetzt wurde, war ein Qualitätssicherungskonzept sehr wichtig. Halluzinationen oder unsicherer Code soll ausgeschlossen sein. Dafür reichen keine Bitten (z. B. in einer `CLAUDE.md`) an Sprachmodelle, sondern nur tatsächliche Prüfungen, um wirklich sicher zu sein.

Unsere CI/CD-Pipeline in [GitHub Actions](https://github.com/Max-imalgutaussehend/LONGEVITY/blob/main/.github/workflows/ci.yml) hat vor jedem Merge auf `dev` oder `main` vier Qualitäts-Gates:

1. TypeScript wird im Strict-Mode betrieben; implizite `any`-Typen sind dadurch ausgeschlossen. Typinkonsistenzen zwischen Frontend und Backend werden abgelehnt.
2. ESLint (mit `@typescript-eslint`) erzwingt gleiche Formatierung, verbietet ungenutzte Imports/Variablen und sichert Architektur-Grenzen ab (z. B. dass die Score-Engine keine Datenbankmodule importieren darf).
3. [Drizzle-SQL-Migrationen](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/db/migrations) laufen fehlerfrei auf der PostgreSQL-Testinstanz durch.
4. Alle Unit- und Integrationstests laufen grün durch.

Jeder selbst überprüft Änderungen der KI und jeder Pull Request erfordert mindestens ein Code-Review durch ein anderes Teammitglied, um sicherzugehen, dass Anforderungen, die in den Issues genannt waren, erfüllt werden, und um die Systemarchitektur gegenzuprüfen.

## Test Coverage

Um zu sehen, wie viel wir von dem Code durch Tests abgedeckt haben, nutzen wir die V8-Coverage-Messung (`pnpm test:coverage`).

Die Test-Suite besteht insgesamt aus 91 Testdateien mit 684 Tests (464 im Backend, 220 im Frontend), die alle zu 100 % grün durchlaufen:

### 1. Gesamtübersicht der Testabdeckung

| Repository / Bereich | Testdateien | Tests | Statements | Branches | Functions | Lines  |
| :------------------- | :---------: | :---: | :--------: | :------: | :-------: | :----: |
| **Backend**          |     63      |  464  |   77.50%   |  73.15%  |  81.57%   | 77.50% |
| **Frontend**         |     28      |  220  |   31.71%   |  66.48%  |  33.11%   | 31.71% |

- **Backend:** Hohe Testabdeckung (77,50 % Statements & Zeilen, 73,15 % Branches, 81,57 % Functions), die durch umfassende Unit- und reale Integrations-Tests erreicht wird.
- **Frontend (31,71 %):** Alle mathematischen Berechnungs-, Validierungs- und Zustandskerne im Frontend weisen eine isolierte Unit-Test-Abdeckung von 90–100 % auf. Da das Frontend darüber hinaus zu großen Teilen aus deklarativem JSX-Markup, Layout-Containern und CSS-Komponenten besteht, die visuell wirken und keine verzweigte Businesslogik enthalten, fällt die zeilenbasierte Abdeckung hier naturgemäß geringer aus. Die automatisierten Playwright-End-to-End-Tests decken ergänzend die echten Benutzerinteraktionen, Klicks und Browser-Workflows im Gesamtzusammenhang ab.
