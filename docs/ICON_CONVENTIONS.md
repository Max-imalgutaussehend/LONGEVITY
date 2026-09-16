# Icon-Konventionen (Lucide Icons)

In der Longevity Frontend-Applikation werden **ausschließlich** Icons aus der Bibliothek [`lucide-react`](https://lucide.dev/) verwendet.
**Keine Emojis** (wie 🏃‍♂️, 🍎, ⚡, 🛡️, ✓, ✕) im UI-Code oder in Benutzertexten!

---

## 1. Installation & Import

```bash
pnpm add lucide-react
```

Importiere Icons immer direkt als benannte Imports:
```tsx
import { Check, X, Shield, Activity } from 'lucide-react';
```

---

## 2. Standard-Größen (Size Guidelines)

| Einsatzbereich | Icon-Größe (`size`) | Hinweise |
| :--- | :--- | :--- |
| **Inline mit Text / Badges** | `12` – `14` | Vertikal zentriert via `display: inline-flex; align-items: center; gap: 4px` |
| **Buttons (Secondary/Ghost)** | `14` – `16` | Mit Text: 4–6px Gap |
| **Cards / Listen-Items** | `16` – `20` | Subtile Akzentfarbe (`#0f6e56`) oder neutrale Tönung |
| **Feature-Karten / Modal Header** | `22` – `26` | Prominente Darstellung oben links in Boxen |
| **Hero / Stat Banner** | `28` – `32` | Nur für visuelle Ankerpunkte |

---

## 3. Standard-Zustände & Aktionen

| Status / Aktion | Empfohlenes Lucide-Icon | Farbe / Kontext |
| :--- | :--- | :--- |
| **Erfolg / Verifiziert** | `<Check />` | `#0f6e56` / Success-Grün |
| **Fehler / Abbrechen / Schließen** | `<X />` | `#a32d2d` oder neutral `#888780` für Modal-Close |
| **Pausiert / Deaktiviert** | `<PauseCircle />` | `#888780` (Neutrale Statusanzeige) |
| **Datenschutz / Sicherheit** | `<Shield />`, `<ShieldCheck />`, `<Lock />` | `#0f6e56` für DSGVO, Vertrauensanker |
| **Externe Links** | `<ExternalLink />` | Size `14`, neben Linktext |
| **Navigation Vor / Zurück** | `<ArrowRight />`, `<ArrowLeft />` | Size `14`–`16` |
| **Tipps / Hinweise** | `<Lightbulb />` | `#f59e0b` (Amber/Gelb) |
| **Highlights / Scoring** | `<Sparkles />` | `#0f6e56` oder `#d97706` |

---

## 4. Vitaldaten & Metriken (`renderMetricIcon`)

In `Daten.tsx` bzw. Metrik-Komponenten:

| Metrik | Lucide-Icon | Bedeutung |
| :--- | :--- | :--- |
| `steps` | `<Footprints />` | Tägliche Schritte |
| `resting_hr` | `<Heart />` | Ruhepuls |
| `sleep_duration` | `<Moon />` | Schlafdauer |
| `hrv` | `<TrendingUp />` | Herzfrequenzvariabilität |
| `zone2_minutes` | `<Zap />` | Zone-2 Ausdauertraining |
| `vo2max` | `<Wind />` | Kardiorespiratorische Fitness |
| `systolic_bp` / `diastolic_bp` | `<Stethoscope />` | Blutdruck |
| `apob` / `ldl` / `hdl` / `triglycerides` | `<FlaskConical />` | Lipidprofil / Laborwerte |
| `hba1c` / `fasting_glucose` | `<Droplet />` | Blutzucker-Marker |
| `waist_circumference` | `<Ruler />` | Bauchumfang |
| `strength_sessions` | `<Dumbbell />` | Krafttrainingseinheiten |
| `smoking` | `<CigaretteOff />` | Rauchstatus |
| `alcohol_units` | `<Wine />` | Alkoholkonsum |

---

## 5. Datenquellen & Wearables (`renderSourceIcon`)

| Datenquelle | Lucide-Icon | Label |
| :--- | :--- | :--- |
| Google Health & Fit | `<Bot />` | `Google Health` |
| Apple Health | `<Apple />` | `Apple Health` |
| Oura Ring | `<CircleDot />` | `Oura Ring` |
| Strava | `<Activity />` | `Strava` |
| Withings | `<Scale />` | `Withings` |
| Health Auto Export | `<Smartphone />` | `Health Auto Export` |
| Laborwerte | `<FlaskConical />` | `Laborwert` |
| Manuell erfasst | `<Pencil />` | `Manuell` |
| Fragebogen | `<FileText />` | `Fragebogen` |

---

## 6. Lebensstil-Archetypen

| Archetyp | Lucide-Icon | Bedeutung |
| :--- | :--- | :--- |
| `athletic` | `<Activity />` | Sportlich & Aktiv |
| `balanced` | `<Sparkles />` | Ausgeglichen |
| `starter` | `<Briefcase />` | Startphase / Büro |
