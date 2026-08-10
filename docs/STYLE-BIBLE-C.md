# Style-Bible C — Comic-Rettung (verbindlich)

**Status:** Gewählter Projektstil (ab v0.4.0)  
**Engine:** Godot 4 · 2D Iso + Spezialmissionen  
**Zielgruppe:** 6–8 Jahre

## Referenzbilder (Primärquelle)

Diese Dateien sind die visuelle Wahrheit. Neue Assets müssen dazu passen:

| Motiv | Datei |
|-------|--------|
| Umgebung Seuzach | [`design-refs/c-umgebung.png`](design-refs/c-umgebung.png) |
| Basis / Erdstation | [`design-refs/c-basis.png`](design-refs/c-basis.png) |
| Mech-Form (Bolt) | [`design-refs/c-mech.png`](design-refs/c-mech.png) |
| Fahrzeug-Form | [`design-refs/c-fahrzeug.png`](design-refs/c-fahrzeug.png) |

Subagent: `.cursor/agents/comic-rettung-art.md` — lädt diese Bilder vor jeder Generierung und übergibt sie als `reference_image_paths`.

## Stilregeln

1. **Dicke schwarze Konturen** in der Grafik selbst (`#1A1A1A`)
2. **Flache Cel-Farben**, max. 1–2 Schattenstufen
3. **Starke Silhouetten**, wenig Textur, hohe TV-/Couch-Lesbarkeit
4. Freundlich, energetisch, kinderserienhaft — nie gruselig, nie fotorealistisch
5. Transformationen: **snappy** Pose-zu-Pose, keine weichen Morphs
6. **Mech ↔ Fahrzeug-Lesbarkeit:** Die Robot-Form muss das jeweilige Hauptfahrzeug klar andeuten (Kabinen, Leitern, Rumpf, Propeller, Spoiler, Reifen als Körperteile) — wie bei Rescue Bots, Stil C  
   - Bolt → Feuerwehrwagen · Marina → Boot/Hovercraft · **Rush → roter Elektro-Supercar**
7. **Spiel-Sprites:** Transparente Hintergründe (RGBA). Keine weißen oder schwarzen AI-„Karten“/Platten. Nach Generierung: `python3 scripts/process_art_alpha.py` und `python3 scripts/verify_art_alpha.py` (muss grün). Walk-Frames: `python3 scripts/pad_walk_frames.py`.
8. **Welt Seuzach inkl. Ohringen:** Landmarken (Bahnhof, Feuerwehr Strehlgasse, Badi Weiher, Schulen Birch/Rietacker/Ohringen) an realen Ortsrefs orientieren (Street View/Fotos), aber stilisiert in C. Schulen = mehrere Einzelgebäude; Wohnen = **mehrere** Hausvarianten.
9. **Facing/Walk:** Dir-Sprites so autoren, wie sie im Spiel ohne Lean/Turn gezeigt werden. Walk `n/e/s/ne/se` (W/NW/SW per Flip). Fahrzeug-Seitenansichten nicht als winzige Streifen liefern (Höhen-Masse lesbar halten).

## Palette

| Rolle | Hex |
|-------|-----|
| Himmel | `#4DA3FF` |
| Gras | `#3DCC5A` |
| Straße | `#6E6E6E` |
| Gebäude hell | `#FFFFFF` / `#FFE082` |
| Outline | `#1A1A1A` |
| Alarm-Icon | `#FF5252` |
| Bolt | `#FFD600` + Schwarz |
| Marina | `#00BFA5` + Weiß |
| Rush | `#E53935` + Schwarz/Dunkel (Elektro-Supercar; freundliches Comic-Rot, kein „Blut“-Look) |
| Aero (später, sparsam) | `#7C4DFF` nur Charakter |

## Godot-Hinweise

- Outline im Sprite, nicht als globaler Outline-Shader verlassen
- `AnimatedSprite2D` / `SpriteFrames` für Charaktere; wenige klare Frames
- UI: weiße Panels, dicke Rahmen, versetzter Sticker-Schatten; Comic-Bubbles für Rettungs-Radio
- TileMap isometrisch; Landmarken als klare Icon-Formen (Kirche, Bahnhof, Feuerwehr, Badi, Schulcluster)
- **Boden/Gras/Straße zum Kacheln:** durchgehende Cel-Fläche + weiche organische Gras-Patches; Straßen als **durchgehende Bänder** (RoadKit: Kreisel **ohne** Mittellinie). Keine schwarzen Per-Kachel-Outlines. Dicke `#1A1A1A`-Konturen gehören auf Charaktere/Props. Keine perspektivischen „3D-Block“-Hero-Sprites als Boden. Haus/Kirche/Hub/Landmarken nur als **einzelne Props**.

## Nicht C

Stil A (Plastik-Spielzeug) und Stil B (weiches Bilderbuch) sind **verworfen** — nur noch historische Vorschläge in `DESIGN-VORSCHLAEGE.md`.
