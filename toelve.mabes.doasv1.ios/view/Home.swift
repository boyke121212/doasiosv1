import UIKit

class Home: Boyke, UIScrollViewDelegate {
    
    // MARK: - UI Components
    private let headerView = UIView()
    let tvJudul = UILabel()
    let tvIsi = UILabel()
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    // Tab Menu Buttons
    private let btAbsen = UIButton(type: .system)
    private let btStatus = UIButton(type: .system)
    private let btBerita = UIButton(type: .system)
    private let btLog = UIButton(type: .system)
    private let btDoas = UIButton(type: .system)
    
    // Main Content Buttons
    private let btHadir = UIButton(type: .system)
    
    // Grid Buttons
    private let btDik = UIButton(type: .system)
    private let btCuti = UIButton(type: .system)
    private let btDinas = UIButton(type: .system)
    private let btIzin = UIButton(type: .system)
    private let btSakit = UIButton(type: .system)
    private let btBko = UIButton(type: .system)
    private let btLd = UIButton(type: .system)
    // UIPageViewController untuk berita slider (mirip ViewPager Android)
    let pageController: UIPageViewController = {
        let pc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pc.view.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    /// List data berita (dikirim dari login)
    var beritaItems: [BeritaItem] = []
    var currentIndex = 0
    var rawDashboardJSON: [String: Any]?
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0) // #F4F6F8
        
        setupUI()
        setupActions()
        setupDoubleBackExit()
        btBerita.addTarget(self, action: #selector(ontapInfo), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(ontaplog), for: .touchUpInside)
        btDoas.addTarget(self, action: #selector(tapdoas), for: .touchUpInside)
        btStatus.addTarget(self, action: #selector(tapstatus), for: .touchUpInside)


    }
    @objc private func tapdoas() {
        let beritaVC = Doas()
        openPage(beritaVC)
    }
    @objc private func tapstatus() {
        let beritaVC = Statuses()
        openPage(beritaVC)
    }
    
    @objc private func ontapInfo() {
        let beritaVC = BeritaViewController()
        openPage(beritaVC)
    }
    
    @objc private func ontaplog() {
        let HistoryVC = History()
        openPage(HistoryVC)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Panggil fungsi dos() yang ada di Hendry.swift
        self.dos()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 1. Header (Hero Section) dengan UIPageViewController
        headerView.backgroundColor = .darkGray
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Setup UIPageViewController sebagai child
        addChild(pageController)
        headerView.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        tvJudul.text = "D.O.A.S"
        tvJudul.textColor = .white
        tvJudul.font = .boldSystemFont(ofSize: 18)
        
        tvIsi.text = "DITTIPIDTER BARESKRIM"
        tvIsi.textColor = .lightGray
        tvIsi.font = .systemFont(ofSize: 13)
        tvIsi.numberOfLines = 2
        
        let heroStack = UIStackView(arrangedSubviews: [tvJudul, tvIsi])
        heroStack.axis = .vertical
        heroStack.spacing = 4
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(heroStack)
        
        // 2. Tab Menu
        let tabMenu = UIStackView(arrangedSubviews: [btAbsen, btStatus, btBerita, btLog, btDoas])
        tabMenu.axis = .horizontal
        tabMenu.distribution = .fillEqually
        tabMenu.backgroundColor = .white
        tabMenu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabMenu)
        
        configureTabButton(btAbsen, title: "Absen", isActive: true)
        configureTabButton(btStatus, title: "Status")
        configureTabButton(btBerita, title: "Berita")
        configureTabButton(btLog, title: "Log")
        configureTabButton(btDoas, title: "DOAS")
        
        // 3. Content ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.axis = .vertical
        contentView.spacing = 20
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // 4. Card Absen
        setupCardAbsen()
        
        // 5. Grid Menu
        setupGridMenu()
        
        // Constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 300),
            
            heroStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            heroStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            tabMenu.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabMenu.heightAnchor.constraint(equalToConstant: 52),
            
            scrollView.topAnchor.constraint(equalTo: tabMenu.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func setupCardAbsen() {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.shadowOpacity = 0.1
        card.layer.shadowRadius = 8
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Presensi Hari Ini"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .gray
        
        btHadir.setTitle("ABSEN DINAS LUAR", for: .normal)
        btHadir.backgroundColor = .systemBlue
        btHadir.setTitleColor(.white, for: .normal)
        btHadir.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btHadir.layer.cornerRadius = 12
        btHadir.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let stack = UIStackView(arrangedSubviews: [label, btHadir])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(stack)
        contentView.addArrangedSubview(card)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupGridMenu() {
        let label = UILabel()
        label.text = "Menu Lainnya"
        label.font = .boldSystemFont(ofSize: 13)
        contentView.addArrangedSubview(label)
        
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 10
        
        let rows = [
            [btDik, btCuti],
            [btDinas, btIzin],
            [btSakit, btBko],
            [btLd]
        ]
        
        for row in rows {
            let rowStack = UIStackView(arrangedSubviews: row)
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            gridStack.addArrangedSubview(rowStack)
            
            row.forEach { configureSecondaryButton($0) }
        }
        
        btDik.setTitle("DIK", for: .normal)
        btCuti.setTitle("Cuti", for: .normal)
        btDinas.setTitle("Dinas", for: .normal)
        btIzin.setTitle("Izin", for: .normal)
        btSakit.setTitle("Sakit", for: .normal)
        btBko.setTitle("BKO", for: .normal)
        btLd.setTitle("Lepas Dinas", for: .normal)
        
        contentView.addArrangedSubview(gridStack)
    }
    
    // MARK: - Helpers & Actions
    private func configureTabButton(_ button: UIButton, title: String, isActive: Bool = false) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: isActive ? .bold : .regular)
        button.setTitleColor(isActive ? .systemBlue : .darkGray, for: .normal)
        if isActive { button.backgroundColor = UIColor(white: 0.9, alpha: 1.0) }
    }
    
    private func configureSecondaryButton(_ button: UIButton) {
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupActions() {
        btHadir.addTarget(self, action: #selector(hadirTapped), for: .touchUpInside)
        
        let absenButtons: [UIButton: String] = [
            btStatus: "status", btDinas: "dinas", btDik: "dik",
            btSakit: "sakit", btBko: "bko", btCuti: "cuti",
            btLd: "ld", btIzin: "izin"
        ]
        
        for (btn, value) in absenButtons {
            btn.addAction(UIAction(handler: { _ in
                self.cekabsen(dari: value) // Panggil fungsi di Hendry.swift
            }), for: .touchUpInside)
        }
        
        btLog.addAction(UIAction(handler: { _ in
           // let historyVC = History() // Ganti ke class History kamu
            //self.navigationController?.pushViewController(historyVC, animated: true)
        }), for: .touchUpInside)
    }
    
    @objc private func hadirTapped() {
        self.go() // Panggil fungsi di Hendry.swift
    }
    
    func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
// ======================================================
// MARK: - BERITA PAGER
// ======================================================

extension Home {

    func applyBeritaItems(_ items: [BeritaItem]) {
        print("📰 [HENDRY] applyBeritaItems called with \(items.count) items")
        
        beritaItems = items
        currentIndex = 0

        guard !items.isEmpty else {
            print("⚠️ [HENDRY] No berita items to display")
            return
        }

        let firstVC = BannerPageVC(item: items[0])

        pageController.dataSource = pageHelper
        pageController.delegate = pageHelper

        pageController.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        )

        // Sync currentIndex with the actually displayed VC
        if let shown = pageController.viewControllers?.first as? BannerPageVC,
           let idx = beritaItems.firstIndex(where: { $0.id == shown.item.id }) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }

        onBeritaChanged(items[0])
        startBeritaAutoSlide()
    }

    func onBeritaChanged(_ berita: BeritaItem) {
        print("📰 [Home] onBeritaChanged: \(berita.judul)")
        
        // Update tvJudul & tvIsi di Home.swift
        tvJudul.text = berita.judul
        
        // Render HTML dari TinyMCE ke NSAttributedString
        if let data = berita.isi.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                // Ubah warna text jadi light gray sesuai design
                let mutableAttr = NSMutableAttributedString(attributedString: attributed)
                mutableAttr.addAttribute(.foregroundColor, 
                                        value: UIColor.lightGray, 
                                        range: NSRange(location: 0, length: mutableAttr.length))
                tvIsi.attributedText = mutableAttr
            } else {
                // Fallback: tampilkan plain text
                tvIsi.text = berita.isi
            }
        } else {
            tvIsi.text = berita.isi
        }
    }
    
    // Auto slide support
    func startBeritaAutoSlide(interval: TimeInterval = 4.0) {
        stopBeritaAutoSlide()
        print("🔄 [HENDRY] Starting auto-slide with interval: \(interval)s")
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.beritaItems.count > 1 else { return }
            
            let nextIndex = (self.currentIndex + 1) % self.beritaItems.count
            let vc = BannerPageVC(item: self.beritaItems[nextIndex])
            
            self.pageController.setViewControllers([vc], direction: .forward, animated: true) { finished in
                if finished {
                    self.currentIndex = nextIndex
                    self.onBeritaChanged(self.beritaItems[self.currentIndex])
                }
            }
        }
        beritaAutoSlideTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stopBeritaAutoSlide() {
        beritaAutoSlideTimer?.invalidate()
        beritaAutoSlideTimer = nil
    }
}


// ======================================================
// MARK: - PAGE VIEW CONTROLLER (SWIPE SUPPORT)
// ======================================================

private final class HomePageDataSourceDelegate: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    weak var owner: Home?

