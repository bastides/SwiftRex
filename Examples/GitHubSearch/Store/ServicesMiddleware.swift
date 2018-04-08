import RxSwift
import SwiftRex

final class ServicesMiddleware: SideEffectMiddleware {
    typealias StateType = GlobalState

    var actionHandler: ActionHandler?
    var allowEventToPropagate = false
    var disposeBag = DisposeBag()

    func sideEffect(for event: EventProtocol) -> AnySideEffectProducer<GlobalState>? {
        switch event {
        case let event as RepositorySearchEvent:
            return AnySideEffectProducer(RepositorySearchService(event: event))
        default: return nil
        }
    }
}
