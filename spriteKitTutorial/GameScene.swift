//
//  GameScene.swift
//  spriteKitTutorial
//
//  Recreated in Swift by Clint Pitzak on 6/25/14.
//  Tutorial: http://www.raywenderlich.com/42699/spritekit-tutorial-for-beginners
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var lastUpdateTimeInterval: CFTimeInterval = CFTimeInterval()
    var lastSpawnTimeInterval: CFTimeInterval = CFTimeInterval()
    var player = SKSpriteNode()
    
    let projectileCategory: UInt32 =  0x1 << 0;
    let monsterCategory: UInt32 =  0x1 << 1;
    
    func rwAdd(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPointMake(a.x + b.x, a.y + b.y)
    }
    
    func rwSub(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPointMake(a.x - b.x, a.y - b.y)
    }
    
    func rwMult(a: CGPoint, b: Float) -> CGPoint {
        return CGPointMake(a.x * b, a.y * b)
    }
    
    func rwLength(a: CGPoint) -> Float {
        return sqrtf(a.x * a.x + a.y * a.y)
    }
    
    func rwNormalize(a: CGPoint) -> CGPoint {
        let length = rwLength(a)
        return CGPointMake(a.x / length, a.y / length)
    }
    
    override func didMoveToView(view: SKView) {
        self.player = SKSpriteNode(imageNamed:"player")
        self.player.position = CGPointMake(self.player.size.width/2, self.frame.size.height/2);
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        self.addChild(player)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        // 1 - Choose one of the touches to work with
        let touch: AnyObject = touches.anyObject()!
        let location = touch.locationInNode(self)
        
        // 2 - Set up initial location of projectile
        var projectile = SKSpriteNode(imageNamed:"projectile")
        projectile.position = self.player.position
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody.dynamic = true
        projectile.physicsBody.categoryBitMask = projectileCategory
        projectile.physicsBody.contactTestBitMask = monsterCategory
        projectile.physicsBody.collisionBitMask = 0
        projectile.physicsBody.usesPreciseCollisionDetection = true
        
        // 3- Determine offset of location to projectile
        let offset = rwSub(location, b: projectile.position)
        
        // 4 - Bail out if you are shooting down or backwards
        if offset.x <= 0 {
            return
        }
        
        // 5 - OK to add now - we've double checked position
        self.addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = rwNormalize(offset)
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = rwMult(direction, b: 1500)
        
        // 8 - Add the shoot amount to the current position
        let realDest = rwAdd(shootAmount, b: projectile.position)
        
        // 9 - Create the actions
        let velocity = CFloat(480.0 / 1.0)
        let realMoveDuration = NSTimeInterval(self.size.width / velocity)
        let actionMove = SKAction.moveTo(realDest, duration: realMoveDuration)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & projectileCategory) != 0
            && (secondBody.categoryBitMask & monsterCategory) != 0 {
            self.projectile(firstBody.node, monsterColidedWith: secondBody.node)
        }
    }
    
    func projectile(projectile: SKNode, monsterColidedWith: SKNode) {
        println("Hit")
        projectile.removeFromParent()
        monsterColidedWith.removeFromParent()
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval) {
        self.lastSpawnTimeInterval += timeSinceLast
        if self.lastSpawnTimeInterval > 1 {
            self.lastSpawnTimeInterval = 0
            self.addMonster()
        }
    }
    
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed:"monster")
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        monster.physicsBody.dynamic = true
        monster.physicsBody.categoryBitMask = monsterCategory
        monster.physicsBody.contactTestBitMask = projectileCategory
        monster.physicsBody.collisionBitMask = 0
        
        // Determine where to spawn the monster along the Y axis
        let minY = monster.size.height / 2;
        let maxY = self.frame.size.height - monster.size.height / 2;
        let rangeY = maxY - minY;
        let actualY = CGFloat((arc4random() % UInt32(rangeY.bridgeToObjectiveC().unsignedIntegerValue))
            + UInt32(minY.bridgeToObjectiveC().unsignedIntegerValue))
        
        // Create the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPointMake(self.frame.size.width + monster.size.width/2, actualY)
        self.addChild(monster)
        
        // Determine speed of the monster
        let minDuration = 2.0
        let maxDuration = 8.0
        let rangeDuration = maxDuration - minDuration
        let actualDuration = NSTimeInterval((arc4random()
            % UInt32(rangeDuration.bridgeToObjectiveC().unsignedIntegerValue))
            + UInt32(minDuration.bridgeToObjectiveC().unsignedIntegerValue))
        
        // Create the actions
        let actionMove = SKAction.moveTo(CGPointMake(-monster.size.width/2, actualY), duration: actualDuration)
        let actionMoveDone = SKAction.removeFromParent()
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        // Handle time delta.
        // If we drop below 60fps, we still want everything to move the same distance.
        var timeSinceLast: CFTimeInterval = currentTime - self.lastUpdateTimeInterval
        self.lastUpdateTimeInterval = currentTime
        if timeSinceLast > 1 { // more than a second since last update
            timeSinceLast = 1.0 / 60.0
            self.lastUpdateTimeInterval = currentTime
        }
        self.updateWithTimeSinceLastUpdate(timeSinceLast)
    }
}
