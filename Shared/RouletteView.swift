//
//  ContentView.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI

struct RouletteView: View {
    @ObservedObject var rouletteViewModel = RouletteViewModel()

    var body: some View {
        let bouns = UIScreen.main.bounds
        let width = bouns.width
        let heigth = bouns.height
        VStack{
            BannerView().frame(height: 60)
            Spacer()
            ZStack{
                Image("arrow2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(Angle(degrees: Double(rouletteViewModel.rouletteDegree)))
                    .animation(Animation.easeOut(duration: 12), value: rouletteViewModel.rouletteDegree)
                Image("\(rouletteViewModel.peoples)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(rouletteViewModel.isVisibleSeparation ? 0.2:0)
                Text(rouletteViewModel.rouletteTheme).font(.title2).frame(width: width * 0.5)
            }
            Spacer()
            HStack{
                Spacer()
                Button(action: {
                    rouletteViewModel.start()
                },
                       label: {
                    Text(LocalizedStringKey("Start")).font(.largeTitle)
                })
                .opacity(rouletteViewModel.isVisibleSettingValue ? 0:1)
                Spacer()
            }
            .padding(.bottom)
            .opacity(rouletteViewModel.isVisibleStartButton ? 0:1)
            Toggle(isOn: $rouletteViewModel.isVisibleSettingValue) {
            }.labelsHidden()
                .padding()
            if rouletteViewModel.isVisibleSettingValue {
                HStack{
                    Text("Theme").font(.title2).padding()
                        .padding(.leading)
                    TextField("Placeholder", text: $rouletteViewModel.rouletteTheme)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                HStack{
                    Text(LocalizedStringKey("Separation")).font(.title2).padding()
                        .padding(.leading)
                    Spacer()
                    Toggle(isOn: $rouletteViewModel.isVisibleSeparation) {
                    }.labelsHidden()
                    .padding()
                    .padding(.trailing)
                }
                HStack{
                    Text(LocalizedStringKey("Peoples"))
                        .font(.title2)
                        .padding(.bottom)
                        .padding(.leading)
                    Spacer()
                    Picker("Number of people", selection: $rouletteViewModel.peoples) {
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                        Text("5").tag(5)
                        Text("6").tag(6)
                        Text("7").tag(7)
                        Text("8").tag(8)
                    }.pickerStyle(WheelPickerStyle())
                    .frame(width: width * 0.4, height: heigth * 0.1)
                    .padding([.leading,.bottom])
                    Spacer()
                }.padding()
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RouletteView()
    }
}
