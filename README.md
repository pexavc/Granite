# Granite - v00.00.00 - Alpha

### iOS & macOS compatible

A powerful **SwiftUI Architecture** that merges Redux event handling and state management with functional programming. While bringing powerful workflows to streamline CoreML/Metal work and to interact with ground-breaking services like *IPFS*.

The Granite architecture provides:

- Testability and Isolation. Routing, business, view logic, have independant classes/protocols to be inherited. Each component is positioned to be decoupled and independant from eachother.
- Tooling for developer productivity. Granite comes with pre-built components to streamline Metal, CoreML integration as well as UserDefault-backed local storage solutions.
- View Library. Granite comes with a comprehensive view library (GraniteUI) that can speed up development, offering thought out templates and other UX solutions.
- IPFS capability, any media type you handle with Granite's framework can be pinned and distributed from IPFS with ease. Based on: https://github.com/ipfs-shipyard/swift-ipfs-http-client

# High Level Overview

> The `Docs` folder has usage examples for each file. Some are still WIP.

- GraniteComponent **(80%)**
	- GraniteCommand **(50%)**
		- GraniteCenter **(50%)**
			- GraniteState **(90%)**
		- GraniteReducer (Reducers) **(90%)**
- GraniteRelay **(80%)**
	- GraniteService **(50%)**
		- GraniteCenter **(50%)**
			- GraniteState **(90%)**
		- GraniteReducer (Reducers) **(90%)**
- GraniteEvent **(80%)**
	- GraniteReducer **(20%)**
- [GraniteIPFS **(25%)**](https://github.com/pexavc/IPFSKit)

> Documentation is a work in progress. Reference the above for progress. It is to show the main types one may experience when using the architecture. Example templates are provided in the meantime.


> This repo will be updated every Friday at the absolute latest, with major changes if minor changes are not scattered throughout the week.


From a historical perspective, this is my prior architecture https://github.com/pexavc/GraniteUI

I have challenged SwiftUI once more.
