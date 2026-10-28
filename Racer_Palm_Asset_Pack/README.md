# Racer Palm Asset Pack

Standalone Godot-4-Testprojekt für das Palmenpaket. **Ins eigene Spiel kopiert wird
nur der Ordner [`racer_palms/`](racer_palms/)** – Anleitung, Wind-API und
Instanzierungstipps stehen in [`racer_palms/README.md`](racer_palms/README.md).

- `project.godot` – öffnet direkt die Demoszene (`racer_palms/demo/racer_palms_demo.tscn`).
- `preview_renders/` – Vorschaubilder der fünf Demo-Kameraansichten.

## Teststatus (ehrlich)

In der Erstellungsumgebung durfte Godot nicht ausgeführt werden. Deshalb:

- **Nicht in Godot geöffnet oder getestet** wurden: Szenen, Shader-Kompilierung,
  Windanimation, Godot-Beleuchtung/Schatten, MultiMesh-Demo.
- Die Bilder in `preview_renders/` sind **keine Godot-Screenshots**. Sie wurden mit
  three.js (WebGL) aus denselben OBJ-Meshes, demselben Layout und denselben
  Kamerapositionen gerendert; die Farblogik des Shaders wurde dafür nachgebaut.
  Godot wird etwas anders aussehen (Filmic-Tonemapping, SSAO, Lambert-Wrap, Backlight).
- Echte Godot-Screenshots aller fünf Ansichten erzeugt ein Befehl:
  `godot --path . res://racer_palms/demo/racer_palms_demo.tscn -- --racer-palms-screenshots`
  (Ablage: `user://racer_palms_screenshots/`).
