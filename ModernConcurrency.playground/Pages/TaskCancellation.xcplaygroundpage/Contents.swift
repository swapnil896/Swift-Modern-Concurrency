//: [Previous](@previous)

import Foundation

/*
 What is TaskCancellation
 - Task Cancellation in Swift is cooperative
 - It means, you REQUEST Cancellation, task decides when to stop
 */
let task = Task {
    // task must check for Cancellation
    // it doesn't stop automatically
}
task.cancel() // requests Cancellation, doesn't force stop

/*
 
 Other languages (forceful):
 task.cancel() → task immediately killed ❌
               → unsafe, resources not cleaned up

 Swift (cooperative):
 task.cancel() → sets cancellation flag ✅
               → task checks flag and stops gracefully
               → resources cleaned up properly ✅
 
 */

// Three ways to handle Cancellation

// 1. Task.isCancelled  - Check flag

let task2 = Task {
    for i in 1...1000 {
        // Check before each iteration
        if Task.isCancelled {
            print("Task Cancelled, stopping at \(i)")
            return  // graceful exit
        }
        print(i)
    }
}

task2.cancel()

// 2. try Task.checkCancellation - throws if cancelled

let task3 = Task {
    for i in 1...1000 {
        try Task.checkCancellation()    // Throws CancellationError is Cancelled
        print(i)
    }
}

task3.cancel()

do {
    try await task3.value
} catch is CancellationError {
    print("Task was Cancelled")
} catch {
    print("Other Error : \(error)")
}

// 3. Task.sleep - automatically throws on cancellation

let task4 = Task {
    print("Task started")
    
    try await Task.sleep(nanoseconds: 5_000_000_000)
    print("completed")
}

task4.cancel()

/*
 Timeline:
 0s ── task created
 0s ── print("started") ✅
 0s ── Task.sleep begins (supposed to sleep 5s)
 0s ── task.cancel() called
 0s ── Task.sleep sees cancellation flag
 0s ── Task.sleep throws CancellationError IMMEDIATELY ✅
       does NOT wait 5 seconds ✅
 */

// withTaskCancellationHandler

func heavyWork() async throws -> [Int] {
    var results: [Int] = []
    for i in 1...100 {
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        results.append(i)
        print("Processed \(i)")
    }
    return results
}

let task5 = Task {
    await withTaskCancellationHandler {
        do {
            let results = try await heavyWork()
            print("Completed \(results)")
        } catch is CancellationError {
            print("Work Cancelled")
        } catch {
            print("Error \(error)")
        }
    } onCancel: {
        print("Cancellation Requested")
    }
}

try await Task.sleep(nanoseconds: 5_000_000_000)
task5.cancel()
