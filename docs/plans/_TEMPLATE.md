# Plan: <kurzname> / Slice <id>

**Status:** Entwurf | Erledigt  
**Typ:** Feature | Bugfix | Art  
**Datum:** YYYY-MM-DD  
**Owner:** …  
**Parent-INDEX:** `docs/plans/<aufgabe>/INDEX.md`  
**Slice-Datei:** `docs/plans/<aufgabe>/S<nn>-<slug>.md`  
**Hängt ab von:** — | S01 | …

Neue Aufgaben: INDEX + Feature-Stubs vom `task-slicer` (typisch **zwei verwandte** Inkremente). `feature-planner` füllt dieses Template **nur wenn nötig** (Bugs/Art/Multi-System/unklarer Scope) in dieselbe Slice-Datei. Offensichtliche Stubs: Planner **überspringen**; Implementer ergänzt Testplan/Akzeptanz. Tests/Review/Git bleiben der Ablauf, keine Extra-Slices. INDEX trägt `offen` → `in Arbeit` → `erledigt` — dieses File nicht durch Phasen jagen. Alte flache `docs/plans/<name>.md` nur historisch.

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
