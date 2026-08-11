extends Object
## WGS84 → Spielwelt. Kirche = Ursprung, +X Ost, +Y Süd.
## 1 F1-Feld = 100 wu = 5,3 m (gemessenes Seuzach-Dorf ohne Ohringen).
class_name SeuzachGeo

const FIELD_METERS := 5.3
const FIELD_WU := 100.0
const UNITS_PER_METER := FIELD_WU / FIELD_METERS

const CHURCH_LAT := 47.5335012
const CHURCH_LON := 8.7261235

## WGS84-Näherung bei Kirchen-Breite.
const METERS_PER_DEG_LAT := 111320.0

## Gemessene Dorf-Ecken (Seuzach ohne Ohringen).
const VILLAGE_SOUTH_LAT := 47.528351
const VILLAGE_SOUTH_LON := 8.730905
const VILLAGE_NORTH_LAT := 47.543536
const VILLAGE_NORTH_LON := 8.729953
const VILLAGE_WEST_LAT := 47.536208
const VILLAGE_WEST_LON := 8.725788
const VILLAGE_EAST_LAT := 47.536171
const VILLAGE_EAST_LON := 8.746202

## OSM way 116582470 Stationsstrasse 53 (building=train_station).
## Not bus platform way 315997018, not railway=station node 1313973484,
## not track stops 130250360 / 1313973485.
const BAHNHOF_LAT := 47.5357159
const BAHNHOF_LON := 8.7388969
const BIRCH_LAT := 47.5353419
const BIRCH_LON := 8.7362524
## OSM building centroids on campus Birch (not the amenity=school yard centroid).
const BIRCH_SCHULHAUS_A_LAT := 47.5352696
const BIRCH_SCHULHAUS_A_LON := 8.7368319
const BIRCH_SCHULHAUS_B_LAT := 47.5351495
const BIRCH_SCHULHAUS_B_LON := 8.7362716
const BIRCH_TURNHALLE_LAT := 47.5354751
const BIRCH_TURNHALLE_LON := 8.7362554
const RIETACKER_LAT := 47.5362833
const RIETACKER_LON := 8.7271400
## OSM building centroids on campus Rietacker (not the amenity=school yard centroid).
const RIETACKER_SCHULHAUS_A_LAT := 47.5360788
const RIETACKER_SCHULHAUS_A_LON := 8.7273791
const RIETACKER_SCHULHAUS_B_LAT := 47.5365102
const RIETACKER_SCHULHAUS_B_LON := 8.7275595
const RIETACKER_TURNHALLE_LAT := 47.5361323
const RIETACKER_TURNHALLE_LON := 8.7262616
const OHRINGEN_LAT := 47.5280584
const OHRINGEN_LON := 8.7121325
## OSM / Gemeinde building centroids on campus Ohringen (not the amenity=school yard centroid).
const OHRINGEN_SCHULHAUS_A_LAT := 47.5283478
const OHRINGEN_SCHULHAUS_A_LON := 8.7123497
const OHRINGEN_SCHULHAUS_B_LAT := 47.5281003
const OHRINGEN_SCHULHAUS_B_LON := 8.7125046
const OHRINGEN_TURNHALLE_LAT := 47.5279647
const OHRINGEN_TURNHALLE_LON := 8.7122618
const FORRENBERG_LAT := 47.5263004
const FORRENBERG_LON := 8.7353138
## OSM way 37106305 Landstrasse 26 (leisure=sports_centre + amenity=public_bath).
## Facility centroid, not pool ways 37084074 / 37084078 / 37084086 / 482858953,
## not Birch indoor pool, not Nominatim village=Oberohringen as district.
const BADI_LAT := 47.5393193
const BADI_LON := 8.7333710
## OSM way 142728231 Bachtobelstrasse 17 building centroid (not amenity node, not Forrenberg hub).
const KIGA_BACHTOBEL_LAT := 47.5376225
const KIGA_BACHTOBEL_LON := 8.7380927
## OSM way 131647378 Weidstrasse 16 (building=POI), not Forrenberg hub, not Ohringen.
const KIGA_WEID_LAT := 47.5330589
const KIGA_WEID_LON := 8.7379167
## OSM way 140785850 Reutlingerstrasse 15 / Schneckenwiesenstrasse (building=POI).
## Not schoolyard way 1071502860, not Forrenberg hub, not Ohringen.
const KIGA_SCHNECKENWIESE_LAT := 47.5347527
const KIGA_SCHNECKENWIESE_LON := 8.7310559
## OSM way 52373683 Schulstrasse 5 Oberohringen (building=POI), not campus ways
## 52373582 / 52373583 / 917552680, not Forrenberg hub.
const KIGA_OHRINGEN_LAT := 47.5278851
const KIGA_OHRINGEN_LON := 8.7126832

## z_index = ACTOR_Z_BASE + floor(y / Z_Y_DIV) + 1; Canvas-Max 4096.
const Z_Y_DIV := 20.0
## Gras / F1-Raster: Seuzach-Dorf + Ohringen + Forrenberg.
const WORLD_BOUNDS := Rect2(Vector2(-25000, -24000), Vector2(57000, 42000))
## OSM Winterthurerstrasse vertex in WINT-KERN (Feld 38, −2); Kirche = (0,0).
const WINTERTHURER_SPAWN := Vector2(3861.9, -101.0)
const HUB_ENTER_SOUTH_WU := 320.0


