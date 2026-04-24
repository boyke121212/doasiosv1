//
//  Purnomo.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit

// MARK: - Loginpage Extensions

extension Loginpage {
    
    /// Check authentication and navigate to Home with berita data
    /// Equivalent dengan logbound() di Android
    func logbound() {
        print("🔐 [PURNOMO] logbound() called")
        
        AuthManager(purnomo: "api/auth-check").checkAuth(
            params: nil,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                
                print("✅ [PURNOMO] Auth check success, parsing response...")
                print("🔐 [PURNOMO] Full JSON response: \(json)")
                
                guard let aesKey = json["aes_key"] as? String else {
                    print("❌ [PURNOMO] AES key not found")
                    self.showToast(message: "Login Gagal - AES key tidak ditemukan")
                    return
                }
                
                print("✅ [PURNOMO] AES Key found: \(aesKey.prefix(20))...")
                
                // Save AES key
                SecurePrefs.shared.saveAesKey(aesKey)
                
                // Parse berita (optional - bisa kosong)
                var listBerita: [BeritaItem] = []
                if let beritaArray = json["berita"] as? [[String: Any]] {
                    print("📰 [PURNOMO] Found \(beritaArray.count) berita items")
                    for obj in beritaArray {
                        listBerita.append(BeritaItem(
                            id: obj["id"] as? String ?? "",
                            judul: CryptoAES.decrypt(obj["judul"] as? String ?? "", aesKey),
                            isi: CryptoAES.decrypt(obj["isi"] as? String ?? "", aesKey),
                            tanggal: obj["tanggal"] as? String ?? "",
                            foto: CryptoAES.decrypt(obj["foto"] as? String ?? "", aesKey),
                            pdf: CryptoAES.decrypt(obj["pdf"] as? String ?? "", aesKey)
                        ))
                    }
                } else {
                    print("⚠️ [PURNOMO] No berita array in response")
                }
                
                DispatchQueue.main.async {
                    print("🚀 [PURNOMO] Navigating to Home with \(listBerita.count) berita items...")
                    self.openPage(Home())
                }
            },
            onLogout: { [weak self] message in
                guard let self = self else { return }
                print("🔴 [PURNOMO] onLogout: \(message)")
                
                DispatchQueue.main.async {
                    self.showToast(message: message)
                }
            },
            onLoading: { [weak self] loading in
                DispatchQueue.main.async {
                    loading ? self?.showLoading() : self?.hideLoading()
                }
            }
        )
    }
    
    /// Setup double back press to exit app
    /// Equivalent dengan setupDoubleBackExit() di Android
    func setupDoubleBackExit() {
        // iOS doesn't have hardware back button like Android
        // This can be implemented using gesture recognizer if needed
        // For now, we'll skip this implementation
        
        print("ℹ️ [PURNOMO] setupDoubleBackExit - Not applicable for iOS (no hardware back button)")
    }
}

// MARK: - Home Extensions

extension Home {
    
    /// Setup double back press to exit app
    /// Equivalent dengan setupDoubleBackExit() di Android
    func setupDoubleBackExit() {
        // iOS doesn't have hardware back button like Android
        // This can be implemented using gesture recognizer if needed
        
        print("ℹ️ [PURNOMO] Home.setupDoubleBackExit - Not applicable for iOS")
    }
}

// MARK: - BeritaItem Model
