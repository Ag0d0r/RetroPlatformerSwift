
RetroPlatformerTemplate
======================

Vad du får:
- Swift-filer: GameScene.swift, GameViewController.swift
- Enkla retro-sprites (PNG) att importera i Xcode Assets.xcassets: player.png, enemy.png, coin.png, tiles.png, bg_layer1.png, bg_layer2.png
- En enkel tilesheet (tiles.png) och en level CSV (level1.csv)
- README med instruktioner

Instruktioner
------------
1. Skapa ett nytt Xcode-projekt i Xcode: File → New → Project → iOS → Game → SpriteKit, Swift.
2. Radera innehållet i GameScene.swift i projektet och ersätt med filen GameScene.swift från denna zip.
3. Öppna GameViewController.swift i ditt Xcode-projekt och ersätt med den här filen (valfritt, men medföljer).
4. Importera PNG-filerna till Assets.xcassets i Xcode (drag & drop).
5. Kopiera level1.csv till appens bundle (lägg filen i projektet och se till att "Target Membership" är satt).
6. Kör på en Mac med Xcode. Ifall din Mac mini kör macOS Catalina, använd Xcode 12.4; koden använder API:er som stöds i Xcode 12 / Swift 5.3.

Vad koden gör
--------------
- Enkel sidoscrollande plattformare-baskod
- Player movement (left/right/jump), kameraföljning
- Tile-based level loader (CSV -> SKTileMapNode)
- Parallax bakgrunder
- Fiender med enkel patrol-AI
- Boss (stor fiende) med grundläggande beteende
- Power-ups (coin pickup)
- Kollision och game-over logik

Anpassa
-------
- Byt ut sprites i Assets.xcassets med dina egna för bättre stil.
- Utöka tiles.png för fler tiles och lägg till TileSet i koden.
- För komplexare levels: använd Tiled (.tmx) eller Xcode's SpriteKit Tile Editor.
