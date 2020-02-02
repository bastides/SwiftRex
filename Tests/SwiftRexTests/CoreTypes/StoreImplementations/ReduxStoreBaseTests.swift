import Foundation
@testable import SwiftRex
import XCTest

class ReduxStoreBaseTests: XCTestCase {
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func testStoreFullWorkflowIntegration() {
        let shouldCallFooMiddleware = expectation(description: "foo middleware should have been called 2 times")
        shouldCallFooMiddleware.expectedFulfillmentCount = 2
        let shouldCallBarMiddleware = expectation(description: "bar middleware should have been called 9 times")
        shouldCallBarMiddleware.expectedFulfillmentCount = 9
        let shouldCallReducer = expectation(description: "reducer should have been called 11 times")
        shouldCallReducer.expectedFulfillmentCount = 11
        shouldCallReducer.expectedFulfillmentCount = 11
        let shouldNotifySubscribers = expectation(description: "subscription notification should have been called 11 times")
        shouldNotifySubscribers.expectedFulfillmentCount = 11
        let events: [AppAction] = [.foo, .bar(.charlie), .foo]
        let initialState = TestState()
        let fooMiddleware = IsoMiddlewareMock<AppAction, TestState>()
        var fooMiddlewareOutput: AnyActionHandler<AppAction>?
        fooMiddleware.receiveContextGetStateOutputClosure = { getState, output in
            fooMiddlewareOutput = output
        }
        fooMiddleware.handleActionClosure = { action in
            guard action == .foo else {
                return .doNothing()
            }

            fooMiddlewareOutput?.dispatch(.bar(.alpha))

            return .do {
                fooMiddlewareOutput?.dispatch(.bar(.bravo))
                shouldCallFooMiddleware.fulfill()
            }
        }
        let barMiddleware = IsoMiddlewareMock<AppAction.Bar, String>()
        var barMiddlewareOutput: AnyActionHandler<AppAction.Bar>?
        barMiddleware.receiveContextGetStateOutputClosure = { getState, output in
            barMiddlewareOutput = output
        }
        barMiddleware.handleActionClosure = { action in
            switch action {
            case .alpha:
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                    barMiddlewareOutput?.dispatch(.delta)
                }
            case .bravo:
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    barMiddlewareOutput?.dispatch(.echo)
                }
            default: break
            }

            return .do {
                shouldCallBarMiddleware.fulfill()
            }
        }

        let subjectMock = CurrentValueSubject(currentValue: initialState)
        let reducer: Reducer<AppAction, TestState> = Reducer { action, state in
            let actionName: String
            switch action {
            case .foo: actionName = "foo"
            case .bar(.alpha): actionName = "alpha"
            case .bar(.bravo): actionName = "bravo"
            case .bar(.charlie): actionName = "charlie"
            case .bar(.delta): actionName = "delta"
            case .bar(.echo): actionName = "echo"
            }
            shouldCallReducer.fulfill()
            return .init(
                value: state.value,
                name: state.name + "_" + actionName
            )
        }

        let store = ReduxStoreBase<AppAction, TestState>(
            subject: subjectMock.subject,
            reducer: reducer,
            middleware: fooMiddleware <> barMiddleware.lift(
                inputActionMap: { $0.bar },
                outputActionMap: { AppAction.bar($0) },
                stateMap: { $0.name }
            )
        )

        var count = 0
        _ = store.statePublisher.subscribe(SubscriberType(onValue: { value in
            shouldNotifySubscribers.fulfill()
            switch count {
            case 0: XCTAssertEqual("_foo", value.name)
            case 1: XCTAssertEqual("_foo_charlie", value.name)
            case 2: XCTAssertEqual("_foo_charlie_foo", value.name)
            case 3: XCTAssertEqual("_foo_charlie_foo_alpha", value.name)
            case 4: XCTAssertEqual("_foo_charlie_foo_alpha_bravo", value.name)
            case 5: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha", value.name)
            case 6: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha_bravo", value.name)
            case 7: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha_bravo_delta", value.name)
            case 8: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha_bravo_delta_delta", value.name)
            case 9: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha_bravo_delta_delta_echo", value.name)
            case 10: XCTAssertEqual("_foo_charlie_foo_alpha_bravo_alpha_bravo_delta_delta_echo_echo", value.name)
            default: XCTFail("Called more times than expected")
            }
            count += 1
        }, onCompleted: { error in XCTFail("Unexpected completion. Error? \(String(describing: error))") }))

        events.forEach(store.dispatch)

        waitForExpectations(timeout: 3)
        XCTAssertEqual(subjectMock.currentValue.value, initialState.value)
        XCTAssertEqual(subjectMock.currentValue.name, "_foo_charlie_foo_alpha_bravo_alpha_bravo_delta_delta_echo_echo")
    }
}
