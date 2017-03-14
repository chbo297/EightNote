//
//  EightNoteHead.swift
//  EightNote
//
//  Created by bo on 13/03/2017.
//  Copyright © 2017 bo. All rights reserved.
//

import UIKit

class EightNoteHead: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.backgroundColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.layer.bounds.size.width/2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
