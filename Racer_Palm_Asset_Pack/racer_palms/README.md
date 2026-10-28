# Racer Palms – stylisiertes Low-Poly-Palmenpaket für Godot 4

Eigenständiges Assetpaket mit drei stilisierten Palmenvarianten, einem gemeinsamen
GPU-Wind-Shader und Hilfsskripten für die Instanzierung. Keine Texturen, keine
Plugins, keine Autoloads, keine Abhängigkeiten zu anderen Projekten.

## Benötigte Godot-Version

- **Godot 4.2 oder neuer** (geschrieben für 4.3, Renderer *Forward+*; *Mobile* funktioniert ebenfalls).
- Im *Compatibility*-Renderer laufen Szenen und Wind auch, nur der Backlight-Effekt der Blätter entfällt.

## Inhalt

```
racer_palms/
  scenes/     racer_palm_coastal.tscn, racer_palm_tall.tscn, racer_palm_windblown.tscn
  meshes/     racer_palm_<variante>.obj (LOD0) und racer_palm_<variante>_lod1.obj (Fernstufe)
  materials/  racer_palm_material.tres   (ein ShaderMaterial für alle Palmen)
  shaders/    racer_palm.gdshader        (Farben, Variation, Windanimation)
  scripts/    racer_palms_wind.gd        (class_name RacerPalmsWind)
              racer_palms_scatter.gd     (class_name RacerPalmsScatter)
  demo/       racer_palms_demo.tscn            Küstenstraße + Einzelansichten
              racer_palms_multimesh_demo.tscn  1 500 Palmen per MultiMesh
              racer_palms_demo_camera.gd, racer_palms_demo_road.gdshader (nur Demo)
  tools/      racer_palms_generate.py    (optional: Meshes neu erzeugen)
```

| Variante | Höhe | Wedel | Dreiecke LOD0 / LOD1 | Einsatz |
|---|---|---|---|---|
| A – Coastal   | ca. 9 m  | 11 | 946 / 351 | Küstenstraße, volle breite Krone |
| B – Tall      | ca. 13 m | 9  | 814 / 273 | Straßenrand, Aussichtspunkte, schlank & gerade |
| C – Windblown | ca. 8 m, ca. 3 m Neigung | 11 | 898 / 351 | Strand, Klippen, asymmetrische Krone |

Jede Palme ist **ein Mesh mit einer Oberfläche und einem Material** – also ein
Draw Call pro Palme bzw. pro MultiMesh. Ursprung jeder Palme ist der Stammfuß
(Y = 0), 1 Einheit = 1 Meter. Die Windblown-Palme neigt sich in Richtung +X.

## Import in ein bestehendes Projekt

1. Den Ordner `racer_palms/` **ins Wurzelverzeichnis** des Projekts kopieren
   (Pfad danach: `res://racer_palms/`). Alle internen Verweise nutzen diesen Pfad.
2. Godot öffnen bzw. zurück in den Editor wechseln – die OBJ-Meshes werden
   automatisch importiert (Standard-Importeinstellungen genügen).
3. Fertig. Optional `res://racer_palms/demo/racer_palms_demo.tscn` starten (F6).

Soll der Ordner woanders liegen (z. B. `res://assets/racer_palms/`), verschiebe ihn
**im FileSystem-Dock von Godot** – dann passt Godot alle Pfade selbst an. Der Ordner
`demo/` und `tools/` können im Spiel gelöscht werden; sie werden von nichts benötigt.

## Verwendung der drei Varianten

**Als Szene** (einzelne Palmen, Level-Design):

```gdscript
var palm := preload("res://racer_palms/scenes/racer_palm_coastal.tscn").instantiate()
palm.position = Vector3(12, 0, -40)
palm.rotation.y = randf() * TAU
palm.scale = Vector3.ONE * randf_range(0.85, 1.15)
add_child(palm)
```

Jede Szene enthält `LOD0` (0–90 m) und `LOD1` (90–700 m) über Godots
*Visibility Ranges*. Die Distanzen lassen sich direkt an den beiden Knoten ändern.

**Alte Palmen ersetzen:** Wenn dein Vegetationssystem bisher ein Mesh + Material
verwendet, setze `mesh = load("res://racer_palms/meshes/racer_palm_coastal.obj")`
und `material_override = RacerPalmsWind.get_material()`.

## Windstärke einstellen

Alle Palmen teilen sich `materials/racer_palm_material.tres`. Der Wind läuft
komplett im Vertex-Shader (kein CPU-Aufwand pro Frame); eine Änderung wirkt sofort
auf alle Palmen, auch in MultiMeshes.