static func meters_per_deg_lon() -> float:
	return METERS_PER_DEG_LAT * cos(deg_to_rad(CHURCH_LAT))


static func gps_to_world(lat: float, lon: float) -> Vector2:
	var x := (lon - CHURCH_LON) * meters_per_deg_lon() * UNITS_PER_METER
	var y := (CHURCH_LAT - lat) * METERS_PER_DEG_LAT * UNITS_PER_METER
	return Vector2(x, y)


static func village_south() -> Vector2:
	return gps_to_world(VILLAGE_SOUTH_LAT, VILLAGE_SOUTH_LON)


static func village_north() -> Vector2:
	return gps_to_world(VILLAGE_NORTH_LAT, VILLAGE_NORTH_LON)


static func village_west() -> Vector2:
	return gps_to_world(VILLAGE_WEST_LAT, VILLAGE_WEST_LON)


static func village_east() -> Vector2:
	return gps_to_world(VILLAGE_EAST_LAT, VILLAGE_EAST_LON)


static func village_ns_fields() -> float:
	return absf(village_north().y - village_south().y) / FIELD_WU


static func village_ew_fields() -> float:
	return absf(village_east().x - village_west().x) / FIELD_WU


static func actor_z(world_y: float, z_base: int) -> int:
	return z_base + int(floor(world_y / Z_Y_DIV)) + 1


static func prop_z(world_y: float, z_base: int) -> int:
	return z_base + int(floor(world_y / Z_Y_DIV))


static func forrenberg_world() -> Vector2:
	return gps_to_world(FORRENBERG_LAT, FORRENBERG_LON)


static func winterthurer_spawn() -> Vector2:
	return WINTERTHURER_SPAWN


static func default_world_spawn() -> Vector2:
	return winterthurer_spawn()


static func hub_enter_pos() -> Vector2:
	return forrenberg_world() + Vector2(0.0, HUB_ENTER_SOUTH_WU)


static func birch_world() -> Vector2:
	return gps_to_world(BIRCH_LAT, BIRCH_LON)


static func birch_schulhaus_a_world() -> Vector2:
	return gps_to_world(BIRCH_SCHULHAUS_A_LAT, BIRCH_SCHULHAUS_A_LON)


static func birch_schulhaus_b_world() -> Vector2:
	return gps_to_world(BIRCH_SCHULHAUS_B_LAT, BIRCH_SCHULHAUS_B_LON)


static func birch_turnhalle_world() -> Vector2:
	return gps_to_world(BIRCH_TURNHALLE_LAT, BIRCH_TURNHALLE_LON)


static func rietacker_world() -> Vector2:
	return gps_to_world(RIETACKER_LAT, RIETACKER_LON)


static func rietacker_schulhaus_a_world() -> Vector2:
	return gps_to_world(RIETACKER_SCHULHAUS_A_LAT, RIETACKER_SCHULHAUS_A_LON)


static func rietacker_schulhaus_b_world() -> Vector2:
	return gps_to_world(RIETACKER_SCHULHAUS_B_LAT, RIETACKER_SCHULHAUS_B_LON)


static func rietacker_turnhalle_world() -> Vector2:
	return gps_to_world(RIETACKER_TURNHALLE_LAT, RIETACKER_TURNHALLE_LON)


static func ohringen_world() -> Vector2:
	return gps_to_world(OHRINGEN_LAT, OHRINGEN_LON)


static func ohringen_schulhaus_a_world() -> Vector2:
	return gps_to_world(OHRINGEN_SCHULHAUS_A_LAT, OHRINGEN_SCHULHAUS_A_LON)


static func ohringen_schulhaus_b_world() -> Vector2:
	return gps_to_world(OHRINGEN_SCHULHAUS_B_LAT, OHRINGEN_SCHULHAUS_B_LON)


static func ohringen_turnhalle_world() -> Vector2:
	return gps_to_world(OHRINGEN_TURNHALLE_LAT, OHRINGEN_TURNHALLE_LON)


static func bahnhof_world() -> Vector2:
	return gps_to_world(BAHNHOF_LAT, BAHNHOF_LON)


static func badi_world() -> Vector2:
	return gps_to_world(BADI_LAT, BADI_LON)


static func kiga_bachtobel_world() -> Vector2:
	return gps_to_world(KIGA_BACHTOBEL_LAT, KIGA_BACHTOBEL_LON)


static func kiga_weid_world() -> Vector2:
	return gps_to_world(KIGA_WEID_LAT, KIGA_WEID_LON)


static func kiga_schneckenwiese_world() -> Vector2:
	return gps_to_world(KIGA_SCHNECKENWIESE_LAT, KIGA_SCHNECKENWIESE_LON)


static func kiga_ohringen_world() -> Vector2:
	return gps_to_world(KIGA_OHRINGEN_LAT, KIGA_OHRINGEN_LON)
