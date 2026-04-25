//
//  Hendry.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit

// MARK: - Home Extensions for Business Logic

extension Home {
    
    /// Check authentication and load berita data
    /// Equivalen
    ///
    func dos() {
        print("🏠 [HENDRY] dos() called - Checking auth and loading berita")
        let auth = AuthManager(purnomo: "api/auth-check")
        auth.checkAuth(
                params: nil,
                onSuccess: { [weak self] json in
                    guard let self = self else { return }
                    
                    // Debug response biar kelihatan di Xcode
                    print("✅ [DOS] Response JSON: \(json)")

                    guard let aesKey = json["aes_key"] as? String else {
                        print("❌ [HENDRY] AES key not found")
                        return
                    }
                    
                    // Pastikan status ok
                    let status = json["status"] as? String ?? ""
                    if status != "ok" {
                        print("❌ [HENDRY] Status is not 'ok': \(status)")
                        return
                    }
                    
                    var listBerita: [BeritaItem] = []
                    if let beritaArray = json["berita"] as? [[String: Any]] {
                        print("✅ [HENDRY] Found \(beritaArray.count) berita items")
                        
                        for obj in beritaArray {
                            let id = obj["id"] as? String ?? ""
                            let judulEncrypted = obj["judul"] as? String ?? ""
                            let isiEncrypted = obj["isi"] as? String ?? ""
                            let tanggal = obj["tanggal"] as? String ?? ""
                            let fotoEncrypted = obj["foto"] as? String ?? ""
                            let pdfEncrypted = obj["pdf"] as? String ?? ""
                            
                            let berita = BeritaItem(
                                id: id,
                                judul: CryptoAES.decrypt(judulEncrypted, aesKey),
                                isi: CryptoAES.decrypt(isiEncrypted, aesKey),
                                tanggal: tanggal,
                                foto: CryptoAES.decrypt(fotoEncrypted, aesKey),
                                pdf: CryptoAES.decrypt(pdfEncrypted, aesKey)
                            )
                            listBerita.append(berita)
                        }
                    }
                    
                    // Update UI di Main Thread
                    DispatchQueue.main.async {
                        if !listBerita.isEmpty {
                            self.updateBeritaPager(with: listBerita)
                        }
                    }
                },
                onLogout: { [weak self] message in
                    guard let self = self else { return }
                    print("🔴 [HENDRY] onLogout called: \(message)")
                    print("🔴 [HENDRY] Clearing tokens and redirecting to login...")
                    
                    // Clear all tokens
                    SecurePrefs.shared.clear()
                    
                    DispatchQueue.main.async {
                        self.showToast(message: message)
                        
                        // Navigate back to login
                        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .first?.windows
                            .first(where: { $0.isKeyWindow }) {
                            
                            let loginVC = Loginpage()
                            window.rootViewController = loginVC
                            window.makeKeyAndVisible()
                            
                            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                            print("✅ [HENDRY] Redirected to login page")
                        }
                    }
                },
                onLoading: { [weak self] loading in
                    DispatchQueue.main.async {
                        loading ? self?.showLoading() : self?.hideLoading()
                    }
                }
            )
        }
    
