//
//  AuthManager.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import Foundation
import UIKit

final class AuthManager {

    private let baseURL = AppConfig2.BASE_URL
    private let securePrefs = SecurePrefs.shared
    private let purnomo: String

    // ======================================================
    // CONSTRUCTOR (SAMA DENGAN ANDROID)
    // ======================================================

    init(purnomo: String) {
        self.purnomo = purnomo
    }

    // ======================================================
    // ANTI RACE CONDITION
    // ======================================================

    private var isRefreshing = false
    private var waitingQueue: [() -> Void] = []

    private func refreshTokenSafe(
        onSuccess: @escaping () -> Void,
        onLogout: @escaping (String) -> Void
    ) {
        print("🔄 [AUTHMANAGER] refreshTokenSafe() called")
        
        if isRefreshing {
            print("⏳ [AUTHMANAGER] Already refreshing, adding to queue...")
            waitingQueue.append(onSuccess)
            return
        }

        isRefreshing = true
        print("🔄 [AUTHMANAGER] Starting token refresh...")

        refreshTokenOnly(
            onSuccess: {
                print("✅ [AUTHMANAGER] Token refresh successful!")
                self.isRefreshing = false
                onSuccess()

                print("🔄 [AUTHMANAGER] Processing \(self.waitingQueue.count) queued requests...")
                self.waitingQueue.forEach { $0() }
                self.waitingQueue.removeAll()
            },

            onLogout: { msg in
                print("❌ [AUTHMANAGER] Token refresh failed: \(msg)")
                self.isRefreshing = false
                self.waitingQueue.removeAll()
                onLogout(msg)
            }
        )
    }

    // ======================================================
    // CHECK AUTH
    // ======================================================

    func checkAuth(
        params: [String: String]? = nil,
        onSuccess: @escaping ([String: Any]) -> Void,
        onLogout: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {
        print("🔐 [AUTHMANAGER] checkAuth() called")
        print("🔐 [AUTHMANAGER] Purnomo: \(purnomo)")
        print("🔐 [AUTHMANAGER] Params: \(params ?? [:])")

        if !Auto.isInternetAvailable() {
            print("❌ [AUTHMANAGER] No internet connection")
            onLoading(false)
            onLogout("Tidak ada koneksi internet")
            return
        }

        guard let accessToken = securePrefs.getAccessToken(),
              let refreshToken = securePrefs.getRefreshToken(),
              !accessToken.isEmpty,
              !refreshToken.isEmpty else {
            print("❌ [AUTHMANAGER] No valid tokens found")
            self.forceLogout(message: "Sesi tidak valid, silakan login ulang")
            return
        }
        
        print("🔐 [AUTHMANAGER] Access Token: \(accessToken.prefix(20))...")
        print("🔐 [AUTHMANAGER] Refresh Token: \(refreshToken.prefix(20))...")

        requestAuth(
            accessToken: accessToken,
            params: params,
            onSuccess: onSuccess,
            onUnauthorized: {
                print("🔐 [AUTHMANAGER] Got 401 Unauthorized, attempting refresh...")
                self.refreshTokenSafe(
                    onSuccess: {
                        print("🔁 [AUTHMANAGER] Retrying original request after refresh...")
                        self.checkAuth(
                            params: params,
                            onSuccess: onSuccess,
                            onLogout: onLogout,
                            onLoading: onLoading
                        )
                    },
                    onLogout: onLogout
                )
            },
            onError: { message in
                print("❌ [AUTHMANAGER] Request error: \(message)")
                onLoading(false)
                self.showToast(message)
            },
            onLoading: onLoading
        )
    }

    func forceLogout(message: String) {
        print("🚪 [AUTHMANAGER] forceLogout() called: \(message)")
        
        securePrefs.clear()

        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Informasi",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.goToMainActivity()
            })
            
