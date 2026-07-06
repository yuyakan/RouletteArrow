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
                action: { isEditing.toggle() },
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

            LadderView(
                laneCount: viewModel.laneCount,
                rungs: viewModel.rungs,
                tracedLanes: viewModel.tracedLanes
            )

            // 下段：結果。たどり着いた lane を強調する。
            laneLabels(labels: viewModel.results, isTop: false)
        }
    }

    /// 上段/下段のラベル行。上段はタップ可能なボタンにする。
    private func laneLabels(labels: [String], isTop: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<viewModel.laneCount, id: \.self) { i in
                let label = i < labels.count ? labels[i] : ""
                let isHighlighted = isTop
                    ? (viewModel.tracedStartLane == i)
                    : (viewModel.tracedLanes?.last == i)
                Group {
                    if isTop {
                        Button(action: { viewModel.trace(from: i) }) {
                            laneChip(label, highlighted: isHighlighted)
                        }
                        .disabled(viewModel.isTracing)
                    } else {
                        laneChip(label, highlighted: isHighlighted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func laneChip(_ label: String, highlighted: Bool) -> some View {
        Text(label.isEmpty ? " " : label)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(highlighted ? .white : BrandTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 6)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(highlighted ? BrandTheme.mint : Color.black.opacity(0.05))
            )
            .padding(.horizontal, 2)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            // 引き直し（横棒をランダムに再生成）
            Button(action: { viewModel.regenerate() }) {
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

            // 経路のクリア
            Button(action: { viewModel.clearTrace() }) {
                Text(LocalizedStringKey("AmidaClear"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            viewModel.tracedLanes == nil
                                ? BrandTheme.mint.opacity(0.4)
                                : BrandTheme.mint
                        )
                    )
            }
            .disabled(viewModel.tracedLanes == nil || viewModel.isTracing)
        }
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
    /// たどった経路（各 row 通過後の lane 位置）。nil のとき経路は描かない。
    let tracedLanes: [Int]?

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
                // 縦線
                ForEach(0..<lanes, id: \.self) { lane in
                    Path { p in
                        p.move(to: CGPoint(x: xForLane(lane), y: top))
                        p.addLine(to: CGPoint(x: xForLane(lane), y: bottom))
                    }
                    .stroke(Color.black.opacity(0.18), lineWidth: 3)
                }

                // 横棒
                ForEach(0..<rowCount, id: \.self) { row in
                    ForEach(rungs[row], id: \.self) { lane in
                        Path { p in
                            let y = yForRow(row)
                            p.move(to: CGPoint(x: xForLane(lane), y: y))
                            p.addLine(to: CGPoint(x: xForLane(lane + 1), y: y))
                        }
                        .stroke(Color.black.opacity(0.18), lineWidth: 3)
                    }
                }

                // たどった経路（縦の下降＋横棒の横移動を折れ線で描く）
                if let path = tracedLanes, path.count == rowCount + 1 {
                    tracePath(path: path, xForLane: xForLane, yForRow: yForRow, top: top, bottom: bottom)
                        .stroke(BrandTheme.mint, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
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
