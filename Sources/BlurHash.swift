// Taken from https://github.com/woltapp/blurhash/blob/712a47f946b98c30097eb1ada086ea00b18681ec/Swift/BlurHashDecode.swift
// and optimized.

import SmithereenAPI
import UIKit

private let base83Alphabet =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"
        .utf8

private let reverseLookupTable: [UInt8] = {
    var table = [UInt8](repeating: 0, count: 256)
    for (i, c) in base83Alphabet.enumerated() {
        table[Int(c)] = UInt8(i)
    }
    return table
}()

extension UInt8 {
    fileprivate func decode83() -> UInt64 {
        UInt64(reverseLookupTable[Int(self)])
    }
}

extension Sequence<UInt8> {
    fileprivate func decode83() -> UInt64 {
        reduce(0) { $0 * 83 + $1.decode83() }
    }
}

private func sRGBToLinear(_ value: UInt64) -> Float {
    let v = Float(value) / 255
    if v <= 0.04045 {
        return v / 12.92
    } else {
        return pow((v + 0.055) / 1.055, 2.4)
    }
}

private func linearTosRGB(_ value: Float) -> UInt8 {
    let v = max(0, min(1, value))
    if v <= 0.0031308 {
        return UInt8(v * 12.92 * 255 + 0.5)
    }
    else {
        return UInt8((1.055 * pow(v, 1 / 2.4) - 0.055) * 255 + 0.5)
    }
}

private func decodeDC(_ value: UInt64) -> (Float, Float, Float) {
    let intR = value >> 16
    let intG = (value >> 8) & 255
    let intB = value & 255
    return (sRGBToLinear(intR), sRGBToLinear(intG), sRGBToLinear(intB))
}

private func decodeAC(_ value: UInt64, maximumValue: Float) -> (Float, Float, Float) {
    let quantR = value / (19 * 19)
    let quantG = (value / 19) % 19
    let quantB = value % 19

    let rgb = (
        signPow((Float(quantR) - 9) / 9, 2) * maximumValue,
        signPow((Float(quantG) - 9) / 9, 2) * maximumValue,
        signPow((Float(quantB) - 9) / 9, 2) * maximumValue,
    )

    return rgb
}

private func signPow(_ value: Float, _ exp: Float) -> Float {
    return copysign(pow(abs(value), exp), value)
}

extension UIImage {

    /// - parameter resolution: The requested output size. Keep this small, and let UIKit scale it up for you.
    ///   32 pixels wide is plenty.
    /// - parameter punch: Adjusts the contrast of the output image.
    ///   Tweak it if you want a different look for your placeholders.
    convenience init?(
        blurHash: BlurHash,
        resolution: CGSize,
        punch: Float = 1,
    ) {
        let bytes = Array(blurHash.string.utf8)
        if bytes.count < 6 { return nil }
        let sizeFlag = bytes[0].decode83()
        let numY = (sizeFlag / 9) + 1
        let numX = (sizeFlag % 9) + 1
        let quantisedMaximumValue = bytes[1].decode83()
        let maximumValue = Float(quantisedMaximumValue + 1) / 166

        guard bytes.count == 4 + 2 * numX * numY else { return nil }

        let colors: [(Float, Float, Float)] = (0 ..< numX * numY).map { i in
            if i == 0 {
                let value = bytes[2 ..< 6].decode83()
                return decodeDC(value)
            } else {
                let start = 4 + Int(i) * 2
                let value = bytes[start ..< start + 2].decode83()
                return decodeAC(value, maximumValue: maximumValue * punch)
            }
        }

        let width = Int(resolution.width)
        let height = Int(resolution.height)
        let bytesPerRow = width * 3

        guard let data = CFDataCreateMutable(
            kCFAllocatorDefault,
            bytesPerRow * height
        ) else { return nil }

        CFDataSetLength(data, bytesPerRow * height)

        guard let pixels = CFDataGetMutableBytePtr(data) else { return nil }

        for y in 0 ..< height {
            for x in 0 ..< width {
                var r: Float = 0
                var g: Float = 0
                var b: Float = 0

                for j in 0 ..< numY {
                    for i in 0 ..< numX {
                        let basis = cos(.pi * Float(x) * Float(i) / Float(width)) *
                            cos(.pi * Float(y) * Float(j) / Float(height))
                        let color = colors[Int(i + j * numX)]
                        r += color.0 * basis
                        g += color.1 * basis
                        b += color.2 * basis
                    }
                }

                let intR = UInt8(linearTosRGB(r))
                let intG = UInt8(linearTosRGB(g))
                let intB = UInt8(linearTosRGB(b))

                let pixelStart = 3 * x + y * bytesPerRow
                pixels[pixelStart] = intR
                pixels[pixelStart + 1] = intG
                pixels[pixelStart + 2] = intB
            }
        }

        guard let provider = CGDataProvider(data: data) else { return nil }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent,
        ) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}