    /// Show confirmation dialog for Apel (attendance check)
    /// Equivalent dengan go() di Android
    func go() {
        print("🏠 [HENDRY] go() called - Showing apel confirmation")
        
        let alert = UIAlertController(
            title: "Konfirmasi Apel",
            message: "Anda Wajib Apel, Kami Akan Cek Kehadiran Apel Anda",
            preferredStyle: .alert
        )
        
        // "Setuju" button
        let yesAction = UIAlertAction(title: "Setuju", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            print("✅ [HENDRY] User agreed to apel, checking attendance...")
            
            // Check apel attendance
            let authManager = AuthManager(purnomo: "api/cekabsen")
            authManager.checkAuth(
                params: nil,
                onSuccess: { [weak self] json in
                    guard let self = self else { return }
                    
                    print("✅ [HENDRY] Apel check response: \(json)")
                    
                    if let absen = json["absen"] as? String {
                        if absen.lowercased() == "sudah" {
                            self.showToast(message: "Anda Sudah Absen")
                        } else {
                            // Navigate to AbsenHadir
                            self.navigateToAbsenHadir()
                        }
                    }
                },
                onLogout: { [weak self] message in
                    guard let self = self else { return }
                    
                    print("🔴 [HENDRY] Apel check logout: \(message)")
                    
                    switch message {
                    case "Verification failed", "__TIMEOUT__", "__NO_INTERNET__":
                        self.showToast(message: message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            exit(0)
                        }
                        
                    default:
                        self.showToast(message: message)
                        // Navigate back or dismiss
                    }
                },
                onLoading: { [weak self] loading in
                    if loading {
                        self?.showLoading()
                    } else {
                        self?.hideLoading()
                    }
                }
            )
        }
        
        // "Tidak" button
        let noAction = UIAlertAction(title: "Tidak", style: .cancel)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true)
    }
    
    /// Check attendance status and navigate accordingly
    /// Equivalent dengan cekabsen() di Android
    func cekabsen(dari: String) {
        print("🏠 [HENDRY] cekabsen() called from: \(dari)")
        
        let authManager = AuthManager(purnomo : "api/cekabsen")
        
        authManager.checkAuth(
            params: nil,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                
                print("✅ [HENDRY] Attendance check response: \(json)")
                
                if let absen = json["absen"] as? String {
                    switch dari.lowercased() {
                    case "status":
                        self.startStatus(absen: absen)
                        
                    case "dinas":
                        self.startAbsen(absen: absen, targetType: .dinas)
                        
                    case "dik":
                        self.startAbsen(absen: absen, targetType: .dik)
                        
                    case "sakit":
                        self.startAbsen(absen: absen, targetType: .sakit)
                        
                    case "bko":
                        self.startAbsen(absen: absen, targetType: .bko)
                        
                    case "cuti":
                        self.startAbsen(absen: absen, targetType: .cuti)
                        
                    case "ld":
                        self.startAbsen(absen: absen, targetType: .ld)
                        
                    case "izin":
                        self.startAbsen(absen: absen, targetType: .izin)
                        
                    default:
                        print("⚠️ [HENDRY] Unknown dari value: \(dari)")
                    }
                }
            },
            onLogout: { [weak self] message in
                guard let self = self else { return }
                
                print("🔴 [HENDRY] Attendance check logout: \(message)")
                
                self.showToast(message: message)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    exit(0)
                }
            },
            onLoading: { [weak self] loading in
                if loading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
        )
    }
    
    /// Navigate to status page or show message
    /// Equivalent dengan startStatus() di Android
    func startStatus(absen: String) {
        if absen.lowercased() == "belum" {
            showToast(message: "Anda Belum Absen")
        } else {
            // Navigate to Statuses view controller
            navigateToStatuses()
        }
    }
    
    /// Navigate to attendance page or show message
    /// Equivalent dengan startAbsen() di Android
    func startAbsen(absen: String, targetType: AbsenType) {
        if absen.lowercased() == "sudah" {
            showToast(message: "Anda Sudah Absen")
        } else {
            // Navigate to appropriate absen view controller
            navigateToAbsen(type: targetType)
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToAbsenHadir() {
        print("🚀 [HENDRY] Navigating to AbsenHadir")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let absenHadirVC = AbsenHadir()
            let navController = UINavigationController(rootViewController: absenHadirVC)
            window.rootViewController = navController
            window.makeKeyAndVisible()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            print("✅ [HENDRY] Successfully navigated to AbsenHadir")
        }
    }
    
    private func navigateToStatuses() {
        print("🚀 [HENDRY] Navigating to Statuses")
        // TODO: Implement navigation to Statuses view controller
        // let statusesVC = Statuses()
        // navigationController?.pushViewController(statusesVC, animated: true)
        showToast(message: "Navigate to Statuses (TODO)")
    }
    
    private func navigateToAbsen(type: AbsenType) {
        print("🚀 [HENDRY] Navigating to Absen type: \(type)")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ [HENDRY] Failed to get window")
            return
        }
        
        let viewController: UIViewController
        
        switch type {
        case .bko:
            viewController = AbsenBko()
            print("✅ [HENDRY] Navigating to AbsenBko")
            
        case .dik:
            viewController = AbsenDik()
            print("✅ [HENDRY] Navigating to AbsenDIk")
        case .dinas:
            viewController = AbsenDinas()
            print("✅ [HENDRY] Navigating to AbsenDinas")
            
        case .sakit:
            viewController = AbsenSakit()
            print("✅ [HENDRY] Navigating to AbsenSakit")
            
        case .cuti:
            viewController = AbsenCuti()
            print("✅ [HENDRY] Navigating to AbsenCuti")
        case .ld:
            viewController = AbsenLd()
            print("✅ [HENDRY] Navigating to AbsenLd")
        case .izin:
            viewController = AbsenIzin()
            print("✅ [HENDRY] Navigating to AbsenIzin")
        
        }
        
        // Navigate with UINavigationController
        let navController = UINavigationController(rootViewController: viewController)
        window.rootViewController = navController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        print("✅ [HENDRY] Navigation to \(type.rawValue) complete")
    }
    
    /// Update berita pager with data
    /// This method should be called after berita data is loaded
    func updateBeritaPager(with listBerita: [BeritaItem]) {
        print("📰 [HENDRY] Updating berita pager with \(listBerita.count) items")
        
        DispatchQueue.main.async {
            // GUNAKAN applyBeritaItems yang sudah ada di extension bawah
            // Ini akan setup UIPageViewController dengan benar
            self.applyBeritaItems(listBerita)
        }
    }
}

// MARK: - Supporting Types

/// Enum for different attendance types
enum AbsenType: String {
    case dinas = "Dinas"
    case dik = "Dik"
    case sakit = "Sakit"
    case bko = "BKO"
    case cuti = "Cuti"
    case ld = "LD"
    case izin = "Izin"
}

// MARK: - Helper Functions

/// Convert HTML to attributed string
func hendry_makeHTMLAttributed(_ html: String, baseFontSize: CGFloat) -> NSAttributedString? {
    let wrapped = """
    <span style=\"font-family: -apple-system, HelveticaNeue; font-size: \(Int(baseFontSize))px; color: #F2F2F2\">\(html)</span>
    """
    guard let data = wrapped.data(using: .utf8) else { return nil }
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue
    ]
    return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
}

extension String {
    /// Strip HTML tags and return plain text
    func hendry_htmlToPlain() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

// ======================================================
