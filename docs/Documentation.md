## Frontend und Backend Datenfluss

### Authentifizierung

Bevor die grundlegende Kommunikation zwischen Front- und Backend funktionieren kann, ist es wichtig, dass sich der User authentifiziert, sodass das Backend die nötigen Daten zur Verfügung stellen kann. Sobald sich ein User anmeldet und die Anmeldedaten im Backend als gültig überprüft wurden (E-Mail existiert und der mit Argon2id geprüfte Passwort-Hash stimmt überein), wird eine Session-ID erstellt, die in der Datenbank (Tabelle `sessions`) gespeichert wird und dem jeweiligen User zugeordnet ist.

Diese Session-ID wird danach an das Frontend zurückgesendet - das passiert über einen `Set-Cookie`-Header mit dem Sicherheitsflag `HttpOnly`. Dadurch speichert der JavaScript-Code den Cookie nicht manuell ab, sondern der Webbrowser verwahrt es selbstständig in einem geschützten Speicher und sendet es bei jedem weiteren Request automatisch im Hintergrund mit. Da Frontend-JavaScript keinen Lesezugriff auf dieses Cookie hat, ist das Verfahren gegen Angriffe wie durch Cross-Site-Scripting (sogenannt XSS) geschützt.

### Datenfluss im Frontend

Nehmen wir an, der User öffnet das Dashboard. Hierzu sind viele Datenabfragen wichtig, eine davon: Welchen Score hat der User? Um diese Anfrage erfolgreich zu erfüllen, wird der Request über das Framework TanStack Query abgehandelt. Dieses Framework erstellt einen Cache, cached und validiert somit bestimmte Datenpunkte, die abgefragt werden: Sollte ein User seinen Score abfragen, so muss dieser bei erneutem Aufruf nicht jedes Mal sofort vom Backend geliefert werden, sondern kann direkt aus dem Cache angezeigt werden. Somit können Seitenwechsel - wenn der User zum Beispiel von „Dashboard“ auf „Hebel“ und wieder zurückgeht - ohne erneute Backend-Anfrage und somit mit sofortiger Informationsanzeige abgehandelt werden.

Dieser Cache gilt standardmäßig für 30 Sekunden als valide (`staleTime: 30_000` ms). Erst danach würde im Hintergrund eine erneute Backend-Anfrage ausgeführt werden, um veraltete Daten zu aktualisieren. Sobald der User selbst eine Änderung vornimmt (u.a. neue Messdaten einträgt), wird der Cache gezielt invalidiert, damit die neu berechneten Aktualisierungen sofort sichtbar werden.

Für Anfragen an das Backend ruft TanStack Query dabei die zentrale Hilfsfunktion `apiClient` auf. Diese setzt die Option `credentials: 'include'` (damit der Browser das geschützte Session-Cookie mitsendet) und fügt bei schreibenden Anfragen (POST/PUT/DELETE) automatisch das CSRF-Schutztoken in den Header ein. Im Frontend existiert zudem die Datei `frontend/src/api/generated.ts`, welche den API-Contract vom Backend direkt ins Frontend einbindet. Damit die beiden Stacks trotzdem lose gekoppelt bleiben, teilen sie sich keine gemeinsamen Code-Dateien. Die Datei wird stattdessen automatisiert durch ein Skript (`pnpm gen:api`) aus der vom Backend bereitgestellten `backend/openapi.json` generiert.

### Datenfluss im Backend

API-Anfragen kommen im Backend zuerst bei der Middleware-Pipeline an, bei der wir Fastify als Web-Framework einsetzen. Davon nutzen wir unter anderem `@fastify/helmet`, um über HTTP-Header sicherzustellen, dass keine böswilligen Skripte ausgeführt oder Seiten in fremde Frames eingebettet werden können. Zudem nutzen wir `@fastify/rate-limit`, wodurch wir Anfragen auf 120 Anfragen pro Minute pro IP einschränken (auf sensiblen Routen wie Login noch strenger), um einen DDoS- und Brute-Force-Schutz zu haben. Danach liest ein Cookie-Parser die mitgeschickten Header aus, insbesondere die unter Authentifizierung genannte Session-ID.

Diese Session-ID wird über `PgSessionStore` mit der Datenbank abgeglichen. Ist die Session dort als gültig und nicht abgelaufen gespeichert, wird die Variable `userId` an das Fastify-Request-Objekt angehängt. Über die Hilfsfunktion `requireUser` kann jede geschützte Route sofort prüfen, zu welchem Account die Anfrage gehört – fehlt die ID, bricht der Request mit HTTP 401 ab.

Der zuständige Route-Handler führt nun seine Logik aus. Um bei unserem Beispiel zu bleiben: Der Score muss berechnet werden. Die Rohdaten hierfür liegen in den PostgreSQL-Tabellen `samples` (Gesundheitsdaten) und `users` (biologisches Geschlecht und Geburtsdatum). Mithilfe der am Request anliegenden `userId` können diese passend abgefragt werden. Statt selbstgeschriebenen SQL Statements nutzen wir das ORM Drizzle. Eine Abfrage sieht beispielsweise so aus:

