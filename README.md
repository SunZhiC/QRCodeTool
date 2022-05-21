# QRCodeTool
Swift 5.6

### Scan, read, create tool.

### 二维码扫描、读取、生成工具

Use camera to scan qrcode, open light, create qrcode from string, add middle image, all in one line.
一行代码实现摄像头二维码扫描、二维码生成、二维码读取，开启闪光灯，为二维码添加中间小图片

**From iOS 10, you should add Privacy - Camera Usage Description in info.plist.**

**从iOS10开始，开启摄像头需要在info.plist文件中添加名称为Privacy - Camera Usage Description 的key**

create a qrcode image from string
```swift
let image = QRCodeTool.shared.createQRCode(input: "https://developer.apple.com/", middleImage: UIImage(named: "test"), scale: .init(x: 0.2, y: 0.2))
```

scan qrcode from camera
```swift
QRCodeTool.shared.scanQRCode(inView: view, isDrawFrame: true) { (result : [String]) in
    print(result)
}
```