    init(owner: Home) {
        self.owner = owner
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let prev = currentIdx - 1
        let targetIdx = (prev >= 0) ? prev : (owner.beritaItems.isEmpty ? nil : owner.beritaItems.count - 1)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let next = currentIdx + 1
        let targetIdx = (next < owner.beritaItems.count) ? next : (owner.beritaItems.isEmpty ? nil : 0)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let owner = owner, let currentVC = pageViewController.viewControllers?.first as? BannerPageVC else { return }
        if let idx = owner.beritaItems.firstIndex(where: { $0.id == currentVC.item.id }) {
            owner.currentIndex = idx
            owner.onBeritaChanged(owner.beritaItems[idx])
        }
    }
}

extension Home {
    // Keep a single instance to avoid redeclarations elsewhere
    private static var _pageHelperKey: UInt8 = 0

    fileprivate var pageHelper: HomePageDataSourceDelegate {
        if let existing = objc_getAssociatedObject(self, &Home._pageHelperKey) as? HomePageDataSourceDelegate {
            return existing
        }
        let helper = HomePageDataSourceDelegate(owner: self)
        objc_setAssociatedObject(self, &Home._pageHelperKey, helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return helper
    }
}

extension Home {
    private static var _beritaTimerKey: UInt8 = 0

    fileprivate var beritaAutoSlideTimer: Timer? {
        get { objc_getAssociatedObject(self, &Home._beritaTimerKey) as? Timer }
        set { objc_setAssociatedObject(self, &Home._beritaTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