            // Present alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               var topController = window.rootViewController {
                
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                
                topController.present(alert, animated: true)
            }
        }
    }
    
    // ======================================================
    // REQUEST AUTH
    // ======================================================

    private func requestAuth(
        accessToken: String,
        params: [String: String]?,
        onSuccess: @escaping ([String: Any]) -> Void,
        onUnauthorized: @escaping () -> Void,
        onError: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {
        print("🌐 [AUTHMANAGER] requestAuth() called")
        print("🌐 [AUTHMANAGER] URL: \(baseURL + purnomo)")

        guard let url = URL(string: baseURL + purnomo) else {
            print("❌ [AUTHMANAGER] Invalid URL!")
            onError("URL tidak valid")
            return
        }

        onLoading(true)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")

        if let params = params {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = params
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            print("🌐 [AUTHMANAGER] Request body: \(bodyString)")
        } else {
            print("🌐 [AUTHMANAGER] No request body")
        }
        
        print("🌐 [AUTHMANAGER] Sending request...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            print("🌐 [AUTHMANAGER] Response received!")

            DispatchQueue.main.async {
                onLoading(false)

                if let error = error {
                    print("❌ [AUTHMANAGER] Network error: \(error.localizedDescription)")
                    onError(error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [AUTHMANAGER] Invalid HTTP response")
                    onError("Response tidak valid")
                    return
                }
                
                print("🌐 [AUTHMANAGER] HTTP Status Code: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 401 {
                    print("🔐 [AUTHMANAGER] Unauthorized (401)")
                    onUnauthorized()
                    return
                }

                guard let data = data else {
                    print("❌ [AUTHMANAGER] No data received")
                    onError("Response kosong")
                    return
                }
                
                // Print raw response
                if let rawString = String(data: data, encoding: .utf8) {
                    print("🌐 [AUTHMANAGER] Raw response: \(rawString)")
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ [AUTHMANAGER] JSON parsing failed")
                    onError("Response server tidak valid")
                    return
                }
                
                print("✅ [AUTHMANAGER] JSON parsed successfully")
                print("🌐 [AUTHMANAGER] JSON keys: \(json.keys)")

                if json["status"] as? String == "ok" {
                    print("✅ [AUTHMANAGER] Status OK, calling onSuccess")
                    onSuccess(json)
                } else {
                    let errorMsg = json["message"] as? String ?? "Terjadi kesalahan"
                    print("❌ [AUTHMANAGER] Status not OK: \(errorMsg)")
                    onError(errorMsg)
                }
            }

        }.resume()
        
        print("🌐 [AUTHMANAGER] Request task started")
    }

    // ======================================================
    // UPLOAD FOTO (PORT DARI uploadMultipartAuth)
    // ======================================================

    func uploadFoto(
        files: [URL]?,
        params: [String: String],
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void,
        onLogout: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {
        print("📤 [AUTHMANAGER] uploadFoto() called")
        print("📤 [AUTHMANAGER] Files count: \(files?.count ?? 0)")
        print("📤 [AUTHMANAGER] Params: \(params)")

        if !Auto.isInternetAvailable() {
            onLoading(false)
            onLogout("Tidak ada koneksi internet")
            return
        }

        guard let accessToken = securePrefs.getAccessToken(),
              !accessToken.isEmpty else {
            self.forceLogout(message: "Sesi Tidak Valid")
            return
        }

        let realFiles = (files != nil && files!.isEmpty) ? nil : files

        guard let url = URL(string: baseURL + purnomo) else {
            onError("URL tidak valid")
            return
        }

        onLoading(true)

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")

        var body = Data()

        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        realFiles?.enumerated().forEach { index, fileURL in
            guard let fileData = try? Data(contentsOf: fileURL) else { return }

            let mime: String

            if fileURL.path.lowercased().hasSuffix(".png") {
                mime = "image/png"
            } else if fileURL.path.lowercased().hasSuffix(".webp") {
                mime = "image/webp"
            } else {
                mime = "image/jpeg"
            }

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"foto\(index + 1)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
                    .data(using: .utf8)!
            )
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("📤 [AUTHMANAGER] Sending multipart upload...")

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {
                onLoading(false)

                if let error = error {
                    print("❌ [AUTHMANAGER] Upload error: \(error.localizedDescription)")
                    onError(error.localizedDescription)
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    onError("Response tidak valid")
                    return
                }
                
                print("📤 [AUTHMANAGER] Upload response status: \(http.statusCode)")

                if http.statusCode == 401 {
                    print("🔐 [AUTHMANAGER] Upload got 401, refreshing token...")
                    self.refreshTokenSafe(
                        onSuccess: {
                            self.uploadFoto(
                                files: files,
                                params: params,
                                onSuccess: onSuccess,
                                onError: onError,
                                onLogout: onLogout,
                                onLoading: onLoading
                            )
                        },
                        onLogout: { message in
                            onLogout(message)
                        }
                    )
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    onError("Response server tidak valid")
                    return
                }

                // Cleanup temp files
                realFiles?.forEach { file in
                    try? FileManager.default.removeItem(at: file)
                }

                print("✅ [AUTHMANAGER] Upload successful!")
                onSuccess(json)
            }

        }.resume()
    }

    // ======================================================
    // REFRESH TOKEN
    // ======================================================
    
    private func refreshTokenOnly(
        onSuccess: @escaping () -> Void,
        onLogout: @escaping (String) -> Void
    ) {
        print("🔄 [AUTHMANAGER] refreshTokenOnly() called")

        guard let refreshToken = securePrefs.getRefreshToken(),
              !refreshToken.isEmpty else {
            print("❌ [AUTHMANAGER] No refresh token found")
            onLogout("Refresh token tidak ditemukan")
            return
        }
        
        print("🔄 [AUTHMANAGER] Refresh Token: \(refreshToken.prefix(20))...")

        guard let url = URL(string: baseURL + AppConfig2.refresh) else {
            print("❌ [AUTHMANAGER] Invalid refresh URL")
            onLogout("URL refresh tidak valid")
            return
        }
        
        print("🔄 [AUTHMANAGER] Refresh URL: \(baseURL + AppConfig2.refresh)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")
        
        print("🔄 [AUTHMANAGER] Sending refresh request...")

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                if let error = error {
                    print("❌ [AUTHMANAGER] Refresh network error: \(error.localizedDescription)")
                    onLogout("Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("❌ [AUTHMANAGER] No data in refresh response")
                    onLogout("Response kosong")
                    return
                }
                
                // Print raw response
                if let rawString = String(data: data, encoding: .utf8) {
                    print("🔄 [AUTHMANAGER] Raw refresh response: \(rawString)")
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    
                    print("✅ [AUTHMANAGER] Refresh JSON parsed")
                    print("🔄 [AUTHMANAGER] JSON keys: \(json.keys)")
                    
                    let status = json["status"] as? Int ?? 0
                    
                    let messages = json["messages"] as? [String: Any]
                    let message = messages?["error"] as? String ?? "Terjadi kesalahan"
                    
                    // ===== jika backend kirim 401 =====
                    if status == 401 {
                        print("🔐 [AUTHMANAGER] Refresh token also expired (401)")
                        self.securePrefs.clear()

                        let alert = UIAlertController(
                            title: "Informasi",
                            message: message,
                            preferredStyle: .alert
                        )

                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.goToMainActivity()
                        })
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                           var topController = window.rootViewController {
                            
                            while let presented = topController.presentedViewController {
                                topController = presented
                            }
                            
                            topController.present(alert, animated: true)
                        }

                        return
                    }

                    // ===== jika sukses =====
                    let newAccess = json["access_token"] as? String ?? ""
                    let newRefresh = json["refresh_token"] as? String ?? ""

                    print("🔄 [AUTHMANAGER] New access token: \(newAccess.prefix(20))...")
                    print("🔄 [AUTHMANAGER] New refresh token: \(newRefresh.prefix(20))...")

                    if newAccess.isEmpty || newRefresh.isEmpty {
                        print("❌ [AUTHMANAGER] Empty tokens in response")
                        self.forceLogout(message: "Anda Harus Login Ulang")
                        return
                    }

                    self.securePrefs.saveAccessToken(newAccess)
                    self.securePrefs.saveRefreshToken(newRefresh)
                    
                    print("✅ [AUTHMANAGER] New tokens saved successfully")

                    onSuccess()

                } catch {
                    print("❌ [AUTHMANAGER] Refresh JSON parsing error: \(error.localizedDescription)")
                    onLogout("Response server tidak valid")
                }
            }

        }.resume()
    }

    // ======================================================
    // TOAST
    // ======================================================
    
    private func showToast(_ message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  var topController = window.rootViewController else {
                return
            }

            while let presented = topController.presentedViewController {
                topController = presented
            }

            if topController is UIAlertController { return }

            let alert = UIAlertController(title: "Informasi", message: message, preferredStyle: .alert)
            
            let refreshAction = UIAlertAction(title: "Refresh", style: .default) { _ in
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController = Home()
                    window.makeKeyAndVisible()
                }
            }
            
            alert.addAction(refreshAction)
            alert.addAction(UIAlertAction(title: "Tutup", style: .cancel, handler: nil))
            
            topController.present(alert, animated: true)
        }
    }
    
    func goToMainActivity() {
        print("🚪 [AUTHMANAGER] Navigating to MainActivity...")
        
        let vc = MainActivity()

        guard let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first else { return }

        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}
