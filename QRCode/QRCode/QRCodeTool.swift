//
//  QRCodeTool.swift
//  QRCoder
//
//  Created by Sun on 2016/10/9.
//  Copyright © 2016年 sunzhichao. All rights reserved.
//

import AVFoundation
import UIKit

typealias ScanResult = ([String]) -> ()

class QRCodeTool: NSObject {
    static let shared = QRCodeTool()
    
    fileprivate lazy var input: AVCaptureDeviceInput? = {
        let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: .back)
        let backDevice = deviceSession.devices[0]
        var isFlash = backDevice.hasFlash
        
        print(isFlash.hashValue)
        let input = try? AVCaptureDeviceInput(device: deviceSession.devices[0])
        return input
    }()
    
    fileprivate lazy var output: AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    
    fileprivate lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        return session
    }()
    
    fileprivate lazy var preLayer: AVCaptureVideoPreviewLayer? = {
        let preLayer = AVCaptureVideoPreviewLayer(session: self.session)
        // 设置视频预览图层尺寸适配方法
        preLayer.videoGravity = .resizeAspectFill
        return preLayer
    }()
    
    var isDrawFrame: Bool = false
    
    var resultBlock: ScanResult?
}

// MARK: - 开启摄像头扫描二维码

extension QRCodeTool {
    /// 扫描二维码
    ///
    /// - parameter inView:      视频预览图层的承载视图
    /// - parameter isDrawFrame: 是否需要绘制边框
    /// - parameter resultBlock: 结果代码块
    public func scanQRCode(inView: UIView, isDrawFrame: Bool = false, resultBlock: ScanResult?) {
        self.resultBlock = resultBlock
        
        self.isDrawFrame = isDrawFrame
        
        // 创建一个会话，连接输入和输出
        if let input = input {
            if session.canAddInput(input), session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
            }
        }
        
        // 输出处理对象，可以处理的数据类型
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        // 添加视频预览图层，然后用户可以看见扫描界面
        preLayer!.frame = UIScreen.main.bounds
        inView.layer.insertSublayer(preLayer!, at: 0)
        
        // 5.启动会话
        session.startRunning()
    }
    
    /// 取消扫描
    func stopScan() {
        session.stopRunning()
    }
}

// MARK: - 设置扫描区域

extension QRCodeTool {
    /// 设置扫描区域
    ///
    /// - parameter scanRect: 扫描区域
    func setScanRect(scanRect: CGRect) {
        let screenSize = UIScreen.main.bounds.size
        let xR = scanRect.origin.x / screenSize.width
        let yR = scanRect.origin.y / screenSize.height
        let wR = scanRect.size.width / screenSize.width
        let hR = scanRect.size.height / screenSize.height
        output.rectOfInterest = CGRect(x: yR, y: xR, width: hR, height: wR)
    }
}

// MARK: - 闪光灯开关

extension QRCodeTool {
    /// 闪光灯开关
    ///
    /// - parameter isOn: 闪光灯状态
    func setTorch(isOn: Bool) {
        let device = input?.device
        if device?.hasTorch ?? false {
            //  操作设备之前，必须先搜定设备
            try? device?.lockForConfiguration()
            // 进行修改配置
            device?.torchMode = isOn ? .on : .off
            // 解锁设备
            device?.unlockForConfiguration()
        }
    }
}

extension QRCodeTool {
    
    /// 根据字符串和图片比例生成一张二维码图片，可以添加自定义中间图片
    /// - Parameters:
    ///   - input: 输入的字符串内容
    ///   - definition: 图片清晰度，建议不低于20
    ///   - middleImage: 自定义的中间图片
    ///   - scale: 图片的缩放比例，默认(0.3， 0.3)
    /// - Returns: 二维码图片
    func createQRCode(input: String, definition: CGPoint = .init(x: 30, y: 30), middleImage: UIImage?, scale: CGPoint = CGPoint(x: 0.3, y: 0.3)) -> UIImage {
        // 1.创建二维码滤镜
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        // 恢复滤镜设置
        filter?.setDefaults()
        
        // 2.给滤镜设置输入内容，只能用KVC设置输入的内容
        let data = input.data(using: String.Encoding.utf8)
        
        filter?.setValue(data, forKeyPath: "inputMessage")
        // 设置纠错率
        filter?.setValue("H", forKeyPath: "inputCorrectionLevel")
        
        // 3.直接取出图片
        let outImage = filter?.outputImage
        
        // 4.对图片进行处理
        let resImage = outImage?.transformed(by: CGAffineTransform(scaleX: definition.x, y: definition.y))
        let image = UIImage(ciImage: resImage!)
        
        guard middleImage != nil else {
            return image
        }
        return addMiddleImage(image: middleImage!, toBackImage: image, scale: scale)
    }
    
