/**
 Zero-argument function that returns the current state. <br/>
 `() -> StateType`
 */
public typealias GetState<StateType> = () -> StateType

public typealias Next = () -> Void

/**
 State reducer: takes current state and an action, computes the new state. <br/>
 `(StateType, ActionProtocol) -> StateType`
 */
public typealias ReduceFunction<ActionType, StateType> = (ActionType, StateType) -> StateType
