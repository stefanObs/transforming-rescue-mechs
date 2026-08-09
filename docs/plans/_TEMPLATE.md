# Plan: <kurzname>

**Status:** Entwurf | Freigegeben | In Umsetzung | Review | Playtest | Erledigt  
**Typ:** Feature | Bugfix  
**Datum:** YYYY-MM-DD  
**Owner:** …

## Ziel

…

## Scope

- In:
- Nicht:

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

- [ ] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

1. …
2. …

## Testplan

### Automatisiert

- [ ] …
- [ ] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot, nach Fix grün)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] …
- [ ] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

## Art-Bedarf

- [ ] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: …

## Akzeptanzkriterien

- [ ] …
- [ ] Bei Bugfix: Repro + RCA erledigt
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
