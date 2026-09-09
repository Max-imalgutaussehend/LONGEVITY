# LONGEVITY — Frontend-Spezifikation

Repo `longevity-frontend`, eingehängt als Submodule unter `frontend/`.
Ergänzt `LONGEVITY-SPEC.md`. Der API-Vertrag steht in `SPEC-backend.md` und wird hier
vorausgesetzt.

---

## 1. Gestaltungsprinzip

Die Oberfläche ist ein Messinstrument, kein Motivationsposter. Sie zeigt eine Zahl, ihre
Herkunft und was sie bewegt. Alles, was davon ablenkt, fliegt raus.

Vier Regeln, die den Stil halten, auch wenn ein Agent den Code generiert:

1. **Ein Akzent, drei Aufgaben.** Teal färbt den Score, die primäre Aktion und positive
   Veränderung. Nichts sonst. Domänen bekommen keine eigenen Farben — sobald sie welche
   haben, sieht es aus wie jede andere Fitness-App.
2. **Farbe bewertet, sie kategorisiert nicht.** Grün heißt besser, Bernstein heißt
   Aufmerksamkeit, Rot heißt schlechter. Kategorien werden über Position und Beschriftung
   unterschieden.
3. **Haarlinien statt Schatten.** Keine `box-shadow` außer dem Fokusring. Trennung
   entsteht durch 1px-Linien und Weißraum.
4. **Zahlen sind das Gestaltungselement.** Große Ziffern, tabellarische Ziffernbreite,
   kurze Beschriftung daneben. Keine Ringe, keine Tachometer, keine Ampeln.

---

## 2. Tokens

Als CSS-Custom-Properties in `src/styles/tokens.css`, in Tailwind über
`theme.extend.colors` referenziert. Keine Farbe darf im Komponentencode als Hex stehen.

### Farbe

```css
--neutral-0:   #FFFFFF;   /* Karten, Eingabefelder */
--neutral-50:  #F7F7F5;   /* Seitenhintergrund */
--neutral-100: #EFEFEC;   /* gefüllte Balkenspur, Zebrastreifen */
--neutral-200: #E8E8E3;   /* Trennlinien, Rahmen */
--neutral-400: #A3A29C;   /* Platzhalter */
--neutral-500: #888780;   /* Metadaten, Einheiten */
--neutral-700: #55544F;   /* Sekundärtext */
--neutral-900: #22221F;   /* Primärtext */

--accent-50:   #E1F5EE;   /* Bandflächen, Hover auf Primäraktion */
--accent-200:  #5DCAA5;   /* Balkenfüllung */
--accent-400:  #1D9E75;   /* Fill, aktive Zustände */
--accent-600:  #0F6E56;   /* Akzenttext, Primärbutton */
--accent-900:  #04342C;   /* Text auf accent-50 */

--warn-50:     #FAEEDA;   --warn-700: #854F0B;
--danger-50:   #FCEBEB;   --danger-700: #A32D2D;
--success-50:  #EAF3DE;   --success-700: #3B6D11;
```

Positive Deltas nutzen `accent-600`, nicht `success-700` — sonst konkurrieren zwei Grüntöne.
`success` ist Zuständen von Systemmeldungen vorbehalten (gespeichert, verifiziert).

Dark Mode ist im MVP **nicht** vorgesehen. Wird er später gebaut, ist er ein Token-Austausch,
kein Komponenten-Refactor — deshalb die strikte Token-Regel.

### Typografie

Eine Familie: **Inter**, selbst gehostet als variable Font (`woff2`, `latin` Subset), zwei
Gewichte: 400 und 500. Kein 600, kein 700.

Alle Zahlen laufen mit `font-variant-numeric: tabular-nums`. Ohne das springt der Score
beim Ziehen des Simulator-Reglers, und genau dieser Moment ist der Pitch.

