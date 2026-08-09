# Transformierende Rettungsmechs

Kindgerechtes 2D-Isometrie-Rettungsspiel: Mechs transformieren sich in Fahrzeuge, helfen in echten Orten (Start: **Seuzach**), bauen Basen und sammeln Münzen für ein Raumschiff nach Hause.

- **Zielgruppe:** 6–8 Jahre  
- **Modi:** Solo & lokaler Co-op (Tastatur / Xbox-Controller)  
- **Engine:** Godot **4.4** + GDScript  
- **Art-Style:** Comic-Rettung (Stil C)

## Konzept & Design

- Spielkonzept: **[docs/KONZEPT.md](docs/KONZEPT.md)**
- MVP-Umsetzungsplan: **[docs/plans/mvp.md](docs/plans/mvp.md)**
- Entwicklungsablauf (Subagenten): **[docs/ENTWICKLUNGSABLAUF.md](docs/ENTWICKLUNGSABLAUF.md)**
- Design-Vorschläge: **[docs/DESIGN-VORSCHLAEGE.md](docs/DESIGN-VORSCHLAEGE.md)**
- Style-Bible C: **[docs/STYLE-BIBLE-C.md](docs/STYLE-BIBLE-C.md)**
- Moodboards: **[docs/design-refs/](docs/design-refs/)**
- Art-Subagent: **[.cursor/agents/comic-rettung-art.md](.cursor/agents/comic-rettung-art.md)**

## Status

MVP-Umsetzung gestartet (**M0** Godot-Grundgerüst). Noch kein voller Spiel-Prototyp.

## Entwicklung

Voraussetzungen: Godot 4.4+ im `PATH` als `godot` (oder `GODOT=/pfad/zum/binary`).

```bash
# Automatisierte Smoke-Tests
./scripts/run_tests.sh

# Spiel starten (Haupt-Scene)
godot --path .

# Kurzer Headless-Smoke-Start
godot --headless --path . --quit-after 2
```

Tests nutzen vorerst einen leichten `SceneTree`-Runner (`tests/smoke_test.gd`). GdUnit4/GUT kann später nachgezogen werden.
