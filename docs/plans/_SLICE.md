# Slice: <id> — <titel>

**Status:** Slice-Entwurf | Freigegeben | In Umsetzung | Review | Playtest | Erledigt  
**Typ:** Feature | Bugfix | Art  
**Parent:** `docs/plans/<kurzname>/INDEX.md`  
**Datum:** YYYY-MM-DD  
**Hängt ab von:** — | S01 | …

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

<ein Satz, lieferbar allein>

## Grenzen

- In:
- Nicht (andere Slices / Rest der Aufgabe):
- Raster / Felder / GPS / Asset-Namen:

## Systeme

…

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. Bei Features: Abschnitt weglassen oder „n/a“.

### Reproduktion

- [ ] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. … |
| Erwartet | … |
| Tatsächlich | … |
| Umgebung | Godot-Version, Branch, Input-Gerät, Scene |
| Evidenz | Logs / Stack / Screenshot-Pfade |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | … |
| Bestätigte Ursache | … |
| Nicht die Ursache | … |
| Fix-Richtung | … |
| Risiken | … |

- [ ] RCA dokumentiert

## Technische Schritte

1. …
2. …

## Testplan

### Automatisiert

- [ ] …

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Nur dieser Slice sichtbar/prüfbar (keine stillen Extra-Lieferungen)

## Art-Bedarf

- [ ] Keine neuen Assets
- [ ] Neue Grafiken → `comic-rettung-art` **nur** für die Assets dieses Slices  
  Details: …

## Akzeptanzkriterien

- [ ] Grenzen eingehalten (nichts aus Nachbar-Slices)
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
- [ ] Git: Commit + Push + Tag für **diesen** Slice
