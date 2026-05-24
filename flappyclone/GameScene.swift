//
//  GameScene.swift
//  flappyclone
//
//  Created by Nikita Zhurakov on 5/21/26.
//

import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum GameState {
        case startScreen
        case playing
        case gameOver
    }

    private struct PhysicsCategory {
        static let bird: UInt32 = 1 << 0
        static let pipe: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
    }

    private let bird = SKNode()
    private let birdArt = SKNode()
    private let wing = SKNode()
    private let eyeNode = SKShapeNode(circleOfRadius: 6.2)
    private let pupilNode = SKShapeNode(circleOfRadius: 2.6)
    private let eyeSparkNode = SKShapeNode(circleOfRadius: 1.1)
    private let beakNode = SKShapeNode()
    private let blushNode = SKShapeNode(ellipseOf: CGSize(width: 9, height: 5))
    private let eyebrowNode = SKShapeNode(rectOf: CGSize(width: 9, height: 2), cornerRadius: 1)
    private let steamNode = SKNode()
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let messageShadowLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private let pipeWidth: CGFloat = 60
    private let pipeGap: CGFloat = 170
    private let groundHeight: CGFloat = 70
    private let pipeCapHeight: CGFloat = 18
    private let pipeCapWidth: CGFloat = 76
    private let wingRestingPosition = CGPoint(x: -5, y: -1)
    private let wingRestingRotation: CGFloat = -0.15
    private let eyeRestingPosition = CGPoint(x: 9, y: 6)
    private let pupilRestingPosition = CGPoint(x: 10.4, y: 5.8)
    private let eyeSparkRestingPosition = CGPoint(x: 9.7, y: 7.4)
    private let bestScoreKey = "BestScore"
    private let flapFeedback = UIImpactFeedbackGenerator(style: .light)
    private let gameOverFeedback = UINotificationFeedbackGenerator()

    private var score = 0
    private var gameState = GameState.startScreen
    private var isScaredExpressionActive = false
    private var isStrainedExpressionActive = false
    private var recentFlapTimes: [TimeInterval] = []

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.45, green: 0.80, blue: 1.0, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -5.5)
        physicsWorld.contactDelegate = self

        prepareFeedback()
        setupLabels()
        showStartScreen()
    }

    private func prepareFeedback() {
        flapFeedback.prepare()
        gameOverFeedback.prepare()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        messageShadowLabel.fontSize = 32
        messageShadowLabel.fontColor = SKColor(white: 0.0, alpha: 0.18)
        messageShadowLabel.numberOfLines = 0
        messageShadowLabel.preferredMaxLayoutWidth = 320
        messageShadowLabel.horizontalAlignmentMode = .center
        messageShadowLabel.zPosition = 9
        addChild(messageShadowLabel)

        messageLabel.fontSize = 32
        messageLabel.fontColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = 320
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.zPosition = 10
        addChild(messageLabel)
    }

    private func resetScene() {
        removeAllChildren()
        removeAllActions()

        score = 0

        addChild(scoreLabel)
        addChild(messageShadowLabel)
        addChild(messageLabel)
        updateScoreLabel()

        setupSky()
        setupClouds()
        setupGround()
        setupBird()
    }

    private func setupSky() {
        let sky = SKSpriteNode(color: SKColor(red: 0.42, green: 0.82, blue: 0.92, alpha: 1.0), size: size)
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sky.zPosition = -20
        addChild(sky)

        let glow = SKShapeNode(ellipseOf: CGSize(width: size.width * 1.35, height: size.height * 0.55))
        glow.fillColor = SKColor(white: 1.0, alpha: 0.10)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        glow.zPosition = -19
        addChild(glow)
    }

    private func setupClouds() {
        let cloudData: [(position: CGPoint, scale: CGFloat, duration: TimeInterval)] = [
            (CGPoint(x: size.width * 0.20, y: size.height * 0.78), 0.58, 18),
            (CGPoint(x: size.width * 0.62, y: size.height * 0.68), 0.74, 22),
            (CGPoint(x: size.width * 0.88, y: size.height * 0.84), 0.48, 16)
        ]

        for data in cloudData {
            let cloud = makeCloud()
            cloud.position = data.position
            cloud.setScale(data.scale)
            cloud.zPosition = -10
            addChild(cloud)

            let driftLeft = SKAction.moveBy(x: -45, y: 0, duration: data.duration)
            let driftRight = SKAction.moveBy(x: 45, y: 0, duration: data.duration)
            cloud.run(SKAction.repeatForever(SKAction.sequence([driftLeft, driftRight])))
        }
    }

    private func makeCloud() -> SKNode {
        let cloud = SKNode()
        let cloudShadowColor = SKColor(red: 0.60, green: 0.82, blue: 0.90, alpha: 0.10)
        let cloudColor = SKColor(white: 1.0, alpha: 0.55)
        let highlightColor = SKColor(white: 1.0, alpha: 0.22)

        let shadow = SKShapeNode(path: makeCloudPath())
        shadow.fillColor = cloudShadowColor
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -5)
        cloud.addChild(shadow)

        let silhouette = SKShapeNode(path: makeCloudPath())
        silhouette.fillColor = cloudColor
        silhouette.strokeColor = .clear
        cloud.addChild(silhouette)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: 42, height: 13))
        highlight.fillColor = highlightColor
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -12, y: 10)
        cloud.addChild(highlight)

        return cloud
    }

    private func makeCloudPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -50, y: -9))
        path.addQuadCurve(to: CGPoint(x: -34, y: 4), control: CGPoint(x: -49, y: 3))
        path.addQuadCurve(to: CGPoint(x: -13, y: 15), control: CGPoint(x: -29, y: 18))
        path.addQuadCurve(to: CGPoint(x: 8, y: 19), control: CGPoint(x: -4, y: 31))
        path.addQuadCurve(to: CGPoint(x: 29, y: 8), control: CGPoint(x: 24, y: 22))
        path.addQuadCurve(to: CGPoint(x: 50, y: -8), control: CGPoint(x: 47, y: 9))
        path.addQuadCurve(to: CGPoint(x: 28, y: -15), control: CGPoint(x: 47, y: -19))
        path.addLine(to: CGPoint(x: -34, y: -15))
        path.addQuadCurve(to: CGPoint(x: -50, y: -9), control: CGPoint(x: -48, y: -17))
        path.closeSubpath()
        return path
    }

    private func showStartScreen() {
        gameState = .startScreen
        resetScene()

        scoreLabel.isHidden = true
        setMessageText("Flappy Clone\nTap to Start")
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.velocity = .zero
    }

    private func startGame() {
        gameState = .playing

        scoreLabel.isHidden = false
        setMessageText("")
        bird.physicsBody?.affectedByGravity = true

        flap()
        startSpawningPipes()
    }

    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: groundHeight))
        ground.fillColor = SKColor(red: 0.58, green: 0.34, blue: 0.18, alpha: 1.0)
        ground.strokeColor = ground.fillColor
        ground.position = CGPoint(x: size.width / 2, y: groundHeight / 2)
        ground.zPosition = 2

        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: groundHeight))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.bird

        addChild(ground)

        let dirtShadow = SKShapeNode(rectOf: CGSize(width: size.width, height: groundHeight * 0.42))
        dirtShadow.fillColor = SKColor(red: 0.43, green: 0.25, blue: 0.14, alpha: 0.35)
        dirtShadow.strokeColor = .clear
        dirtShadow.position = CGPoint(x: size.width / 2, y: groundHeight * 0.23)
        dirtShadow.zPosition = 3
        addChild(dirtShadow)

        let grass = SKShapeNode(rectOf: CGSize(width: size.width, height: 16))
        grass.fillColor = SKColor(red: 0.34, green: 0.86, blue: 0.26, alpha: 1.0)
        grass.strokeColor = grass.fillColor
        grass.position = CGPoint(x: size.width / 2, y: groundHeight - 8)
        grass.zPosition = 3
        addChild(grass)

        for index in stride(from: -12, through: Int(size.width) + 12, by: 18) {
            let scallop = SKShapeNode(circleOfRadius: 9)
            scallop.fillColor = SKColor(red: 0.34, green: 0.86, blue: 0.26, alpha: 1.0)
            scallop.strokeColor = .clear
            scallop.position = CGPoint(x: CGFloat(index), y: groundHeight - 16)
            scallop.zPosition = 3
            addChild(scallop)
        }

        for index in stride(from: 16, through: Int(size.width), by: 38) {
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = SKColor(red: 0.32, green: 0.18, blue: 0.10, alpha: 0.30)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(index), y: 20 + CGFloat(index % 19))
            dot.zPosition = 4
            addChild(dot)
        }

        for index in stride(from: 28, through: Int(size.width), by: 52) {
            let dash = SKShapeNode(rectOf: CGSize(width: 8, height: 3), cornerRadius: 1.5)
            dash.fillColor = SKColor(red: 0.72, green: 0.46, blue: 0.26, alpha: 0.28)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: CGFloat(index), y: 34 + CGFloat(index % 15))
            dash.zPosition = 4
            addChild(dash)
        }
    }

    private func setupBird() {
        bird.removeAllChildren()
        bird.removeAllActions()
        createBirdVisuals()

        bird.position = CGPoint(x: size.width * 0.3, y: size.height * 0.55)
        bird.zRotation = 0
        bird.zPosition = 5

        bird.physicsBody = SKPhysicsBody(circleOfRadius: 18)
        bird.physicsBody?.mass = 0.15
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.collisionBitMask = PhysicsCategory.pipe | PhysicsCategory.ground
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground

        addChild(bird)
    }

    private func createBirdVisuals() {
        let outlineColor = SKColor(red: 0.50, green: 0.26, blue: 0.03, alpha: 1.0)
        isScaredExpressionActive = false
        isStrainedExpressionActive = false
        recentFlapTimes.removeAll()
        birdArt.removeAllChildren()
        birdArt.removeAllActions()
        birdArt.setScale(1)
        birdArt.zRotation = 0
        bird.addChild(birdArt)

        let backTuft = SKShapeNode(ellipseOf: CGSize(width: 6, height: 12))
        backTuft.fillColor = SKColor(red: 1.0, green: 0.78, blue: 0.08, alpha: 1.0)
        backTuft.strokeColor = outlineColor
        backTuft.lineWidth = 1
        backTuft.position = CGPoint(x: -5, y: 16)
        backTuft.zRotation = -0.50
        backTuft.zPosition = 0
        birdArt.addChild(backTuft)

        let frontTuft = SKShapeNode(ellipseOf: CGSize(width: 6, height: 11))
        frontTuft.fillColor = SKColor(red: 1.0, green: 0.86, blue: 0.10, alpha: 1.0)
        frontTuft.strokeColor = outlineColor
        frontTuft.lineWidth = 1
        frontTuft.position = CGPoint(x: 1, y: 17)
        frontTuft.zRotation = 0.28
        frontTuft.zPosition = 0
        birdArt.addChild(frontTuft)

        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: -16, y: 1))
        bodyPath.addQuadCurve(to: CGPoint(x: -5, y: 16), control: CGPoint(x: -16, y: 13))
        bodyPath.addQuadCurve(to: CGPoint(x: 13, y: 13), control: CGPoint(x: 6, y: 19))
        bodyPath.addQuadCurve(to: CGPoint(x: 20, y: 2), control: CGPoint(x: 21, y: 10))
        bodyPath.addQuadCurve(to: CGPoint(x: 15, y: -11), control: CGPoint(x: 21, y: -6))
        bodyPath.addQuadCurve(to: CGPoint(x: -4, y: -16), control: CGPoint(x: 6, y: -19))
        bodyPath.addQuadCurve(to: CGPoint(x: -16, y: 1), control: CGPoint(x: -16, y: -13))
        bodyPath.closeSubpath()

        let bodyShadow = SKShapeNode(path: bodyPath)
        bodyShadow.fillColor = SKColor(red: 0.94, green: 0.48, blue: 0.0, alpha: 1.0)
        bodyShadow.strokeColor = outlineColor
        bodyShadow.lineWidth = 1.2
        bodyShadow.position = CGPoint(x: 0, y: -1)
        bodyShadow.zPosition = 0
        birdArt.addChild(bodyShadow)

        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.10, alpha: 1.0)
        body.strokeColor = outlineColor
        body.lineWidth = 1.3
        body.zPosition = 1
        birdArt.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 13, height: 8))
        belly.fillColor = SKColor(red: 1.0, green: 0.97, blue: 0.44, alpha: 0.68)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: -5, y: -5)
        belly.zPosition = 2
        birdArt.addChild(belly)

        let bodyHighlight = SKShapeNode(ellipseOf: CGSize(width: 11, height: 5))
        bodyHighlight.fillColor = SKColor(white: 1.0, alpha: 0.22)
        bodyHighlight.strokeColor = .clear
        bodyHighlight.position = CGPoint(x: -1, y: 8)
        bodyHighlight.zPosition = 2
        birdArt.addChild(bodyHighlight)

        blushNode.removeAllActions()
        blushNode.fillColor = SKColor(red: 1.0, green: 0.22, blue: 0.28, alpha: 0.0)
        blushNode.strokeColor = .clear
        blushNode.position = CGPoint(x: 4, y: -5)
        blushNode.setScale(1)
        blushNode.zPosition = 3
        birdArt.addChild(blushNode)

        wing.removeAllChildren()
        wing.removeAllActions()
        wing.position = wingRestingPosition
        wing.zRotation = wingRestingRotation
        wing.setScale(1)
        wing.zPosition = 2

        let wingPath = CGMutablePath()
        wingPath.move(to: CGPoint(x: 0, y: 6))
        wingPath.addQuadCurve(to: CGPoint(x: -17, y: 2), control: CGPoint(x: -8, y: 13))
        wingPath.addQuadCurve(to: CGPoint(x: -13, y: -5), control: CGPoint(x: -19, y: -3))
        wingPath.addQuadCurve(to: CGPoint(x: 0, y: -7), control: CGPoint(x: -7, y: -11))
        wingPath.closeSubpath()

        let wingShape = SKShapeNode(path: wingPath)
        wingShape.fillColor = SKColor(red: 1.0, green: 0.67, blue: 0.05, alpha: 1.0)
        wingShape.strokeColor = outlineColor
        wingShape.lineWidth = 1.2
        wingShape.zPosition = 1
        wing.addChild(wingShape)

        let wingHighlight = SKShapeNode(ellipseOf: CGSize(width: 8, height: 4))
        wingHighlight.fillColor = SKColor(white: 1.0, alpha: 0.18)
        wingHighlight.strokeColor = .clear
        wingHighlight.position = CGPoint(x: -7, y: 3)
        wingHighlight.zPosition = 2
        wing.addChild(wingHighlight)

        birdArt.addChild(wing)

        eyeNode.removeAllActions()
        eyeNode.fillColor = .white
        eyeNode.strokeColor = SKColor(white: 0.08, alpha: 1.0)
        eyeNode.lineWidth = 1.1
        eyeNode.position = eyeRestingPosition
        eyeNode.setScale(1)
        eyeNode.zPosition = 3
        birdArt.addChild(eyeNode)

        pupilNode.removeAllActions()
        pupilNode.fillColor = .black
        pupilNode.strokeColor = .black
        pupilNode.position = pupilRestingPosition
        pupilNode.setScale(1)
        pupilNode.zPosition = 4
        birdArt.addChild(pupilNode)

        eyeSparkNode.removeAllActions()
        eyeSparkNode.fillColor = .white
        eyeSparkNode.strokeColor = .clear
        eyeSparkNode.position = eyeSparkRestingPosition
        eyeSparkNode.setScale(1)
        eyeSparkNode.zPosition = 5
        birdArt.addChild(eyeSparkNode)

        eyebrowNode.removeAllActions()
        eyebrowNode.fillColor = SKColor(red: 0.36, green: 0.18, blue: 0.02, alpha: 0.0)
        eyebrowNode.strokeColor = .clear
        eyebrowNode.position = CGPoint(x: 8, y: 13)
        eyebrowNode.zRotation = -0.35
        eyebrowNode.setScale(1)
        eyebrowNode.zPosition = 6
        birdArt.addChild(eyebrowNode)

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: 18, y: 2))
        beakPath.addLine(to: CGPoint(x: 28, y: -1))
        beakPath.addLine(to: CGPoint(x: 18, y: -4))
        beakPath.closeSubpath()

        beakNode.removeAllActions()
        beakNode.path = beakPath
        beakNode.fillColor = SKColor(red: 1.0, green: 0.52, blue: 0.08, alpha: 1.0)
        beakNode.strokeColor = SKColor(red: 0.60, green: 0.24, blue: 0.0, alpha: 1.0)
        beakNode.lineWidth = 1.1
        beakNode.setScale(1)
        beakNode.zPosition = 0
        birdArt.addChild(beakNode)

        steamNode.removeAllChildren()
        steamNode.removeAllActions()
        steamNode.position = CGPoint(x: -8, y: 19)
        steamNode.zPosition = 20
        birdArt.addChild(steamNode)
    }

    private func startSpawningPipes() {
        let spawn = SKAction.run { [weak self] in
            self?.spawnPipePair()
        }
        let firstDelay = SKAction.wait(forDuration: 1.0)
        let wait = SKAction.wait(forDuration: 1.8)
        let spawnLoop = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(SKAction.sequence([firstDelay, spawnLoop]), withKey: "spawnPipes")
    }

    private func spawnPipePair() {
        let pipePair = SKNode()
        pipePair.name = "pipePair"
        pipePair.position.x = size.width + pipeWidth
        pipePair.userData = ["passed": false]

        let minimumGapCenter = groundHeight + pipeGap / 2 + 40
        let maximumGapCenter = size.height - pipeGap / 2 - 80
        let gapCenter = CGFloat.random(in: minimumGapCenter...maximumGapCenter)

        let lowerPipeHeight = gapCenter - pipeGap / 2 - groundHeight
        let upperPipeHeight = size.height - (gapCenter + pipeGap / 2)

        let lowerPipe = makePipe(height: lowerPipeHeight, isUpperPipe: false)
        lowerPipe.position = CGPoint(x: 0, y: groundHeight + lowerPipeHeight / 2)
        pipePair.addChild(lowerPipe)

        let upperPipe = makePipe(height: upperPipeHeight, isUpperPipe: true)
        upperPipe.position = CGPoint(x: 0, y: gapCenter + pipeGap / 2 + upperPipeHeight / 2)
        pipePair.addChild(upperPipe)

        addChild(pipePair)

        let moveLeft = SKAction.moveBy(x: -size.width - pipeWidth * 2, y: 0, duration: 4.0)
        let remove = SKAction.removeFromParent()
        pipePair.run(SKAction.sequence([moveLeft, remove]))
    }

    private func makePipe(height: CGFloat, isUpperPipe: Bool) -> SKNode {
        let pipe = SKNode()
        pipe.zPosition = 1

        let bodyHeight = max(height - pipeCapHeight, 1)
        let bodyOffsetY = isUpperPipe ? pipeCapHeight / 2 : -pipeCapHeight / 2

        let body = SKShapeNode(rectOf: CGSize(width: pipeWidth, height: bodyHeight))
        body.fillColor = SKColor(red: 0.06, green: 0.70, blue: 0.16, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.0, green: 0.28, blue: 0.05, alpha: 1.0)
        body.lineWidth = 3
        body.position = CGPoint(x: 0, y: bodyOffsetY)
        pipe.addChild(body)

        let pipeShadow = SKShapeNode(rectOf: CGSize(width: 10, height: bodyHeight))
        pipeShadow.fillColor = SKColor(red: 0.0, green: 0.25, blue: 0.05, alpha: 0.35)
        pipeShadow.strokeColor = .clear
        pipeShadow.position = CGPoint(x: pipeWidth / 2 - 8, y: bodyOffsetY)
        pipeShadow.zPosition = 1
        pipe.addChild(pipeShadow)

        let pipeHighlight = SKShapeNode(rectOf: CGSize(width: 9, height: max(bodyHeight - 10, 1)), cornerRadius: 4)
        pipeHighlight.fillColor = SKColor(red: 0.65, green: 1.0, blue: 0.55, alpha: 0.32)
        pipeHighlight.strokeColor = .clear
        pipeHighlight.position = CGPoint(x: -pipeWidth / 2 + 11, y: bodyOffsetY)
        pipeHighlight.zPosition = 1
        pipe.addChild(pipeHighlight)

        let capOffsetY = isUpperPipe ? -height / 2 + pipeCapHeight / 2 : height / 2 - pipeCapHeight / 2
        let cap = SKShapeNode(rectOf: CGSize(width: pipeCapWidth, height: pipeCapHeight), cornerRadius: 8)
        cap.fillColor = SKColor(red: 0.08, green: 0.78, blue: 0.18, alpha: 1.0)
        cap.strokeColor = SKColor(red: 0.0, green: 0.28, blue: 0.05, alpha: 1.0)
        cap.lineWidth = 3
        cap.position = CGPoint(x: 0, y: capOffsetY)
        cap.zPosition = 1
        pipe.addChild(cap)

        let capHighlight = SKShapeNode(rectOf: CGSize(width: pipeCapWidth - 16, height: 4), cornerRadius: 2)
        capHighlight.fillColor = SKColor(red: 0.70, green: 1.0, blue: 0.52, alpha: 0.38)
        capHighlight.strokeColor = .clear
        capHighlight.position = CGPoint(x: 0, y: capOffsetY + pipeCapHeight * 0.22)
        capHighlight.zPosition = 2
        pipe.addChild(capHighlight)

        let bodyPhysics = SKPhysicsBody(rectangleOf: CGSize(width: pipeWidth, height: bodyHeight), center: body.position)
        let capPhysics = SKPhysicsBody(rectangleOf: CGSize(width: pipeCapWidth, height: pipeCapHeight), center: cap.position)
        pipe.physicsBody = SKPhysicsBody(bodies: [bodyPhysics, capPhysics])
        pipe.physicsBody?.isDynamic = false
        pipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        pipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird

        return pipe
    }

    private func flap() {
        bird.physicsBody?.velocity = .zero
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 55))
        bird.zRotation = 0.35
        setScaredExpression(active: false)
        recordFlapForStrain()
        animateTapSquash()
        playFlapFeedback()
        flapWing()
    }

    private func recordFlapForStrain() {
        let now = CACurrentMediaTime()
        recentFlapTimes.append(now)
        recentFlapTimes = recentFlapTimes.filter { now - $0 <= 0.8 }

        if recentFlapTimes.count >= 4 {
            setStrainedExpression(active: true)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.55),
                SKAction.run { [weak self] in
                    self?.recentFlapTimes.removeAll()
                    self?.setStrainedExpression(active: false)
                }
            ]), withKey: "strainCooldown")
        }
    }

    private func animateTapSquash() {
        birdArt.removeAction(forKey: "tapSquash")
        birdArt.xScale = 1
        birdArt.yScale = 1

        let squash = SKAction.scaleX(to: 1.16, y: 0.86, duration: 0.06)
        let settle = SKAction.scale(to: 1.0, duration: 0.10)
        birdArt.run(SKAction.sequence([squash, settle]), withKey: "tapSquash")
    }

    private func animateGameOverSquash() {
        birdArt.removeAction(forKey: "tapSquash")
        birdArt.removeAction(forKey: "gameOverSquash")
        birdArt.xScale = 1
        birdArt.yScale = 1
        birdArt.zRotation = 0

        let squash = SKAction.group([
            SKAction.scaleX(to: 1.28, y: 0.66, duration: 0.08),
            SKAction.rotate(toAngle: -0.24, duration: 0.08)
        ])
        let stretch = SKAction.group([
            SKAction.scaleX(to: 0.82, y: 1.20, duration: 0.10),
            SKAction.rotate(toAngle: 0.20, duration: 0.10)
        ])
        let settle = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.12),
            SKAction.rotate(toAngle: 0, duration: 0.12)
        ])

        birdArt.run(SKAction.sequence([squash, stretch, settle]), withKey: "gameOverSquash")
    }

    private func playFlapFeedback() {
        flapFeedback.impactOccurred(intensity: 0.6)
        flapFeedback.prepare()
    }

    private func playGameOverFeedback() {
        gameOverFeedback.notificationOccurred(.error)
        gameOverFeedback.prepare()
    }

    private func flapWing() {
        wing.removeAction(forKey: "flap")
        wing.position = wingRestingPosition
        wing.zRotation = wingRestingRotation
        wing.xScale = 1
        wing.yScale = 1

        let flapUp = SKAction.group([
            SKAction.rotate(toAngle: -1.05, duration: 0.07, shortestUnitArc: true),
            SKAction.scaleX(to: 1.12, y: 0.85, duration: 0.07)
        ])
        let flapDown = SKAction.group([
            SKAction.rotate(toAngle: wingRestingRotation, duration: 0.13, shortestUnitArc: true),
            SKAction.scale(to: 1.0, duration: 0.13)
        ])

        wing.run(SKAction.sequence([flapUp, flapDown]), withKey: "flap")
    }

    private func updateScoreLabel() {
        scoreLabel.text = "\(score)"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 90)
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageShadowLabel.position = CGPoint(x: messageLabel.position.x + 1, y: messageLabel.position.y - 1)
    }

    private func setMessageText(_ text: String) {
        messageLabel.text = text
        messageShadowLabel.text = text
    }

    private func endGame() {
        guard gameState == .playing else { return }

        gameState = .gameOver
        removeAction(forKey: "spawnPipes")

        enumerateChildNodes(withName: "pipePair") { node, _ in
            node.removeAllActions()
        }

        bird.physicsBody?.velocity = .zero
        bird.physicsBody?.affectedByGravity = false
        animateGameOverSquash()
        playGameOverFeedback()

        let bestScore = max(score, UserDefaults.standard.integer(forKey: bestScoreKey))
        UserDefaults.standard.set(bestScore, forKey: bestScoreKey)

        setMessageText("Game Over\nScore: \(score)\nBest: \(bestScore)\nTap to Restart")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .startScreen:
            startGame()
        case .playing:
            flap()
        case .gameOver:
            resetScene()
            startGame()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }

        updateScoreLabel()

        if bird.position.y > size.height + 60 {
            endGame()
            return
        }

        updateBirdTilt()

        enumerateChildNodes(withName: "pipePair") { [weak self] node, _ in
            guard let self else { return }
            let hasPassed = node.userData?["passed"] as? Bool ?? false
            let pipeRightEdge = node.position.x + self.pipeWidth / 2

            if !hasPassed && pipeRightEdge < self.bird.position.x {
                node.userData?["passed"] = true
                self.score += 1
                self.updateScoreLabel()
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let hitPipe = categories == (PhysicsCategory.bird | PhysicsCategory.pipe)
        let hitGround = categories == (PhysicsCategory.bird | PhysicsCategory.ground)

        if hitPipe || hitGround {
            endGame()
        }
    }

    private func updateBirdTilt() {
        let verticalSpeed = bird.physicsBody?.velocity.dy ?? 0
        let targetRotation: CGFloat = verticalSpeed > 0 ? 0.35 : -0.45
        bird.zRotation += (targetRotation - bird.zRotation) * 0.1
        updateFearExpression(for: verticalSpeed)
    }

    private func updateFearExpression(for verticalSpeed: CGFloat) {
        if verticalSpeed < -250 {
            setScaredExpression(active: true)
        } else if verticalSpeed >= -100 {
            setScaredExpression(active: false)
        }
    }

    private func setScaredExpression(active: Bool) {
        guard isScaredExpressionActive != active else { return }
        isScaredExpressionActive = active

        eyeNode.removeAction(forKey: "expression")
        pupilNode.removeAction(forKey: "expression")
        eyeSparkNode.removeAction(forKey: "expression")
        beakNode.removeAction(forKey: "expression")

        if active {
            eyeNode.run(SKAction.scale(to: 1.18, duration: 0.12), withKey: "expression")
            pupilNode.run(SKAction.group([
                SKAction.scale(to: 1.22, duration: 0.12),
                SKAction.move(to: CGPoint(x: pupilRestingPosition.x + 0.8, y: pupilRestingPosition.y - 0.8), duration: 0.12)
            ]), withKey: "expression")
            eyeSparkNode.run(SKAction.move(to: CGPoint(x: eyeSparkRestingPosition.x + 0.5, y: eyeSparkRestingPosition.y + 0.7), duration: 0.12), withKey: "expression")
            beakNode.run(SKAction.scaleX(to: 1.0, y: 1.22, duration: 0.12), withKey: "expression")
        } else {
            eyeNode.run(SKAction.scale(to: 1.0, duration: 0.14), withKey: "expression")
            if !isStrainedExpressionActive {
                pupilNode.run(SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.14),
                    SKAction.move(to: pupilRestingPosition, duration: 0.14)
                ]), withKey: "expression")
            }
            eyeSparkNode.run(SKAction.move(to: eyeSparkRestingPosition, duration: 0.14), withKey: "expression")
            beakNode.run(SKAction.scale(to: 1.0, duration: 0.14), withKey: "expression")
        }
    }

    private func setStrainedExpression(active: Bool) {
        guard isStrainedExpressionActive != active else { return }
        isStrainedExpressionActive = active

        blushNode.removeAction(forKey: "strain")
        eyebrowNode.removeAction(forKey: "strain")
        steamNode.removeAllActions()

        if active {
            blushNode.run(SKAction.group([
                SKAction.fadeAlpha(to: 0.62, duration: 0.10),
                SKAction.scale(to: 1.25, duration: 0.10)
            ]), withKey: "strain")
            eyebrowNode.run(SKAction.fadeAlpha(to: 0.95, duration: 0.10), withKey: "strain")
            showSteamPuff()

            pupilNode.removeAction(forKey: "expression")
            pupilNode.run(SKAction.group([
                SKAction.scaleX(to: 1.28, y: 0.82, duration: 0.10),
                SKAction.move(to: CGPoint(x: pupilRestingPosition.x + 0.4, y: pupilRestingPosition.y - 0.2), duration: 0.10)
            ]), withKey: "expression")
        } else {
            blushNode.run(SKAction.group([
                SKAction.fadeAlpha(to: 0.0, duration: 0.18),
                SKAction.scale(to: 1.0, duration: 0.18)
            ]), withKey: "strain")
            eyebrowNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.14), withKey: "strain")

            if !isScaredExpressionActive {
                pupilNode.removeAction(forKey: "expression")
                pupilNode.run(SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.14),
                    SKAction.move(to: pupilRestingPosition, duration: 0.14)
                ]), withKey: "expression")
            }
        }
    }

    private func showSteamPuff() {
        guard steamNode.children.isEmpty else { return }

        let puff = SKShapeNode(ellipseOf: CGSize(width: 8, height: 6))
        puff.fillColor = SKColor(white: 1.0, alpha: 0.78)
        puff.strokeColor = .clear
        puff.position = .zero
        puff.zPosition = 1
        steamNode.addChild(puff)

        let puffTwo = SKShapeNode(ellipseOf: CGSize(width: 5, height: 4))
        puffTwo.fillColor = SKColor(white: 1.0, alpha: 0.62)
        puffTwo.strokeColor = .clear
        puffTwo.position = CGPoint(x: 6, y: 3)
        puffTwo.zPosition = 1
        steamNode.addChild(puffTwo)

        let rise = SKAction.group([
            SKAction.moveBy(x: -5, y: 12, duration: 0.34),
            SKAction.fadeOut(withDuration: 0.34),
            SKAction.scale(to: 1.35, duration: 0.34)
        ])
        let cleanup = SKAction.run { [weak self] in
            self?.steamNode.removeAllChildren()
            self?.steamNode.position = CGPoint(x: -8, y: 19)
            self?.steamNode.alpha = 1
            self?.steamNode.setScale(1)
        }

        steamNode.run(SKAction.sequence([rise, cleanup]))
    }
}
