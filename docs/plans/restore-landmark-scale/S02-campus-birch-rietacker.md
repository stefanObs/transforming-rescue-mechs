# Slice: S02 — Campus Birch + Rietacker Ausrichtung

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die beiden Seuzach-Schul-Campi Birch und Rietacker stehen wieder mit grob korrekter Gebäude-Ausrichtung und stimmigen Größenverhältnissen der Trakte zueinander und zur Strasse — validiert gegen Google Maps / Street View.

## In diesem Schritt

- Rotation/Facing und relative Scale der Birch-Gebäude (Cluster) gegen Maps/Street View anpassen
- Dasselbe für Rietacker (Cluster); Hof-Lücken und Achsen grob maps-getreu
- Bestehende Campus-Sprites weiterverwenden, wo möglich

## Nicht (andere Feature-Schritte)

- Ohringen-Campus / Kigas / Bahnhof / Badi (S03–S05)
- Globale Scale-Konstanten erneut umwerfen (S01)
- Neue Wohnhäuser; Art-Regen nur wenn Ausrichtung/Maßstab per Code nicht erreichbar

## Art (optional, damit Planner übersprungen werden kann)

- nein — bevorzugt Rotation/Scale im Code; Art nur wenn Sprite-Facing dem realen Gebäude widerspricht

## Testplan (optional, 2 Bullets)

- Suite: Birch- und Rietacker-Cluster vorhanden; Rotation/Scale-Assertions wo sinnvoll
- Playtest: beide Campi neben Strasse; Ausrichtung/Relativgröße vs. Maps/Street-View-Refs grob stimmig
