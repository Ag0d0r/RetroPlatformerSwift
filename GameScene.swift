
import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let ground: UInt32 = 0x1 << 1
    static let enemy:  UInt32 = 0x1 << 2
    static let coin:   UInt32 = 0x1 << 3
    static let powerup:UInt32 = 0x1 << 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    // Nodes
    var player: SKSpriteNode!
    var cameraNode: SKCameraNode!
    var tileMap: SKTileMapNode?

    // Controls
    var moveLeft = false
    var moveRight = false
    var lastUpdateTime: TimeInterval = 0

    // Gameplay
    var score = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.cyan
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        setupParallaxBackground()
        setupPlayer()
        setupGround()
        loadTileMapCSV(named: "level1")
        spawnEnemiesDemo()
        setupCamera()
    }

    // MARK: - Setup

    func setupParallaxBackground() {
        // Two layers for parallax - use images imported to Assets: bg_layer1, bg_layer2
        let bg1 = SKSpriteNode(imageNamed: "bg_layer1")
        bg1.anchorPoint = CGPoint.zero
        bg1.position = CGPoint.zero
        bg1.zPosition = -10
        bg1.name = "bg1"
        addChild(bg1)

        let bg2 = SKSpriteNode(imageNamed: "bg_layer2")
        bg2.anchorPoint = CGPoint.zero
        bg2.position = CGPoint.zero
        bg2.zPosition = -9
        bg2.name = "bg2"
        addChild(bg2)
    }

    func setupPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 100, y: 300)
        player.zPosition = 10
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0.0
        player.physicsBody?.friction = 0.8
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.coin | PhysicsCategory.powerup
        player.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.enemy
        addChild(player)
    }

    func setupGround() {
        // A large ground node so player has ground if tilemap missing
        let ground = SKSpriteNode(color: SKColor.brown, size: CGSize(width: 5000, height: 80))
        ground.position = CGPoint(x: 2500, y: 40)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.zPosition = 5
        addChild(ground)
    }

    func setupCamera() {
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
    }

    // MARK: - Tilemap loader (CSV)

    func loadTileMapCSV(named resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "csv"),
              let text = try? String(contentsOf: url) else {
            print("Level CSV not found")
            return
        }
        let rows = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n").map { String($0) }
        let tileWidth: Int = 64
        let tileHeight: Int = 64
        let cols = rows.first?.split(separator: ",").count ?? 0
        let rowsCount = rows.count

        // Load tiles texture (tiles.png) and create individual textures
        let tilesTexture = SKTexture(imageNamed: "tiles")
        var textures: [SKTexture] = []
        let tilesPerRow = 3 // we made a small tilesheet with 3 tiles horizontally
        for i in 0..<tilesPerRow {
            let x = CGFloat(i) * (1.0 / CGFloat(tilesPerRow))
            let rect = CGRect(x: x, y: 0, width: 1.0/CGFloat(tilesPerRow), height: 1.0)
            textures.append(SKTexture(rect: rect, in: tilesTexture))
        }

        // Create tile definitions & tile set programmatically
        var tileDefs: [SKTileDefinition] = []
        for tex in textures {
            let def = SKTileDefinition(texture: tex, size: CGSize(width: tileWidth, height: tileHeight))
            tileDefs.append(def)
        }
        let tileRule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: tileDefs)
        let tileGroup = SKTileGroup(rules: [tileRule])
        let tileSet = SKTileSet(tileGroups: [tileGroup], tileSetType: .grid)

        // Create tile map
        let tileMapNode = SKTileMapNode(tileSet: tileSet, columns: cols, rows: rowsCount, tileSize: CGSize(width: tileWidth, height: tileHeight))
        tileMapNode.anchorPoint = CGPoint.zero
        tileMapNode.position = CGPoint(x: 0, y: 120) // raise above bottom
        tileMapNode.zPosition = 0
        addChild(tileMapNode)
        self.tileMap = tileMapNode

        // Fill tilemap from CSV values; convention: 0 = empty, 1..n = tile index (1-based)
        for (rowIndex, row) in rows.enumerated() {
            let cells = row.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            for (colIndex, value) in cells.enumerated() {
                if value > 0 {
                    let tileIndex = value - 1
                    if tileIndex < tileDefs.count {
                        tileMapNode.setTileGroup(tileGroup, forColumn: colIndex, row: rowsCount - 1 - rowIndex)
                    }
                }
            }
        }

        // Add physics bodies for tiles (simple approach: create nodes where tile exists)
        for col in 0..<cols {
            for row in 0..<rowsCount {
                if tileMapNode.tileGroup(atColumn: col, row: row) != nil {
                    let tileNode = SKNode()
                    tileNode.position = CGPoint(x: CGFloat(col) * CGFloat(tileWidth) + CGFloat(tileWidth)/2,
                                                y: CGFloat(row) * CGFloat(tileHeight) + CGFloat(tileHeight)/2 + tileMapNode.position.y)
                    tileNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: tileWidth, height: tileHeight))
                    tileNode.physicsBody?.isDynamic = false
                    tileNode.physicsBody?.categoryBitMask = PhysicsCategory.ground
                    addChild(tileNode)
                }
            }
        }
    }

    // MARK: - Enemies / AI

    func spawnEnemiesDemo() {
        // Spawn a few patrol enemies to demonstrate AI
        spawnEnemy(at: CGPoint(x: 600, y: 200))
        spawnEnemy(at: CGPoint(x: 1000, y: 200))
        spawnBoss(at: CGPoint(x: 1400, y: 300))
    }

    func spawnEnemy(at pos: CGPoint) {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = pos
        enemy.zPosition = 8
        enemy.name = "enemy"
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.allowsRotation = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player
        enemy.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.player
        addChild(enemy)

        // Simple patrol action
        let moveRight = SKAction.moveBy(x: 120, y: 0, duration: 1.2)
        let moveLeft  = SKAction.moveBy(x: -120, y: 0, duration: 1.2)
        let seq = SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft]))
        enemy.run(seq)
    }

    func spawnBoss(at pos: CGPoint) {
        let boss = SKSpriteNode(color: .purple, size: CGSize(width: 140, height: 140))
        boss.position = pos
        boss.zPosition = 9
        boss.name = "boss"
        boss.userData = ["hp": 10]
        boss.physicsBody = SKPhysicsBody(rectangleOf: boss.size)
        boss.physicsBody?.isDynamic = true
        boss.physicsBody?.allowsRotation = false
        boss.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        boss.physicsBody?.contactTestBitMask = PhysicsCategory.player
        boss.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.player
        addChild(boss)

        let wait = SKAction.wait(forDuration: 2.0)
        let shoot = SKAction.run { [weak self, weak boss] in
            guard let self = self, let boss = boss else { return }
            self.bossShoot(from: boss)
        }
        boss.run(SKAction.repeatForever(SKAction.sequence([wait, shoot])))
    }

    func bossShoot(from boss: SKNode) {
        let projectile = SKSpriteNode(color: .black, size: CGSize(width: 20, height: 20))
        projectile.position = boss.position
        projectile.zPosition = 9
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.player
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.ground
        addChild(projectile)

        // Give it a leftward velocity
        projectile.physicsBody?.velocity = CGVector(dx: -200, dy: 50)
        // Remove after some time
        projectile.run(SKAction.sequence([SKAction.wait(forDuration: 6.0), SKAction.removeFromParent()]))
    }

    // MARK: - Touches / Controls

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if location.x < size.width / 2 {
            moveLeft = true
        } else {
            moveRight = true
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveLeft = false
        moveRight = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // swipe up to jump
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let prev = touch.previousLocation(in: self)
        if location.y - prev.y > 40 {
            jumpPlayer()
        }
    }

    func jumpPlayer() {
        if let vel = player.physicsBody?.velocity, abs(vel.dy) < 10 {
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 420))
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Horizontal movement via velocity control for nicer physics
        let targetSpeed: CGFloat = 180.0
        if moveLeft {
            player.physicsBody?.velocity.dx = -targetSpeed
        } else if moveRight {
            player.physicsBody?.velocity.dx = targetSpeed
        } else {
            // gentle damping
            player.physicsBody?.velocity.dx *= 0.9
        }

        // Camera follow
        if let cam = camera {
            cam.position = CGPoint(x: player.position.x + 100, y: size.height / 2)
            // Parallax backgrounds move slower
            if let bg1 = childNode(withName: "bg1") as? SKSpriteNode {
                bg1.position.x = cam.position.x * 0.3 - size.width * 0.5
            }
            if let bg2 = childNode(withName: "bg2") as? SKSpriteNode {
                bg2.position.x = cam.position.x * 0.6 - size.width * 0.5
            }
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        let names = [a.node?.name, b.node?.name]

        // Coin pickup
        if names.contains("coin") && names.contains(nil) == false {
            if a.node?.name == "coin" {
                a.node?.removeFromParent()
                score += 1
            } else if b.node?.name == "coin" {
                b.node?.removeFromParent()
                score += 1
            }
            return
        }

        // Player hits enemy
        if (a.categoryBitMask & PhysicsCategory.player) != 0 &&
            (b.categoryBitMask & PhysicsCategory.enemy) != 0 {
            handlePlayerHitEnemy(playerNode: a.node, enemyNode: b.node)
        } else if (b.categoryBitMask & PhysicsCategory.player) != 0 &&
                    (a.categoryBitMask & PhysicsCategory.enemy) != 0 {
            handlePlayerHitEnemy(playerNode: b.node, enemyNode: a.node)
        }
    }

    func handlePlayerHitEnemy(playerNode: SKNode?, enemyNode: SKNode?) {
        guard let playerNode = playerNode, let enemyNode = enemyNode else { return }

        // If player is falling onto enemy -> destroy enemy
        if let vy = player.physicsBody?.velocity.dy, vy < -50 {
            // stomp!
            enemyNode.removeFromParent()
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 180))
            return
        }

        // Otherwise take damage / game over
        gameOver()
    }

    func gameOver() {
        // Simple restart
        let label = SKLabelNode(text: "Game Over")
        label.fontSize = 48
        label.position = CGPoint(x: player.position.x + 100, y: size.height/2)
        addChild(label)
        player.removeFromParent()
        self.isPaused = true
    }
}
