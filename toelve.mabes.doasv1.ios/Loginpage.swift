//
//  Loginpage.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit

class Loginpage: Boyke {
    
    // MARK: - UI Properties (Equivalent dengan ViewBinding)
    
    /// ScrollView (root container)
    private var scrollView: UIScrollView!
    
    /// Main Container
    private var containerView: UIView!
    
    /// Header Accent (blue background)
    private var headerAccent: UIView!
    
    /// Card Login (white card container)
    private var cardLogin: UIView!
    
    /// Logo ImageView
    private var imgLogo: UIImageView!
    
    /// Title Label "Masuk ke DOAS"
    private var lblTitle: UILabel!
    
    /// Subtitle Label
    private var lblSubtitle: UILabel!
    
    /// Divider View (blue line)
    private var divider: UIView!
    
    /// Username TextField
    private var etUsername: UITextField!
    private var usernameContainer: UIView!
    
    /// Password TextField
    private var etPassword: UITextField!
    private var passwordContainer: UIView!
    private var btnTogglePassword: UIButton!
    
    /// Login Button
    private var btMasuk: UIButton!
    
    /// Double back to exit tracking
    private var lastBackPressTime: Date?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI (equivalent dengan ActivityLoginpageBinding.inflate + setContentView)
        setupUI()
        
        // Apply edge to edge padding
        applyEdgeToEdgePadding(view: view)
        
