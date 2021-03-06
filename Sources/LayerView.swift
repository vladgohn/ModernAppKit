// MIT License
//
// Copyright © 2016-2017 Darren Mo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa

/// A layer-backed view with additional APIs for setting background color,
/// border width, border color, and corner radius. Use if you do not need
/// to do custom drawing. Supports animations.
open class LayerView: NSView {
   // MARK: Layer Properties

   public enum BorderWidth {
      case points(_: CGFloat)
      case pixels(_: CGFloat)

      func inPoints(usingScale contentsScale: CGFloat) -> CGFloat {
         switch self {
         case .points(let borderWidthInPoints):
            return borderWidthInPoints

         case .pixels(let borderWidthInPixels):
            return borderWidthInPixels / contentsScale
         }
      }

      func inPixels(usingScale contentsScale: CGFloat) -> CGFloat {
         switch self {
         case .points(let borderWidthInPoints):
            return borderWidthInPoints * contentsScale

         case .pixels(let borderWidthInPixels):
            return borderWidthInPixels
         }
      }
   }

   /// The background color of the view. Corresponds to the
   /// `backgroundColor` property of `CALayer`. Animatable.
   ///
   /// The default value is no color.
   @objc
   public dynamic var backgroundColor = NSColor.clear {
      didSet {
         needsDisplay = true
      }
   }

   /// The width of the border around the view. Corresponds to the
   /// `borderWidth` property of `CALayer`.
   ///
   /// To animate, use `animatableBorderWidthInPoints` or
   /// `animatableBorderWidthInPixels`.
   ///
   /// The default value is 0.
   public var borderWidth: BorderWidth {
      get {
         return _borderWidth
      }

      set {
         _borderWidth = newValue

         // Stop animations
         willChangeValue(forKey: "animatableBorderWidthInPoints")
         didChangeValue(forKey: "animatableBorderWidthInPoints")
         willChangeValue(forKey: "animatableBorderWidthInPixels")
         didChangeValue(forKey: "animatableBorderWidthInPixels")
      }
   }
   private var _borderWidth = BorderWidth.points(0) {
      didSet {
         needsDisplay = true
      }
   }

   /// An animatable version of the `borderWidth` property. Values
   /// are in points.
   ///
   /// The `fromValue` of the animation will be automatically set
   /// to the current value of `borderWidth`.
   @objc
   public dynamic var animatableBorderWidthInPoints: CGFloat = 0 {
      didSet {
         _borderWidth = .points(animatableBorderWidthInPoints)
      }
   }

   /// An animatable version of the `borderWidth` property. Values
   /// are in pixels.
   ///
   /// The `fromValue` of the animation will be automatically set
   /// to the current value of `borderWidth`.
   @objc
   public dynamic var animatableBorderWidthInPixels: CGFloat = 0 {
      didSet {
         _borderWidth = .pixels(animatableBorderWidthInPixels)
      }
   }

   private var contentsScale: CGFloat = 1.0

   /// The color of the border around the view. Corresponds to the
   /// `borderColor` property of `CALayer`. Animatable.
   ///
   /// The default value is opaque black.
   @objc
   public dynamic var borderColor = NSColor.black {
      didSet {
         needsDisplay = true
      }
   }

   /// The radius of the rounded corners of the view. Corresponds to the
   /// `cornerRadius` property of `CALayer`. Animatable.
   ///
   /// The default value is 0.
   @objc
   public dynamic var cornerRadius: CGFloat = 0 {
      didSet {
         needsDisplay = true
      }
   }

   // MARK: Initialization

   private static let backgroundColorCoderKey = "mo.darren.ModernAppKit.LayerView.backgroundColor"
   private static let isBorderWidthInPointsCoderKey = "mo.darren.ModernAppKit.LayerView.isBorderWidthInPoints"
   private static let borderWidthCoderKey = "mo.darren.ModernAppKit.LayerView.borderWidth"
   private static let borderColorCoderKey = "mo.darren.ModernAppKit.LayerView.borderColor"
   private static let cornerRadiusCoderKey = "mo.darren.ModernAppKit.LayerView.cornerRadius"

