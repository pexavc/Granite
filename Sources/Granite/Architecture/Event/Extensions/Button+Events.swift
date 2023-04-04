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
    
    public init<S: EventExecutable>(_ reducer: S, @ViewBuilder label: () -> Label) {
        self.init {
            reducer.send()
        } label: {
            label()
        }
    }
    
    public init<S: EventExecutable, I: GranitePayload>(_ reducer: S, value : I, @ViewBuilder label: () -> Label) {
        self.init {
            reducer.send(value)
        } label: {
            label()
        }
    }
}
