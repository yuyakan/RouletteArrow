//
//  ContentView.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI

struct ContentView: View {
    @State var showIntersitialAd: Bool = false
    @State private var degree: Int = 0
    @State var randomSelect: Int = 0
    @State var setting: Bool = false
    @State var start: Bool = false
    @State var separation: Bool = false
    @State var peoples: Int = 4
    @State var text: String = "Roullet arrow"
    @State var fixedNumber: Int = 0
    @State var previousPeoples: Int = 4
    var body: some View {
        let bouns = UIScreen.main.bounds
        let width = bouns.width
        let heigth = bouns.height
        VStack{
            Text(" ").font(.largeTitle).opacity(0)
            Spacer()    
            ZStack{
                Image("\(peoples)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(separation ? 0.2:0)
                Image("arrow2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(Angle(degrees: Double(degree)))
                    .animation(Animation.easeOut(duration: 8), value: degree)
                Text(text).font(.title2).frame(width: width * 0.5)
            }
            Spacer()
            
            HStack{
                Toggle(isOn: $setting) {
                }.labelsHidden()
                    .padding()
                Spacer()
                Button(action: {
                    start.toggle()
                    rotate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        start.toggle()
                        showIntersitialAd.toggle()
                    }
                },
                       label: {
                    Text("Start").font(.largeTitle)
                })
                    .opacity(setting ? 0:1)
                Spacer()
                Toggle(isOn: $setting) {
                }.labelsHidden()
                .padding()
                .hidden()
                .disabled(true)
            }
            .padding(.bottom)
            .opacity(start ? 0:1)
            
            if setting {
                HStack{
                    Text("Theme").font(.title2).padding()
                    TextField("Placeholder", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                HStack{
                    Text("Separation").font(.title2).padding()
                    Spacer()
                    Toggle(isOn: $separation) {
                    }.labelsHidden()
                    .padding()
                }.padding(.bottom)
                HStack{
                    Text("\(peoples) people")
                        .font(.title2)
                        .padding(.bottom)
                    Spacer()
                    Picker("Number of people", selection: $peoples) {
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
    func rotate() {
        self.randomSelect = Int.random(in: 1...peoples)
        self.degree += 2160 + Int((360 / peoples) * randomSelect) + Int((360 / previousPeoples) * fixedNumber)
        self.fixedNumber = peoples - randomSelect
        //これがないと人数を変えたときに矢印がずれる
        self.previousPeoples = peoples
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
