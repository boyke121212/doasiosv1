//
//  MainActivity.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit

class MainActivity: Boyke {
    
    // MARK: - UI Properties (Equivalent dengan ViewBinding di Android)
    
    /// Background Image (equivalent dengan imgBackground)
    private var imgBackground: UIImageView!
    
    /// Overlay View (equivalent dengan overlay)
    private var overlay: UIView!
    
    /// Logo Container (equivalent dengan logoContainer)
    private var logoContainer: UIStackView!
    
    /// Logo Dittipidter (equivalent dengan imgDitTipidter)
    private var imgDitTipidter: UIImageView!
    
    /// Bottom Group Container (equivalent dengan bottomGroup)
    private var bottomGroup: UIStackView!
    
    /// Bareskrim Text (equivalent dengan tvBareskrim)
    private var tvBareskrim: UILabel!
    
    /// Login Button (equivalent dengan btLogin)
    private var btLogin: UIButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI (equivalent dengan ActivityMainBinding.inflate + setContentView)
        setupUI()
        
        // Apply edge to edge padding
        applyEdgeToEdgePadding(view: view)
        
        // 🔒 HIDE BUTTON LOGIN DULU
        btLogin.isHidden = true
        
        // Check tokens
       
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("🏠 [MAINACTIVITY] viewDidAppear called")
        
        let akses = SecurePrefs.shared.getAccessToken()
        let refresh = SecurePrefs.shared.getRefreshToken()
        
        print("🏠 [MAINACTIVITY] Access Token: \(akses ?? "nil")")
        print("🏠 [MAINACTIVITY] Refresh Token: \(refresh ?? "nil")")
        
        if akses?.isEmpty ?? true || refresh?.isEmpty ?? true {
            print("🏠 [MAINACTIVITY] No tokens found, showing login button")
            btLogin.isHidden = false
        } else {
            print("🏠 [MAINACTIVITY] Tokens found, navigating to Home...")
            // Panggil navigasi di sini karena Window sudah nempel (tidak nil)
            navigateToHome()
        }
    }

    private func navigateToHome() {
        print("🏠 [MAINACTIVITY] navigateToHome() called")
        DispatchQueue.main.async {
            // Gunakan cara yang lebih kuat untuk mengambil window
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                print("❌ [MAINACTIVITY] Window not found!")
                return
            }
            
            print("✅ [MAINACTIVITY] Window found, creating Home VC")
            let homeVC = Home()
            // Tambahkan data berita kosong atau dummy jika diperlukan agar tidak crash saat load table
            homeVC.beritaItems = []
            
            window.rootViewController = homeVC
            window.makeKeyAndVisible()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            print("✅ [MAINACTIVITY] Navigation to Home complete!")
        }
    }
    // MARK: - UI Setup
    
    private func setupUI() {
        // Background setup
        view.backgroundColor = .white
        
        // 1. Background Image (imgBackground)
        imgBackground = UIImageView()
        imgBackground.image = UIImage(named: "opening") // Pastikan ada image "opening" di Assets
        imgBackground.contentMode = .scaleAspectFill
        imgBackground.clipsToBounds = true
        imgBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imgBackground)
        
        // 2. Overlay (overlay - visibility gone by default)
        overlay = UIView()
        overlay.backgroundColor = UIColor(white: 0.66, alpha: 0.33) // #55A8A7A7
        overlay.isHidden = true // visibility="gone"
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        
        // 3. Logo Container (logoContainer)
        logoContainer = UIStackView()
        logoContainer.axis = .vertical
        logoContainer.alignment = .center
        logoContainer.spacing = 0
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoContainer)
        
        // 4. Logo Image (imgDitTipidter)
        imgDitTipidter = UIImageView()
        imgDitTipidter.image = UIImage(named: "doas2") // Using doas2 logo (PNG/JPEG)
        imgDitTipidter.contentMode = .scaleAspectFit
        imgDitTipidter.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addArrangedSubview(imgDitTipidter)
        
        // 5. Bottom Group Container (bottomGroup)
        bottomGroup = UIStackView()
        bottomGroup.axis = .vertical
        bottomGroup.alignment = .center
        bottomGroup.spacing = 16
        bottomGroup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomGroup)
        
        // 6. Bareskrim Text (tvBareskrim)
        tvBareskrim = UILabel()
        tvBareskrim.text = "BARESKRIM POLRI"
        tvBareskrim.textColor = UIColor(white: 0.88, alpha: 1.0) // #E0E0E0
        tvBareskrim.font = UIFont.systemFont(ofSize: 12)
        tvBareskrim.translatesAutoresizingMaskIntoConstraints = false
        bottomGroup.addArrangedSubview(tvBareskrim)
        
        // 7. Login Button (btLogin)
        btLogin = UIButton(type: .custom)
        btLogin.setTitle("LOGIN", for: .normal)
        btLogin.setTitleColor(.white, for: .normal)
        btLogin.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btLogin.backgroundColor = UIColor.systemBlue // Temporary, nanti ganti dengan btn_primary style
        btLogin.layer.cornerRadius = 12
        btLogin.translatesAutoresizingMaskIntoConstraints = false
        btLogin.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        bottomGroup.addArrangedSubview(btLogin)
        
        // Setup All Constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background Image - Full Screen (match_parent)
            imgBackground.topAnchor.constraint(equalTo: view.topAnchor),
            imgBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imgBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imgBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Overlay - Full Screen (match_parent)
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Logo Container - Top center with margin 20dp
            logoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Logo Image - 90dp x 90dp
            imgDitTipidter.widthAnchor.constraint(equalToConstant: 90),
            imgDitTipidter.heightAnchor.constraint(equalToConstant: 90),
            
            // Bottom Group - Bottom aligned with padding 32dp
            bottomGroup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            bottomGroup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            bottomGroup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            
            // Login Button - Full width in parent with height 56dp
            btLogin.leadingAnchor.constraint(equalTo: bottomGroup.leadingAnchor),
            btLogin.trailingAnchor.constraint(equalTo: bottomGroup.trailingAnchor),
            btLogin.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    // MARK: - Actions
    
    /// Equivalent dengan binding.btLogin.setOnClickListener di Android
    @objc private func loginButtonTapped() {
        let loginVC = Loginpage()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
    
    // MARK: - Navigation
    
    /// Navigate to Home (equivalent dengan startActivity + finishAffinity)
   
}
