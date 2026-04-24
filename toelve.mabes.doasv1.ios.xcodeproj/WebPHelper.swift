//
//  WebPHelper.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import Foundation
import UIKit

/// Helper untuk load WebP images tanpa external library
/// Menggunakan bundle resource loading
class WebPHelper {
    
    /// Load WebP image from bundle
    static func loadWebPImage(named name: String) -> UIImage? {
        // Cari file .webp di bundle
        guard let path = Bundle.main.path(forResource: name, ofType: "webp") else {
            print("⚠️ WebP file '\(name).webp' not found in bundle")
            return nil
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("⚠️ Failed to load data from '\(name).webp'")
            return nil
        }
        
        // Try to decode as regular image (iOS 14+ supports WebP natively in some cases)
        if let image = UIImage(data: data) {
            return image
        }
        
        print("⚠️ Failed to decode WebP image '\(name).webp'")
        print("💡 Solusi: Install SDWebImageWebPCoder atau convert ke PNG")
        return nil
    }
}

/// Extension untuk UIImageView
extension UIImageView {
    func setWebPImage(named name: String, placeholder: UIImage? = nil) {
        self.image = placeholder
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = WebPHelper.loadWebPImage(named: name) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
