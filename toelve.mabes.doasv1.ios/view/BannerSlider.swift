//
//  BannerSlider.swift
//  Doas
//
//  Created by Admin on 05/03/26.
//

import UIKit

final class BannerSlider: NSObject {

    private let pageController: UIPageViewController
    private weak var parent: UIViewController?

    private var items: [BeritaItem] = []
    private var timer: Timer?

    init(parent: UIViewController, container: UIView) {

        self.parent = parent

        pageController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )

        super.init()

        parent.addChild(pageController)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pageController.view)

        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: container.topAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        pageController.didMove(toParent: parent)

        pageController.dataSource = self
        pageController.delegate = self
    }

    func setItems(_ items: [BeritaItem]) {

        self.items = items

        guard let first = items.first else { return }

        let vc = BannerPageVC(item: first)

        pageController.setViewControllers(
            [vc],
            direction: .forward,
            animated: false
        )

        startAutoSlide()
    }

    private func startAutoSlide() {

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in

            guard
                let current = self.pageController.viewControllers?.first as? BannerPageVC,
                let index = self.items.firstIndex(where: { $0.id == current.item.id })
            else { return }

            let nextIndex = (index + 1) % self.items.count

            let vc = BannerPageVC(item: self.items[nextIndex])

            self.pageController.setViewControllers(
                [vc],
                direction: .forward,
                animated: true
            )
        }
    }
}

extension BannerSlider: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {

        guard
            let vc = viewController as? BannerPageVC,
            let index = items.firstIndex(where: { $0.id == vc.item.id }),
            index > 0
        else { return nil }

        return BannerPageVC(item: items[index - 1])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {

        guard
            let vc = viewController as? BannerPageVC,
            let index = items.firstIndex(where: { $0.id == vc.item.id }),
            index < items.count - 1
        else { return nil }

        return BannerPageVC(item: items[index + 1])
    }
}
