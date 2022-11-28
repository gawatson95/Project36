//
//  GameScene.swift
//  Project36
//
//  Created by Grant Watson on 11/28/22.
//

import SpriteKit
import GameplayKit

enum GameState {
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    var backgroundMusic: SKAudioNode!
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    
    let rockTexture = SKTexture(imageNamed: "rock")
    var rockPhysics: SKPhysicsBody!
    
    let explosion = SKEmitterNode(fileNamed: "PlayerExplosion")
    
    var gameState = GameState.showingLogo
    
    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
            configureHighScore()
        }
    }

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        rockPhysics = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        
        createPlayer()
        createSky()
        createBackground()
        createGround()
        createScore()
        createLogos()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .showingLogo:
            gameState = .playing
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run { [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startRocks()
            }
            
            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)
            
        case .playing:
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
        case .dead:
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                view?.presentScene(scene, transition: transition)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }
        
        let value = player.physicsBody!.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
        
        player.run(rotate)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1
            return
        }
        
        //ignore collision if collide with empty object (ie collided after removed from parent)
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else { return }
        
        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            
            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            
            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())
            
            player.removeFromParent()
    
            highScoreLabel.alpha = 1
            
            speed = 0
        }
    }
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "player-1")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 5, y: frame.height * 0.75)
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size())
        // get notified if player touches anything == dies in game
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        player.physicsBody!.isDynamic = false
        player.physicsBody?.collisionBitMask = 0
        
        let frame2 = SKTexture(imageNamed: "player-2")
        let frame3 = SKTexture(imageNamed: "player-3")
        let animation = SKAction.animate(with: [playerTexture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)
        
        player.run(runForever)
    }
    
    func createSky() {
        let topSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        let bottomSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.25))
        bottomSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        topSky.position = CGPoint(x: frame.midX, y: frame.height)
        bottomSky.position = CGPoint(x: frame.midX, y: bottomSky.frame.height)
        
        addChild(topSky)
        addChild(bottomSky)
        
        bottomSky.zPosition = -40
        topSky.zPosition = -40
    }
    
    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition = -30
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 100)
            addChild(background)
            
            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 20)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        
        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)
            
            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())
            ground.physicsBody?.isDynamic = false
            
            addChild(ground)
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }
    
    func createRocks() {
        let rockTexture = SKTexture(imageNamed: "rock")
        
        let topRock = SKSpriteNode(texture: rockTexture)
        topRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        topRock.physicsBody?.isDynamic = false
        topRock.zRotation = .pi
        topRock.xScale = -1.0
        
        let bottomRock = SKSpriteNode(texture: rockTexture)
        bottomRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        bottomRock.physicsBody?.isDynamic = false
        
        topRock.zPosition = -20
        bottomRock.zPosition = -20
        
        let rockCollision = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 32, height: frame.height))
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false
        rockCollision.name = "scoreDetect"
        
        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)
        
        let xPosition = frame.width + topRock.frame.width
        
        let max = CGFloat(frame.height / 3)
        let yPosition = CGFloat.random(in: -50...max)
        
        let rockDistance: CGFloat = 70
        
        topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPosition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)
        
        let endPosition = frame.width + (topRock.frame.width * 2)
        
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }
    
    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocks()
        }
        
        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever )
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 24
        
        scoreLabel.position = CGPoint(x: frame.maxX - 100, y: frame.maxY - 70)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.black
        
        addChild(scoreLabel)
    }
    
    func createLogos() {
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
        
        highScoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        highScoreLabel.fontSize = 24
        highScoreLabel.fontColor = UIColor.black
        highScoreLabel.text = "High Score: \(UserDefaults.standard.value(forKey: "savedScore") as? Int ?? 0)"
        highScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 75)
        highScoreLabel.alpha = 0
        addChild(highScoreLabel)
    }
    
    func configureHighScore() {
        let defaults = UserDefaults.standard
        
        if let savedScore = defaults.value(forKey: "savedScore") as? Int {
            print("SAVED: \(savedScore)")
            print(score)
            if score > savedScore {
                highScoreLabel.text = "NEW High Score: \(score)"
                defaults.set(score, forKey: "savedScore")
            } else {
                highScoreLabel.text = "High Score: \(savedScore)"
            }
        } else {
            highScoreLabel.text = "High Score: \(score)"
            defaults.set(score, forKey: "savedScore")
        }
    }
}
