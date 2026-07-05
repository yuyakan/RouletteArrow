//
//  LotteryView.swift
//  RouletteArrow
//
//  ルーレット型の抽選タブ。
//  項目を色分けした円グラフに並べ、回して当選/順位を決める。
//

import SwiftUI

struct LotteryView: View {
    @StateObject private var viewModel = LotteryViewModel()
    @State private var isEditingItems = false

    var body: some View {
        ZStack {
            BrandTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 8)

                // 設定パネル表示中は盤面を小さくしてパネル領域を広げる
                wheelStage
                    .frame(maxHeight: isEditingItems ? 220 : .infinity)

                Spacer(minLength: 8)

                // 設定パネル表示中はスタートボタンを隠し、パネルの領域を広げる
                if isEditingItems {
                    settingsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    spinButton
                        .padding(.bottom, 8)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isEditingItems)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Button(
                action: { isEditingItems.toggle() },
                label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isEditingItems ? BrandTheme.mint : BrandTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                                .overlay(
                                    Circle().stroke(
                                        isEditingItems ? BrandTheme.mint.opacity(0.6) : Color.black.opacity(0.08),
                                        lineWidth: 1
                                    )
                                )
                        )
                }
            )
            .padding(.trailing)
            .padding(.top, 8)
        }
    }

    // MARK: - Wheel

    private var wheelStage: some View {
        ZStack {
            WheelView(items: viewModel.validItems, results: viewModel.segmentResults)
                .rotationEffect(Angle(degrees: Double(viewModel.rotationDegree)))
                .animation(.easeOut(duration: 12), value: viewModel.rotationDegree)
                .padding(.horizontal, 24)

            // 固定ポインタ。通常/順番決めは真上の1本、複数当選は当選数ぶんを円周に等間隔で配置。
            pointers
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 円周上に配置する固定ポインタ群。
    /// 通常は1本、複数当選/順番決めは指定人数ぶんを等間隔で配置。順番決めは各ポインタに順位番号を振る。
    private var pointers: some View {
        // 判定(SegmentResolver.arrowSegmentIndices)と見た目を一致させるため、
        // 上(12時)を基準に、時計回りへ 360/本数 ずつ配置する。
        let count = (viewModel.mode == .single)
            ? 1
            : min(max(2, viewModel.winnerCount), max(2, viewModel.validItems.count))
        let numbered = (viewModel.mode == .ranking)
        return GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            // 三角の先端が円の縁に接するよう、中心からわずかに内側へ寄せる
            let radius = side / 2 - 6
            ForEach(0..<count, id: \.self) { i in
                let angle = 360.0 / Double(count) * Double(i)   // 12時からの時計回り角度
                let rad = (angle - 90) * .pi / 180              // 画面座標(0度=右)へ変換
                ZStack {
                    Pointer()
                        .fill(BrandTheme.mint)
                        .frame(width: 28, height: 22)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)
                        // 三角の先端(下向き)が円の中心を向くように回転
                        .rotationEffect(Angle(degrees: angle))

                    // 順番決めのときは順位番号を三角の外側に添える（常に正立）
                    if numbered {
                        Text("\(i + 1)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(BrandTheme.textPrimary.opacity(0.85)))
                            // ポインタの外側（円の中心と反対方向）へずらす
                            .offset(
                                x: CGFloat(cos(rad)) * 26,
                                y: CGFloat(sin(rad)) * 26
                            )
                    }
                }
                .position(
                    x: geo.size.width / 2 + CGFloat(cos(rad)) * radius,
                    y: geo.size.height / 2 + CGFloat(sin(rad)) * radius
                )
            }
        }
        .padding(.horizontal, 24)
    }

    private var spinButton: some View {
        Button(
            action: { viewModel.spin() },
            label: {
                Text(LocalizedStringKey("Start"))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(viewModel.canSpin ? BrandTheme.mint : BrandTheme.mint.opacity(0.4))
                    )
            }
        )
        .disabled(!viewModel.canSpin)
    }

    // MARK: - Settings panel（矢印タブと同じ下部パネル）

    private var settingsPanel: some View {
        VStack(spacing: 16) {
            // 項目リスト（可変長。多いときはパネル内をスクロール）
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStringKey("Items"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.items.indices), id: \.self) { i in
                            HStack {
                                TextField(LocalizedStringKey("ItemPlaceholder"), text: $viewModel.items[i])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: { viewModel.removeItem(at: IndexSet(integer: i)) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(Color.red.opacity(0.7))
                                }
                            }
                        }

                        Button(action: { viewModel.addItem() }) {
                            Label(LocalizedStringKey("AddItem"), systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(BrandTheme.mint)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }

            Divider().overlay(Color.black.opacity(0.08))

            // モード選択
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("Mode"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary)

                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(LotteryMode.allCases) { m in
                        Text(LocalizedStringKey(m.titleKey)).tag(m)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // 複数当選=当選数、順番決め=順位を付ける人数。どちらもポインタ本数。
                if viewModel.mode != .single {
                    let labelKey = viewModel.mode == .ranking ? "RankCount" : "WinnerCount"
                    Stepper(value: $viewModel.winnerCount, in: 2...max(2, viewModel.maxWinnerCount)) {
                        Text("\(NSLocalizedString(labelKey, comment: "")): \(viewModel.winnerCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(BrandTheme.textPrimary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.03))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Wheel drawing

/// 項目数に応じて色分けした扇形を描き、各扇にラベル文字を配置する円グラフ。
private struct WheelView: View {
    let items: [String]
    /// セグメントindex -> 抽選結果。空なら未抽選（強調なし）。
    let results: [Int: SegmentOutcome]

    /// ブランドカラーを基調にしたセグメント色パレット
    private static let palette: [Color] = [
        BrandTheme.mint,
        Color(red: 0x2E / 255, green: 0x9E / 255, blue: 0xC4 / 255),
        Color(red: 0xF2 / 255, green: 0xB6 / 255, blue: 0x3C / 255),
        Color(red: 0xE8 / 255, green: 0x6A / 255, blue: 0x6A / 255),
        Color(red: 0x9B / 255, green: 0x7E / 255, blue: 0xDE / 255),
        Color(red: 0x5E / 255, green: 0xC5 / 255, blue: 0x8B / 255)
    ]

    /// 当選ハイライトのあるモードか（通常/複数当選）。順位バッジのみのモードでは減光しない。
    private var hasWinnerHighlight: Bool {
        results.values.contains { $0.isWinner }
    }

    var body: some View {
        GeometryReader { geo in
            let count = max(items.count, 1)
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let step = 360.0 / Double(count)

            ZStack {
                // 扇形本体。当選ハイライトのあるモードでは、当選以外を減光する。
                ForEach(0..<count, id: \.self) { i in
                    let dimmed = hasWinnerHighlight && !(results[i]?.isWinner ?? false)
                    Wedge(startDegree: step * Double(i), endDegree: step * Double(i + 1))
                        .fill(Self.palette[i % Self.palette.count])
                        .opacity(dimmed ? 0.25 : 1)
                }

                // ラベル
                ForEach(0..<items.count, id: \.self) { i in
                    let mid = step * (Double(i) + 0.5)
                    let rad = mid * .pi / 180
                    let labelRadius = radius * 0.62
                    Text(items[i])
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: radius * 0.8)
                        .rotationEffect(Angle(degrees: mid))
                        .position(
                            x: center.x + CGFloat(cos(rad)) * labelRadius,
                            y: center.y + CGFloat(sin(rad)) * labelRadius
                        )
                }

                // 外周リングと中心
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: size, height: size)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.10, height: size * 0.10)
                    .shadow(color: Color.black.opacity(0.15), radius: 2)
            }
        }
    }
}

/// 0度(右)基準・時計回りの扇形。SwiftUIのY軸は下向きなので addArc の角度はそのまま時計回りになる。
private struct Wedge: Shape {
    let startDegree: Double
    let endDegree: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: center)
        p.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startDegree),
            endAngle: Angle(degrees: endDegree),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

/// 下向きの三角ポインタ
private struct Pointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct LotteryView_Previews: PreviewProvider {
    static var previews: some View {
        LotteryView()
    }
}
