# Transformierende Rettungsmechs

Kindgerechtes 2D-Isometrie-Rettungsspiel: Mechs transformieren sich in Fahrzeuge, helfen in echten Orten (Start: **Seuzach**), bauen Basen und sammeln Münzen für ein Raumschiff nach Hause.

- **Zielgruppe:** 6–8 Jahre  
- **Modi:** Solo & lokaler Co-op (Tastatur / Xbox-Controller)  
- **Engine:** Godot **4.4** + GDScript  
- **Art-Style:** Comic-Rettung (Stil C)

## Spiel starten — aktuelle Sprites sehen

**Empfohlen während der Entwicklung** (immer der aktuelle Stand aus dem Repo):

```bash
godot --path .
# oder:
./play-linux.sh
```

Taste **1** Bolt · **2** Marina · **3** Rush · **Space** Transformieren.

### Warum keine neuen Sprites?

`./play-linux.sh` startete früher zuerst den Ordner `build/linux/`. Ein **alter Export** enthält noch keine neuen Art-Dateien. Die Starter überspringen veraltete Exports jetzt automatisch und nutzen den Projektmodus.

Frischen Standalone-Build erzeugen:

```bash
./scripts/export_linux.sh
./play-linux.sh
```

### Starter ohne Godot-Installation

| Plattform | Starter |
|-----------|---------|
| Linux | `./play-linux.sh` |
| macOS | `./play-macos.sh` oder `play-macos.command` |
| Windows | `play-windows.bat` |

Reihenfolge: frischer Export unter `build/` → Godot im `PATH`/`GODOT` → einmaliger Download nach `.tools/`.

## Konzept & Design

- Spielkonzept: **[docs/KONZEPT.md](docs/KONZEPT.md)**
- MVP-Umsetzungsplan: **[docs/plans/mvp.md](docs/plans/mvp.md)**
- Entwicklungsablauf (Subagenten): **[docs/ENTWICKLUNGSABLAUF.md](docs/ENTWICKLUNGSABLAUF.md)**
- Design-Vorschläge: **[docs/DESIGN-VORSCHLAEGE.md](docs/DESIGN-VORSCHLAEGE.md)**
- Style-Bible C: **[docs/STYLE-BIBLE-C.md](docs/STYLE-BIBLE-C.md)**
- Moodboards: **[docs/design-refs/](docs/design-refs/)**
- Art-Subagent: **[.cursor/agents/comic-rettung-art.md](.cursor/agents/comic-rettung-art.md)**

## Status

MVP-Umsetzung: **M0–M2** erledigt; spielbar: Bolt, Marina, **Rush** (roter Supercar).

## Entwicklung

```bash
# Automatisierte Smoke-Tests
./scripts/run_tests.sh

# Spiel starten (siehe auch Starter oben)
./play-linux.sh
```

Tests: `tests/smoke_test.gd` via `./scripts/run_tests.sh`. GdUnit4/GUT Follow-up später.