```typescript
db.select().from(samples).where(eq(samples.userId, user.id));
```

Anders als bei SQL-Strings können keine Tippfehler passieren, da TypeScript falsche Funktionsnamen bzw. Spalten merkt und diese somit nicht erst zur Laufzeit fehlschlagen. Zudem werden alle Werte von Drizzle parametrisiert, wodurch die Anwendung vor SQL-Injections geschützt ist.

Die erhaltenen Daten werden dann an die Rechenfunktion `computeScore()` übergeben. Über diese wird das Ergebnis kalkuliert, das Backend sichert einen Snapshot in der Datenbank und Fastify sendet das Resultat als typisiertes JSON mit Status 200 OK an das Frontend zurück.

---

## Designentscheidungen

In jedem Teilaspekt der Softwareentwicklung gibt es Designentscheidungen - hier werden die wichtigsten und bewusst gewählten Architektur-Trade-offs beschrieben. Im Allgemeinen wurden die Entscheidungen so getroffen, dass sie der Datensicherheit (DSGVO-Konformität bei Gesundheitsdaten) dienen, eine deterministische mathematische Testbarkeit bieten und eine hohe Wartbarkeit sicherstellen.

### 1. Server-Side Sessions mit PostgreSQL anstatt Stateless JWTs im LocalStorage

In sehr vielen Webanwendungen (auch in Projekten, die wir zuvor im Studium gebaut haben) werden zur Authentifizierung zustandslose JWT-Tokens im `localStorage` genutzt. Für dieses Projekt haben wir uns bewusst für die oft als traditioneller angesehene Alternative von Server-Side Sessions entschieden.

Wie im Authentifizierungsflow beschrieben, erfordert jede Anfrage einen kurzen Abgleich mit der Tabelle `sessions` in der Datenbank. JWT-Tokens dagegen könnten rein mathematisch über ihre Signatur ohne Datenbankzugriff validiert werden, was bei wenigen Anfragen Latenzvorteile, bei vielen Anfragen auch zu bedeutender Serverlastminimierung führen können. Bei einer Gesundheitsplattform gelten jedoch besondere Anforderungen an Sicherheit und DSGVO Art. 9:

1. **Sofortige Widerrufbarkeit (Revocation):** Setzt der User sein Passwort zurück, verliert sein Smartphone, können alle aktiven Sitzungen augenblicklich und geräteübergreifend beendet werden. Ein einmal ausgestelltes JWT bliebe dagegen bis zu seinem Ablaufdatum gültig.
2. **Schutz vor Token-Diebstahl:** Durch das Speichern der Session-ID im `HttpOnly`-Cookie kann bösartiges JavaScript im Browser die Sitzung nicht auslesen.

Alternativen wären JWTs mit sehr kurzer Lebensdauer oder eine serverseitige Token-Blacklist gewesen. Ersteres löst das Problem des sofortigen Widerrufs nicht vollständig, und Zweiteres benötigt am Ende ebenso eine Datenbankabfrage bei allen Request - womit der angebliche Vorteil der Zustandslosigkeit von JWTs wieder verloren geht.

### 2. Append-Only für Messwerte; keine veränderlichen Datensätze (Updates)

Das Backend überschreibt keine vorhandenen Messwerte in der Tabelle `samples`, sondern fügt Messungen immer als unveränderliche neue Einträge hinzu. Zwar wäre es speichersparender, bestehende Datenzeilen bei Korrekturen einfach per SQL-`UPDATE` zu überschreiben, da die Tabellen sonst kontinuierlich anwachsen. Dennoch haben wir uns für das Append-Only-Prinzip entschieden:

1. Für das Vertrauen in eine Gesundheitsplattform ist es wichtig, dass der Verlauf immer abgerufen werden kann. Es lässt sich zu jedem Zeitpunkt lückenlos nachvollziehen, auf Basis welcher Rohdaten der Score an einem bestimmten Tag in der Vergangenheit berechnet wurde.
2. Wird der Berechnungsalgorithmus in Zukunft an neue medizinische Erkenntnisse angepasst, können vergangene Scores rückwirkend neu berechnet werden, ohne dass ursprüngliche Messpunkte fehlen.
3. Durch einen Unique-Constraint auf `(user_id, metric, measured_at)` mit `ON CONFLICT DO NOTHING` können Nutzer trotzdem denselben Apple-Health-Export mehrfach hochladen, ohne dass Duplikate entstehen oder bestehende Daten beschädigt werden.

