//
//  BannerAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/07.
//

import GoogleMobileAds
import SwiftUI

struct BannerAdView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = BannerAdViewController()
        return viewController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

class BannerAdViewController: UIViewController, BannerViewDelegate {
    var bannerView: BannerView!
    let adUnitID = "ca-app-pub-3940256099942544/2934735716"//テスト
    private var retryCount = 0
    private let maxRetryCount = 5

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBanner()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.loadBanner()
        }
    }

    private func loadBanner() {
        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        bannerView.delegate = self
        bannerView.rootViewController = self

        let bannerWidth = view.frame.size.width
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: bannerWidth)

        let request = Request()
        request.scene = view.window?.windowScene
        bannerView.load(request)

        setAdView(bannerView)
    }

    func setAdView(_ view: BannerView) {
        bannerView = view
        self.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        let viewDictionary = ["_bannerView": bannerView!]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
    }

    // 読み込み成功通知
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        retryCount = 0
    }

    // 読み込み失敗通知：指数バックオフによるリトライ（最大 maxRetryCount 回）
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("バナー広告の読み込みに失敗しました: \(error.localizedDescription)")
        guard retryCount < maxRetryCount else {
            print("バナー広告の読み込みを \(maxRetryCount) 回試みましたが失敗しました")
            return
        }
        retryCount += 1
        let delay = pow(2.0, Double(retryCount - 1))
        print("バナー広告を \(delay) 秒後に再読み込みします（\(retryCount)/\(maxRetryCount)）")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let request = Request()
            request.scene = self.view.window?.windowScene
            self.bannerView.load(request)
        }
    }
}
