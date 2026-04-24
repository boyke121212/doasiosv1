//
//  SecurePrefs.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import Foundation
import Security

/// Secure preferences untuk menyimpan token dengan aman menggunakan Keychain
/// Equivalent dengan SecurePrefs.kt di Android (SharedPreferences + EncryptedSharedPreferences)
class SecurePrefs {
    
    // MARK: - Singleton
    
    static let shared = SecurePrefs()
    
    // MARK: - Constants
    
    private let serviceName = "com.toelve.mabes.doasv1.ios"
    private let accessTokenKey = "ACCESS_TOKEN"
    private let refreshTokenKey = "REFRESH_TOKEN"
    
    // MARK: - Initializer
    
    private init() {
        // Private init untuk singleton
    }
    
    /// Static method untuk compatibility dengan Android (SecurePrefs.get(context))
    static func get() -> SecurePrefs {
        return shared
    }
    
    // MARK: - Access Token
    
    /// Simpan access token ke Keychain
    func saveAccessToken(_ token: String) {
        save(key: accessTokenKey, value: token)
    }
    
    /// Ambil access token dari Keychain
    func getAccessToken() -> String? {
        return get(key: accessTokenKey)
    }
    
    // MARK: - Refresh Token
    
    /// Simpan refresh token ke Keychain
    func saveRefreshToken(_ token: String) {
        save(key: refreshTokenKey, value: token)
    }
    
    /// Ambil refresh token dari Keychain
    func getRefreshToken() -> String? {
        return get(key: refreshTokenKey)
    }
    
    // MARK: - AES Key
    
    /// Simpan AES key ke Keychain
    func saveAesKey(_ key: String) {
        save(key: "superkey", value: key)
    }
    
    /// Ambil AES key dari Keychain
    func getAesKey() -> String? {
        return get(key: "superkey")
    }
    
    // MARK: - Login Status
    
    /// Simpan login status
    func saveLogin(_ value: String) {
        save(key: "isLogin", value: value)
    }
    
    /// Ambil login status
    func getLogin() -> String? {
        return get(key: "isLogin")
    }
    
    // MARK: - Clear
    
    /// Hapus semua data dari Keychain (logout)
    func clear() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }
    
    // MARK: - Private Keychain Methods
    
    /// Simpan value ke Keychain
    private func save(key: String, value: String) {
        // Hapus value lama jika ada
        delete(key: key)
        
        // Siapkan data
        guard let data = value.data(using: .utf8) else { return }
        
        // Query untuk save ke Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Save to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("❌ Error saving to Keychain: \(status)")
        }
    }
    
    /// Ambil value dari Keychain
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let value = String(data: data, encoding: .utf8) {
                return value
            }
        }
        
        return nil
    }
    
    /// Hapus value dari Keychain
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