    /// 根据一个二维码图片，查看二维码结果，并返回
    ///
    /// - parameter qrImage: 二维码图片
    ///
    /// - returns: 识别结果和绘制好边框的二维码图片
    func detectorQRCode(qrImage: UIImage) -> (resultStrs: [String], resultImg: UIImage) {
        // 1.创建一个二维码探测器
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        // 2.探测图片的特征值
        let ciImage = CIImage(image: qrImage)
        guard let features = detector?.features(in: ciImage!) else {
            return ([], qrImage)
        }
        
        // 3.处理特征值
        var resultImg = qrImage
        var resultStrs = [String]()
        for feature in features as! [CIQRCodeFeature] {
            resultStrs.append(feature.messageString!)
            // 在识别出来的图片周围添加相框
            resultImg = drawFrame(feature: feature, image: resultImg)
        }
        return (resultStrs, resultImg)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeTool: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if isDrawFrame {
            removeQRCodeFrame(layer: preLayer!)
        }
        
        var resultStrs = [String]()
        
        for metadataObject in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            if isDrawFrame {
                drawQRCodeFrame(metadataObject: metadataObject, layer: preLayer!)
            }
            resultStrs.append(metadataObject.stringValue ?? "")
        }
        
        resultBlock?(resultStrs)
    }
}

private extension QRCodeTool {
    func addMiddleImage(image: UIImage, toBackImage: UIImage, scale: CGPoint) -> UIImage {
        // 开启图形上下文
        let size: CGSize = toBackImage.size
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        
        // 绘制大图片
        toBackImage.draw(in: CGRect(x: 0, y: 0, width: size
                .width, height: size.height))
        
        // 绘制小图片
        let w = size.width * scale.x
        let h = size.height * scale.y
        let x = (size.width - w) * 0.5
        let y = (size.height - h) * 0.5
        
        image.draw(in: CGRect(x: x, y: y, width: w, height: h))
        
        // 从图形上下文中取得图片
        let curImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        guard curImage != nil else {
            return toBackImage
        }
        return curImage!
    }
    
    func drawFrame(feature: CIQRCodeFeature, image: UIImage) -> UIImage {
        // 1.开启图形上下文
        let size = image.size
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        
        // 2.绘制大图片
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 3.翻转坐标系
        let context = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -size.height)
        
        UIColor.red.setStroke()
        let bounds = feature.bounds
        let path = UIBezierPath(rect: bounds)
        path.lineWidth = 10
        path.stroke()
        
        // 4.获取新图片
        let curImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        
        // 5.关闭图形上下文
        UIGraphicsEndImageContext()
        
        return curImage
    }
    
    func removeQRCodeFrame(layer: AVCaptureVideoPreviewLayer) {
        if let layers = layer.sublayers {
            for layer in layers {
                if layer.isKind(of: CAShapeLayer.self) {
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
    
    func drawQRCodeFrame(metadataObject: AVMetadataMachineReadableCodeObject, layer: AVCaptureVideoPreviewLayer) {
        guard let qrObj = layer.transformedMetadataObject(for: metadataObject) as? AVMetadataMachineReadableCodeObject else { return }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 6
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        let path = UIBezierPath()
        
        let pointArray = qrObj.corners
        for (index, point) in pointArray.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.close()
        shapeLayer.path = path.cgPath
        
        layer.addSublayer(shapeLayer)
    }
}
