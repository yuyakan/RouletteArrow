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
        let bouns = UIScreen.main.bounds
        let width = bouns.width
        let heigth = bouns.height
        VStack{
            HStack{
                Button(
                    action: {
                        rouletteViewModel.setting()
                    },
                    label: {
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(rouletteViewModel.isVisibleSettingValue ? .blue : .black)
                    }
                )
                .padding(.top)
                .padding()
                Spacer()
            }
            
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
                    .rotationEffect(self.angle)
                    .gesture(rotation)
                    .opacity(rouletteViewModel.isVisibleSeparation ? 0.2:0)
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
                .opacity(rouletteViewModel.isVisibleStartButton ? 0:1)
            }
            
            Spacer()
            
            if rouletteViewModel.isVisibleSettingValue {
                HStack{
                    Text(LocalizedStringKey("Separation")).font(.title2)
                        .padding([.horizontal, .top])
                        .padding(.leading)
                    Spacer()
                    Toggle(isOn: $rouletteViewModel.isVisibleSeparation) {
                    }.labelsHidden()
                        .padding([.horizontal, .top])
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
                }
                .padding()
                .padding(.bottom)
                Spacer()
            }
            else {
                Text(" ").font(.title).opacity(0).frame(height: 60)
            }
            
            BannerView().frame(height: 60)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RouletteView()
    }
}