```gdscript
RacerPalmsWind.set_wind(1.5, Vector2(1, 0.2))  # Stärke (0–3), Richtung X/Z, optional Tempo
RacerPalmsWind.set_wind_enabled(false)         # Wind komplett aus
RacerPalmsWind.set_weather(0.8)                # Wetterwert aus dem Spiel: 0 = ruhig … 1 = Sturm
```

Alternativ einen `Node` mit dem Skript `racer_palms_wind.gd` in die Szene legen und
die Werte im Inspector setzen. Feinabstimmung (Stamm-Schwanken, Wedel-Bewegung,
Blattflattern, alle Farben) direkt im Material unter *Shader Parameters*.

Der Stamm bewegt sich nur minimal (`trunk_sway`), die Wedel schwingen je Wedel
und je Palme phasenverschoben – auch bei Instanzierung, weil die Phase aus der
Weltposition jeder Instanz berechnet wird.

## Effiziente Instanzierung (große Welt)

- **MultiMesh pro Variante** verwenden – siehe `demo/racer_palms_multimesh_demo.tscn`.
  Ohne den Scatter-Knoten:

  ```gdscript
  var mmi := MultiMeshInstance3D.new()
  mmi.multimesh = RacerPalmsScatter.build_multimesh(
      RacerPalmsScatter.get_mesh(RacerPalmsScatter.Variant.TALL), my_transforms)
  mmi.material_override = RacerPalmsWind.get_material()   # wichtig!
  mmi.extra_cull_margin = 1.5                            # Wind verschiebt Vertices etwas
  add_child(mmi)
  ```
- **In Zellen/Chunks aufteilen** (z. B. 250 × 250 m pro MultiMesh). Godot cullt ein
  MultiMesh nur als Ganzes; kleine Chunks lassen sich zusätzlich mit
  `visibility_range_end` ausblenden.
- **Nah/Fern trennen:** für nahe Chunks die LOD0-Meshes, für entfernte Chunks die
  `_lod1`-Meshes (ca. ⅓ der Dreiecke) verwenden.
- **Schatten:** Für weit entfernte Chunks `cast_shadow = OFF` setzen; nahe Palmen
  werfen schöne Schatten auf Straße und Sand. `directional_shadow_max_distance`
  von 150–250 m ist für eine Fahrkamera ausreichend.
- Farbvariation pro Palme kommt automatisch aus dem Shader (`instance_variation`),
  zusätzliche Farb-/Custom-Daten im MultiMesh sind nicht nötig.
- Größe 0,8–1,2 und zufällige Y-Rotation reichen, damit 3 Varianten nach deutlich
  mehr Varianten aussehen.

## Meshes neu erzeugen (optional)

Die Geometrie wurde offline mit `tools/racer_palms_generate.py` erzeugt (Python 3 +
NumPy) und liegt fertig als OBJ vor – das Spiel generiert zur Laufzeit nichts.
Parameter (Höhe, Neigung, Anzahl/Länge/Breite der Wedel …) stehen oben im Skript in
`VARIANTS`. `python3 racer_palms_generate.py` überschreibt die Dateien in `meshes/`.

## Demo-Steuerung

`racer_palms_demo.tscn`: Tasten **1–5** Kameraansichten (Coastal, Tall, Windblown,
alle drei, Küstenstraße), **W** Wind an/aus, **+/−** Windstärke, **P** Screenshot nach
`user://racer_palms_screenshots/`. Alle fünf Ansichten automatisch rendern:

```
godot --path <projektordner> res://racer_palms/demo/racer_palms_demo.tscn -- --racer-palms-screenshots
```

## Bekannte Einschränkungen

- Die Paket-Dateien verweisen auf `res://racer_palms/…`. Beim Verschieben außerhalb
  des Godot-Editors (Dateimanager) müssen die Pfade angepasst werden.
- Die Mesh-Daten (Bauteil, Position im Wedel, Wedel-Zufallswert) stecken in den
  UV-Koordinaten. Ein Material mit Textur ist daher nicht direkt sinnvoll – Farben
  bitte über die Shader-Parameter anpassen.
- Die Palmen brauchen `material_override`, weil OBJ-Dateien kein Godot-Material
  mitbringen. Ohne Override erscheinen sie weiß.
- Wind ist reine Optik: keine Kollision/Physik, keine Abhängigkeit von Godot-Wetter.
- Godot erzeugt beim Import zusätzlich automatische Mesh-LODs. Falls Palmen auf
  große Distanz löchrig wirken, im Import-Dock der OBJ *Generate LODs* deaktivieren
  und neu importieren.
- Der Stamm hat keine Kollisionsform. Für Kollisionen einen einfachen
  `CylinderShape3D` (Radius ca. 0,25 m) am Stammfuß ergänzen.
- Das Paket wurde ohne laufendes Godot erstellt (siehe Hinweis im übergeordneten
  README); die Vorschaubilder stammen aus einem WebGL-Nachbau der Shader-Farben.
