# Granite - Alpha

### iOS & macOS compatible

A **SwiftUI Architecture** that merges Redux event handling and state management with functional programming.

The Granite architecture provides:

- Testability and Isolation. Routing, business, view logic, independant classes/protocols to be inherited. Each component is positioned to be decoupled and independant from eachother.
  - Allows for a more structured approach in development. 
  - Building in a way, that makes context-switching less stressful when coming back to old code.
- View Library. Granite comes with a comprehensive view library (GraniteUI) that can speed up development, offering thought out templates and other UX solutions.
- Speeds up development to bootstrap ideas and make them production ready.
  - Neatia as seen below took 2 weeks from the ground-up, to build. Given [Third-Party Packages](https://github.com/pexavc/Nea#swift-packages--credits) were used in the process.

# High Level Overview

> This is my prior architecture, that has an in-depth look into my thought process, eventually leading to this re-write: https://github.com/pexavc/GraniteUI

#### Inheritance

- GraniteComponent 
	- GraniteCommand 
		- GraniteCenter 
			- GraniteState 
		- GraniteReducer (Reducers)
- GraniteRelay 
	- GraniteService 
		- GraniteCenter 
			- GraniteState 
		- GraniteReducer (Reducers)

This doc will use my [open-sourced macOS app](https://github.com/pexavc/Nea), 100% built with Granite/SwiftUI, as a working example.

#### Disclaimer

The architecture itself is still a WIP, but currently I have moved onto seeing its production viability and it has passed certain benchmarks that made me comfortable to begin sharing documentation and reasons behind use.

- Live Production Apps that use `Granite`
  - [Bullish](https://apps.apple.com/us/app/bullish-simulate-forecast/id6449899191)
     - An iOS/iPadOS virtual portfolio for Stocks. With on-device training
         - Big data management and storage, with Stock/time-series data dating older than decade or more.
         - High throughput within `GraniteComponents` when training data for the Generative Forecasting or processing updates when syncing Stocks and displaying changes in a portfolio.
  - [Neatia](https://apps.apple.com/us/app/neatia/id6449069312)
     - A macOS GPT/ChatBot client and prompt creator/organizer. 
         - Network interfacing
         - High throughput between `GraniteRelays` for query/response interactions
         - Payment processing and Payment state management. 
             - Uses another personal and simple [StoreKit2 interface](https://github.com/pexavc/VaultKit) as well.
- Apps in Development that WILL use `Granite`
  - [Marble](https://github.com/pexavc/LaMarque) This was initially built with an earlier version of the Granite design pattern.
     - An Audio/Video music visualizer that uses Metal to render textures at 60FPS+. With multiple instance in 1 page running at 30FPS+.
         - High throughput texture management, video encoding, and audio processing.
         - And eventually, *Vision Pro* compatibility for Mixed Reality experiences.

# Table of Contents

- [XCTemplates](#XCTemplates)
- [Guide](#Guide)
	- [GraniteComponent](#GraniteComponent) //Views
	- [GraniteReducer](#GraniteReducer) //Business logic
	  - [Pattern 1](#Pattern-1)
	  - [Pattern 2](#Pattern-2) 
	  - [Services in Reducers](#Services-in-Reducers)
	  - [Lifecycle Reducers](#Lifecycle-Reducers)
	- [GraniteRelay](#GraniteRelay) //Services
	  - ***WIP***

# XCTemplates
Located in [/Resources/Templates](https://github.com/pexavc/Granite/tree/main/Resources/Templates)

Move XCTemplate files to this location: ~/Library/Developer/Xcode/Templates/Modules/...

They will appear as modules within XCode for easy Component/Relay and Reducer creation when creating a new file.


# Guide

## [GraniteComponent](https://github.com/pexavc/Nea/blob/main/Components/Modules/Mount/Mount.swift)

### Directory Structure

- `/ComponentName`
  - ComponentName.swift
  - ComponentName+View.swift
  - ComponentName+Center.swift //The "State" sits here
  - `/Reducers`
     - ComponentName.ExampleReducer.swift 


#### [ComponentName.swift](https://github.com/pexavc/Nea/blob/main/Components/Modules/Mount/Mount.swift)

Initialized the SwiftUI Granite Component, with it's "GraniteCenter/GraniteState" and relevant services ("Relays") required.

```swift
import Granite
import SandKit
import SwiftUI

struct Mount: GraniteComponent {
    @Command var center: Center
    
    @Relay var environment: EnvironmentService
    @Relay var account: AccountService
    @Relay var sand: SandService
    @Relay var config: ConfigService
    
    @SharedObject(SessionManager.id) var session: SessionManager
    
}
```

#### [ComponentName+View.swift](https://github.com/pexavc/Nea/blob/main/Components/Modules/Mount/Mount%2BView.swift)

Granite does not use `var body: some View` to initialize a view, but rather `var view: some View`. In the backend, `var body` is still used however, but different lifecycles are monitored prior to the component appearing.

```swift
import Granite
import GraniteUI
import SwiftUI
import SandKit

extension Mount: View {
    var queryHeight: CGFloat {
        environment.sizeFor(.query).height + (environment.titleBarHeight / 2)
    }
    
    var responseHeight: CGFloat {
        environment.sizeFor(.response).height + (environment.titleBarHeight / 2)
    }
    
    var backgroundView: some View {
        { ... }
    }
    
    var mainView: some View {
        { ... }
    }
    
    var toolbarViews: some View {
        { ... }
    }
    
    public var view: some View { //Granite's "var body: some View {}"
        ZStack {
            backgroundView
            
            mainView
            
            toolbarViews
            
            if session.isLocked {
                lockedView
            }
        }
    }
}
```


#### [ComponentName+Center.swift](https://github.com/pexavc/Nea/blob/main/Components/Modules/Mount/Mount%2BCenter.swift)

The "Center" houses the State. And works similarly to a `@State` property wrapper. This view heavily relies on the state changes of its services rather than its own. Which is why there isn't much to see here. 

```swift
import Granite
import SwiftUI

extension Mount {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            var somethingToUpdate: Bool = false
        }
        
        @Store public var state: State
    }
}

```

[Below](https://github.com/pexavc/Nea/blob/a57b3733dee4be65e7c64b19d7acca16af1c75f9/Components/Modules/Query/Query%2BView.swift#L18-L32) is an example of a component firing its own reducer and how a state would update triggering view changes.

> Code changed vs. links' for clarity.

```swift
public var view: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if session.isLocked {
                    { ... }
                } else {
                    MacEditorTextView(
                        text: query.center.$state.binding.value,//<----- state's string is bound (1)
                        
                        { ... }
                        
                        onEditingChanged: {
                            center.$state.binding.wrappedValue.isEditing = true
                        },
                        onCommit: {
                            guard environment.center.state.isCommandActive == false else {
                                return
                            }
                            
                            center.ask.send()//<----- fire reducer (2)
                        },
                        
            { ... }
        }
}
```

Comment `(2)` triggers [this](https://github.com/pexavc/Nea/blob/a57b3733dee4be65e7c64b19d7acca16af1c75f9/Components/Modules/Query/Query%2BCenter.swift#L13).

```swift

extension Query {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            var query: String = ""
            var isEditing: Bool = false
            var isCommandMenuActive: Bool = false
        }
        
        @Event var ask: Query.Ask.Reducer// <----- primed reducer
        
        @Store public var state: State
    }
}
```

Reducers are isolated files, that house core business logic. 

```swift
import Granite
import SandKit

extension Query {
    struct Ask: GraniteReducer {
        typealias Center = Query.Center
        
        func reduce(state: inout Center.State) {
            state.query//<---- do something with the state
            
            state.query = "newValue"
            state.isEditing = false
        }
    }
}
```


## [GraniteReducer](https://github.com/pexavc/Nea/blob/main/Services/Environment/Reducers/EnvironmentService._.swift)

A Granite Reducer can have 2 patterns.

#### Pattern 1

Pretty straightforward, but what if we want to fire another reducer from here? Or maybe add a Payload?

```swift
import Granite

extension EnvironmentService {
    struct Boot: GraniteReducer {
        typealias Center = EnvironmentService.Center
        
        func reduce(state: inout Center.State) {
        
        }
    }
}
```

Creating a struct that inherits from `GranitePayload` allows it to be linked to a reducers `send` function. As we saw earlier in `center.ask.send()`. Now we can also do something like `env.boot.send(Boot.Meta(data: someData)))`

Other reducers can be nested in reducers to fire.

> CAREFUL about circular dependency. If a reducer in a service references another service, in which that OTHER service also references the callee. A recursive block will occur.

```swift
import Granite

extension EnvironmentService {
    struct Boot: GraniteReducer {
        typealias Center = EnvironmentService.Center
        
        struct Meta: GranitePayload {
            var data: Data
        }
        
        @Payload var meta: Meta?//the `optional` is important
        
        @Event var next: NextReducer.Reducer//Another reducer
        
        func reduce(state: inout Center.State) {
            next.send()
        }
    }
    
    struct NextReducer: GraniteReducer {
        typealias Center = EnvironmentService.Center
        
        func reduce(state: inout Center.State) {
        
        }
    }
}
```

>[Issue #1](https://github.com/pexavc/Granite/issues/1) Recent changes have made async nested reducers affect the order AND reliability of how a state updates. This will be fixed soon, with this comment being removed after.

#### Pattern 2

You can also define a new typealias to skip the `@Payload` property wrapper.

```swift
import Granite

extension EnvironmentService {
    struct Boot: GraniteReducer {
        typealias Center = EnvironmentService.Center
        typealias Payload = Boot.Meta
        
        struct Meta: GranitePayload {
            var data: Data
        }
        
        func reduce(state: inout Center.State, payload: Payload)//New Parameter required, or this will never fire
        {
            next.send()
        }
    }
}
```

#### Services in Reducers

Dependency injection is tedious when wanting context through an App's lifecycle. In Granite you can simply reference the service again in the reducer, uptodate, and invoke its' reducers.

```swift
import Granite

extension EnvironmentService {
    struct Boot: GraniteReducer {
        typealias Center = EnvironmentService.Center
        
        @Relay var service: AnotherService
        
        func reduce(state: inout Center.State)
        {
            service.preload()//Services load their states async. Force a preload if it's required now.
        }
    }
}
```

#### Lifecycle Reducers

You can set a lifecycle property to a reducer's `@Event` property wrapper to have it called automatically.

```swift
import Granite
import SwiftUI

extension AnotherComponent {
    struct Center: GraniteCenter {
        struct State: GraniteState {
        
        }
        
        //Property wrapper accepts a lifecycle param
        @Event(.onAppear) var onAppear: OnAppear.Reducer
        
        @Store public var state: State
    }
}
```

## [GraniteRelay](https://github.com/pexavc/Nea/tree/main/Services/Config)

### Directory Structure

- `/RelayName`
  - RelayName
  - RelayName+Center.swift //The "State" sits here
  - `/Reducers`
     - RelayName.ExampleReducer.swift 

A [GraniteRelay](https://github.com/pexavc/Nea/blob/main/Services/Config/ConfigService.swift) is setup similarly to a `GraniteComponent`. Except there's no `var view` and `@Command`.

The online parameter of the property wrapper `@Service` allows the changes of this service to be broadcasted to all views that have it declared. Changing in option in 1 view, will update ALL the views that reference the same stateful variable to render something.

```swift
import Granite

struct ConfigService: GraniteService {
    @Service(.online) var center: Center
}
```

***WIP***
