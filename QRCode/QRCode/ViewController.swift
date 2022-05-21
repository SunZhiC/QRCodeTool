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
        createQRCode()
    }
    
    func openScan() {
        let qr = QRCodeTool.shared
        qr.scanQRCode(inView: view, isDrawFrame: true) { (result : [String]) in
            print(result)
        }
        qr.setScanRect(scanRect: scanView.frame)
        qr.setTorch(isOn: false)
    }
    
    func createQRCode() {
        let image = QRCodeTool.shared.createQRCode(input: "https://developer.apple.com/", middleImage: UIImage(named: "test"), scale: .init(x: 0.2, y: 0.2))
        let imageView = UIImageView(image: image)
        scanView.addSubview(imageView)
        imageView.frame = scanView.bounds
    }




}