Als Trade-off nehmen wir den höheren Speicherbedarf in Kauf. Zudem bedeutet eine längere Historie potenziell ein höheres Datenvolumen bei einem theoretischen Datenleck. Da die Datenbank jedoch von Grund auf isoliert und mit strengen Zugriffsbeschränkungen betrieben wird, überwiegt der Nutzen der Datenintegrität deutlich.

### 3. Isolierte Score-Engine anstatt Service-Layer

In vielen Backend-Architekturen ist es üblich, Geschäftslogik in Services zu kapseln, die die benötigten Daten selbst aus der Datenbank abfragen. Wir haben uns bewusst dagegen entschieden: Unsere Score-Engine in `backend/src/score/` ist eine vollkommen reine mathematische Funktion ohne jegliche Ein- und Ausgabeabhängigkeiten.

- Der Trade-off: Der aufrufende Route-Handler muss die Daten vorbereiten. Er muss zuerst alle relevanten Profil- und Messdaten aus der Datenbank laden und sie der Funktion jeweils als Parameter übergeben.
- Vorteil: Die Engine importiert weder die Datenbank, noch Fastify, noch greift sie auf die Systemuhr (`Date.now()`) zu. Dadurch ist die Berechnung deterministisch: Gleiche Eingabewerte führen immer zu der selben Ausgabe. Dies ermöglicht Tests ohne Datenbank und ist transparenter in der Entwicklung. Eine feste ESLint-Boundary-Regel verhindert hierbei im Code, dass externe Abhängigkeiten in den Score-Ordner eingeschleust werden.

---

## Tests- und Qualitätssicherungskonzept

### Tests

In vielen Webpanwendungen werden Mocks genutzt, um Komponenten isoliert zu testen. Dabei werden Schnittstellen wie Datenbankabfragen durch falsche "Dummy-Objekte" ersetzt. Das beschleunigt die Ausführung, bringt aber auch Nachteile: Tests laufen zwar grün durch, aber wenn in der echten PostgreSQL-Datenbank ein abweichender Datentyp, ein fehlender Index oder ein Constraint existiert, treten Fehler erst im Produktivbetrieb auf.

Daher ist eine klare Trennung gegeben:

- Jeder der Backend-Integrationstests läuft ausnahmslos gegen eine reale PostgreSQL-16-Instanz (lokal mittels Docker Compose, in GitHub Actions über einen Service-Container).
- Das mathematische Herzstück der Anwendung – die Score-Engine – benötigt, wie früher erwähnt, keine Datenbank. Sie wird im Rahmen von sogenannten Golden Master Tests (`backend/src/score/__tests__/golden.test.ts`) mit JSON-Datensätzen gefüttert. Da das mathematische Soll-Ergebnis jedes Profils unter gleichen Daten deterministisch ist, fallen falsche Abweichungen sofort auf. Ein Monotonie-Test stellt zudem sicher, dass eine Verbesserung eines Einzelwerts den Gesamtscore niemals senken kann.
- Mit Vitest und jsdom testen wir Berechnungs- und Formatierungsfunktionen im Interface (z. B. die Punkteberechnung bis zum nächsten Score-Band) sowie Labels an Schiebereglern und Formularen (`formLabelA11y`, `sliderA11y`), um Screenreader-Kompatibilität zu garantieren.
- Da vollständige Browser-Tests ressourcen- und zeitintensiv sind, werden nur gezielt die wichtigsten Benutzerreisen im echten Headless-Browser abgedeckt.

### Qualitätssicherung

Da im Entwicklungsprozess auch Künstliche Intelligenz als Hilfe eingesetzt wurde, war ein Qualitätssicherungskonzept sehr wichtig. Halluzinationen oder unsicherer Code soll ausgeschlossen sein. Dafür reichen keine bloßen Bitten (z.B. in einer CLAUDE.md) an Sprachmodelle, sondern nur deterministische Prüfungen, um wirklich sicher zu sein.

Unsere CI/CD-Pipeline in GitHub Actions erzwingt vor jedem Merge auf `dev` oder `main` vier feste Qualitäts-Gates:

1. TypeScript wird im Strict-Mode betrieben; implizite `any`-Typen sind verboten. Typinkonsistenzen zwischen Frontend und Backend werden abgelehnt
2. ESLint(mit `@typescript-eslint`) erzwingt gleiche Formatierung, verbietet ungenutzte Imports/Variablen und sichert Architektur-Grenzen ab (z. B. dass die Score-Engine keine Datenbankmodule importieren darf).
3. Drizzle-SQL-Migrationen laufen fehlerfrei auf der PostgreSQL-Testinstanz durch.
4. Alle Unit- und Integrationstests rennen auf grün durch.

Als finale Sicherheitsstufe galt für alle Änderungen das traditionelle Vier-Augen-Prinzip: Jeder selbst überprüft Änderungen der KI und jeder Pull Request mindestens ein Code-Review durch ein anderes Teammitglied, um die Einhaltung der Anforderungen, die in den Issues genannt waren, und der Systemarchitektur gegenzuprüfen.
