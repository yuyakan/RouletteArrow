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

                wheelStage

                Spacer(minLength: 8)

                resultsView

                spinButton
                    .padding(.bottom, 8)

                BannerAdView().frame(height: 60)
            }
        }
        .sheet(isPresented: $isEditingItems) {
            itemEditor
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Button(
                action: { isEditingItems = true },
                label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(BrandTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
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
            WheelView(items: viewModel.validItems)
                .rotationEffect(Angle(degrees: Double(viewModel.rotationDegree)))
                .animation(.easeOut(duration: 12), value: viewModel.rotationDegree)
                .padding(.horizontal, 24)

            // 上部固定ポインタ（真上から下向きの三角）
            VStack {
                Pointer()
                    .fill(BrandTheme.mint)
                    .frame(width: 28, height: 22)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)
                Spacer()
            }
            .padding(.top, 4)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsView: some View {
        if !viewModel.results.isEmpty {
            VStack(spacing: 6) {
                ForEach(viewModel.results) { r in
                    HStack(spacing: 8) {
                        if viewModel.mode == .ranking || viewModel.mode == .multiple {
                            Text("\(r.rank).")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(BrandTheme.mint)
                        }
                        Text(r.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(BrandTheme.textPrimary)
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .transition(.opacity)
        }
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

    // MARK: - Item editor

    private var itemEditor: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStringKey("Items"))) {
                    ForEach(Array(viewModel.items.indices), id: \.self) { i in
                        TextField(LocalizedStringKey("ItemPlaceholder"), text: $viewModel.items[i])
                    }
                    .onDelete { viewModel.removeItem(at: $0) }

                    Button(action: { viewModel.addItem() }) {
                        Label(LocalizedStringKey("AddItem"), systemImage: "plus.circle.fill")
                            .foregroundColor(BrandTheme.mint)
                    }
                }

                Section(header: Text(LocalizedStringKey("Mode"))) {
                    Picker(LocalizedStringKey("Mode"), selection: $viewModel.mode) {
                        ForEach(LotteryMode.allCases) { m in
                            Text(LocalizedStringKey(m.titleKey)).tag(m)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if viewModel.mode == .multiple {
                        Stepper(value: $viewModel.winnerCount, in: 2...max(2, viewModel.maxWinnerCount)) {
                            Text("\(NSLocalizedString("WinnerCount", comment: "")): \(viewModel.winnerCount)")
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("EditItems"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("OK")) { isEditingItems = false }
                }
            }
        }
    }
}

// MARK: - Wheel drawing

/// 項目数に応じて色分けした扇形を描き、各扇にラベル文字を配置する円グラフ。
private struct WheelView: View {
    let items: [String]

    /// ブランドカラーを基調にしたセグメント色パレット
    private static let palette: [Color] = [
        BrandTheme.mint,
        Color(red: 0x2E / 255, green: 0x9E / 255, blue: 0xC4 / 255),
        Color(red: 0xF2 / 255, green: 0xB6 / 255, blue: 0x3C / 255),
        Color(red: 0xE8 / 255, green: 0x6A / 255, blue: 0x6A / 255),
        Color(red: 0x9B / 255, green: 0x7E / 255, blue: 0xDE / 255),
        Color(red: 0x5E / 255, green: 0xC5 / 255, blue: 0x8B / 255)
    ]

    var body: some View {
        GeometryReader { geo in
            let count = max(items.count, 1)
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let step = 360.0 / Double(count)

            ZStack {
                // 扇形本体
                ForEach(0..<count, id: \.self) { i in
                    Wedge(startDegree: step * Double(i), endDegree: step * Double(i + 1))
                        .fill(Self.palette[i % Self.palette.count])
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
