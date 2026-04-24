import Foundation
import UIKit
import CryptoKit
import CoreLocation
import Security

final class DeviceSecurityHelper {
    
    // =================================================
    // SHA-256
    // =================================================
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // =================================================
    // DEVICE ID (Vendor ID + Fallback Persistent)
    // =================================================
    
    private static let fallbackKey = "device_fallback_id"
    
    private static func getVendorId() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    private static func getFallbackId() -> String {
        
        if let existing = readKeychain(key: fallbackKey) {
            return existing
        }
        
        let newId = UUID().uuidString
        saveKeychain(key: fallbackKey, value: newId)
        return newId
    }
    
    static func getDeviceHash() -> String {

        if let vendor = UIDevice.current.identifierForVendor?.uuidString {
            return sha256(vendor)
        }

        // Fallback (Simulator)
        let key = "device_persistent_id"

        if let saved = readKeychain(key: key) {
            return sha256(saved)
        }

        let newID = UUID().uuidString
        saveKeychain(key: key, value: newID)

        return sha256(newID)
    }
    
    // =================================================
    // APP SIGNATURE HASH (ANTI RESIGN / CLONE)
    // =================================================
    
    static func getAppSignatureHash() -> String {

        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let executable = Bundle.main.executableURL?.lastPathComponent ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""

        let teamID = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String ?? ""

        let combined = bundleID + executable + build + teamID

        return sha256(combined)
    }
    
    // =================================================
    // DEBUG CHECK
    // =================================================
    
    static func isDebuggable() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // =================================================
    // JAILBREAK DETECTION (ROOT EQUIVALENT)
    // =================================================
    
    static func isDeviceJailbroken() -> Bool {
        
        // Simulator tidak dianggap jailbreak
        if isEmulator() {
            return false
        }
        
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        if canOpenCydia() {
            return true
        }
        
        if canWriteOutsideSandbox() {
            return true
        }
        
        return false
    }
    
    private static func canOpenCydia() -> Bool {
        guard let url = URL(string: "cydia://package/com.example.package") else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    private static func canWriteOutsideSandbox() -> Bool {
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
    
    // =================================================
    // EMULATOR DETECTION
    // =================================================
    
    static func isEmulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // =================================================
    // MOCK LOCATION DETECTION (HEURISTIC)
    // =================================================
    
    static func isUsingMockLocation(location: CLLocation?) -> Bool {
        
        guard let location = location else { return false }
        
        if location.horizontalAccuracy < 0 {
            return true
        }
        
        if location.speed > 50 {
            return true
        }
        
        if location.horizontalAccuracy > 1000 {
            return true
        }
        
        return false
    }
    
    // =================================================
    // FINAL VALIDATION
    // =================================================
    
    static func validateDeviceOrExit() {
        
        if isDeviceJailbroken() {
            forceExit(message: "Perangkat terdeteksi JAILBREAK.\nAplikasi ditutup.")
            return
        }
        
        if isUsingMockLocation(location: nil) {
            forceExit(message: "Fake GPS terdeteksi.")
            return
        }
    }
    
    private static func forceExit(message: String) {
        DispatchQueue.main.async {
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                exit(0)
            }
            
            let alert = UIAlertController(
                title: "Keamanan",
                message: message,
                preferredStyle: .alert
            )
            
            rootVC.present(alert, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                exit(0)
            }
        }
    }
    
    // =================================================
    // KEYCHAIN INTERNAL (PERSISTENT STORAGE)
    // =================================================
    
    private static func saveKeychain(key: String, value: String) {
        
        let data = value.data(using: .utf8)!
        
        deleteKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func readKeychain(key: String) -> String? {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    private static func deleteKeychain(key: String) {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
