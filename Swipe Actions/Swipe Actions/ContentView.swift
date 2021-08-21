//
//  ContentView.swift
//  Swipe Actions
//
//  Created by Aleksey Fedorov on 19.08.2021.
//

import SwiftUI
import AVKit

let buttonWidth: CGFloat = 70

enum CellButtons: Identifiable {
    case flag
    case delete
    case save
    case info
    
    var id: String {
        return "\(self)"
    }
}

struct CellButtonView: View {
    let data: CellButtons
    let cellHeight: CGFloat
    
    func getView(for image: String, title: String) -> some View {
        VStack {
            Image(systemName: image)
            Text(title)
        }.padding(5)
        .foregroundColor(.primary)
        .font(.subheadline)
        .frame(width: buttonWidth, height: cellHeight)
    }
    
    var body: some View {
        switch data {
        case .flag:
            getView(for: "flag.fill", title: "Флажок")
            .background(Color.yellow)
        case .delete:
            getView(for: "delete.right", title: "Удалить")
            .background(Color.red)
        case .save:
            getView(for: "square.and.arrow.down", title: "Сохранить")
            .background(Color.blue)
        case .info:
            getView(for: "info.circle", title: "Еще")
            .background(Color.green)
        }
    }
}
class SoundManager {
    static let instance = SoundManager()
    
    var player: AVAudioPlayer?
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "tada", withExtension: ".mp3") else { return }
        do {
        player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch let error {
            print("Error playing sound. \(error.localizedDescription)")
        }
    }
}
struct HelloWorld: View {
      
        var body: some View {
         
          GeometryReader { _ in
          
          ZStack {
            
            Color.black
            .edgesIgnoringSafeArea(.all)
            
            Circle()
            .frame(width: 200, height: 200)
            .foregroundColor(Color.white)
            
            Circle()
            .frame(width: 180, height: 180)
            .foregroundColor(Color.green)
            
            Button(action: {
              
                SoundManager.instance.playSound()
              
              print("Button Tapped!")
              
              
              
            }) {
            Text("Hello world")
              .font(.largeTitle)
              .foregroundColor(Color.white)
              .bold()
              .italic()
          }
            }
                
            
            
          }.navigationBarTitle(Text("Personal Alarm"))
          }
         
          }

struct ContentView: View {
    var body: some View {
        VStack {
        NavigationView {
            NavigationLink(destination: SwipeView()) {
                Text("Tap to Swipe")
            }.navigationBarTitle("menu")
                
            }
        NavigationView {
            NavigationLink(destination: HelloWorld()) {
                Text("Sound")
            }.navigationBarTitle("menu")
        }
        }
    }
    }

struct SwipeView: View {
    var body: some View {
        NavigationView {
        ScrollView {
            LazyVStack.init(spacing: 0, pinnedViews: [.sectionHeaders], content: {
                
                Section.init(header:
                                HStack {
                                    Text("Test menu")
                                    Spacer()
                                }.padding()
                                .background(Color.green))
                {
                    ForEach(1...5, id: \.self) { count in
                        ContentCell(data: "swipe \(count)")
                            .addButtonActions(leadingButtons: [.save],
                                              trailingButton:  [.info, .flag, .delete], onClick: { button in
                                                print("clicked: \(button)")
                                              })
                    }
                }
            })
        }.navigationTitle("Swipe actions")
        }
    }
}

struct ContentCell: View {
    let data: String
    var body: some View {
        VStack {
            HStack {
                Text(data)
                Spacer()
            }.padding()
            Divider()
                .padding(.leading)
        }
    }
}


extension View {
    func addButtonActions(leadingButtons: [CellButtons], trailingButton: [CellButtons], onClick: @escaping (CellButtons) -> Void) -> some View {
        self.modifier(SwipeContainerCell(leadingButtons: leadingButtons, trailingButton: trailingButton, onClick: onClick))
    }
}


struct SwipeContainerCell: ViewModifier  {
    enum VisibleButton {
        case none
        case left
        case right
    }
    @State private var offset: CGFloat = 0
    @State private var oldOffset: CGFloat = 0
    @State private var visibleButton: VisibleButton = .none
    let leadingButtons: [CellButtons]
    let trailingButton: [CellButtons]
    let maxLeadingOffset: CGFloat
    let minTrailingOffset: CGFloat
    let onClick: (CellButtons) -> Void
    
    init(leadingButtons: [CellButtons], trailingButton: [CellButtons], onClick: @escaping (CellButtons) -> Void) {
        self.leadingButtons = leadingButtons
        self.trailingButton = trailingButton
        maxLeadingOffset = CGFloat(leadingButtons.count) * buttonWidth
        minTrailingOffset = CGFloat(trailingButton.count) * buttonWidth * -1
        self.onClick = onClick
    }
    
    func reset() {
        visibleButton = .none
        offset = 0
        oldOffset = 0
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .contentShape(Rectangle()) ///otherwise swipe won't work in vacant area
        .offset(x: offset)
        .gesture(DragGesture(minimumDistance: 15, coordinateSpace: .local)
        .onChanged({ (value) in
            let totalSlide = value.translation.width + oldOffset
            if  (0...Int(maxLeadingOffset) ~= Int(totalSlide)) || (Int(minTrailingOffset)...0 ~= Int(totalSlide)) { //left to right slide
                withAnimation{
                    offset = totalSlide
                }
            }
            ///can update this logic to set single button action with filled single button background if scrolled more then buttons width
        })
        .onEnded({ value in
            withAnimation {
              if visibleButton == .left && value.translation.width < -20 { ///user dismisses left buttons
                reset()
             } else if  visibleButton == .right && value.translation.width > 20 { ///user dismisses right buttons
                reset()
             } else if offset > 25 || offset < -25 { ///scroller more then 50% show button
                if offset > 0 {
                    visibleButton = .left
                    offset = maxLeadingOffset
                } else {
                    visibleButton = .right
                    offset = minTrailingOffset
                }
                oldOffset = offset
                ///Bonus Handling -> set action if user swipe more then x px
            } else {
                reset()
            }
         }
        }))
            GeometryReader { proxy in
                HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(leadingButtons) { buttonsData in
                        Button(action: {
                            withAnimation {
                                reset()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { ///call once hide animation done
                                onClick(buttonsData)
                            }
                        }, label: {
                            CellButtonView.init(data: buttonsData, cellHeight: proxy.size.height)
                        })
                    }
                }.offset(x: (-1 * maxLeadingOffset) + offset)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(trailingButton) { buttonsData in
                        Button(action: {
                            withAnimation {
                                reset()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { ///call once hide animation done
                                onClick(buttonsData)
                            }
                        }, label: {
                            CellButtonView.init(data: buttonsData, cellHeight: proxy.size.height)
                        })
                    }
                }.offset(x: (-1 * minTrailingOffset) + offset)
            }
        }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
