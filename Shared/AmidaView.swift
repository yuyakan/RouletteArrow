//
//  AmidaView.swift
//  RouletteArrow
//
//  あみだくじタブ。
//  上段の参加者をタップすると横棒をたどって下段の結果へ経路がハイライトされる。
//

import SwiftUI

struct AmidaView: View {
    @StateObject private var viewModel = AmidaViewModel()
    @State private var isEditing = false
    /// スタートが押されてあみだくじを表示したか。押すまでは縦線・横棒を隠す。
    @State private var hasStarted = false

    /// 上段レーンごとの経路色。lane index を色数で割った余りで割り当てる。
    private static let lanePalette: [Color] = [
        BrandTheme.mint,
        Color(red: 0x2E / 255, green: 0x9E / 255, blue: 0xC4 / 255),
        Color(red: 0xF2 / 255, green: 0xB6 / 255, blue: 0x3C / 255),
        Color(red: 0xE8 / 255, green: 0x6A / 255, blue: 0x6A / 255),
        Color(red: 0x9B / 255, green: 0x7E / 255, blue: 0xDE / 255),
        Color(red: 0x5E / 255, green: 0xC5 / 255, blue: 0x8B / 255),
        Color(red: 0xE9 / 255, green: 0x84 / 255, blue: 0xC2 / 255),
        Color(red: 0x4A / 255, green: 0x6C / 255, blue: 0xF0 / 255)
    ]

    /// 上段 lane に対応する経路色。
    private static func color(for lane: Int) -> Color {
        lanePalette[((lane % lanePalette.count) + lanePalette.count) % lanePalette.count]
    }

