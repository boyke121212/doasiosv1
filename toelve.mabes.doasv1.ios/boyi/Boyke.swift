//
//  Boyke.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit

/// Base view controller class yang di-inherit oleh semua view controller di aplikasi.
/// Equivalent dengan Boyke.kt di Android.
class Boyke: UIViewController {
    
    // MARK: - Properties
    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initLoading()
        applyEdgeToEdgeAutomatically()
    }
    
    // MARK: - Edge to Edge
    
    /// Mengatur agar content tidak tertutup oleh safe area secara otomatis.
    /// Equivalent dengan enableEdgeToEdge() dan applyEdgeToEdgeAutomatically() di Android.
    private func applyEdgeToEdgeAutomatically() {
        // Di iOS, safe area sudah ditangani otomatis oleh system
        // Kita hanya perlu memastikan view menggunakan safe area layout guides
        
        // Extend edges under top and bottom bars (equivalent dengan edge-to-edge)
        edgesForExtendedLayout = [.top, .bottom]
        extendedLayoutIncludesOpaqueBars = true
        
        // Pastikan view menggunakan safe area
        if let rootView = view {
            // Safe area sudah otomatis di-handle oleh iOS
            // Tapi kita bisa apply padding manual jika diperlukan
            applyEdgeToEdgePadding(view: rootView)
        }
    }
    
    /// Mengatur agar view tertentu tidak tertutup oleh status bar atau navigation bar.
    /// Panggil ini setelah view di-setup.
    ///
    /// - Parameter view: View yang akan di-apply padding berdasarkan safe area.
    func applyEdgeToEdgePadding(view: UIView) {
        // Di iOS, kita gunakan safeAreaLayoutGuide
        // Untuk mendapatkan padding yang sama seperti di Android
        
        // Jika menggunakan Auto Layout, constraints otomatis menggunakan safe area
        // Jika menggunakan frame-based layout, kita bisa apply padding manual
        
        // Cara 1: Menggunakan safeAreaInsets (untuk frame-based layout)
        if view.constraints.isEmpty {
            // Frame-based layout - apply manual padding
            let safeArea = view.safeAreaInsets
            view.layoutMargins = UIEdgeInsets(
                top: safeArea.top,
                left: safeArea.left,
                bottom: safeArea.bottom,
                right: safeArea.right
            )
        }
        // Cara 2: Auto Layout sudah otomatis handle safe area
    }
    
    // MARK: - Loading Dialog
    
    /// Inisialisasi loading dialog.
    /// Equivalent dengan initLoading() di Android.
    private func initLoading() {
        if loadingView == nil {
            // Buat background overlay
            let overlay = UIView()
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.isHidden = true
            
            // Buat container untuk loading indicator (equivalent dengan dialog_loading.xml)
            let containerView = UIView()
            containerView.backgroundColor = .white
            containerView.layer.cornerRadius = 12
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            // Buat activity indicator (equivalent dengan ProgressBar di Android)
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .gray
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            
            // Setup hierarchy
            containerView.addSubview(indicator)
            overlay.addSubview(containerView)
            
            // Setup constraints untuk indicator di dalam container
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                
                containerView.widthAnchor.constraint(equalToConstant: 100),
                containerView.heightAnchor.constraint(equalToConstant: 100),
                containerView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])
            
            self.loadingView = overlay
            self.activityIndicator = indicator
        }
    }
    
    /// Menampilkan loading dialog.
    /// Equivalent dengan showLoading() di Android.
    func showLoading() {
        guard !isBeingDismissed,
              let loadingView = loadingView
        else { return }
        
        // Get window dari windowScene (iOS 15+)
        let window: UIWindow?
        if let viewWindow = view.window {
            window = viewWindow
        } else if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        } else {
            window = nil
        }
        
        guard let window = window else { return }
        
        if loadingView.isHidden {
            // Add ke window jika belum ada
            if loadingView.superview == nil {
                window.addSubview(loadingView)
                
                // Setup constraints untuk full screen
                NSLayoutConstraint.activate([
                    loadingView.topAnchor.constraint(equalTo: window.topAnchor),
                    loadingView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    loadingView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                    loadingView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
                ])
            }
            
            loadingView.isHidden = false
            activityIndicator?.startAnimating()
            
            // Prevent user interaction (equivalent dengan setCancelable(false))
            loadingView.isUserInteractionEnabled = true
        }
    }
    
    func openPage(_ vc: UIViewController) {
        // MATIKAN monitor instance lama agar tidak terjadi zombie monitor di background
        
        vc.modalPresentationStyle = .fullScreen
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
    
    /// Menyembunyikan loading dialog.
    /// Equivalent dengan hideLoading() di Android.
    func hideLoading() {
        guard !isBeingDismissed else { return }
        
        if let loadingView = loadingView, !loadingView.isHidden {
            loadingView.isHidden = true
            activityIndicator?.stopAnimating()
        }
    }
    
    
    // MARK: - Deinitialization
    
    deinit {
        // Cleanup loading view
        loadingView?.removeFromSuperview()
        loadingView = nil
        activityIndicator = nil
    }
    
    /// Override viewWillDisappear untuk cleanup loading jika view controller di-dismiss.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            hideLoading()
        }
    }
}