   public override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)

      commonInit()
   }

   public required init?(coder: NSCoder) {
      guard let backgroundColor = coder.decodeObject(forKey: LayerView.backgroundColorCoderKey) as? NSColor else {
         return nil
      }
      self.backgroundColor = backgroundColor

      let isBorderWidthInPoints = coder.decodeBool(forKey: LayerView.isBorderWidthInPointsCoderKey)
      let borderWidth = CGFloat(coder.decodeDouble(forKey: LayerView.borderWidthCoderKey))
      if isBorderWidthInPoints {
         self._borderWidth = .points(borderWidth)
      } else {
         self._borderWidth = .pixels(borderWidth)
      }

      guard let borderColor = coder.decodeObject(forKey: LayerView.borderColorCoderKey) as? NSColor else {
         return nil
      }
      self.borderColor = borderColor

      self.cornerRadius = CGFloat(coder.decodeDouble(forKey: LayerView.cornerRadiusCoderKey))

      super.init(coder: coder)

      commonInit()
   }

   open override func encode(with aCoder: NSCoder) {
      super.encode(with: aCoder)

      aCoder.encode(backgroundColor, forKey: LayerView.backgroundColorCoderKey)

      switch borderWidth {
      case .points(let borderWidthInPoints):
         aCoder.encode(true, forKey: LayerView.isBorderWidthInPointsCoderKey)
         aCoder.encode(Double(borderWidthInPoints), forKey: LayerView.borderWidthCoderKey)

      case .pixels(let borderWidthInPixels):
         aCoder.encode(false, forKey: LayerView.isBorderWidthInPointsCoderKey)
         aCoder.encode(Double(borderWidthInPixels), forKey: LayerView.borderWidthCoderKey)
      }

      aCoder.encode(borderColor, forKey: LayerView.borderColorCoderKey)
      aCoder.encode(Double(cornerRadius), forKey: LayerView.cornerRadiusCoderKey)
   }

   private func commonInit() {
      wantsLayer = true
      layerContentsRedrawPolicy = .onSetNeedsDisplay

      let animatableProperties = [
         "backgroundColor",
         "animatableBorderWidthInPoints",
         "animatableBorderWidthInPixels",
         "borderColor",
         "cornerRadius"
      ]
      for propertyName in animatableProperties {
         let key = NSAnimatablePropertyKey(rawValue: propertyName)
         animations[key] = CABasicAnimation(keyPath: propertyName)
      }
   }

   // MARK: Updating the Layer

   open override var wantsUpdateLayer: Bool {
      return true
   }

   open override func updateLayer() {
      guard let layer = layer else {
         return
      }

      layer.backgroundColor = backgroundColor.cgColor

      layer.borderWidth = borderWidth.inPoints(usingScale: contentsScale)
      layer.borderColor = borderColor.cgColor

      layer.cornerRadius = cornerRadius
   }

   open override func viewDidChangeBackingProperties() {
      super.viewDidChangeBackingProperties()

      contentsScale = window?.backingScaleFactor ?? 1.0
   }

   // MARK: Animations

   open override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
      guard let animationObj = super.animation(forKey: key) else {
         return nil
      }
      guard let animation = animationObj as? CABasicAnimation else {
         return animationObj
      }

      switch key.rawValue {
      case "animatableBorderWidthInPoints":
         guard animation.fromValue == nil else {
            break
         }

         // Set fromValue to current borderWidth value, which may be
         // different from current animatableBorderWidthInPoints value
         animation.fromValue = borderWidth.inPoints(usingScale: contentsScale)

      case "animatableBorderWidthInPixels":
         guard animation.fromValue == nil else {
            break
         }

         // Set fromValue to current borderWidth value, which may be
         // different from current animatableBorderWidthInPixels value
         animation.fromValue = borderWidth.inPixels(usingScale: contentsScale)

      default:
         break
      }

      return animation
   }
}
