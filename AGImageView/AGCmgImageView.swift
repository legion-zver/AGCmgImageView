//
//  AGImageView.swift
//  AGImageView
//
//  Created by Александр Зверь on 16.11.16.
//  Copyright © 2016 ALEXANDER GARIN. All rights reserved.
//

import Cmg
import UIKit

@IBDesignable
class AGCmgImageView: UIView
{
    // Наше базовое изображение
    public var image: UIImage? = nil {
        didSet {
            if self.usePreview {
                self.createPreviewImage()
                if self.imagePreview == nil {
                    usePreview = false
                }
            } else {
                self.imageLayer.contents = image?.cgImage
            }
            self.calcImageLayerSize()
            self.updateImageTransform()
            self.applyFilters()
        }
    }
    
    // Использовать превью
    @IBInspectable public var usePreview: Bool = false {
        didSet {
            if !self.usePreview && self.imagePreview != nil {
                self.imagePreview = nil
            } else {
                self.createPreviewImage()
                if self.imagePreview == nil {
                    usePreview = false
                }
            }
            self.applyFilters()
        }
    }
    
    // Превью
    private var imagePreview: UIImage? = nil
    
    private let imageLayer: CALayer = CALayer()
    
    private let netLayer: CAShapeLayer = CAShapeLayer()

    @IBInspectable public var netSize:Int = 1 {
        didSet {
            self.updateNet()
        }
    }
    
    // MARK: - Режим обрезки - смещение / масштаб
    @IBInspectable public var isCropping: Bool = false {
        didSet {
            self.netLayer.isHidden = !isCropping
        }
    }
    
    // MARK: - Смещение изображения
    @IBInspectable public var offsetX: CGFloat = 0.0 {
        didSet {
            offsetX = self.testImageOffsetX()
            self.imageLayer.position.x = offsetX + (self.frame.size.width*0.5)
        }
    }
    
    @IBInspectable public var offsetY: CGFloat = 0.0 {
        didSet {
            offsetY = self.testImageOffsetY()
            self.imageLayer.position.y = offsetY + (self.frame.size.height*0.5)
        }
    }
    
    // MARK: - Поворот изображения
    @IBInspectable public var usePerspectiveRotation: Bool = false {
        didSet {
            self.updateImageTransform()
        }
    }
    
    @IBInspectable public var angleX: CGFloat = 0.0 {
        didSet {
            self.updateImageTransform()
        }
    }
    
    @IBInspectable public var angleY: CGFloat = 0.0 {
        didSet {
            self.updateImageTransform()
        }
    }
    
    @IBInspectable public var angleZ: CGFloat = 0.0 {
        didSet {
            self.updateImageTransform()
        }
    }
    
    // MARK: - Масштаб
    @IBInspectable public var scale: CGFloat = 1.0 {
        didSet {
            if scale < minScale {
                scale = minScale
            } else if scale > maxScale {
                scale = maxScale
            }
            self.updateImageTransform()
        }
    }
    
    // MARK: - Ограничения масштаба
    public var minScale: CGFloat {
        get {
            return self.minScaleValue
        }
    }
    
    public var maxScale: CGFloat {
        get {
            return self.maxScaleValue
        }
    }
    private var minScaleValue: CGFloat = 1.0
    private var maxScaleValue: CGFloat = 1.0
    
    // MARK: - Фильтры
    private var applyFiltersProccIndex: Int = 0
    
    @IBInspectable public var brightness: CGFloat = 0.0 {
        didSet {
            self.applyFilters()
        }
    }
    
    @IBInspectable public var contrast: CGFloat = 1.0 {
        didSet {
            self.applyFilters()
        }
    }
    
    @IBInspectable public var saturation: CGFloat = 1.0 {
        didSet {
            self.applyFilters()
        }
    }
    
    @IBInspectable public var gamma: CGFloat = 1.0 {
        didSet {
            self.applyFilters()
        }
    }
    
    public var filters = [Filterable]() {
        didSet {
            self.applyFilters()
        }
    }
    
    @IBInspectable public var resultClearBackground: Bool = true
    
