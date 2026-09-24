//
//  KeyboardView.swift
//  MyTube
//

import SwiftUI

enum KeyboardMode {
    case letters
    case symbols1
    case symbols2
}

struct KBBtn: View {
    var label: String?
    var image: Image?
    var maxWidth: CGFloat?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Color(white: 0.15)
                if let text = label {
                    Text(text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else if let img = image {
                    img
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: maxWidth ?? .infinity, maxHeight: .infinity)
            .cornerRadius(6)
            .padding(2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct KeyboardView: View {
    var width: CGFloat = 720
    
    @State private var mode: KeyboardMode = .letters
    @State private var shifted: Bool = false
    
    func shift() {
        shifted.toggle()
    }
    
    func setKeyboardMode(_ mode: KeyboardMode) {
        self.mode = mode
    }
    
    func sendKey(key: String) {
        CarPlaySingleton.shared.sendInput(shifted ? key.uppercased() : key)
    }
    
    func backspace() {
        CarPlaySingleton.shared.backspaceInput()
    }
    
    func dismiss() {
        CarPlaySingleton.shared.toggleKeyboard()
    }
    
    func makeBtn(label: String? = nil, affectedByShift: Bool = true, image: Image? = nil, maxWidth: CGFloat? = nil, action: (() -> Void)? = nil) -> KBBtn {
        let text = affectedByShift && shifted ? label?.uppercased() : label
        return KBBtn(label: text, image: image, maxWidth: maxWidth, action: action ?? { sendKey(key: label ?? "") })
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if mode == .letters {
                    HStack(spacing: 0) {
                        makeBtn(label: "q"); makeBtn(label: "w"); makeBtn(label: "e"); makeBtn(label: "r"); makeBtn(label: "t")
                        makeBtn(label: "y"); makeBtn(label: "u"); makeBtn(label: "i"); makeBtn(label: "o"); makeBtn(label: "p")
                    }
                    HStack(spacing: 0) {
                        makeBtn(label: "a"); makeBtn(label: "s"); makeBtn(label: "d"); makeBtn(label: "f"); makeBtn(label: "g")
                        makeBtn(label: "h"); makeBtn(label: "j"); makeBtn(label: "k"); makeBtn(label: "l")
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: shifted ? Image(systemName: "shift.fill") : Image(systemName: "shift"), maxWidth: width / 8, action: { shift() })
                        makeBtn(label: "z"); makeBtn(label: "x"); makeBtn(label: "c"); makeBtn(label: "v"); makeBtn(label: "b"); makeBtn(label: "n"); makeBtn(label: "m")
                        makeBtn(image: Image(systemName: "delete.left"), maxWidth: width / 8, action: { backspace() })
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: Image(systemName: "textformat.123"), maxWidth: width / 8, action: { setKeyboardMode(.symbols1) })
                        makeBtn(label: "space", affectedByShift: false, action: { sendKey(key: " ") })
                        makeBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 8, action: { dismiss() })
                    }
                } else if mode == .symbols1 {
                    HStack(spacing: 0) {
                        makeBtn(label: "1"); makeBtn(label: "2"); makeBtn(label: "3"); makeBtn(label: "4"); makeBtn(label: "5")
                        makeBtn(label: "6"); makeBtn(label: "7"); makeBtn(label: "8"); makeBtn(label: "9"); makeBtn(label: "0")
                    }
                    HStack(spacing: 0) {
                        makeBtn(label: "-"); makeBtn(label: "/"); makeBtn(label: ":"); makeBtn(label: ";"); makeBtn(label: "(")
                        makeBtn(label: ")"); makeBtn(label: "$"); makeBtn(label: "&"); makeBtn(label: "@"); makeBtn(label: "\"")
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: Image(systemName: "number.square"), maxWidth: width / 8, action: { setKeyboardMode(.symbols2) })
                        makeBtn(label: "."); makeBtn(label: ","); makeBtn(label: "?"); makeBtn(label: "!"); makeBtn(label: "'")
                        makeBtn(image: Image(systemName: "delete.left"), maxWidth: width / 8, action: { backspace() })
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: Image(systemName: "abc"), maxWidth: width / 8, action: { setKeyboardMode(.letters) })
                        makeBtn(label: "space", affectedByShift: false, action: { sendKey(key: " ") })
                        makeBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 8, action: { dismiss() })
                    }
                } else if mode == .symbols2 {
                    HStack(spacing: 0) {
                        makeBtn(label: "["); makeBtn(label: "]"); makeBtn(label: "{"); makeBtn(label: "}"); makeBtn(label: "#")
                        makeBtn(label: "%"); makeBtn(label: "^"); makeBtn(label: "*"); makeBtn(label: "+"); makeBtn(label: "=")
                    }
                    HStack(spacing: 0) {
                        makeBtn(label: "_"); makeBtn(label: "\\"); makeBtn(label: "|"); makeBtn(label: "~"); makeBtn(label: "<")
                        makeBtn(label: ">"); makeBtn(label: "€"); makeBtn(label: "£"); makeBtn(label: "¥"); makeBtn(label: "•")
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: Image(systemName: "textformat.123"), maxWidth: width / 8, action: { setKeyboardMode(.symbols1) })
                        makeBtn(label: "."); makeBtn(label: ","); makeBtn(label: "?"); makeBtn(label: "!"); makeBtn(label: "'")
                        makeBtn(image: Image(systemName: "delete.left"), maxWidth: width / 8, action: { backspace() })
                    }
                    HStack(spacing: 0) {
                        makeBtn(image: Image(systemName: "abc"), maxWidth: width / 8, action: { setKeyboardMode(.letters) })
                        makeBtn(label: "space", affectedByShift: false, action: { sendKey(key: " ") })
                        makeBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 8, action: { dismiss() })
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
    }
}
