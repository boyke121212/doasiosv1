//
//  AbsensiManager.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit
import AVFoundation
import CoreLocation
import LocalAuthentication

class AbsensiManager: NSObject {
    
    // MARK: - Properties
    
    var lat: Double?
    var lon: Double?
    var capturedFile: URL?
    
    private var kantorLat: Double?
    private var kantorLon: Double?
    
    private var mode: ModeAbsensi = .PERLU_LOKASI
    private let radiusMeter: Double = 100.0
    
    private var lensFacing: AVCaptureDevice.Position = .front
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private weak var viewController: UIViewController?
    private weak var previewView: UIView?
    
    private let locationManager = CLLocationManager()
    
    private var onPreviewCallback: ((URL) -> Void)?
    
    // MARK: - Initialization
    
    init(viewController: UIViewController, previewView: UIView) {
        self.viewController = viewController
        self.previewView = previewView
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Biometric Authentication
    
    func authenticate(onSuccess: @escaping () -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verifikasi Sidik Jari untuk konfirmasi absensi"
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        onSuccess()
                    } else {
                        self.toast("Autentikasi gagal")
                    }
                }
            }
        } else {
            // Fallback jika biometric tidak tersedia
            onSuccess()
        }
    }
    
    // MARK: - Set Lokasi Kantor
    
    func setLokasiKantor(lat: Double, lon: Double) {
        self.kantorLat = lat
        self.kantorLon = lon
    }
    
    // MARK: - Prepare
    
    func prepare(modeAbsensi: ModeAbsensi) {
        self.mode = modeAbsensi
        ensureCamera()
    }
    
    // MARK: - Capture
    
    func capture(onPreview: @escaping (URL) -> Void) {
#if targetEnvironment(simulator)
        // SIMULATOR: Generate dummy image (tapi pakai lokasi real dari HP)
        if mode == .PERLU_LOKASI {
            guard let _ = self.lat, let _ = self.lon else {
                toast("Lokasi belum tersedia")
                return
            }
        }
        
        self.onPreviewCallback = onPreview
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.createDummyPhoto()
        }
#else
        guard let photoOutput = self.photoOutput else {
            toast("Kamera belum siap")
            return
        }
        
        if mode == .PERLU_LOKASI {
            guard let lat = self.lat, let lon = self.lon else {
                toast("Lokasi belum tersedia")
                return
            }
            
            // Optional: Check radius
            // if let kantorLat = kantorLat, let kantorLon = kantorLon {
            //     let jarak = hitungJarak(lat1: lat, lon1: lon, lat2: kantorLat, lon2: kantorLon)
            //     if jarak > radiusMeter {
            //         toast("Diluar area absensi (\(Int(jarak)) m)")
            //         return
            //     }
            // }
        }
        
        self.onPreviewCallback = onPreview
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
#endif
    }
    
    // MARK: - Location
    
    private func requestLocationInternal() {
        locationManager.requestLocation()
    }
    
    private func hitungJarak(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) *
                cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
    
    // MARK: - Camera
    
    private func startCameraInternal() {
#if targetEnvironment(simulator)

    DispatchQueue.main.async {

        guard let previewView = self.previewView else { return }

        // dummy preview layer
        let img = UIImage(systemName: "person.crop.square.fill")!
        let imageView = UIImageView(image: img)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = previewView.bounds

        previewView.addSubview(imageView)

        print("SIMULATOR CAMERA PREVIEW")
    }

#else
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: lensFacing
        ) else {
            toast("Kamera tidak tersedia")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            self.photoOutput = output
            self.captureSession = session
            
            // Setup preview layer
            if let previewView = self.previewView {
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.frame = previewView.bounds
                previewLayer.videoGravity = .resizeAspectFill
                
                // Remove old layers
                previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                previewView.layer.addSublayer(previewLayer)
                self.previewLayer = previewLayer
            }
            
            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            
        } catch {
            toast("Gagal memulai kamera: \(error.localizedDescription)")
        }
