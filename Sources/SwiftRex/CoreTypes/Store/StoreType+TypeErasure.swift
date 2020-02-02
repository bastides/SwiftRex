public struct AnyStoreType<ActionType, StateType>: StoreType {
    private let actionHandler: AnyActionHandler<ActionType>
    private let stateProvider: AnyStateProvider<StateType>

    public init<S: StoreType>(_ store: S) where S.ActionType == ActionType, S.StateType == StateType {
        self.init(action: store.dispatch, state: store.statePublisher)
    }

    public init(action: @escaping (ActionType) -> Void, state: UnfailablePublisherType<StateType>) {
        self.actionHandler = AnyActionHandler(action)
        self.stateProvider = AnyStateProvider(state)
    }

    public func dispatch(_ action: ActionType) {
        actionHandler.dispatch(action)
    }

    public var statePublisher: UnfailablePublisherType<StateType> {
        stateProvider.statePublisher
    }
}

extension StoreType {
    public func eraseToAnyStoreType() -> AnyStoreType<ActionType, StateType> {
        AnyStoreType(self)
    }
}
