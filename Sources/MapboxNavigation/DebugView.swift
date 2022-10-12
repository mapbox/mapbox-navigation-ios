#if canImport(SwiftUI)
import SwiftUI
#endif

import Combine

@available(iOS 13.0, *)
class Option: ObservableObject, Identifiable {
    
    let id = UUID()
    
    let name: String
    
    @Published var isEnabled: Bool = false
    
    init(name: String, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

@available(iOS 14.0, *)
struct ToggleView: View {
    
    let title: String
    
    @State var isOn: Bool = false
    
    var onToggle: ((Bool) -> Void)? = nil
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .onChange(of: isOn) { value in
                onToggle?(value)
            }
    }
    
    init(title: String,
         isOn: Bool = false,
         onToggle: ((Bool) -> Void)? = nil) {
        self.title = title
        self.isOn = isOn
        self.onToggle = onToggle
    }
}

@available(iOS 13.0, *)
class OptionsViewModel: ObservableObject {
    
    @Published var options = [
        Option(name: "Show navigation camera viewport",
               isEnabled: true)
    ]
}

@available(iOS 14.0, *)
struct ListElement: View {
    
    @ObservedObject var option: Option
    
    var body: some View {
        ToggleView(title: option.name,
                   isOn: option.isEnabled) { isOn in
            option.isEnabled = isOn
        }
    }
}

@available(iOS 14.0, *)
struct DebugView: View {
    
    @ObservedObject var optionsViewModel = OptionsViewModel()
    
    var body: some View {
        List(optionsViewModel.options) { option in
            ListElement(option: option)
        }
    }
}

//NotificationCenter.default.post(name: .didTriggerNavigationCameraViewportVisibilityChange,
//                                object: option,
//                                userInfo: [
//                                 NavigationCamera.NotificationUserInfoKey.viewportVisibility: self.
//                                ])
