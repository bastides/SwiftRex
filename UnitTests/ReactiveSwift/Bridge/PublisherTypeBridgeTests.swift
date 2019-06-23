import ReactiveSwift
import SwiftRex
import SwiftRexForRac
import XCTest

class PublisherTypeBridgeTests: XCTestCase {
    func testPublisherTypeToSignalProducerOnValue() {
        let shouldCallClosureValue = expectation(description: "Closure should be called")
        let shouldCallClosureCompleted = expectation(description: "Closure should be called")

        let publisherType = PublisherType<String, Error> { subscriber in
            subscriber.onValue("test")
            subscriber.onCompleted(nil)
            return FooSubscription()
        }

        _ = publisherType.producer.start(.init(
            value: { string in
                XCTAssertEqual("test", string)
                shouldCallClosureValue.fulfill()
            },
            failed: { error in
                XCTFail("Unexpected error: \(error)")
            },
            completed: {
                shouldCallClosureCompleted.fulfill()
            }
        ))

        wait(for: [shouldCallClosureValue, shouldCallClosureCompleted], timeout: 0.1)
    }

    func testPublisherTypeToObservableOnError() {
        let shouldCallClosureValue = expectation(description: "Closure should be called")
        let shouldCallClosureError = expectation(description: "Closure should be called")
        let someError = SomeError()

        let publisherType = PublisherType<String, Error> { subscriber in
            subscriber.onValue("test")
            subscriber.onCompleted(someError)
            return FooSubscription()
        }

        _ = publisherType.producer.start(.init(
            value: { string in
                XCTAssertEqual("test", string)
                shouldCallClosureValue.fulfill()
            },
            failed: { error in
                XCTAssertEqual(someError, error as! SomeError)
                shouldCallClosureError.fulfill()
            },
            completed: {
                XCTFail("Unexpected completion")
            }
        ))

        wait(for: [shouldCallClosureValue, shouldCallClosureError], timeout: 0.1)
    }

    func testSignalProducerToPublisherTypeOnValue() {
        let shouldCallClosureValue = expectation(description: "Closure should be called")
        let shouldCallClosureCompleted = expectation(description: "Closure should be called")

        let signalProducer = SignalProducer<String, SomeError> { observer, _ in
            observer.send(value: "test")
            observer.sendCompleted()
        }

        _ = signalProducer.asPublisher().subscribe(SubscriberType(
            onValue: { string in
                XCTAssertEqual("test", string)
                shouldCallClosureValue.fulfill()
            },
            onCompleted: { error in
                if let error = error {
                    XCTFail("Unexpected error: \(error)")
                }
                shouldCallClosureCompleted.fulfill()
            }))

        wait(for: [shouldCallClosureValue, shouldCallClosureCompleted], timeout: 0.1)
    }

    func testSignalProducerToPublisherTypeOnError() {
        let shouldCallClosureValue = expectation(description: "Closure should be called")
        let shouldCallClosureError = expectation(description: "Closure should be called")
        let someError = SomeError()

        let signalProducer = SignalProducer<String, SomeError> { observer, _ in
            observer.send(value: "test")
            observer.send(error: someError)
        }

        _ = signalProducer.asPublisher().subscribe(SubscriberType(
            onValue: { string in
                XCTAssertEqual("test", string)
                shouldCallClosureValue.fulfill()
            },
            onCompleted: { error in
                guard let error = error else {
                    XCTFail("Unexpected completion")
                    return
                }

                XCTAssertEqual(someError, error)
                shouldCallClosureError.fulfill()
            }))

        wait(for: [shouldCallClosureValue, shouldCallClosureError], timeout: 0.1)
    }
}
