//
//  ImageProcessor.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit
import AVFoundation
import CoreLocation

enum ModeAbsensi {
    case PERLU_LOKASI
    case TANPA_LOKASI
}

class ImageProcessor {
    
    static func processAndSave(
        file: URL,
        isFrontCamera: Bool,
        lat: Double?,
        lon: Double?,
        mode: ModeAbsensi,
        quality: CGFloat = 0.7
    ) {
        guard let original = UIImage(contentsOfFile: file.path) else { return }
        
        let rotated = fixOrientation(bitmap: original, file: file, isFrontCamera: isFrontCamera)
        let watermarked = addWatermark(bitmap: rotated, lat: lat, lon: lon, mode: mode)
        
        if let data = watermarked.jpegData(compressionQuality: quality) {
            try? data.write(to: file)
        }
    }
    
    private static func fixOrientation(
        bitmap: UIImage,
        file: URL,
        isFrontCamera: Bool
    ) -> UIImage {
        
        var rotation: CGFloat = 0
        
        // Read EXIF orientation
        if let imageSource = CGImageSourceCreateWithURL(file as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
           let orientationValue = properties[kCGImagePropertyOrientation as String] as? UInt32 {
            
            switch orientationValue {
            case 3: rotation = 180
            case 6: rotation = 90
            case 8: rotation = 270
            default: rotation = 0
            }
        }
        
        guard let cgImage = bitmap.cgImage else { return bitmap }
        
        var transform = CGAffineTransform.identity
        
        // Apply rotation
        if rotation != 0 {
            transform = transform.rotated(by: rotation * .pi / 180)
        }
        
        // Mirror for front camera
        if isFrontCamera {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        // If no transformation needed, return original
        if transform.isIdentity {
            return bitmap
        }
        
        // Create context and apply transformation
        let width = cgImage.width
        let height = cgImage.height
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return bitmap }
        
        context.concatenate(transform)
        
        let drawRect: CGRect
        if isFrontCamera {
            drawRect = CGRect(x: -width, y: 0, width: width, height: height)
        } else {
            drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        context.draw(cgImage, in: drawRect)
        
        if let newCGImage = context.makeImage() {
            return UIImage(cgImage: newCGImage)
        }
        
        return bitmap
    }
    
    private static func addWatermark(
        bitmap: UIImage,
        lat: Double?,
        lon: Double?,
        mode: ModeAbsensi
    ) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: bitmap.size)
        
        return renderer.image { context in
            // Draw original image
            bitmap.draw(at: .zero)
            
            // Setup text attributes
            let textSize = bitmap.size.width * 0.035
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: textSize, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -4.0,
                .paragraphStyle: paragraphStyle
            ]
            
            // Format timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.locale = Locale.current
            let waktu = formatter.string(from: Date())
            
            // Build text lines
            var lines: [String] = []
            
            if mode == .PERLU_LOKASI, let lat = lat, let lon = lon {
                lines = [
                    waktu,
                    String(format: "Lat: %.6f  Lon: %.6f", lat, lon),
                    "DOAS ABSENSI"
                ]
            } else {
                lines = [
                    waktu,
                    "DOAS ABSENSI"
                ]
            }
            
            // Calculate positioning
            let marginBottom = bitmap.size.height * 0.04
            let lineHeight = textSize * 1.5
            var y = bitmap.size.height - (CGFloat(lines.count) * lineHeight) - marginBottom
            
            // Draw each line
            for line in lines {
                let rect = CGRect(x: 40, y: y, width: bitmap.size.width - 80, height: lineHeight)
                line.draw(in: rect, withAttributes: attributes)
                y += lineHeight
            }
        }
    }
}
