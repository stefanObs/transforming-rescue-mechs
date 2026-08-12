# Slice: S02 — Style-C Street-Facing House Art

**Parent:** `docs/plans/houses-street-aligned/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (zwei zusammengehörige spieler-sichtbare Inkremente: (1) Facing-Varianten oder korrigiertes Haus-Set für Strassen-Front, (2) Anbindung in Placement für die beiden Korridor-Achsen — nur so viele Assets wie für realistische Ausrichtung nötig). Plan empfohlen (Art + Placement); Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Wo S01 mit Flip/Setback allein nicht reicht (alle authored Häuser schauen in dieselbe Iso-Richtung), gibt es Style-C-Facing-Varianten bzw. korrigierte Fronts, sodass Wohnzeilen entlang Winterthurer- und Kirche-/Schneckenwiese-Achsen zur Strasse lesen.

## In diesem Schritt

- Nach S01-Playtest: nur die fehlenden Facing-Varianten / korrigiertes `house_*`-Set (Comic-Rettung C; Refs `c-iso-city-map` + `c-umgebung`/`c-basis`; Proportionen aus bestehenden Style-C-Häusern)
- Placement wählt Variante nach Strassen-Seite/Achse (lange Fassade / Front zur Strasse); kein Iso-brechen via Rotation
- Alpha-Pipeline (`process_art_alpha` / `verify_art_alpha`); Import falls Tests `ResourceLoader.exists` brauchen
- Minimale Asset-Menge — kein volles Neugen aller Häuser „schönheitshalber“

## Nicht (andere Feature-Schritte)

- S01 Placement neu erfinden; neue Housing-Korridore / Voll-Seuzach
- Landmarken-Art oder Scale; ein Slice pro einzelner PNG

## Art

- ja — Style-C via `comic-rettung-art`; nur Assets für Street-Facing-Lücke nach S01

## Testplan

- Suite: neue Varianten ladbar; Housing weiterhin off-road / corridor-tagged; Landmark-Scales unverändert
- Play: auf beiden Korridor-Achsen und beiden Seiten lesen Fassaden zur Strasse (nicht alle Häuser dieselbe Iso-Front trotz korrektem Flip)
