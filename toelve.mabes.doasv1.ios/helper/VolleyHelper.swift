//
//  VolleyHelper.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import Foundation
import UIKit

/// Network helper untuk handle HTTP requests
/// Equivalent dengan VolleyHelper.kt di Android (menggunakan Volley library)
class VolleyHelper {
    
    // MARK: - Singleton
    
    static let shared = VolleyHelper()
    
    // MARK: - Properties
    
    var currentFilter: [String: String] = [:]
    
    // MARK: - Initializer
    
    private init() {
        // Private init untuk singleton
    }
    
    // MARK: - Upload Multipart with Auth
    
    /// Upload file menggunakan multipart/form-data dengan authentication
    /// Equivalent dengan uploadMultipartAuth() di Android
    func uploadMultipartAuth(
        url: String,
        accessToken: String,
        params: [String: String],
        fileField: String,
        file: URL?,
        onLoading: @escaping (Bool) -> Void,
        onSuccess: @escaping ([String: Any]) -> Void,
        onUnauthorized: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        let deviceHash = DeviceSecurityHelper.getDeviceHash()
        
        onLoading(true)
        
        guard let url = URL(string: url) else {
            onLoading(false)
            onError("URL tidak valid")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Boundary untuk multipart
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Headers
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceHash, forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")
        
        // Body
        var body = Data()
        
        // Add params
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file if exists
        if let fileURL = file, FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileData = try? Data(contentsOf: fileURL) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Timeout 20 seconds (equivalent dengan RetryPolicy 20000)
        request.timeoutInterval = 20
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                onLoading(false)
                
                if let error = error {
                    let errorMessage = self?.parseError(error: error, data: data, response: response) ?? "Network error: \(error.localizedDescription)"
                    onError(errorMessage)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    onError("Response tidak valid")
                    return
                }
                
                // Handle status codes
                switch httpResponse.statusCode {
                case 200...299:
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                onSuccess(json)
                            } else {
                                onError("Response server tidak valid")
                            }
                        } catch {
                            onError("Response server tidak valid: \(error.localizedDescription)")
                        }
                    } else {
                        onError("Response kosong")
                    }
                    
                case 401:
                    let message = self?.parseErrorMessage(from: data)
                    onUnauthorized(message)
                    
                default:
                    let message = self?.parseErrorMessage(from: data)
                    onError(message ?? "Terjadi kesalahan jaringan")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Auth Check
    
