// Generated using Sourcery 0.17.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
import Foundation
@testable import SwiftRex
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif













class MiddlewareMock<ActionType, StateType>: Middleware {
    var context: (() -> MiddlewareContext<ActionType, StateType>) {
        get { return underlyingContext }
        set(value) { underlyingContext = value }
    }
    var underlyingContext: (() -> MiddlewareContext<ActionType, StateType>)!

    //MARK: - handle

    var handleActionNextCallsCount = 0
    var handleActionNextCalled: Bool {
        return handleActionNextCallsCount > 0
    }
    var handleActionNextReceivedArguments: (action: ActionType, next: Next)?
    var handleActionNextClosure: ((ActionType, @escaping Next) -> Void)?

    func handle(action: ActionType, next: @escaping Next) {
        handleActionNextCallsCount += 1
        handleActionNextReceivedArguments = (action: action, next: next)
        handleActionNextClosure?(action, next)
    }

}
