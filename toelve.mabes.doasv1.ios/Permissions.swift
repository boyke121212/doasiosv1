//
//  Permissions.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import Foundation
import AVFoundation
import Photos
import CoreLocation
import UIKit

public final class Permissions: NSObject {
    
    // MARK: - Singleton
    public static let shared = Permissions()
    
    // MARK: - Location
    private var locationManager: CLLocationManager?
    private var locationCompletion: ((CLAuthorizationStatus) -> Void)?

    /// Open the app's Settings page
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Request location WhenInUse authorization.
    public func requestLocationWhenInUse(completion: ((CLAuthorizationStatus) -> Void)? = nil) {
        self.locationCompletion = completion
        
        let manager = CLLocationManager()
        manager.delegate = self
        self.locationManager = manager
        
        // Check current status
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            openAppSettings()
            completion?(status)
        case .authorizedWhenInUse, .authorizedAlways:
            completion?(status)
        @unknown default:
            completion?(status)
        }
    }

    // MARK: - Camera
    /// Request camera access. Calls completion with current access state.
    public func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            openAppSettings()
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // MARK: - Photo Library
    /// Request photo library read/write access. Calls completion with resulting status.
    public func requestPhotoLibraryAccess(completion: @escaping (PHAuthorizationStatus) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async { completion(status) }
            }
        } else {
            // iOS 13 and earlier
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async { completion(status) }
            }
        }
    }

    /// Check current statuses and open Settings if any critical permission is denied.
    public func enforcePermissionsIfDenied() {
        // Camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .denied || cameraStatus == .restricted {
            openAppSettings()
            return
        }
        
        // Photo Library
        let photoStatus: PHAuthorizationStatus
        if #available(iOS 14, *) {
            photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            photoStatus = PHPhotoLibrary.authorizationStatus()
        }
        
        if photoStatus == .denied || photoStatus == .restricted {
            openAppSettings()
            return
        }
        
        // Location (When In Use)
        let manager = CLLocationManager()
        let locationStatus = manager.authorizationStatus
        if locationStatus == .denied || locationStatus == .restricted {
            openAppSettings()
            return
        }
    }
    
    /// Request all permissions at once
    public func requestAllPermissions(completion: @escaping () -> Void) {
        requestCameraAccess { _ in
            self.requestPhotoLibraryAccess { _ in
                self.requestLocationWhenInUse { _ in
                    completion()
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension Permissions: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationCompletion?(status)
    }
    
    // For iOS 13 and earlier
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationCompletion?(status)
    }
}

