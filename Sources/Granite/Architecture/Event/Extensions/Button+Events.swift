import Foundation
import SwiftUI

extension Button {

    public init(action : GraniteAction<Void>.ActionWrapper, @ViewBuilder label: () -> Label) {
        self.init {
            action.perform()
        } label: {
            label()
        }
    }

    public init<I>(action : GraniteAction<I>.ActionWrapper, value : I, @ViewBuilder label: () -> Label) {
        self.init {
            action.perform(value)
        } label: {
            label()
        }
    }
    
    public init<S: EventExecutable>(_ expedition: S, @ViewBuilder label: () -> Label) {
        self.init {
            expedition.send()
        } label: {
            label()
        }
    }
    
    public init<S: EventExecutable, I: GranitePayload>(_ expedition: S, value : I, @ViewBuilder label: () -> Label) {
        self.init {
            expedition.send(value)
        } label: {
            label()
        }
    }
}
