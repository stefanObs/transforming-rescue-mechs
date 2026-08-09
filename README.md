# Transformierende Rettungsmechs

Kindgerechtes 2D-Isometrie-Rettungsspiel: Mechs transformieren sich in Fahrzeuge, helfen in echten Orten (Start: **Seuzach**), bauen Basen und sammeln Münzen für ein Raumschiff nach Hause.

- **Zielgruppe:** 6–8 Jahre  
- **Modi:** Solo & lokaler Co-op (Tastatur / Xbox-Controller)  
- **Engine:** Godot **4.4** + GDScript  
- **Art-Style:** Comic-Rettung (Stil C)

## Spiel starten (ohne Godot-Installation)

Im Projektordner eines der Starter-Skripte ausführen. Die Skripte nutzen zuerst einen **exportierten Build** unter `build/`, sonst Godot im `PATH` / `GODOT`, sonst laden sie **einmalig** ein portables Godot 4.4.1 nach `.tools/` (Internet nötig beim ersten Mal).

| Plattform | Starter |
|-----------|---------|
| Linux | `./play-linux.sh` |
| macOS | `./play-macos.sh` oder Doppelklick auf `play-macos.command` |
| Windows | `play-windows.bat` (Doppelklick) |

Optionale Argumente werden durchgereicht, z. B. `./play-linux.sh --quit-after 2`.

### Linux-Standalone exportieren (optional)

Wenn Export-Templates für Godot 4.4.1 installiert sind:

```bash
./scripts/export_linux.sh
./play-linux.sh
```

## Konzept & Design

- Spielkonzept: **[docs/KONZEPT.md](docs/KONZEPT.md)**
- MVP-Umsetzungsplan: **[docs/plans/mvp.md](docs/plans/mvp.md)**
- Entwicklungsablauf (Subagenten): **[docs/ENTWICKLUNGSABLAUF.md](docs/ENTWICKLUNGSABLAUF.md)**
- Design-Vorschläge: **[docs/DESIGN-VORSCHLAEGE.md](docs/DESIGN-VORSCHLAEGE.md)**
- Style-Bible C: **[docs/STYLE-BIBLE-C.md](docs/STYLE-BIBLE-C.md)**
- Moodboards: **[docs/design-refs/](docs/design-refs/)**
- Art-Subagent: **[.cursor/agents/comic-rettung-art.md](.cursor/agents/comic-rettung-art.md)**

## Status

MVP-Umsetzung: **M0** und **M1** erledigt (Sandbox: Bewegen + Transform).

## Entwicklung

```bash
# Automatisierte Smoke-Tests
./scripts/run_tests.sh

# Spiel starten (siehe auch Starter oben)
./play-linux.sh
```

Tests: `tests/smoke_test.gd` via `./scripts/run_tests.sh`. GdUnit4/GUT Follow-up später.
