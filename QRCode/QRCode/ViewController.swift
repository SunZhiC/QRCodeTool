//
//  ViewController.swift
//  QRCode
//
//  Created by Sun on 2016/10/10.
//  Copyright © 2016年 sunzhichao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var scanView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let qr = QRCodeTool.shareInstance
        qr.scanQRCode(inView: view, isDrawFrame: true) { (result : [String]) in
            print(result)
        }
        qr.setScanRect(scanRect: scanView.frame)
        qr.setTorch(isOn: true)
    }




}

