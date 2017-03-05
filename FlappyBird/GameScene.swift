//
//  GameScene.swift
//  FlappyBird
//
//  Created by 熊谷一騎 on 2017/02/19.
//  Copyright © 2017 熊谷一騎. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    var item:SKNode!
    var appleNode:SKSpriteNode!
    
    let birdCategory:UInt32 = 1 << 0
    let groundCategory:UInt32 = 1 << 1
    let wallCategory:UInt32 = 1 << 2
    let scoreCategory:UInt32 = 1 << 3
    let itemCategory:UInt32 = 1 << 4
    
    var score = 0
    let userDefaults:UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        backgroundColor = UIColor(colorLiteralRed:0.15, green:0.75, blue:0.90, alpha:1.0)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)

        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItem()
    }
    
    func setupGround(){
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        //地面をスクロールして表示させるのに必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        stride(from: 0.0, to: needNumber, by: 1.0).forEach{i in
            // テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示位置を設定
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height/2)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            sprite.physicsBody?.categoryBitMask = groundCategory
            sprite.physicsBody?.isDynamic = false
            
            sprite.run(repeatScrollGround)
            addChild(sprite)
        }
    }
    
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        let needNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        stride(from: 0.0, to: needNumber, by: 1.0).forEach{i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height-cloudTexture.size().height/2)
            sprite.run(repeatScrollCloud)
            addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            wall.addChild(upper)
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            //スコアアップ用
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)    // ←追加
        
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = self.birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0{
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0{
            return
        }
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory{
            print("ScoreUp")
            self.score += 1
            scoreLabelNode.text = "Score:\(score)"
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else if(contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            itemNode.removeFromParent()
            print("ScoreUp")
            self.score += 1
            scoreLabelNode.text = "Score:\(score)"
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else{
            print("Gameover")
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            let roll = SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart(){
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    func setupItem(){
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "apple")
        itemTexture.filteringMode = SKTextureFilteringMode.linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:3.0)
        
        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run({
            //self.itemNode = SKNode()
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(self.frame.size.height) )
            self.itemNode.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            
            let sprite = SKSpriteNode(texture: itemTexture)
            //self.appleNode.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: CGFloat(random_y))
            sprite.position = CGPoint(x: 0.0, y: CGFloat(random_y))
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            sprite.physicsBody?.categoryBitMask = self.itemCategory
            sprite.physicsBody?.contactTestBitMask = self.birdCategory
            sprite.physicsBody?.isDynamic = false
            
            self.itemNode.addChild(sprite)
            self.itemNode.run(itemAnimation)
            
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 1.0)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        self.itemNode.run(repeatForeverAnimation)
    }
}
