# Video als SplashScreen-Hintergrund hinzufügen

## Schritt-für-Schritt Anleitung:

### 1. Video vorbereiten
- **Format:** MP4 (empfohlen)
- **Größe:** Maximal 10-15 MB für gute Performance
- **Auflösung:** 1080p oder niedriger (iPhone-kompatibel)
- **Dauer:** 3-10 Sekunden (wird geloopt)

### 2. Video zu Xcode hinzufügen
1. Öffne dein Xcode-Projekt
2. Rechtsklick auf den `SnapDish` Ordner im Project Navigator
3. Wähle "Add Files to 'SnapDish'"
4. Wähle dein Video aus
5. Stelle sicher, dass "Add to target: SnapDish" aktiviert ist
6. Klicke "Add"

### 3. Video-Namen anpassen
In `SplashScreenView.swift` Zeile 88, ändere:
```swift
if let videoURL = Bundle.main.url(forResource: "DEIN_VIDEO_NAME", withExtension: "mp4") {
```

**Beispiel:** Wenn dein Video "intro_video.mp4" heißt:
```swift
if let videoURL = Bundle.main.url(forResource: "intro_video", withExtension: "mp4") {
```

### 4. Video-Optimierungen
- **Loop:** Das Video wird automatisch geloopt
- **Aspect Fill:** Video füllt den ganzen Bildschirm aus
- **Fallback:** Falls Video nicht gefunden wird, wird ein Farbverlauf angezeigt

### 5. Performance-Tipps
- Verwende kurze Videos (3-5 Sekunden)
- Komprimiere das Video vor dem Hinzufügen
- Teste auf verschiedenen Geräten

## Unterstützte Formate:
- ✅ MP4 (empfohlen)
- ✅ MOV
- ✅ M4V

## Fallback-Verhalten:
Falls das Video nicht gefunden wird, wird automatisch ein schöner Farbverlauf angezeigt, damit die App trotzdem funktioniert.

