//
//  ViewController.swift
//  DFSphereView
//
//  Created by 付 旦 on 3/7/20.
//  Copyright © 2020 付 旦. All rights reserved.
//

import UIKit
import DFSphereViewFramework

class ViewController: UIViewController {

    let dateSource = ["hello", "hola", "o hai yo", "adios", "amingo", "c la vi"]
    @IBOutlet var sphereview: DFSphereView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var array = [UIView]()
        dateSource.forEach { (prompt) in
            let tagView = UILabel.init(frame: CGRect.init(origin: .zero, size: .init(width: 128, height: 44)))
            tagView.text = prompt
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(buttonPressed(ges:)))
            tagView.addGestureRecognizer(tap)
            tagView.text = prompt
            array.append(tagView)
        }
        sphereview.setCloudTags(array)
    }
    
    @objc func buttonPressed(ges: UIGestureRecognizer) {
        sphereview.timerStop()
        let btn = ges.view ?? UIView()
        UIView.animate(withDuration: 0.3, animations: {
            btn.transform = CGAffineTransform(scaleX: 2, y: 2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, animations: {
                btn.transform = CGAffineTransform(scaleX: 1, y: 1);
            }, completion: { _ in
                self.sphereview.timerStart()
            })
        })
    }


}