| Rolle | Größe / Zeilenhöhe | Gewicht | Tracking |
|---|---|---|---|
| Score-Ziffer | 56 / 1.0 | 500 | −0.02em |
| Kennzahl | 30 / 1.1 | 500 | −0.01em |
| Seitentitel | 20 / 1.3 | 500 | 0 |
| Abschnittstitel | 15 / 1.4 | 500 | 0 |
| Fließtext | 14 / 1.6 | 400 | 0 |
| Tabellenzelle | 13 / 1.5 | 400 | 0 |
| Metadaten, Einheiten | 12 / 1.4 | 400 | 0 |

Alles in Satzkasten. Keine Versalien für Beschriftungen, keine Kursivschrift.
Fließtextzeilen maximal 72 Zeichen.

### Maße

Abstandsskala 4 / 8 / 12 / 16 / 24 / 32 / 48. Radien: 8px für Steuerelemente,
10px für Karten, 999px nur für Bänder und Statusmarken. Rahmen immer 1px `--neutral-200`.

Layout: feste Seitenleiste 220px, Inhaltsspalte maximal 1040px, zentriert, 32px
Innenabstand. Unter 900px klappt die Seitenleiste zu einer oberen Navigationsleiste.

Fokusring: `outline: 2px solid var(--accent-400); outline-offset: 2px`. Nie entfernen.

---

## 3. Komponenten

In `src/components/`, jede mit einer Storybook-freien Beispielseite unter `/dev/kit`
(nur im Dev-Build), damit Zustände ohne Backend prüfbar sind.

| Komponente | Zweck | Zustände |
|---|---|---|
| `AppShell` | Seitenleiste, Inhaltsbereich, Sync-Status | — |
| `ScoreHero` | Score, Delta, Band, Vitalitätsalter, Abdeckung | laden, leer, normal |
| `TrendChart` | Score über 90 Tage, Linie ohne Fläche | laden, zu wenig Daten (<7 Tage) |
| `DomainBar` | eine Domänenzeile mit Gewicht, Balken, Wert | normal, unter 50 (Bernstein) |
| `MetricRow` | Metrik mit Wert, Perzentil, Alter, Beitrag | vorhanden, fehlend, veraltet |
| `LeverCard` | Hebel mit Zielwert und Delta | — |
| `SimulatorSlider` | Regler mit Ist-Marke und Live-Ausgabe | — |
| `SourceCard` | Datenquelle mit Schalter, Adapter, letzter Sync | aktiv, aus, Mock, Fehler |
| `TokenCard` | Score-Nachweis mit Ablauf und Widerruf | gültig, abgelaufen, widerrufen |
| `OfferRow` | Partnerangebot mit Bandschwelle | erfüllt, offen |
| `EmptyState` | Titel, ein Satz, eine Aktion | — |
| `MockBadge` | neutrale Marke „Mock" | — |

`MockBadge` ist neutral gefärbt (`neutral-100` auf `neutral-700`), nicht warnend. Es
markiert eine bewusste Entscheidung, keinen Fehler.

### Diagramme

Nur `TrendChart` und die Balken in `DomainBar`. Recharts ohne Gitternetz, ohne Legende,
Achsen in `neutral-500` bei 12px, Linie 2px in `accent-400`, letzter Punkt als 4px-Kreis.
Tooltip zeigt Datum, Score und Abdeckung.

---

## 4. Routen

Alle unter `AppShell` außer `/verify/:id`, `/login` und `/register`.

### `/dashboard`

