# Designentscheidungen

In jedem Teilaspekt der Softwareentwicklung gibt es Designentscheidungen, im Folgenden werden unsere wichtigsten und bewusst gewählten Architektur-Trade-offs beschrieben. Im Allgemeinen wurden die Entscheidungen so getroffen, dass sie der Datensicherheit (DSGVO-Konformität bei Gesundheitsdaten) dienen, eine deterministische mathematische Testbarkeit bieten und eine hohe Wartbarkeit sicherstellen.

## 1. Server-Side Sessions mit PostgreSQL anstatt Stateless JWTs im LocalStorage

In sehr vielen Webanwendungen (auch in Projekten, die wir zuvor im Studium gebaut haben) werden zur Authentifizierung zustandslose JWT-Tokens im `localStorage` genutzt. Für dieses Projekt haben wir uns bewusst für die oft als traditioneller angesehene Alternative von Server-Side Sessions entschieden.

Wie im Authentifizierungsflow beschrieben, erfordert jede Anfrage einen kurzen Abgleich mit der Tabelle [`sessions`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/db/schema.ts) in der Datenbank. JWT-Tokens dagegen könnten rein mathematisch über ihre Signatur ohne Datenbankzugriff validiert werden, was bei wenigen Anfragen Latenzvorteile, bei vielen Anfragen auch zu bedeutender Serverlastminimierung führen kann. Bei einer Gesundheitsplattform gelten jedoch besondere Anforderungen an Sicherheit und DSGVO Art. 9:

1. Setzt der User sein Passwort zurück, können alle aktiven Sitzungen sofort und geräteübergreifend beendet werden. Ein ausgestelltes JWT bleibt aber bis zu seinem Ablaufdatum gültig.
2. Durch das Speichern der Session-ID im `HttpOnly`-Cookie kann JavaScript im Browser die ID nicht auslesen.

Alternativen wären JWTs mit sehr kurzer Lebensdauer oder eine serverseitige Token-Blacklist gewesen. Ersteres löst das Problem des sofortigen Widerrufs nicht vollständig, und Zweiteres benötigt am Ende ebenso eine Datenbankabfrage bei allen Requests - womit der angebliche Vorteil der Zustandslosigkeit von JWTs wieder verloren geht.

## 2. Append-Only für Messwerte; keine veränderlichen Datensätze (Updates)

Das Backend überschreibt keine vorhandenen Messwerte in der Tabelle [`samples`](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/db/schema.ts), sondern fügt Messungen immer als unveränderliche neue Einträge hinzu. Zwar wäre es speichersparender, bestehende Datenzeilen bei Korrekturen einfach per SQL-`UPDATE` zu überschreiben, da die Tabellen sonst kontinuierlich anwachsen. Dennoch haben wir uns für das Append-Only-Prinzip entschieden:

1. Für das Vertrauen in eine Gesundheitsplattform ist es wichtig, dass der Verlauf immer abgerufen werden kann. Es lässt sich zu jedem Zeitpunkt lückenlos nachvollziehen, auf Basis welcher Rohdaten der Score an einem bestimmten Tag in der Vergangenheit berechnet wurde.
2. Wird der Berechnungsalgorithmus in Zukunft an neue medizinische Erkenntnisse angepasst, können vergangene Scores rückwirkend neu berechnet werden, ohne dass ursprüngliche Messpunkte fehlen.
3. Durch einen Unique-Constraint auf `(user_id, metric, measured_at)` mit `ON CONFLICT DO NOTHING` können Nutzer trotzdem denselben Apple-Health-Export mehrfach hochladen, ohne dass Duplikate entstehen oder bestehende Daten beschädigt werden.

Als Trade-off nehmen wir den höheren Speicherbedarf in Kauf. Zudem bedeutet eine längere Historie potenziell ein höheres Datenvolumen bei einem theoretischen Datenleck. Da die Datenbank jedoch von Grund auf isoliert und mit strengen Zugriffsbeschränkungen betrieben wird, überwiegt der Nutzen der Datenintegrität deutlich.

## 3. Isolierte Score-Engine anstatt Service-Layer

In vielen Backend-Architekturen ist es üblich, Geschäftslogik in Services zu kapseln, die die benötigten Daten selbst aus der Datenbank abfragen. Wir haben uns bewusst dagegen entschieden: Unsere Score-Engine in [`backend/src/score/`](https://github.com/Max-imalgutaussehend/longevity-backend/tree/main/src/score) ist eine vollkommen reine mathematische Funktion ohne jegliche Ein- und Ausgabeabhängigkeiten.

- Der Trade-off: Der aufrufende Route-Handler muss die Daten vorbereiten. Er muss zuerst alle relevanten Profil- und Messdaten aus der Datenbank laden und sie der Funktion jeweils als Parameter übergeben.
- Vorteil: Die Engine importiert weder die Datenbank, noch [Fastify](https://github.com/Max-imalgutaussehend/longevity-backend/blob/main/src/app.ts), noch greift sie auf die Systemuhr (`Date.now()`) zu. Dadurch ist die Berechnung deterministisch: Gleiche Eingabewerte führen immer zu derselben Ausgabe. Dies ermöglicht Tests ohne Datenbank und ist transparenter in der Entwicklung. Eine feste ESLint-Boundary-Regel verhindert hierbei im Code, dass externe Abhängigkeiten in den Score-Ordner eingeschleust werden.