    /// 経路を表示対象に加えて、線を引くアニメーションを走らせる。
    private func startTrace(_ addPaths: () -> Bool) {
        guard !viewModel.isTracing else { return }
        // 広告表示回はスタート処理（経路追加・描画）を行わない（広告のみ表示）
        guard AdManager.shared.notifySpin() else { return }
        guard addPaths() else { return }
        // 実行された1回として累計する（レビュー依頼は設定を閉じたときに判定・表示）
        ReviewManager.shared.notifyExecutedSpin()
        // スタート時にあみだくじ（縦線・横棒）を表示する。
        if !hasStarted {
            withAnimation(.easeInOut(duration: 0.2)) { hasStarted = true }
        }
        // まず進捗を 0 に戻す（アニメーションなしで即反映）。
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { viewModel.beginDrawing() }
        // 次の描画サイクルで 0→1 へアニメーションさせ、線を引いていく。
        DispatchQueue.main.async {
            withAnimation(.linear(duration: AmidaViewModel.drawDuration)) {
                viewModel.drawProgress = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AmidaViewModel.drawDuration + 0.05) {
            viewModel.endDrawing()
        }
    }

    var body: some View {
        ZStack {
            BrandTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 8)

                // 設定パネル表示中はあみだ図を小さくしてパネル領域を広げる
                ladderStage
                    .frame(maxHeight: isEditing ? 240 : .infinity)
                    .padding(.horizontal, 24)

                Spacer(minLength: 8)

                if isEditing {
                    settingsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    controls
                        .padding(.bottom, 40)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isEditing)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Button(
                action: {
                    if !isEditing {
                        // 編集を開くときはスタート前の状態に戻す（項目変更で経路が無効になるため）
                        viewModel.clearTrace()
                        hasStarted = false
                    } else {
                        // 設定を閉じるとき：レビュー依頼（優先）または広告を表示
                        AdManager.shared.notifySettingsClosed()
                    }
                    isEditing.toggle()
                },
                label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isEditing ? BrandTheme.mint : BrandTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                                .overlay(
                                    Circle().stroke(
                                        isEditing ? BrandTheme.mint.opacity(0.6) : Color.black.opacity(0.08),
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

    // MARK: - Ladder

    private var ladderStage: some View {
        VStack(spacing: 8) {
            // 上段：参加者（タップで経路をたどる）
            laneLabels(labels: viewModel.participants, isTop: true)

            // スタートを押すまではあみだくじ本体（横棒）を隠し、縦線の上端・下端だけをちら見せする。
            ZStack {
                if hasStarted {
                    LadderView(
                        laneCount: viewModel.laneCount,
                        rungs: viewModel.rungs,
                        tracedPaths: viewModel.tracedPaths,
                        progress: viewModel.drawProgress,
                        color: { Self.color(for: $0) }
                    )
                    .transition(.opacity)
                } else {
                    // 縦線の上端・下端（株）だけをちら見せし、中央は不透明カバーで隠す。
                    LadderView(
                        laneCount: viewModel.laneCount,
                        rungs: viewModel.rungs,
                        tracedPaths: [:],
                        progress: 0,
                        color: { Self.color(for: $0) },
                        stubOnly: true
                    )
                    hiddenCover
                }
            }

            // 下段：結果。たどり着いた lane を強調する。
            laneLabels(labels: viewModel.results, isTop: false)
        }
    }

    /// スタート前に中央のあみだくじを覆う不透明カバー。
    /// 中身は透けず、中央の鍵アイコンで「隠れている」ことを示す。
    private var hiddenCover: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        // 透過なしのベタ塗り（ごく薄いグレー地の不透明カバー。色味は控えめに）
        let fill = Color.black.opacity(0.04)
        return ZStack {
            shape.fill(Color.white)
            shape.fill(fill)
            shape.stroke(Color.black.opacity(0.08), lineWidth: 1)

            // 中央の鍵アイコン
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BrandTheme.mint.opacity(0.55))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                )
        }
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        // 上下の株（縦線の見えている区間）を残すため内側に余白を取る
        .padding(.vertical, 26)
    }

    /// 上段/下段のラベル行。上段はタップ可能なボタンにする。
    private func laneLabels(labels: [String], isTop: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<viewModel.laneCount, id: \.self) { i in
                let label = i < labels.count ? labels[i] : ""
                // 色：上段は常に自レーンの色。下段は「そこに到達した経路の開始レーン」の色。
                let highlightColor: Color? = isTop
                    ? Self.color(for: i)
                    : startLaneColorReaching(resultLane: i)
                laneChip(label, highlightColor: highlightColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// 下段 resultLane に到達している経路があれば、その開始レーンの色を返す。
    /// ただし線がゴールまで引き終わる（アニメーション完了）までは色をつけない。
    private func startLaneColorReaching(resultLane: Int) -> Color? {
        // 描画アニメーション中は結果を伏せる
        guard !viewModel.isTracing, viewModel.drawProgress >= 1 else { return nil }
        for (startLane, path) in viewModel.tracedPaths where path.last == resultLane {
            return Self.color(for: startLane)
        }
        return nil
    }

    private func laneChip(_ label: String, highlightColor: Color?) -> some View {
        Text(label.isEmpty ? " " : label)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(highlightColor != nil ? .white : BrandTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 6)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(highlightColor ?? Color.black.opacity(0.05))
            )
            .padding(.horizontal, 2)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            // 引き直し（横棒をランダムに再生成）。スタート前の状態に戻す。
            Button(action: {
                viewModel.regenerate()
                withAnimation(.easeInOut(duration: 0.2)) { hasStarted = false }
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(BrandTheme.mint)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                            .overlay(Circle().stroke(BrandTheme.mint.opacity(0.4), lineWidth: 1))
                    )
            }
            .disabled(viewModel.isTracing)

            // スタート：全員ぶんの経路を一度に引く
            Button(action: { startTrace { viewModel.traceAll() } }) {
                Text(LocalizedStringKey("Start"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(canTraceAll ? BrandTheme.mint : BrandTheme.mint.opacity(0.4)))
            }
            .disabled(!canTraceAll || viewModel.isTracing)
        }
    }

    /// 未表示の参加者がまだいれば「全員」ボタンを有効にする。
    private var canTraceAll: Bool {
        viewModel.tracedPaths.count < viewModel.laneCount
    }

    // MARK: - Settings panel

    private var settingsPanel: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(LocalizedStringKey("AmidaParticipant"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BrandTheme.textPrimary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                    Text(LocalizedStringKey("AmidaResult"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BrandTheme.textPrimary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                    // 削除ボタンぶんの余白
                    Color.clear.frame(width: 28, height: 1)
                }
                .fixedSize(horizontal: false, vertical: true)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.participants.indices), id: \.self) { i in
                            HStack(spacing: 8) {
                                TextField(LocalizedStringKey("ItemPlaceholder"), text: $viewModel.participants[i])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                TextField(LocalizedStringKey("AmidaResultPlaceholder"), text: $viewModel.results[i])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                Button(action: { viewModel.removeLane(at: i) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(Color.red.opacity(0.7))
                                        .frame(width: 28)
                                }
                                .disabled(viewModel.laneCount <= AmidaViewModel.laneRange.lowerBound)
                            }
                        }

                        if viewModel.laneCount < AmidaViewModel.laneRange.upperBound {
                            Button(action: { viewModel.addLane() }) {
                                Label(LocalizedStringKey("AddItem"), systemImage: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(BrandTheme.mint)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }

            Divider().overlay(Color.black.opacity(0.08))

            // 複雑さ（横棒の量）の選択
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("AmidaComplexity"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BrandTheme.textPrimary.opacity(0.5))

                Picker("Complexity", selection: $viewModel.complexity) {
                    ForEach(AmidaComplexity.allCases) { c in
                        Text(LocalizedStringKey(c.titleKey)).tag(c)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
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

// MARK: - Ladder drawing

/// 縦線・横棒・たどった経路を描くあみだくじ図。
private struct LadderView: View {
    let laneCount: Int
    let rungs: [[Int]]
    /// 表示する経路群。開始レーン → 経路（各 row 通過後の lane 位置）。
    let tracedPaths: [Int: [Int]]
    /// 線を引くアニメーションの進捗（0→1）。
    let progress: CGFloat
    /// 開始レーンごとの色。
    let color: (Int) -> Color
    /// true のときは縦線の上端・下端の短い区間だけを描く（スタート前のちら見せ）。
    var stubOnly: Bool = false
    /// 縦線・横棒の色（すりガラス越しに見せたいときは濃いめの色を渡す）。
    var lineColor: Color = Color.black.opacity(0.18)

    /// ちら見せ時に見せる縦線の長さ（上端・下端それぞれ）。
    private let stubLength: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let lanes = max(laneCount, 2)
            let laneSpacing = geo.size.width / CGFloat(lanes)
            // 各縦線の x 座標（レーンの中央）
            let xForLane: (Int) -> CGFloat = { laneSpacing * (CGFloat($0) + 0.5) }
            let rowCount = rungs.count
            let top: CGFloat = 8
            let bottom = geo.size.height - 8
            let rowSpacing = rowCount > 0 ? (bottom - top) / CGFloat(rowCount) : 0
            // row 番号 → y 座標（横棒は各 row の中央に置く）
            let yForRow: (Int) -> CGFloat = { top + rowSpacing * (CGFloat($0) + 0.5) }

            ZStack {
                // 縦線。ちら見せ時は上端・下端の短い区間だけを描く。
                ForEach(0..<lanes, id: \.self) { lane in
                    Path { p in
                        let x = xForLane(lane)
                        if stubOnly {
                            p.move(to: CGPoint(x: x, y: top))
                            p.addLine(to: CGPoint(x: x, y: min(top + stubLength, bottom)))
                            p.move(to: CGPoint(x: x, y: max(bottom - stubLength, top)))
                            p.addLine(to: CGPoint(x: x, y: bottom))
                        } else {
                            p.move(to: CGPoint(x: x, y: top))
                            p.addLine(to: CGPoint(x: x, y: bottom))
                        }
                    }
                    .stroke(lineColor, lineWidth: 3)
                }

                // 横棒（ちら見せ時は描かない）
                if !stubOnly {
                    ForEach(0..<rowCount, id: \.self) { row in
                        ForEach(rungs[row], id: \.self) { lane in
                            Path { p in
                                let y = yForRow(row)
                                p.move(to: CGPoint(x: xForLane(lane), y: y))
                                p.addLine(to: CGPoint(x: xForLane(lane + 1), y: y))
                            }
                            .stroke(lineColor, lineWidth: 3)
                        }
                    }
                }

                // たどった経路（縦の下降＋横棒の横移動を折れ線で描く）。
                // 開始レーンごとに色分けし、trim で線が引かれていくアニメーションにする。
                ForEach(tracedPaths.keys.sorted(), id: \.self) { startLane in
                    if let path = tracedPaths[startLane], path.count == rowCount + 1 {
                        tracePath(path: path, xForLane: xForLane, yForRow: yForRow, top: top, bottom: bottom)
                            .trim(from: 0, to: progress)
                            .stroke(color(startLane), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                }
            }
        }
    }

    /// たどった経路を1本の折れ線 Path として組み立てる。
    private func tracePath(
        path: [Int],
        xForLane: (Int) -> CGFloat,
        yForRow: (Int) -> CGFloat,
        top: CGFloat,
        bottom: CGFloat
    ) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: xForLane(path[0]), y: top))
        for row in 0..<(path.count - 1) {
            let y = yForRow(row)
            let fromLane = path[row]
            let toLane = path[row + 1]
            // 横棒の高さまで縦に降りる
            p.addLine(to: CGPoint(x: xForLane(fromLane), y: y))
            if fromLane != toLane {
                // 横棒で隣のレーンへ移動
                p.addLine(to: CGPoint(x: xForLane(toLane), y: y))
            }
        }
        // 最後のレーンで下段まで降りる
        p.addLine(to: CGPoint(x: xForLane(path[path.count - 1]), y: bottom))
        return p
    }
}

struct AmidaView_Previews: PreviewProvider {
    static var previews: some View {
        AmidaView()
    }
}
