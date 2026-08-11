import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import AccountContext

// MARK: - Хранилище настроек
private let fakeOfflineKey = "amnezia_fake_offline"

func getFakeOfflineEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: fakeOfflineKey)
}

func setFakeOfflineEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: fakeOfflineKey)
}

// MARK: - Секции и пункты
private enum AmneziaModsSection: Int32 {
    case mods
}

private enum AmneziaModsEntry: ItemListNodeEntry {
    case fakeOffline(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        return AmneziaModsSection.mods.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .fakeOffline:
            return 0
        }
    }

    static func == (lhs: AmneziaModsEntry, rhs: AmneziaModsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.fakeOffline(lTheme, lText, lValue), .fakeOffline(rTheme, rText, rValue)):
            return lTheme === rTheme && lText == rText && lValue == rValue
        }
    }

    static func < (lhs: AmneziaModsEntry, rhs: AmneziaModsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem & ItemListItem {
        let arguments = arguments as! AmneziaModsArguments
        switch self {
        case let .fakeOffline(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { newValue in
                    arguments.toggleFakeOffline(newValue)
                }
            )
        }
    }
}

// MARK: - Arguments (действия)
private struct AmneziaModsArguments {
    let toggleFakeOffline: (Bool) -> Void
}

// MARK: - State
private struct AmneziaModsState: Equatable {
    var fakeOfflineEnabled: Bool
}

// MARK: - Построение списка
private func amneziaModsEntries(
    state: AmneziaModsState,
    presentationData: PresentationData
) -> [AmneziaModsEntry] {
    var entries: [AmneziaModsEntry] = []
    entries.append(.fakeOffline(
        presentationData.theme,
        "Fake Offline",
        state.fakeOfflineEnabled
    ))
    return entries
}

// MARK: - Публичная функция создания контроллера
public func amneziaModsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(
        AmneziaModsState(fakeOfflineEnabled: getFakeOfflineEnabled()),
        ignoreRepeated: true
    )
    let stateValue = Atomic(
        value: AmneziaModsState(fakeOfflineEnabled: getFakeOfflineEnabled())
    )

    let updateState: ((AmneziaModsState) -> AmneziaModsState) -> Void = { f in
        statePromise.set(stateValue.modify(f))
    }

    let arguments = AmneziaModsArguments(
        toggleFakeOffline: { value in
            setFakeOfflineEnabled(value)
            updateState { state in
                var state = state
                state.fakeOfflineEnabled = value
                return state
            }
        }
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Amnezia Mods"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: amneziaModsEntries(state: state, presentationData: presentationData),
            style: .blocks
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
