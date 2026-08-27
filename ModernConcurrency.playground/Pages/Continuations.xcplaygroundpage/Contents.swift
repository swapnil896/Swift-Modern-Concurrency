//: [Previous](@previous)

import Foundation
import CoreLocation

struct User {}

// MARK: ================ CONTINUATIONS ================

// Continuation = bridging between callback based code and async await

// Without Continuation
func fetchUser(_ completion: @escaping (User?, Error?) -> Void) {
    // callback based
}

// With Continuation
func fetchUser() async throws -> User {
    // async await
    return User()
}

/*
 Real world problem:
   └─ lots of existing code uses callbacks
   └─ delegates
   └─ completion handlers
   └─ NotificationCenter
   └─ CLLocationManager
   └─ you want to use async/await
   └─ but cant change the original API
   └─ Continuation bridges the gap ✅
 */

// MARK: ================ Types of Continuations ================

// 1. withCheckedContinuation
// Safe, non throwing

func fetchData() async -> Data {
    await withCheckedContinuation { continuation in
        continuation.resume(returning: Data())
    }
}

// 2. withCheckedThrowingContinuation
// Safe, throwing

func fetchDataThrowing() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        // continuation.resume(returning: Data)
        // continuation.resume(throwing: Error)
    }
}

// 3. withUnsafeContinuation
// Unsafe, non throwing, faster

func fetchDataUnsafeCont() async -> Data {
    await withUnsafeContinuation { continuation in
        // no safety checks
    }
}

// 4. withUnsafeThrowingContinuation
// Unsafe, can throw, faster

func fetchDataUnsafeThrowCont() async throws -> Data {
    try await withUnsafeThrowingContinuation { continuation in
        // no safety checks
    }
}

// MARK: ================ Checked vs Unsafe ================
/*
 withCheckedContinuation ✅
   └─ Swift checks you call resume exactly ONCE
   └─ warns if called twice ✅
   └─ warns if never called ✅
   └─ slight performance overhead
   └─ USE THIS in development ✅

 withUnsafeContinuation ⚠️
   └─ no safety checks
   └─ calling resume twice = crash ❌
   └─ never calling resume = memory leak ❌
   └─ faster performance
   └─ USE THIS only when performance critical
 */

// Golden rule of Continuations
// continuation.resume() must be called EXACTLY only once - No more, no less

// 3 ways to resume
/*
 1. continuation.resume(with: .success(value))  // return result type
    continuation.resume(with: .failure(error))
 
 2. continuation.resume(throwing: error) // throw an error
 
 3. continuation.resume(returning: Data())  // return a value
 */


// MARK: ================ Real World examples ================

struct Employee: Codable {}
let request = URLRequest(url: URL(string: "/getEmployee")!)

// 1. Converting URLSession Completion Handler
// Old Callback based
func fetchEmployee(_ completion: @escaping (Employee?, Error?) -> Void) {
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            completion(nil, error)
            return
        }
        let employee = try? JSONDecoder().decode(Employee.self, from: data ?? Data())
        completion(employee, nil)
    }.resume()
}

// With continuation
func fetchEmployeeContinuation() async throws -> Employee {
    try await withCheckedThrowingContinuation { continuation in
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            
            do {
                let employee = try? JSONDecoder().decode(Employee.self, from: data ?? Data())
                continuation.resume(returning: employee!)
            } catch {
                continuation.resume(throwing: error)
            }
        }.resume()
    }
}

// 2. Converting CLLocationManager Delegate
// Old delegate method
class LocationManager: NSObject, CLLocationManagerDelegate {
    var manager = CLLocationManager()
    var completion: ((CLLocation) -> Void)?
    
    func getLocation(completion: @escaping (CLLocation) -> Void) {
        self.completion = completion
        manager.delegate = self
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first!)
    }
}

// With Continuation
class LocationManagerCont: NSObject, CLLocationManagerDelegate {
    var manager = CLLocationManager()
    var continuation: CheckedContinuation<CLLocation, Error>?
    
    func getLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first!)
        continuation = nil  // clear after use
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil  // clear after use
    }
}
