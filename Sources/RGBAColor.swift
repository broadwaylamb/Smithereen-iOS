import SwiftUI

@propertyWrapper
struct RGBAColor: Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var wrappedValue: Color {
        Color(.displayP3, red: red, green: green, blue: blue, opacity: alpha)
    }

    var projectedValue: RGBAColor {
        self
    }
}

extension RGBAColor: _ExpressibleByColorLiteral {
    init(_colorLiteralRed red: Float, green: Float, blue: Float, alpha: Float) {
        self.init(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }
}

// https://mina86.com/2021/srgb-lab-lchab-conversions/

private let RAD_TO_DEG: Double = 180 / .pi

private let LAB_E: Double = 0.008856
private let LAB_16_116: Double = 0.1379310
private let LAB_K_116: Double = 7.787036
private let LAB_X: Double = 0.95047
private let LAB_Y: Double = 1
private let LAB_Z: Double = 1.08883

extension RGBAColor {

    private func toXYZ() -> XYZColor {
        func gammaExpansion(_ v: Double) -> Double {
            let absV = abs(v)
            let out = absV > 0.04045
            ? pow((absV + 0.055) / 1.055, 2.4)
            : absV / 12.92
            return v > 0 ? out : -out
        }

        let r = gammaExpansion(red)
        let g = gammaExpansion(green)
        let b = gammaExpansion(blue)
        return XYZColor(
            x: r * 0.4124108464885388   + g * 0.3575845678529519  + b * 0.18045380393360833,
            y: r * 0.21264934272065283  + g * 0.7151691357059038  + b * 0.07218152157344333,
            z: r * 0.019331758429150258 + g * 0.11919485595098397 + b * 0.9503900340503373,
            alpha: alpha,
        )
    }

    func toLCH() -> LCHColor {
        toXYZ().toLAB().toLCH()
    }
}

private struct XYZColor {
    var x: Double
    var y: Double
    var z: Double
    var alpha: Double

    fileprivate func toRGB() -> RGBAColor {
        func gammaCompression(_ v: Double) -> Double {
            let absV = abs(v)
            let out = absV > 0.0031308
            ? 1.055 * pow(absV, 1 / 2.4) - 0.055
            : absV * 12.92
            return v > 0 ? out : -out
        }

        let r = x *  3.240812398895283    + y * -1.5373084456298136  + z * -0.4985865229069666
        let g = x * -0.9692430170086407   + y *  1.8759663029085742  + z *  0.04155503085668564
        let b = x *  0.055638398436112804 + y * -0.20400746093241362 + z *  1.0571295702861434
        let R = gammaCompression(r)
        let G = gammaCompression(g)
        let B = gammaCompression(b)
        return RGBAColor(red: R, green: G, blue: B, alpha: alpha)
    }

    fileprivate func toLAB() -> LABColor {
        func f(_ v: Double) -> Double {
            return v > LABColor.epsilon
                ? pow(v, 1.0 / 3.0)
                : (LABColor.kappa * v + 16) / 116
        }

        let fx = f(x / LABColor.labX)
        let fy = f(y)
        let fz = f(z / LABColor.labZ)
        return LABColor(
            l: 116 * fy - 16,
            a: 500 * (fx - fy),
            b: 200 * (fy - fz),
            alpha: alpha,
        )
    }
}

private struct LABColor {
    var l: Double
    var a: Double
    var b: Double
    var alpha: Double

    static let epsilon: Double = 216.0 / 24389.0
    static let kappa: Double = 24389.0 / 27.0
    static let labX: Double = 0.9504492182750991
    static let labZ: Double = 1.0889166484304715

    func toXYZ() -> XYZColor {
        func fInv(_ v: Double) -> Double {
            let vCube = v * v * v
            return vCube > LABColor.epsilon
                ? vCube
                : (v * 116 - 16) / LABColor.kappa
        }

        let fy = (l + 16) / 116
        let fx = a / 500 + fy
        let fz = fy - (b / 200)
        let x = fInv(fx) * LABColor.labX
        let y = fInv(fy)
        let z = fInv(fz) * LABColor.labZ
        return XYZColor(
            x: x,
            y: y,
            z: z,
            alpha: alpha,
        )
    }

    func toLCH() -> LCHColor {
        LCHColor(
            l: l,
            c: sqrt(a * a + b * b),
            h: atan2(b, a) * 180 / .pi ,
            alpha: alpha,
        )
    }
}

struct LCHColor {
    var l: Double
    var c: Double
    var h: Double {
        didSet {
            h = sanitizeAngle(h)
        }
    }
    var alpha: Double

    init(l: Double, c: Double, h: Double, alpha: Double) {
        self.l = l
        self.c = c
        self.h = sanitizeAngle(h)
        self.alpha = alpha
    }

    fileprivate func toLAB() -> LABColor {
        let rad = h * .pi / 180
        return LABColor(
            l: l,
            a: cos(rad) * c,
            b: sin(rad) * c,
            alpha: alpha,
        )
    }

    func toRGB() -> RGBAColor {
        toLAB().toXYZ().toRGB()
    }
}

private func sanitizeAngle(_ degrees: Double) -> Double {
    let rem = degrees.remainder(dividingBy: 360)
    if rem < 0 {
        return rem + 360
    } else {
        return rem
    }
}

