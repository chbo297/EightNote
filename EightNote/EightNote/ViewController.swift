//
//  ViewController.swift
//  EightNote
//
//  Created by bo on 13/03/2017.
//  Copyright © 2017 bo. All rights reserved.
//

import UIKit

let BLACK_HOLE_COLLISION = "leftblackhole"


class ViewController : UIViewController, UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate, VoiceDetectorDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initHeadView()
        self.initAnimator()
        
        self.addLand(CGRect.init(x: 0, y: self.view.bounds.maxY - 50, width: self.view.bounds.size.width, height: 50))
        
        self.voiceDetector = VoiceDetector()
        self.voiceDetector?.delegate = self
        self.voiceDetector?.startDetect()
        
    }
    
    var voiceDetector : VoiceDetector?
    
    
    //视图size设置
    let headSize = CGSize.init(width: 30, height: 30)
    
    lazy var maxLandWidthUnit : Int = 24
    lazy var unitLength : CGFloat = 32
    
    var head : EightNoteHead?
    
    //动画属性
    var animator : UIDynamicAnimator?
    var gravityBehavior : UIGravityBehavior?
    var collisionBehavior : UICollisionBehavior?
    var pushBehavior : UIPushBehavior?
    var headItemBehavior : UIDynamicItemBehavior?
    var floorItemBehavior : UIDynamicItemBehavior?
    var lastItemBehavior : UIDynamicItemBehavior?
    
    func initHeadView() {
        self.head = EightNoteHead.init(frame: CGRect.init(x: self.view.center.x, y: 0, width: 30, height: 30))
        self.view.addSubview(self.head!)
    }
    
    func initAnimator() {
        let anim = UIDynamicAnimator.init(referenceView: self.view)
        
        //重力
        let gravity = UIGravityBehavior.init()
        gravity.addItem(self.head!)
        anim.addBehavior(gravity)
        self.gravityBehavior = gravity
        
        //主角属性
        let headitem = UIDynamicItemBehavior.init()
        headitem.density = 0.1
        headitem.elasticity = 0
        headitem.friction = 0
        headitem.resistance = 0.9
        headitem.allowsRotation = false
        headitem.action = {
            if abs(self.head!.center.x - self.view.center.x)  > 10 {
                headitem.addLinearVelocity(CGPoint.init(x: (self.view.center.x - self.head!.center.x)/2, y: 0), for: self.head!)
            } else {
                headitem.addLinearVelocity(CGPoint.init(x: -headitem.linearVelocity(for: self.head!).x, y: 0), for: self.head!)
            }
        }
        headitem.addItem(self.head!)
        anim.addBehavior(headitem)
        self.headItemBehavior = headitem
        
        //跳跃动力
        let push = UIPushBehavior.init(items: [self.head!], mode: UIPushBehaviorMode.instantaneous)
        anim.addBehavior(push)
        self.pushBehavior = push
        
        //最后一块儿land的属性
        let lastitem = UIDynamicItemBehavior.init()
        lastitem.action = {
            if let item = self.lastItemBehavior?.items.last {
                let gap = self.view.bounds.maxX - item.center.x - item.bounds.size.width/2
                if gap >= self.nextBluffWidth! {
                    let size = self.creatLandSize()
                    let nextrect = CGRect.init(x: self.view.bounds.maxX, y: self.view.bounds.maxY - 32 - size.height,
                                               width: size.width, height: size.height)
                    self.addLand(nextrect)
                }
            }
            
        }
        anim.addBehavior(lastitem)
        self.lastItemBehavior = lastitem
        
        //land的属性
        let flooritem = UIDynamicItemBehavior.init()
        flooritem.density = 10
        flooritem.elasticity = 0
        flooritem.friction = 0
        flooritem.resistance = 1
        flooritem.allowsRotation = false
        anim.addBehavior(flooritem)
        self.floorItemBehavior = flooritem
        
        //碰撞行为
        let collision = UICollisionBehavior.init()
        let rect = self.view.bounds
        let maxlandwidth = CGFloat(self.maxLandWidthUnit) * self.unitLength
        let extendwidth = maxlandwidth + 100
        collision.addBoundary(withIdentifier: "bottom" as NSCopying,
                              from: CGPoint.init(x: rect.minX - extendwidth, y:  rect.maxY),
                              to: CGPoint.init(x: rect.maxX + extendwidth, y:  rect.maxY))
        collision.addBoundary(withIdentifier: BLACK_HOLE_COLLISION as NSCopying,
                              from: CGPoint.init(x: rect.minX - extendwidth, y:  rect.minY),
                              to: CGPoint.init(x: rect.minX - extendwidth, y:  rect.maxY))
        collision.collisionDelegate = self
        collision.addItem(self.head!)
        anim.addBehavior(collision)
        self.collisionBehavior = collision
        
        self.animator = anim
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if identifier is String {
            let iden = identifier as! String
            if iden == "leftblackhole" {
                //移除该land
                self.gravityBehavior?.removeItem(item)
                self.collisionBehavior?.removeItem(item)
                self.floorItemBehavior?.removeItem(item)
                self.lastItemBehavior?.removeItem(item)
                if item is LandView {
                    let view = item as! LandView
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    var nextBluffWidth : CGFloat?
    
    func addLand(_ rect : CGRect) {
        let land = LandView.init(frame: rect)
        self.view.addSubview(land)
        
        if let item = self.lastItemBehavior?.items.last {
            self.lastItemBehavior?.removeItem(item)
        }
        
        self.collisionBehavior?.addItem(land)
        self.gravityBehavior?.addItem(land)
        self.floorItemBehavior?.addItem(land)
        self.lastItemBehavior?.addItem(land)
        
        self.nextBluffWidth = self.creatBluffWidth()
    }

    
    func headJump(_ velocityY : CGFloat) {
        let originvel = self.headItemBehavior!.linearVelocity(for: self.head!)
        var setvelocity : CGFloat
        if originvel.y > 0 {
            return
        } else if originvel.y == 0 {
            setvelocity = velocityY
        } else {
            setvelocity = 0.001
        }
        
        self.pushBehavior?.magnitude = setvelocity
        self.pushBehavior?.angle = CGFloat(-M_PI_2)
        self.pushBehavior?.active = true
    }
    
    func headMove(_ velocityX : CGFloat) {
        for (_, value) in (self.floorItemBehavior?.items.enumerated())! {
            let vx = self.floorItemBehavior!.linearVelocity(for: value).x
            let vel = CGFloat(velocityX)
            if (abs(vx - vel) > 5) {
                self.floorItemBehavior?.addLinearVelocity(CGPoint.init(x: vel - vx, y: 0), for: value)
            }
        }
    }
    
    func headStop() {
        for (_, value) in (self.floorItemBehavior?.items.enumerated())! {
            self.floorItemBehavior?.addLinearVelocity(CGPoint.init(x: -self.floorItemBehavior!.linearVelocity(for: value).x/1.1, y: 0), for: value)
        }
    }
    
    @IBAction func jumpTouchUp(_ sender: UIButton) {
    }
    
    @IBAction func jumpTouchDown(_ sender: Any) {
        self.headJump(0.06)
    }

    @IBAction func leftDown(_ sender: UIButton) {
        self.headMove(7500)
    }
    
    @IBAction func rightDown(_ sender: UIButton) {
        self.headMove(-7500)
    }
    
    func highVoice(_ voice: CGFloat) {
        self.headJump(voice)
    }
    
    func lowVoice() {
        self.headMove(-75)
    }
    
    func silence() {
        self.headStop()
    }
    
    func creatBluffWidth() -> CGFloat {
        let unit = Int(arc4random_uniform(8) + 1)
        return CGFloat(unit * 32)
    }
    
    func creatLandSize() -> CGSize {
        let widthunit = Int(arc4random_uniform(24) + 1)
        let heightunit = Int(arc4random_uniform(30))
        
        let maxheight = self.view.bounds.minY + 32
        let minheight = self.view.bounds.maxY - 32
        
        let unitheight = (maxheight - minheight)/30
        
        return CGSize.init(width: CGFloat(widthunit * 32),
                           height: CGFloat(Float(minheight) + Float(unitheight) * Float(heightunit)))
    }

}