    // MARK: - Инициализация
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initLayers()
    }
    
    private func initLayers() {
        
        self.isMultipleTouchEnabled = true
        
        self.imageLayer.name = "image"
        self.layer.addSublayer(self.imageLayer)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(AGCmgImageView.panHandle(recognizer:)))
        self.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(AGCmgImageView.pinchHandle(recognizer:)))
        self.addGestureRecognizer(pinch)
        
        self.netLayer.name = "net"
        //self.netLayer.isHidden = true
        self.netLayer.isHidden = !self.isCropping
        self.netLayer.lineWidth = 1.0
        self.netLayer.strokeColor = UIColor.white.cgColor
        self.layer.addSublayer(self.netLayer)
        
        self.updateNet()
        self.calcImageLayerSize()
    }
    
    // MARK: - Работа с фильтрами
    private func createPreviewImage() {
        if self.image != nil {
            // Создаем изображение для preview из базового изображения
            if self.superview != nil {
                self.imagePreview = self.image?.cmg_resizeAtAspectFit(self.bounds.size)
            } else {
                self.imagePreview = self.image?.cmg_resizeAtAspectFit(CGSize(width: 400, height: 400))
            }
        }
    }
    
    private func applyFilters(onlyBaseImage: Bool = false, callback:((_ success: Bool)->Void)? = nil) {
        if image != nil {
            if applyFiltersProccIndex <= 0 || onlyBaseImage {
                self.applyFiltersProccIndex += 1
                DispatchQueue.global().async {
                    var allfilters = [Filterable]()
                    allfilters.append(ColorControls().configuration { (c: ColorControls) in
                        c.inputContrast.setValue(Float(self.contrast))
                        c.inputBrightness.setValue(Float(self.brightness))
                        c.inputSaturation.setValue(Float(self.saturation))
                    })                
                    allfilters.append(GammaAdjust().configuration({ (g:GammaAdjust) in
                        g.inputPower.setValue(Float(self.gamma))
                    }))
                    if self.filters.count > 0 {
                        allfilters.append(contentsOf: self.filters)
                    }
                    let newImage:UIImage?
                    
                    if self.usePreview && !onlyBaseImage {
                        newImage = self.imagePreview?.cmg_chain(allfilters)
                    } else {
                        newImage = self.image?.cmg_chain(allfilters)
                    }
                    if newImage != nil {
                        DispatchQueue.main.async {
                            self.imageLayer.contents = newImage?.cgImage
                            
                            CATransaction.begin()
                            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                            
                            self.calcImageLayerSize()
                            self.updateImageTransform()
                            
                            CATransaction.commit()
                        }
                    }
                    if self.applyFiltersProccIndex > 1 {
                        DispatchQueue.main.async {
                            self.applyFiltersProccIndex = 0
                            self.applyFilters(onlyBaseImage: onlyBaseImage, callback: callback)
                        }
                    } else {
                        self.applyFiltersProccIndex = 0
                        if callback != nil {
                            callback?(true) // Вызываем callback
                        }
                    }
                }
            } else {
                if applyFiltersProccIndex < 2 {
                    applyFiltersProccIndex += 1
                }
            }
            return
        }
        callback?(false)
    }
    
    // MARK: - Жесты
    
    @objc private func pinchHandle(recognizer: UIPinchGestureRecognizer) {
        if self.isCropping && self.superview != nil {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            
            self.scale += recognizer.scale-1.0
            
            self.offsetX = self.testImageOffsetX()
            self.offsetY = self.testImageOffsetY()
            
            CATransaction.commit()
        }
        recognizer.scale = 1.0
    }
    
    @objc private func panHandle(recognizer: UIPanGestureRecognizer) {
        DispatchQueue.main.async {
            if self.isCropping && self.superview != nil {
                let translation = recognizer.translation(in: self.superview)
                
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                
                self.offsetX += translation.x
                self.offsetY += translation.y
                
                CATransaction.commit()
                
                recognizer.setTranslation(CGPoint.zero, in: self.superview)
            }
        }
    }
    
    // MARK: - Сеть
    
    private func updateNet() {
        self.netLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        
        let path = UIBezierPath()
        
        let stepX: CGFloat = self.netLayer.frame.width / max(2.0, CGFloat(self.netSize)+1.0)
        let stepY: CGFloat = self.netLayer.frame.height / max(2.0, CGFloat(self.netSize)+1.0)
        
        var pos:CGFloat = stepX
        for _ in 0..<self.netSize {
            path.move(to: CGPoint(x: pos, y: 0))
            path.addLine(to: CGPoint(x: pos, y: self.netLayer.frame.height))
            pos += stepX
        }
        
        pos = stepY
        for _ in 0..<self.netSize {
            path.move(to: CGPoint(x: 0, y: pos))
            path.addLine(to: CGPoint(x: self.netLayer.frame.width, y: pos))
            pos += stepY
        }
        
        self.netLayer.path = path.cgPath
        self.netLayer.setNeedsDisplay()
    }
    
    // MARK: - Обновление размеров
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Обновляем размеры
        self.calcImageLayerSize()
        self.updateNet()
    }
    
    
    // MARK: - Работа с размерами слоя
    
    private func testImageOffsetX()->CGFloat {
        let dw:CGFloat = (self.imageLayer.frame.size.width - self.frame.size.width)*0.5
        if dw > 0 {
            if self.offsetX > dw {
                return dw
            } else if self.offsetX < -dw {
                return -dw
            }
            return self.offsetX
        }
        return 0
    }
    
    private func testImageOffsetY()->CGFloat{
        let dh:CGFloat = (self.imageLayer.frame.size.height - self.frame.size.height)*0.5
        if dh > 0 {
            if offsetY > dh {
                return dh
            } else if offsetY < -dh {
                return -dh
            }
            return self.offsetY
        }
        return 0
    }
    
    private func updateImageTransform() {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)        
        
        self.calcImageLayerSize()
        
        var transform = CATransform3DMakeScale(self.scale*1.00001, self.scale*1.00001, self.scale*1.00001)
        
        if self.usePerspectiveRotation {
            transform.m34 = -1.0/500.0
        }
        
        if self.angleX != 0 {
            transform = CATransform3DRotate(transform, self.angleX*CGFloat(M_PI)/180, 1.0,  0.0, 0.0)
        }
        if self.angleY != 0 {
            transform = CATransform3DRotate(transform, self.angleY*CGFloat(M_PI)/180, 0.0, 1.0, 0.0)
        }
        if self.angleZ != 0 {
            transform = CATransform3DRotate(transform, self.angleZ*CGFloat(M_PI)/180, 0.0, 0.0, 1.0)
        }
        self.imageLayer.transform = transform
        
        CATransaction.commit()
    }
    
    private func updateMinMaxScale() {
        let size = self.getImageLayerBaseSize()
        
        let sW:CGFloat = self.frame.width / size.width
        let sH:CGFloat = self.frame.height / size.height
        
        self.minScaleValue = min(sW, sH)
        self.maxScaleValue = max(sW, sH)
        
        if self.scale < self.minScaleValue && self.minScaleValue > 0.0 {
            self.scale = self.minScaleValue
        } else if self.scale > self.maxScaleValue && self.maxScaleValue > 0.0 {
            self.scale = self.minScaleValue
        }
    }
    
    private func getImageLayerBaseSize()->CGSize {
        var destWidth:  CGFloat = self.frame.width
        var destHeight: CGFloat = self.frame.height
        if self.image != nil {
        let imageSize:  CGSize  = (self.image?.size)!
            if self.contentMode == .scaleAspectFit {
                if imageSize.width > imageSize.height {
                    destHeight = (imageSize.height * self.frame.width / imageSize.width)
                } else {
                    destWidth = (imageSize.width * self.frame.height / imageSize.height)
                }
                if destWidth > self.frame.width {
                    destWidth = self.frame.width
                    destHeight = (imageSize.height * self.frame.width / imageSize.width)
                }
                if (destHeight > self.frame.height) {
                    destHeight = self.frame.height
                    destWidth = (imageSize.width * self.frame.height / imageSize.height)
                }
            } else {
                let widthRatio = self.frame.width / imageSize.width
                let heightRatio = self.frame.height / imageSize.height
                
                if heightRatio > widthRatio {
                    destHeight = self.frame.height
                    destWidth = (imageSize.width * self.frame.height / imageSize.height)
                } else {
                    destWidth = self.frame.width;
                    destHeight = (imageSize.height * self.frame.width / imageSize.width)
                }
            }
        }
        return CGSize(width: destWidth, height: destHeight)
    }
    
    private func calcImageLayerSize() {
        if self.image != nil {
            
            let size = self.getImageLayerBaseSize()
            
            self.imageLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.imageLayer.position = CGPoint(x: offsetX + self.frame.size.width*0.5, y: offsetY + self.frame.size.height*0.5)
            
            self.updateMinMaxScale()
        }
    }
    
    // MARK: - Create Result Image
    
    public func createResultImage(resolutionSize: CGFloat = 720.0, callback: @escaping (_ image: UIImage?)->Void) {
        self.applyFilters(onlyBaseImage: true, callback: { (success: Bool) in
            if success  {
                self.setNeedsDisplay()
                DispatchQueue.main.async {
                    // Расчет размеров конечного изображения
                    let frameSize = CGSize(width: min(self.imageLayer.frame.size.width, self.frame.size.width), height: min(self.imageLayer.frame.size.height, self.frame.size.height))
                    
                    let imageSize: CGSize
                    
                    let k: CGFloat
                    
                    if frameSize.width >= self.frame.size.width {
                        imageSize = CGSize(width: Int(resolutionSize), height: Int(resolutionSize*(frameSize.height / frameSize.width)))
                        k = (imageSize.width / self.frame.size.width)
                        
                    } else {
                        imageSize = CGSize(width: Int(resolutionSize*(frameSize.width / frameSize.height)), height: Int(resolutionSize))
                        k = (imageSize.height / self.frame.size.height)
                    }
                    
                    // Расчитываем смещение
                    let renderSize = CGSize(width: Int(k*self.frame.size.width), height: Int(k*self.frame.size.height))
                    
                    // Расчет смещения
                    let renderOffset = CGPoint(x: Int((imageSize.width-renderSize.width)*0.5), y: Int((imageSize.height-renderSize.height)*0.5))
                    
                    let bkgTmp = self.backgroundColor
                    
                    let isHiddenNet = self.netLayer.isHidden
                    self.netLayer.isHidden = true
                    
                    if self.resultClearBackground {
                        self.backgroundColor = UIColor.clear
                    }
                    
                    UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
                    if let context = UIGraphicsGetCurrentContext() {
                        context.clear(CGRect(origin: CGPoint.zero, size: imageSize))
                    }
                    self.drawHierarchy(in: CGRect(origin: renderOffset, size: renderSize), afterScreenUpdates: true)
                    let img = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    self.backgroundColor = bkgTmp
                    self.netLayer.isHidden = isHiddenNet
                    
                    callback(img)
                }
                return
            }
            callback(nil)
        })
    }
}
