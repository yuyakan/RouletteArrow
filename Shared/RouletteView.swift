//
//  ContentView.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI

struct RouletteView: View {
    @ObservedObject var rouletteViewModel = RouletteViewModel()
    var interstitial = Interstitial()
    
    var body: some View {
        let bouns = UIScreen.main.bounds
        let width = bouns.width
        let heigth = bouns.height
        VStack{
            Text(" ").font(.largeTitle).opacity(0)
            Spacer()    
            ZStack{
                Image("\(rouletteViewModel.roulettePeoples)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(rouletteViewModel.isVisibleSeparation ? 0.2:0)
                Image("arrow2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(Angle(degrees: Double(rouletteViewModel.rouletteDegree)))
                    .animation(Animation.easeOut(duration: 8), value: rouletteViewModel.rouletteDegree)
                Text(rouletteViewModel.rouletteTheme).font(.title2).frame(width: width * 0.5)
            }
            Spacer()
            
            HStack{
                Toggle(isOn: $rouletteViewModel.isVisibleSettingValue) {
                }.labelsHidden()
                    .padding()
                Spacer()
                Button(action: {
                    rouletteViewModel.isVisibleStartButton.toggle()
                    rouletteViewModel.rouletteRotate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        rouletteViewModel.isVisibleStartButton.toggle()
                        interstitial.presentInterstitial()
                    }
                },
                       label: {
                    Text("Start").font(.largeTitle)
                })
                .opacity(rouletteViewModel.isVisibleSettingValue ? 0:1)
                Spacer()
                Toggle(isOn: $rouletteViewModel.isVisibleSettingValue) {
                }.labelsHidden()
                .padding()
                .hidden()
                .disabled(true)
            }
            .padding(.bottom)
            .opacity(rouletteViewModel.isVisibleStartButton ? 0:1)
            
            if rouletteViewModel.isVisibleSettingValue {
                HStack{
                    Text("Theme").font(.title2).padding()
                    TextField("Placeholder", text: $rouletteViewModel.rouletteTheme)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                HStack{
                    Text("Separation").font(.title2).padding()
                    Spacer()
                    Toggle(isOn: $rouletteViewModel.isVisibleSeparation) {
                    }.labelsHidden()
                    .padding()
                }.padding(.bottom)
                HStack{
                    Text("peoples")
                        .font(.title2)
                        .padding(.bottom)
                    Spacer()
                    Picker("Number of people", selection: $rouletteViewModel.roulettePeoples) {
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
        .onAppear() {
            interstitial.loadInterstitial()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RouletteView()
    }
}