        // Setup double back to exit
        setupDoubleBackExit()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0) // #F4F6F8
        
        // 1. ScrollView (fillViewport)
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // 2. Container View (equivalent dengan ConstraintLayout)
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        
        // 3. Header Accent (blue background 160dp)
        headerAccent = UIView()
        headerAccent.backgroundColor = UIColor(red: 0.16, green: 0.38, blue: 1.0, alpha: 1.0) // #2962FF
        headerAccent.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerAccent)
        
        // 4. Card Login (white card with shadow)
        cardLogin = UIView()
        cardLogin.backgroundColor = .white
        cardLogin.layer.cornerRadius = 22
        cardLogin.layer.shadowColor = UIColor.black.cgColor
        cardLogin.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardLogin.layer.shadowOpacity = 0.15
        cardLogin.layer.shadowRadius = 12
        cardLogin.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cardLogin)
        
        // 5. Logo
        imgLogo = UIImageView()
        imgLogo.image = UIImage(named: "doas2") // Load from Assets (PNG/JPEG only)
        imgLogo.contentMode = .scaleAspectFit
        imgLogo.translatesAutoresizingMaskIntoConstraints = false
        cardLogin.addSubview(imgLogo)
        
        // 6. Title "Masuk ke DOAS"
        lblTitle = UILabel()
        lblTitle.text = "Masuk ke DOAS"
        lblTitle.font = UIFont.boldSystemFont(ofSize: 22)
        lblTitle.textColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0) // #111111
        lblTitle.textAlignment = .center
        lblTitle.translatesAutoresizingMaskIntoConstraints = false
        cardLogin.addSubview(lblTitle)
        
        // 7. Subtitle
        lblSubtitle = UILabel()
        lblSubtitle.text = "Data Anda Adalah Tanggung Jawab Anda"
        lblSubtitle.font = UIFont.systemFont(ofSize: 14)
        lblSubtitle.textColor = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0) // #777777
        lblSubtitle.textAlignment = .center
        lblSubtitle.numberOfLines = 0
        lblSubtitle.translatesAutoresizingMaskIntoConstraints = false
        cardLogin.addSubview(lblSubtitle)
        
        // 8. Divider (blue line)
        divider = UIView()
        divider.backgroundColor = UIColor(red: 0.16, green: 0.38, blue: 1.0, alpha: 1.0) // #2962FF
        divider.translatesAutoresizingMaskIntoConstraints = false
        cardLogin.addSubview(divider)
        
        // 9. Username Container
        usernameContainer = createTextFieldContainer()
        cardLogin.addSubview(usernameContainer)
        
        let lblUsername = UILabel()
        lblUsername.text = "Username"
        lblUsername.font = UIFont.systemFont(ofSize: 12)
        lblUsername.textColor = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0)
        lblUsername.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(lblUsername)
        
        etUsername = UITextField()
        etUsername.font = UIFont.systemFont(ofSize: 16)
        etUsername.textColor = .black
        etUsername.autocapitalizationType = .none
        etUsername.autocorrectionType = .no
        etUsername.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(etUsername)
        
        NSLayoutConstraint.activate([
            lblUsername.topAnchor.constraint(equalTo: usernameContainer.topAnchor, constant: 8),
            lblUsername.leadingAnchor.constraint(equalTo: usernameContainer.leadingAnchor, constant: 16),
            
            etUsername.topAnchor.constraint(equalTo: lblUsername.bottomAnchor, constant: 4),
            etUsername.leadingAnchor.constraint(equalTo: usernameContainer.leadingAnchor, constant: 16),
            etUsername.trailingAnchor.constraint(equalTo: usernameContainer.trailingAnchor, constant: -16),
            etUsername.bottomAnchor.constraint(equalTo: usernameContainer.bottomAnchor, constant: -8)
        ])
        
        // 10. Password Container
        passwordContainer = createTextFieldContainer()
        cardLogin.addSubview(passwordContainer)
        
        let lblPassword = UILabel()
        lblPassword.text = "Password"
        lblPassword.font = UIFont.systemFont(ofSize: 12)
        lblPassword.textColor = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0)
        lblPassword.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.addSubview(lblPassword)
        
        etPassword = UITextField()
        etPassword.font = UIFont.systemFont(ofSize: 16)
        etPassword.textColor = .black
        etPassword.isSecureTextEntry = true
        etPassword.autocapitalizationType = .none
        etPassword.autocorrectionType = .no
        etPassword.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.addSubview(etPassword)
        
        // Password toggle button
        btnTogglePassword = UIButton(type: .custom)
        btnTogglePassword.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        btnTogglePassword.setImage(UIImage(systemName: "eye"), for: .selected)
        btnTogglePassword.tintColor = .gray
        btnTogglePassword.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        btnTogglePassword.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.addSubview(btnTogglePassword)
        
        NSLayoutConstraint.activate([
            lblPassword.topAnchor.constraint(equalTo: passwordContainer.topAnchor, constant: 8),
            lblPassword.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 16),
            
            etPassword.topAnchor.constraint(equalTo: lblPassword.bottomAnchor, constant: 4),
            etPassword.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 16),
            etPassword.trailingAnchor.constraint(equalTo: btnTogglePassword.leadingAnchor, constant: -8),
            etPassword.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: -8),
            
            btnTogglePassword.centerYAnchor.constraint(equalTo: etPassword.centerYAnchor),
            btnTogglePassword.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -16),
            btnTogglePassword.widthAnchor.constraint(equalToConstant: 30),
            btnTogglePassword.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 11. Login Button
        btMasuk = UIButton(type: .custom)
        btMasuk.setTitle("LOGIN", for: .normal)
        btMasuk.setTitleColor(.white, for: .normal)
        btMasuk.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btMasuk.backgroundColor = UIColor(red: 0.16, green: 0.38, blue: 1.0, alpha: 1.0) // #2962FF
        btMasuk.layer.cornerRadius = 16
        btMasuk.layer.shadowColor = UIColor.black.cgColor
        btMasuk.layer.shadowOffset = CGSize(width: 0, height: 3)
        btMasuk.layer.shadowOpacity = 0.2
        btMasuk.layer.shadowRadius = 6
        btMasuk.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        btMasuk.translatesAutoresizingMaskIntoConstraints = false
        cardLogin.addSubview(btMasuk)
        
        // Setup all constraints
        setupConstraints()
        
        // Dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func createTextFieldContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }
    
    private func setupConstraints() {
        _ = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // ScrollView - Full screen
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container View
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header Accent - 160dp height
            headerAccent.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerAccent.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerAccent.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerAccent.heightAnchor.constraint(equalToConstant: 160),
            
            // Card Login - marginTop="-80dp" (overlap dengan header)
            cardLogin.topAnchor.constraint(equalTo: headerAccent.bottomAnchor, constant: -80),
            cardLogin.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            cardLogin.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            cardLogin.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -24),
            
            // Logo - 88dp x 88dp, centered
            imgLogo.topAnchor.constraint(equalTo: cardLogin.topAnchor, constant: 28),
            imgLogo.centerXAnchor.constraint(equalTo: cardLogin.centerXAnchor),
            imgLogo.widthAnchor.constraint(equalToConstant: 88),
            imgLogo.heightAnchor.constraint(equalToConstant: 88),
            
            // Title - marginTop 16dp
            lblTitle.topAnchor.constraint(equalTo: imgLogo.bottomAnchor, constant: 16),
            lblTitle.leadingAnchor.constraint(equalTo: cardLogin.leadingAnchor, constant: 28),
            lblTitle.trailingAnchor.constraint(equalTo: cardLogin.trailingAnchor, constant: -28),
            
            // Subtitle - marginTop 6dp
            lblSubtitle.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 6),
            lblSubtitle.leadingAnchor.constraint(equalTo: cardLogin.leadingAnchor, constant: 28),
            lblSubtitle.trailingAnchor.constraint(equalTo: cardLogin.trailingAnchor, constant: -28),
            
            // Divider - 40dp x 4dp, marginTop 16dp
            divider.topAnchor.constraint(equalTo: lblSubtitle.bottomAnchor, constant: 16),
            divider.centerXAnchor.constraint(equalTo: cardLogin.centerXAnchor),
            divider.widthAnchor.constraint(equalToConstant: 40),
            divider.heightAnchor.constraint(equalToConstant: 4),
            
            // Username Container - marginTop 24dp
            usernameContainer.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 24),
            usernameContainer.leadingAnchor.constraint(equalTo: cardLogin.leadingAnchor, constant: 28),
            usernameContainer.trailingAnchor.constraint(equalTo: cardLogin.trailingAnchor, constant: -28),
            usernameContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            
            // Password Container - marginTop 14dp
            passwordContainer.topAnchor.constraint(equalTo: usernameContainer.bottomAnchor, constant: 14),
            passwordContainer.leadingAnchor.constraint(equalTo: cardLogin.leadingAnchor, constant: 28),
            passwordContainer.trailingAnchor.constraint(equalTo: cardLogin.trailingAnchor, constant: -28),
            passwordContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            
            // Login Button - marginTop 28dp, height 54dp
            btMasuk.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 28),
            btMasuk.leadingAnchor.constraint(equalTo: cardLogin.leadingAnchor, constant: 28),
            btMasuk.trailingAnchor.constraint(equalTo: cardLogin.trailingAnchor, constant: -28),
            btMasuk.heightAnchor.constraint(equalToConstant: 54),
            btMasuk.bottomAnchor.constraint(equalTo: cardLogin.bottomAnchor, constant: -28)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func togglePasswordVisibility() {
        etPassword.isSecureTextEntry.toggle()
        btnTogglePassword.isSelected = !etPassword.isSecureTextEntry
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// Equivalent dengan binding.btMasuk.setOnClickListener di Android
    @objc private func loginButtonTapped() {
        print("🔘 [LOGIN] Login button tapped!")
        
        let username = etUsername.text ?? ""
        let password = etPassword.text ?? ""
        
        print("🔘 [LOGIN] Username: '\(username)'")
        print("🔘 [LOGIN] Password length: \(password.count)")
        
        if username.isEmpty || password.isEmpty {
            print("⚠️ [LOGIN] Validation failed: empty fields")
            showToast(message: "Username dan Password harus diisi")
            return
        }
        
        // Show loading
        print("🔘 [LOGIN] Showing loading...")
        showLoading()
        
        // Get BASE_URL from BuildConfig (equivalent)
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            print("❌ [LOGIN] BASE_URL not found in Info.plist!")
            hideLoading()
            showToast(message: "Konfigurasi BASE_URL tidak ditemukan")
            return
        }
        
        let url = baseURL + "/cekdata"
        print("🔘 [LOGIN] Full URL: \(url)")
        
        // Gunakan Task untuk handle async call dari sync context
        Task { @MainActor in
            print("🔘 [LOGIN] Starting async task...")
            await self.performLogin(url: url, username: username, password: password)
        }
    }
    
    /// Perform login asynchronously
    @MainActor
    private func performLogin(url: String, username: String, password: String) async {
        print("🔵 [LOGIN] Starting login request to: \(url)")
        print("🔵 [LOGIN] Username: \(username)")
        
        await VolleyHelper.shared.login(
            url: url,
            username: username,
            password: password,
            onSuccess: { [weak self] json in
                print("✅ [LOGIN] onSuccess called!")
                print("✅ [LOGIN] Response JSON: \(json)")
                
                guard let self = self else {
                    print("⚠️ [LOGIN] self is nil in onSuccess")
                    return
                }
                
                // Pastikan kita di main thread
                DispatchQueue.main.async {
                    print("✅ [LOGIN] Hiding loading...")
                    self.hideLoading()
                    
                    if let status = json["status"] as? String, status == "success" {
                        print("✅ [LOGIN] Status is success, extracting tokens...")
                        
                        guard let accessToken = json["access_token"] as? String,
                              let refreshToken = json["refresh_token"] as? String else {
                            print("❌ [LOGIN] Tokens not found in response")
                            self.showToast(message: "Token tidak valid")
                            return
                        }
                        
                        print("✅ [LOGIN] Tokens extracted successfully")
                        
                        // 🔐 SIMPAN TOKEN (PAKAI SecurePrefs)
                        SecurePrefs.shared.saveAccessToken(accessToken)
                        SecurePrefs.shared.saveRefreshToken(refreshToken)
                        
                        print("✅ [LOGIN] Tokens saved, navigating to home...")
                        
                        // Navigate to Home (equivalent dengan logbound)
                        self.logbound()
                    } else {
                        let message = json["message"] as? String ?? "Login gagal"
                        print("❌ [LOGIN] Status is not success: \(message)")
                        self.showToast(message: message)
                    }
                }
            },
            onError: { [weak self] errorMessage in
                print("❌ [LOGIN] onError called!")
                print("❌ [LOGIN] Error message: \(errorMessage)")
                
                guard let self = self else {
                    print("⚠️ [LOGIN] self is nil in onError")
                    return
                }
                
                // Pastikan kita di main thread
                DispatchQueue.main.async {
                    print("❌ [LOGIN] Hiding loading...")
                    self.hideLoading()
                    self.showToast(message: errorMessage)
                }
            }
        )
        
        print("🔵 [LOGIN] Login request initiated, waiting for response...")
    }
    
    // MARK: - Navigation
    
    
    // MARK: - Double Back to Exit
    
    /// Equivalent dengan setupDoubleBackExit() di Android

    
    // MARK: - Helper Methods
    
    /// Show toast message (equivalent dengan Toast.makeText)
     func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.dismiss(animated: true)
        }
    }
}
