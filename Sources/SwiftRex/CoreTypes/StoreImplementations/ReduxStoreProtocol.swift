import Foundation

// sourcery: AutoMockable
// sourcery: AutoMockableGeneric = StateType
// sourcery: AutoMockableGeneric = ActionType
// sourcery: AutoMockableSkip = "dispatch(_ action: ActionType)"
public protocol ReduxStoreProtocol: class, StoreType {
    associatedtype MiddlewareType: Middleware
        where MiddlewareType.StateType == StateType, MiddlewareType.ActionType == ActionType
    var pipeline: ReduxPipelineWrapper<MiddlewareType> { get }
}

extension ReduxStoreProtocol {
    public func dispatch(_ action: ActionType) {
        pipeline.dispatch(action)
    }
}