#endif
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
    
    func stop() {
        stopCamera()
        capturedFile = nil
    }
    
    func restartPreview() {
        capturedFile = nil
        startCameraInternal()
    }
    
    func switchCamera() {
        lensFacing = (lensFacing == .front) ? .back : .front
        stopCamera()
        startCameraInternal()
    }
    
    // MARK: - Permissions
    
    private func ensureCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCameraInternal()
            if mode == .PERLU_LOKASI {
                ensureLocation()
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startCameraInternal()
                        if self.mode == .PERLU_LOKASI {
                            self.ensureLocation()
                        }
                    } else {
                        self.toast("Izin kamera wajib")
                    }
                }
            }
            
        case .denied, .restricted:
            toast("Izin kamera wajib")
            
        @unknown default:
            break
        }
    }
    
    private func ensureLocation() {
        // AMBIL LOKASI REAL DARI HP/EMULATOR (tidak pakai dummy)
        let status: CLAuthorizationStatus
        
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocationInternal()
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            toast("Izin lokasi wajib")
            
        @unknown default:
            break
        }
    }
    
    // MARK: - File Management
    
    private func createDummyPhoto() {
        #if targetEnvironment(simulator)
        // Create dummy image
        let size = CGSize(width: 720, height: 900) // 4:5 ratio
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])
            
            // Add icon
            let iconSize: CGFloat = 200
            let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                 y: (size.height - iconSize) / 2 - 50,
                                 width: iconSize,
                                 height: iconSize)
            
            if let personIcon = UIImage(systemName: "person.crop.square.fill") {
                personIcon.withTintColor(.white, renderingMode: .alwaysOriginal)
                    .draw(in: iconRect)
            }
            
            // Add text
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            let text = "SIMULATOR DUMMY PHOTO"
            let textRect = CGRect(x: 0, y: size.height - 100, width: size.width, height: 50)
            (text as NSString).draw(in: textRect,
                                   withAttributes: attrs)
            
            // Add location if available
            if let lat = lat, let lon = lon {
                let locText = "Lat: \(String(format: "%.6f", lat))\nLon: \(String(format: "%.6f", lon))"
                let locAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.8)
                ]
                let locRect = CGRect(x: 20, y: 20, width: size.width - 40, height: 60)
                (locText as NSString).draw(in: locRect, withAttributes: locAttrs)
            }
        }
        
        let file = createImageFile()
        
        // Save image
        if let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: file)
        }
        
        // Process image (same as real camera)
        ImageProcessor.processAndSave(
            file: file,
            isFrontCamera: (lensFacing == .front),
            lat: lat,
            lon: lon,
            mode: mode
        )
        
        self.capturedFile = file
        self.onPreviewCallback?(file)
        
        print("✅ [SIMULATOR] Dummy photo created: \(file.path)")
        #endif
    }
    
    private func createImageFile() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let doasDirectory = documentsDirectory.appendingPathComponent("DOAS", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: doasDirectory.path) {
            try? FileManager.default.createDirectory(
                at: doasDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        return doasDirectory.appendingPathComponent("absen_\(timestamp).jpg")
    }
    
    private func toast(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Informasi",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.viewController?.present(alert, animated: true)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension AbsensiManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("❌ [ABSENSI] Capture error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.toast("Gagal ambil foto")
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.toast("Gagal memproses foto")
            }
            return
        }
        
        let file = createImageFile()
        
        // Save image temporarily
        if let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: file)
        }
        
        // Process image (rotate, watermark, etc.)
        ImageProcessor.processAndSave(
            file: file,
            isFrontCamera: (lensFacing == .front),
            lat: lat,
            lon: lon,
            mode: mode
        )
        
        DispatchQueue.main.async {
            self.capturedFile = file
            self.stopCamera()
            self.onPreviewCallback?(file)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension AbsensiManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            print("📍 [ABSENSI] Location updated: \(lat ?? 0), \(lon ?? 0)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [ABSENSI] Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            requestLocationInternal()
        }
    }
}