Der Einstieg. Reihenfolge von oben: `ScoreHero`, `TrendChart`, Domänenliste,
der stärkste Hebel als Karte mit Link nach `/hebel`, darunter Bandfortschritt
(„Noch 2 Punkte bis Band 80") und Datenstreak.

*Leerzustand:* frisch registriert, keine Samples. `ScoreHero` zeigt 50 mit dem Hinweis,
dass ohne Daten der Kohortenmittelwert gilt, und einer Aktion „Datenquelle verbinden".
Kein Skelett, das eine Zahl vortäuscht.

*Abnahme:* Score, Vitalitätsalter und Abdeckung stimmen mit `GET /score/current` überein;
der Verlauf zeigt 90 Punkte; die Domänenreihenfolge ist absteigend nach Gewicht, nicht
nach Wert.

### `/score`

Die Aufschlüsselung. Pro Domäne ein Abschnitt mit Gewicht in der Überschrift, darunter
`MetricRow` je Metrik: Wert mit Einheit, Perzentil, Alter des Werts, Beitrag in Punkten
mit Vorzeichen. Fehlende Metriken bleiben sichtbar und zeigen „kein Wert" plus eine
Aktion, ihn nachzutragen — die Lücke ist eine Information.

Oben ein Satz, der die Abdeckung erklärt: fehlende Werte ziehen den Score zur Mitte,
nicht nach unten.

*Abnahme:* Die Summe aller `contribution` plus Shrinkage ergibt den Gesamtscore auf
0,1 genau. Ein Testfall prüft das im Frontend, nicht nur im Backend.

### `/hebel`

Oben die drei Vorschläge aus `GET /score/levers`. Darunter der Simulator: ein
`SimulatorSlider` je simulierbarer Metrik, jeder mit einer Marke am Ist-Wert. Rechts
oder darunter der prognostizierte Score, das Delta, das Vitalitätsalter und das Band.

Die Berechnung läuft **im Backend** über `POST /score/simulate`, debounced auf 120 ms,
mit optimistischer Anzeige des letzten Ergebnisses während des Ladens. Keine zweite
Formel im Frontend — das ist die wichtigste Regel dieser Route.

Ein Zurücksetzen-Knopf stellt alle Regler auf den Ist-Wert.

*Abnahme:* Regler ziehen aktualisiert den Score in unter 200 ms sichtbar; der Score
springt beim Ziehen nicht in der Breite; Zurücksetzen ergibt exakt den aktuellen Score.

### `/daten`

Vier `SourceCard`. Jede zeigt Art, Adapter, letzten Sync, Anzahl der Werte und einen
Schalter. Aktivieren öffnet einen Einwilligungsdialog mit einem Satz, welche Metriken
die Quelle liefert; erst die Bestätigung setzt `enabled`.

Darunter drei Wege, echte Daten zu liefern, jeweils mit einer Zeile Erklärung:
Export-Upload (Dateifeld), Webhook-URL (kopierbar, mit Hinweis auf die iOS-App
Health Auto Export), manuelles Laborformular.

Das Laborformular listet die sieben Laborwerte mit Einheit und Datumsfeld, validiert
Bereiche clientseitig und zeigt Serverfehler an der Zeile, nicht als Sammelmeldung.

*Abnahme:* Eine Quelle deaktivieren ändert Score und Abdeckung sofort sichtbar;
das Regenerieren einer Mock-Quelle mit gleichem Seed liefert denselben Verlauf.

### `/freigabe`

Zwei Blöcke. Oben „Was gespeichert ist": Quellen mit Werteanzahl, Zeitraum, plus
Aktionen Export und Kontolöschung. Die Löschung verlangt die Eingabe des Passworts und
nennt beim Namen, was verschwindet.

Unten „Aktive Nachweise": `TokenCard` je Token mit Band, Ausstelldatum, Ablauf, Link zum
Kopieren, QR-Code und Widerruf. Ein Knopf erzeugt einen neuen Nachweis mit Auswahl der
Gültigkeit (30 / 90 / 180 Tage).

Der Text an der Ausstellung ist Teil der Funktion und lautet sinngemäß: übertragen wird
das Band, nicht der Score und keine Einzelwerte.

*Abnahme:* Ein Widerruf macht die zugehörige Verifikationsseite sofort ungültig;
nach der Kontolöschung führt jeder Aufruf zur Anmeldeseite.

### `/verify/:id` — öffentlich

Eine einzelne, zentrierte Karte auf `neutral-50`, ohne Seitenleiste, ohne Navigation.
Zeigt das Band groß, darunter Ausstelldatum, Ablauf und den Hinweis, dass die Signatur
geprüft wurde. Bei Ungültigkeit dieselbe Karte mit Klartextgrund: nicht gefunden,
widerrufen, abgelaufen, Signatur ungültig.

Diese Seite ist im Pitch der Beweis. Sie darf nichts anzeigen, was ein Rückschluss auf
Einzelwerte erlaubt, und sie muss ohne Anmeldung in einem fremden Browser funktionieren.

*Abnahme:* In einem Inkognito-Fenster geöffnet, rendert die Seite das Band korrekt und
stellt keinen einzigen authentifizierten Request.

### `/vorteile`

Bandmarke oben, darunter `OfferRow` je Angebot, sortiert nach Schwelle. Erfüllte Angebote
tragen eine Marke, offene zeigen den Abstand in Punkten. Ein Knopf führt nach `/freigabe`,
um einen Nachweis zu erzeugen.

Unter der Liste ein neutraler Hinweis, dass es sich um Demo-Konditionen handelt, solange
kein Partner angebunden ist. Der Hinweis wird nicht versteckt.

### `/report`

Der Wochenbericht als Seite: Score am Wochenanfang und -ende, Delta, die am stärksten
verbesserte und die schwächste Metrik, Streak. Ein Knopf „Als E-Mail senden" ruft
`POST /report/send`; im Dev-Stack landet sie in Mailpit.

### `/login`, `/register`

Einspaltig, zentriert, maximal 360px breit. Registrierung fragt E-Mail, Passwort,
Geburtsdatum und Geschlecht ab — letzteres mit einem Satz Begründung, weil die
Referenzkurven danach unterscheiden. Ohne diese Erklärung wirkt das Feld übergriffig.

---

## 5. Zustände und Fehler

Für jede Route sind drei Zustände zu bauen, keiner ist optional: laden, leer, Fehler.

- **Laden:** Skelette in `neutral-100`, gleiche Maße wie der Inhalt. Nie ein Spinner
  mitten auf der Seite.
- **Leer:** `EmptyState` mit Titel, einem Satz und genau einer Aktion. Keine
  Entschuldigung, keine Illustration.
- **Fehler:** was passiert ist und was zu tun ist, in einem Satz. Kein „Ups", keine
  Fehlercodes im Klartext, keine erste Person.

Netzwerkfehler zeigen einen Wiederholen-Knopf, der wirklich neu lädt. Ein 401 leitet auf
`/login` um und merkt sich das Ziel.

---

## 6. Technik

```
src/
├─ main.tsx  router.tsx
├─ api/
│  ├─ client.ts          fetch-Wrapper, credentials: 'include'
│  └─ generated.ts       aus openapi.json, nicht von Hand editieren
├─ components/
├─ routes/
├─ hooks/
└─ styles/tokens.css
```

Datenzugriff über TanStack Query. Ein `queryKey` pro Endpunkt; nach `PATCH /sources/:id`
und jedem Ingest werden `score/*` und `sources` invalidiert.

Typen kommen ausschließlich aus `api/generated.ts` (`pnpm gen:api` gegen
`backend/openapi.json`). Handgeschriebene Response-Interfaces sind verboten — sie
driften und der Bruch fällt erst im Betrieb auf.

Build: Vite, Ausgabe als statische Dateien, in einem Nginx-Alpine-Image ausgeliefert.
`VITE_API_BASE_URL` wird zur Buildzeit gesetzt; im Compose-Stack ist es `/api`.

### Qualitätsschwelle

- Bedienbar per Tastatur, sichtbarer Fokus überall, Regler auch mit Pfeiltasten.
- `prefers-reduced-motion` respektiert; im MVP gibt es ohnehin nur Übergänge auf
  Zustandswechsel, keine Einblendanimationen.
- Kontrast mindestens 4,5:1 für Text. `neutral-500` auf `neutral-0` erfüllt das,
  `neutral-400` nicht — deshalb nur für Platzhalter.
- Responsiv bis 375px. Die Domänenliste und die Metrikzeilen brechen dort zweizeilig um,
  die Tabelle wird nicht horizontal gescrollt.
- Drei Playwright-Flows: Registrierung bis erster Score, Simulation mit Reglerbewegung,
  Nachweis erzeugen und in einem zweiten Kontext verifizieren.