    /// Check authentication dengan POST request
    /// Equivalent dengan authCheck() di Android
    func authCheck(
        url: String,
        accessToken: String,
        params: [String: String]? = nil,
        onLoading: @escaping (Bool) -> Void,
        onSuccess: @escaping ([String: Any]) -> Void,
        onUnauthorized: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        print("🌐 [VOLLEY] authCheck() called")
        print("🌐 [VOLLEY] URL: \(url)")
        print("🌐 [VOLLEY] Access Token: \(accessToken.prefix(20))...")
        print("🌐 [VOLLEY] Params: \(params ?? [:])")
        
        onLoading(true)
        
        guard let url = URL(string: url) else {
            print("❌ [VOLLEY] Invalid URL!")
            onLoading(false)
            onError("URL tidak valid")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        
        // Headers
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")
        request.setValue(timestamp, forHTTPHeaderField: "X-Request-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Request-Nonce")
        
        print("🌐 [VOLLEY] Headers set:")
        print("   - Authorization: Bearer \(accessToken.prefix(20))...")
        print("   - X-Device-Hash: \(DeviceSecurityHelper.getDeviceHash())")
        print("   - Platform: ios")
        
        // Body params (form-urlencoded)
        if let params = params, !params.isEmpty {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            print("🌐 [VOLLEY] Request body: \(bodyString)")
        } else {
            print("🌐 [VOLLEY] No body params")
        }
        
        print("🌐 [VOLLEY] Sending POST request...")
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print("🌐 [VOLLEY] Response received!")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 [VOLLEY] HTTP Status Code: \(httpResponse.statusCode)")
                print("🌐 [VOLLEY] Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            DispatchQueue.main.async {
                onLoading(false)
                
                if let error = error {
                    print("❌ [VOLLEY] Network error: \(error.localizedDescription)")
                    let errorMessage = self?.parseError(error: error, data: data, response: response) ?? "Network error: \(error.localizedDescription)"
                    onError(errorMessage)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [VOLLEY] Invalid HTTP response")
                    onError("Response tidak valid")
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    print("❌ [VOLLEY] No data received or empty data")
                    onError("Response kosong dari server")
                    return
                }
                
                // Print raw response
                if let rawString = String(data: data, encoding: .utf8) {
                    print("🌐 [VOLLEY] Raw response: \(rawString)")
                }
                
                // Parse response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ [VOLLEY] JSON parsed successfully")
                        print("🌐 [VOLLEY] JSON keys: \(json.keys)")
                        let status = json["status"] as? String ?? ""
                        print("🌐 [VOLLEY] Status: \(status)")
                        
                        switch httpResponse.statusCode {
                        case 200...299:
                            if status == "ok" {
                                print("✅ [VOLLEY] Success! Calling onSuccess callback")
                                print("🌐 [VOLLEY] Full JSON: \(json)")
                                onSuccess(json)
                            } else {
                                let message = json["message"] as? String ?? "Terjadi kesalahan"
                                print("❌ [VOLLEY] Status not OK: \(message)")
                                onError(message)
                            }
                            
                        case 401:
                            print("🔐 [VOLLEY] Unauthorized (401)")
                            let message = self?.parseErrorMessage(from: data)
                            onUnauthorized(message)
                            
                        default:
                            print("❌ [VOLLEY] Error status code: \(httpResponse.statusCode)")
                            let message = self?.parseErrorMessage(from: data)
                            onError(message ?? "Terjadi kesalahan jaringan")
                        }
                    } else {
                        print("❌ [VOLLEY] Response is not a valid JSON object")
                        onError("Response server tidak valid")
                    }
                } catch {
                    print("❌ [VOLLEY] JSON parsing error: \(error.localizedDescription)")
                    onError("Response server tidak valid: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
        print("🌐 [VOLLEY] Request task started (resume called)")
    }
    
    // MARK: - Refresh Token
    
    /// Refresh access token menggunakan refresh token
    /// Equivalent dengan refreshToken() di Android
    func refreshToken(
        url: String,
        refreshToken: String,
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        print("🔄 [VOLLEY] refreshToken() called")
        print("🔄 [VOLLEY] URL: \(url)")
        print("🔄 [VOLLEY] Refresh Token: \(refreshToken.prefix(20))...")
        
        guard let url = URL(string: url) else {
            print("❌ [VOLLEY] Invalid URL!")
            onError("URL tidak valid")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        
        // Headers
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")
        
        print("🔄 [VOLLEY] Headers set:")
        print("   - Authorization: Bearer \(refreshToken.prefix(20))...")
        print("   - X-Device-Hash: \(DeviceSecurityHelper.getDeviceHash())")
        print("   - Platform: ios")
        print("🔄 [VOLLEY] Sending POST request...")
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print("🔄 [VOLLEY] Refresh token response received!")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 [VOLLEY] HTTP Status Code: \(httpResponse.statusCode)")
            }
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [VOLLEY] Refresh token error: \(error.localizedDescription)")
                    let errorMessage = self?.parseError(error: error, data: data, response: response) ?? "Network error: \(error.localizedDescription)"
                    onError(errorMessage)
                    return
                }
                
                guard let data = data else {
                    print("❌ [VOLLEY] No data in refresh token response")
                    onError("Response kosong")
                    return
                }
                
                // Print raw response
                if let rawString = String(data: data, encoding: .utf8) {
                    print("🔄 [VOLLEY] Raw refresh response: \(rawString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ [VOLLEY] Refresh token JSON parsed successfully")
                        print("🔄 [VOLLEY] Response: \(json)")
                        onSuccess(json)
                    } else {
                        print("❌ [VOLLEY] Response is not a valid JSON object")
                        onError("Response server tidak valid")
                    }
                } catch {
                    print("❌ [VOLLEY] JSON parsing error: \(error.localizedDescription)")
                    onError("Response server tidak valid: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
        print("🔄 [VOLLEY] Refresh token request task started")
    }
    
    // MARK: - Login
    
    /// Login request dengan security checks
    /// Equivalent dengan login() di Android
    func login(
        url: String,
        username: String,
        password: String,
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) async {
        print("🌐 [VOLLEY] login() called")
        print("🌐 [VOLLEY] URL string: \(url)")
        
        guard let url = URL(string: url) else {
            print("❌ [VOLLEY] Invalid URL!")
            onError("URL tidak valid")
            return
        }
        
        print("🌐 [VOLLEY] Checking device security...")
        let isJailbroken = DeviceSecurityHelper.isDeviceJailbroken()
        let isSimulator = DeviceSecurityHelper.isEmulator()
        let isFakeGps = DeviceSecurityHelper.isUsingMockLocation(location: nil)
        let isDebug = DeviceSecurityHelper.isDebuggable()
        // Note: isValidInstaller check not implemented in DeviceSecurityHelper
        let isInstallerValid = true // Default to true for iOS (App Store validation)
        
        print("🌐 [VOLLEY] Security checks complete:")
        print("   - Jailbroken: \(isJailbroken)")
        print("   - Simulator: \(isSimulator)")
        print("   - Fake GPS: \(isFakeGps)")
        print("   - Debug: \(isDebug)")
        print("   - Installer Valid: \(isInstallerValid)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Params
        let params: [String: String] = [
            "username": username,
            "password": password,
            "device_hash": DeviceSecurityHelper.getDeviceHash(),
            "app_signature": DeviceSecurityHelper.getAppSignatureHash(),
            "is_rooted": isJailbroken ? "1" : "0",
            "is_emulator": isSimulator ? "1" : "0",
            "is_fake_gps": isFakeGps ? "1" : "0",
            "is_debug": isDebug ? "1" : "0",
            "is_installer_valid": isInstallerValid ? "1" : "0",
            "platform": "ios"
        ]
        
        let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🌐 [VOLLEY] Request body: \(bodyString)")
        print("🌐 [VOLLEY] Sending POST request...")
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print("🌐 [VOLLEY] Response received!")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 [VOLLEY] HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [VOLLEY] Network error: \(error.localizedDescription)")
                    let errorMessage = self?.parseError(error: error, data: data, response: response) ?? "Network error: \(error.localizedDescription)"
                    onError(errorMessage)
                    return
                }
                
                guard let data = data else {
                    print("❌ [VOLLEY] No data received")
                    onError("Response kosong")
                    return
                }
                
                // Print raw response
                if let rawString = String(data: data, encoding: .utf8) {
                    print("🌐 [VOLLEY] Raw response: \(rawString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ [VOLLEY] JSON parsed successfully: \(json)")
                        onSuccess(json)
                    } else {
                        print("❌ [VOLLEY] Response is not a valid JSON object")
                        onError("Response server tidak valid")
                    }
                } catch {
                    print("❌ [VOLLEY] JSON parsing error: \(error.localizedDescription)")
                    onError("Response server tidak valid: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
        print("🌐 [VOLLEY] Request task started (resume called)")
    }
    
    // MARK: - Error Parsing
    
    /// Parse error dari response
    /// Equivalent dengan parseError() di Android
    private func parseError(error: Error?, data: Data?, response: URLResponse?) -> String {
        // 1️⃣ IDEAL PATH: pesan dari server
        if let data = data {
            if let message = parseErrorMessage(from: data) {
                return message
            }
        }
        
        // 2️⃣ REALITY PATH: Error types
        if let error = error as NSError? {
            switch error.code {
            case NSURLErrorTimedOut:
                return "__TIMEOUT__"
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                return "__NO_INTERNET__"
            case NSURLErrorUserAuthenticationRequired:
                return "Verification failed"
            default:
                return "Sesi kamu sudah berakhir, silakan login ulang"
            }
        }
        
        return "Terjadi kesalahan jaringan"
    }
    
    /// Parse error message dari JSON response
    private func parseErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Coba ambil dari messages.error
                if let messages = json["messages"] as? [String: Any],
                   let errorMsg = messages["error"] as? String {
                    return errorMsg
                }
                
                // Atau dari message langsung
                if let message = json["message"] as? String {
                    return message
                }
            }
        } catch {
            // Ignore parsing error
        }
        
        return nil
    }
}

