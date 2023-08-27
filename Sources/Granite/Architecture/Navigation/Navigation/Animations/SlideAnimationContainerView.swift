//
//  SlideAnimationContainerView.swift
//  
//
//  Created by PEXAVC on 8/23/23.
//

import Foundation
import SwiftUI

//MARK: Slide in /swipe
struct SlideAnimationContainerView<MenuContent: View>: View {
    @Environment(\.graniteNavigationStyle) var style
    
    @Binding var isShowing: Bool
    @Binding var loaded: Bool
    
    let animationDuration: CGFloat
    
    var startLocationThreshold: CGFloat = 0.1
    var startThreshold: CGFloat = 0.05
    var activeThreshold: CGFloat = 0.6
    var viewingThreshold: CGFloat = 1
    
    var startLocationWidth: CGFloat
    var startWidth: CGFloat
    var width: CGFloat
    
    @State var offsetX: CGFloat = 0
    
    //First load only
    @State var hasShown: Bool = false
    
    var opacity: CGFloat {
        (offsetX / width) * 0.8
    }
    
    private let menuContent: () -> MenuContent
    
    init(_ isShowing: Binding<Bool>,
         loaded: Binding<Bool>,
         animationDuration: CGFloat = 0.6,
         @ViewBuilder _ menuContent: @escaping () -> MenuContent) {
        _isShowing = isShowing
        _loaded = loaded
#if os(iOS)
        let viewingWidth: CGFloat = UIScreen.main.bounds.width * viewingThreshold
#else
        let viewingWidth: CGFloat = 350
#endif
        self._offsetX = .init(initialValue: viewingWidth)
        self.width = viewingWidth
        self.startWidth = viewingWidth * startThreshold
        self.startLocationWidth = viewingWidth * startLocationThreshold
        self.menuContent = menuContent
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        let drag = DragGesture()
            .onChanged { value in
                
                guard abs(value.startLocation.x) <= startLocationWidth,
                      abs(value.translation.width) >= startWidth else {
                    return
                }
                DispatchQueue.main.async {
                    
                    //isShowing = 0
                    
                    //!isShowing = width
                    
                    let translation = (value.translation.width - (startWidth * (isShowing ? -1 : 1))) + (isShowing ? 0 : width)
                    self.offsetX = max(0, min(translation, width))
                }
            }
            .onEnded { event in
                DispatchQueue.main.async {
                    if offsetX > activeThreshold * width {
                        withAnimation {
                            self.isShowing = false
                            self.offsetX = width
                        }
                    } else{
                        
                        withAnimation {
                            self.isShowing = true
                            self.offsetX = 0
                        }
                    }
                }
            }
        
        return ZStack(alignment: .leading) {
            style.backgroundColor
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
                .opacity(1.0 - (self.offsetX / width))
            
            menuContent()
                .offset(x: self.offsetX)
                .allowsHitTesting(self.offsetX == 0)
                .environment(\.graniteNavigationShowingKey, self.hasShown)
        }
        .simultaneousGesture(drag)
        .onChange(of: loaded) { state in
            guard state else { return }
            
            //TODO: duration should be customizable from granite destination
            withAnimation(.interactiveSpring(blendDuration: animationDuration)) {
                self.isShowing = true
                self.offsetX = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                self.hasShown = true
            }
        }
    }
}
