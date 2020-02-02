import Foundation
@testable import SwiftRex
import XCTest

class ReduxPipelineWrapperTests: XCTestCase {
    func testDispatchCallOnActionAlwaysInMainThread() {
        let middlewareMock = IsoMiddlewareMock<AppAction, TestState>()
        let stateSubjectMock = CurrentValueSubject(currentValue: TestState())
        let reducerMock = createReducerMock()
        reducerMock.1.reduceClosure = { _, state in state }
        let sut = ReduxPipelineWrapper<IsoMiddlewareMock<AppAction, TestState>>(
            state: stateSubjectMock.subject,
            reducer: reducerMock.0,
            middleware: middlewareMock)

        let actionToDispatch: AppAction = .bar(.charlie)
        let expectedAction: AppAction = .bar(.charlie)
        let shouldCallMiddlewareActionHandler = expectation(description: "middleware action handler should have been called")
        middlewareMock.handleActionClosure = { action in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(action, expectedAction)
            shouldCallMiddlewareActionHandler.fulfill()
            return .doNothing()
        }

        DispatchQueue.global().async {
            sut.dispatch(actionToDispatch)
        }

        wait(for: [shouldCallMiddlewareActionHandler], timeout: 0.1)
    }

    func testMiddlewareDispatchesNewActionsBackToTheStore() {
        let middlewareMock = IsoMiddlewareMock<AppAction, TestState>()
        var middlewareDispatcher: AnyActionHandler<AppAction>?
        middlewareMock.receiveContextGetStateOutputClosure = { getState, output in
            middlewareDispatcher = output
        }
        let stateSubjectMock = CurrentValueSubject(currentValue: TestState())
        let reducerMock = createReducerMock()
        reducerMock.1.reduceClosure = { _, state in state }
        _ = ReduxPipelineWrapper<IsoMiddlewareMock<AppAction, TestState>>(
            state: stateSubjectMock.subject,
            reducer: reducerMock.0,
            middleware: middlewareMock)

        let actionToDispatch: AppAction = .bar(.charlie)
        let expectedAction: AppAction = .bar(.charlie)
        let shouldCallMiddlewareActionHandler = expectation(description: "middleware action handler should have been called")
        middlewareMock.handleActionClosure = { action in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(action, expectedAction)
            shouldCallMiddlewareActionHandler.fulfill()
            return .doNothing()
        }

        DispatchQueue.global().async {
            middlewareDispatcher?.dispatch(actionToDispatch)
        }

        wait(for: [shouldCallMiddlewareActionHandler], timeout: 0.1)
    }

    func testMiddlewareGetStateIsSetCorrectly() {
        let middlewareMock = IsoMiddlewareMock<AppAction, TestState>()
        var middlewareGetState: (() -> TestState)?
        middlewareMock.receiveContextGetStateOutputClosure = { getState, output in
            middlewareGetState = getState
        }
        let currentState = TestState()
        let stateSubjectMock = CurrentValueSubject(currentValue: currentState)
        _ = ReduxPipelineWrapper<IsoMiddlewareMock<AppAction, TestState>>(
            state: stateSubjectMock.subject,
            reducer: createReducerMock().0,
            middleware: middlewareMock)
        XCTAssertEqual(currentState, middlewareGetState?())
    }

    func testReducersPipelineWillBeWiredToTheEndOfMiddlewarePipeline() {
        let middlewareMock = IsoMiddlewareMock<AppAction, TestState>()
        let initialState = TestState()
        let stateSubjectMock = CurrentValueSubject(currentValue: initialState)
        let reducerMock = createReducerMock()
        let sut = ReduxPipelineWrapper<IsoMiddlewareMock<AppAction, TestState>>(
            state: stateSubjectMock.subject,
            reducer: reducerMock.0,
            middleware: middlewareMock)

        let actionToDispatch: AppAction = .bar(.charlie)
        let expectedAction: AppAction = .bar(.charlie)
        let shouldCallReducerActionHandler = expectation(description: "middleware action handler should have been called")
        middlewareMock.handleActionClosure = { _ in
            .doNothing()
        }

        reducerMock.1.reduceClosure = { action, state in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(action, expectedAction)
            XCTAssertEqual(initialState, state)
            shouldCallReducerActionHandler.fulfill()
            return state
        }

        DispatchQueue.global().async {
            sut.dispatch(actionToDispatch)
        }

        wait(for: [shouldCallReducerActionHandler], timeout: 0.1)
    }

    func testReducersChangeTheState() {
        let middlewareMock = IsoMiddlewareMock<AppAction, TestState>()
        let initialState = TestState()
        let reducedState = TestState(value: UUID(), name: "reduced state")
        let stateSubjectMock = CurrentValueSubject(currentValue: initialState)
        let reducerMock = createReducerMock()
        let sut = ReduxPipelineWrapper<IsoMiddlewareMock<AppAction, TestState>>(
            state: stateSubjectMock.subject,
            reducer: reducerMock.0,
            middleware: middlewareMock)

        let shouldCallReducerActionHandler = expectation(description: "middleware action handler should have been called")
        middlewareMock.handleActionClosure = { _ in
            .doNothing()
        }

        reducerMock.1.reduceClosure = { _, state in
            XCTAssertEqual(initialState, state)
            shouldCallReducerActionHandler.fulfill()
            return reducedState
        }

        sut.dispatch(.bar(.charlie))

        wait(for: [shouldCallReducerActionHandler], timeout: 0.1)
        XCTAssertEqual(reducedState, stateSubjectMock.currentValue)
        XCTAssertNotEqual(initialState, stateSubjectMock.currentValue)
    }
}
