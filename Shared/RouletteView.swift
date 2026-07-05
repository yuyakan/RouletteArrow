//
//  ContentView.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI

struct RouletteView: View {
    @ObservedObject var rouletteViewModel = RouletteViewModel()
    @State var angle = Angle(degrees: 0.0)

    var rotation: some Gesture {
        RotationGesture()
            .onChanged { angle in
                self.angle = angle
            }
    }

    var body: some View {
        ZStack {
            BrandTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer()

                rouletteStage

                Spacer()

                if rouletteViewModel.isVisibleSettingValue {
                    settingsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Color.clear.frame(height: 60)
                }

                BannerAdView().frame(height: 60)
            }
            .animation(.easeInOut(duration: 0.25), value: rouletteViewModel.isVisibleSettingValue)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(
                action: { rouletteViewModel.setting() },
                label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(rouletteViewModel.isVisibleSettingValue ? BrandTheme.mint : BrandTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                                .overlay(
                                    Circle().stroke(
                                        rouletteViewModel.isVisibleSettingValue ? BrandTheme.mint.opacity(0.6) : Color.black.opacity(0.08),
                                        lineWidth: 1
                                    )
                                )
                        )
                }
            )
            .padding(.leading)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Roulette

    private var rouletteStage: some View {
        ZStack {
            // 矢印本体（回転する）。複数当選/順番決めでは複数本を等間隔配置する。
            arrows

            // 区切り線（黒線画像。白背景でそのまま見えるので薄く重ねる）
            Image("\(rouletteViewModel.peoples)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(self.angle)
                .gesture(rotation)
                .opacity(rouletteViewModel.isVisibleSeparation ? 0.25 : 0)

            // Startボタン
            startButton
                .opacity(rouletteViewModel.isVisibleSettingValue ? 0 : 1)
                .opacity(rouletteViewModel.isVisibleStartButton ? 0 : 1)
        }
        .padding(.horizontal, 24)
    }

    /// 矢印群。single のときは1本、multiple/ranking のときは effectiveArrowCount 本を
    /// 360/本数 ずつオフセットして同じ回転量で一緒に回す。ranking では先端に順位番号を添える。
    private var arrows: some View {
        let count = rouletteViewModel.effectiveArrowCount
        let baseDegree = Double(rouletteViewModel.rouletteDegree)
        let spread = 360.0 / Double(count)
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let degree = baseDegree + spread * Double(i)
                ZStack {
                    Image("arrow2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    // 順番決めのときだけ順位番号を表示する。
                    // arrow2 は穂先が画像の下端側にあるため、番号は下方向(穂先の外側)へ置く。
                    // テキストは矢印の回転を打ち消して常に正立させ、どの向きでも読めるようにする。
                    if rouletteViewModel.mode == .ranking {
                        GeometryReader { geo in
                            let side = min(geo.size.width, geo.size.height)
                            Text("\(rouletteViewModel.rank(for: i))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(BrandTheme.mint)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                )
                                .rotationEffect(Angle(degrees: -degree))
                                .position(x: geo.size.width / 2, y: geo.size.height / 2 + side * 0.38)
                        }
                    }
                }
                .rotationEffect(Angle(degrees: degree))
            }
        }
        .animation(.easeOut(duration: 12), value: rouletteViewModel.rouletteDegree)
    }

    private var startButton: some View {
        Button(
            action: { rouletteViewModel.start() },
            label: {
                Text(LocalizedStringKey("Start"))
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(BrandTheme.mint)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
            }
        )
    }

    // MARK: - Settings

    private var settingsPanel: some View {
        VStack(spacing: 20) {
            HStack {
                Text(LocalizedStringKey("Separation"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary)
                Spacer()
                Toggle(isOn: $rouletteViewModel.isVisibleSeparation) {}
                    .labelsHidden()
                    .tint(BrandTheme.mint)
            }

            Divider().overlay(Color.black.opacity(0.08))

            HStack {
                Text(LocalizedStringKey("Peoples"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary)
                Spacer()
                Picker("Number of people", selection: $rouletteViewModel.peoples) {
                    ForEach(2...8, id: \.self) { n in
                        Text("\(n)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(BrandTheme.textPrimary)
                            .tag(n)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 120, height: 90)
                .clipped()
            }

            Divider().overlay(Color.black.opacity(0.08))

            // モード選択（通常 / 複数当選 / 順番決め）
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("Mode"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary)

                Picker("Mode", selection: $rouletteViewModel.mode) {
                    ForEach(ArrowMode.allCases) { m in
                        Text(LocalizedStringKey(m.titleKey)).tag(m)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // 複数当選 / 順番決めのときだけ矢印の本数を選ばせる
            if rouletteViewModel.mode != .single {
                HStack {
                    Text(LocalizedStringKey(rouletteViewModel.mode == .ranking ? "RankCount" : "WinnerCount"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(BrandTheme.textPrimary)
                    Spacer()
                    Picker("Arrow count", selection: $rouletteViewModel.arrowCount) {
                        ForEach(2...rouletteViewModel.maxArrowCount, id: \.self) { n in
                            Text("\(n)")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundColor(BrandTheme.textPrimary)
                                .tag(n)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 120, height: 90)
                    .clipped()
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RouletteView()
    }
}
