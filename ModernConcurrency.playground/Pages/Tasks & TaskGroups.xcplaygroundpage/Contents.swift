//: [Previous](@previous)

import Foundation

//MARK: - =========== Q1 ===============

let task1 = Task {
    print("Task 1 started")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    print("Task 1 completed")
    return "Result 1"
}

let task2 = Task {
    print("Task 2 started")
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    print("Task 2 completed")
    return "Result 2"
}

let result1 = await task1.value
let result2 = await task2.value

print(result1)
print(result2)

/*
 Four questions:

 1. Do task1 and task2 run sequentially or concurrently?
 2. What is the order of print statements?
 3. task2 finishes in 1 second, task1 finishes in 2 seconds — does result2 wait for task1 to finish before printing?
 4. What is the total execution time — 3 seconds or 2 seconds?
 
 Answers :
 1. They run concurrently. task1 starts immediately, also task2 starts immediately
 
 2. "Task 1 started"
    "Task 2 started"
    "Task 2 completed"
    "Task 1 completed"
    "Result 1"
    "Result 2"
 
 3. let result1 = await task1.value   // ⚠️ waits for task1 first
    let result2 = await task2.value   // only reached after task1 done
 
    // these two lines are SEQUENTIAL
    // even though tasks run concurrently
    let result1 = await task1.value   // blocks here until task1 done (2s)
    let result2 = await task2.value   // only starts waiting after result1 ready
 
    // if you want BOTH concurrently use async let
    async let result1 = doWork1()    // ✅ concurrent
    async let result2 = doWork2()    // ✅ concurrent
    let (r1, r2) = await (result1, result2)  // collect both
 
 4. 2 seconds
 */

//MARK: - =========== Q2 ===============

func fetchUserData() async throws -> String {
    try await Task.sleep(nanoseconds: 2_000_000_000)
    return "User Data"
}

func fetchPosts() async throws -> String {
    try await Task.sleep(nanoseconds: 2_000_000_000)
    return "Posts"
}

func fetchNotifications() async throws -> String {
    try await Task.sleep(nanoseconds: 2_000_000_000)
    return "Notifications"
}

func loadDashboardApproachA() async throws {
    let userData = try await fetchUserData()
    print(userData)
    let posts = try await fetchPosts()
    print(posts)
    let notifications = try await fetchNotifications()
    print(notifications)
    
    print(userData, posts, notifications)
}

func loadDashboardApproachB() async throws {
    async let userData = fetchUserData()
    async let posts = fetchPosts()
    async let notifications = fetchNotifications()
    
    let (u, p, n) = try await (userData, posts, notifications)
    print(u, p, n)
}

try await loadDashboardApproachA()
try await loadDashboardApproachB()

/*
 Four questions:

 1. What is the difference between Approach A and Approach B?
 2. If each function takes 2 seconds — what is total time for Approach A and Approach B?
 3. What does async let do differently than regular let?
 4. Which approach is better and when would you use Approach A over Approach B?
 
 Answers :
 
 1. Approach A is sequential, that is fetchPosts() will wait for the result of fetchUserData(), and fetchNotifications() will wait for the result of its previous task fetchPosts().
    Approach B is parallel, that is all 3 tasks start simultaneously, doesnt wait for any previous tasks completion
 
 2. Approach A takes 2+2+2=6 secs, Approach B takes 2 secs
 
 3. regular let — evaluates immediately, sequential. async let — starts immediately, suspends later
 
 4. Approach A is better when a task is dependent on the result of previous task.
    Approach B is better when tasks are independent, and need to run parallely
 */

// MARK: =========== TaskGroup ===============

/*
 TaskGroup - Run multiple tasks concurrently
             collect their results
             wait for ALL to complete
 */

await withTaskGroup(of: String.self) { group in
    group.addTask { return "Result1" }
    group.addTask { return "Result2" }
    group.addTask { return "Result3" }
    // waits for all tasks
}

// Collecting results

await withTaskGroup(of: String.self) { group in
    group.addTask {
        print("Starting Task 1 in group")
        return "Result 1"
    }
    group.addTask {
        print("Starting Task 2 in group")
        return "Result 2"
    }
    group.addTask {
        print("Starting Task 3 in group")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return "Result 3"
    }
    
    // Collecting results - 2 ways
    // Way 1 - for await loop
    for await result in group {
        print(result)
    }
    
    // Way 2 - group.next()
    while let result = await group.next() {
        print(result)
    }
}

// Results come in completion order

await withTaskGroup(of: String.self) { group in
    group.addTask {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        return "Slow task"
    }
    
    group.addTask {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "Fast task"
    }
    
    group.addTask {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return "Medium task"
    }
    
    for await result in group {
        print(result)
        // Prints in completion order
        // Fast task -> 1s
        // Medium task -> 2s
        // Slow task -> 3s
        // Not in addition order
    }
}

// Collecting into Array
func fetchUser(id: Int) async -> String {
    if id == 3 {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    return "User \(id)"
}

func fetchAllUsers(ids: [Int]) async -> [String] {
    await withTaskGroup(of: String.self) { group in
        for id in ids {
            group.addTask {
                await fetchUser(id: id)
            }
        }
        
        var users: [String] = []
        for await user in group {
            users.append(user)
        }
        return users
    }
}

// Results come in completion order, not addition order
// To maintain original order, use tuple with index

func fetchAllUsersOriginalOrder(ids: [Int]) async -> [String] {
    await withTaskGroup(of: (Int, String).self) { group in
        for (index, id) in ids.enumerated() {
            group.addTask {
                let user = await fetchUser(id: id)
                return (index, user)
            }
        }
        
        var users: [(Int, String)] = []
        for await result in group {
            users.append(result)
        }
        
        return users
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }
    }
}

print(await fetchAllUsers(ids: [1, 2, 3, 4, 5, 6]))
print(await fetchAllUsersOriginalOrder(ids: [1, 2, 3, 4, 5, 6]))

// withTaskGroup vs withThrowingTaskGroup
func downloadImage() async throws -> String {
    return "Image"
    //throw URLError(.badURL)
}

// withTaskGroup - no throwing
await withTaskGroup(of: String?.self) { group in
    group.addTask {
        try? await downloadImage()  // error converted to nil
    }
    
    for await result in group {
        if let image = result {
            print(image)
        } else {
            print("Null")
        }
    }
}

try await withThrowingTaskGroup(of: String.self) { group in
    group.addTask {
        try await downloadImage()
    }
    
    for try await result in group {
        print(result)
    }
}

// Error handling in withThrowingTaskGroup
func downloadImage(id: Int) async throws -> String {
    if id == 3 {
        throw URLError(.badURL)
    }
    return "Image \(id)"
}

// when ONE task throws:
func imageDownloader() async throws -> [String] {
    try await withThrowingTaskGroup(of: String.self) { group in
        group.addTask { try await downloadImage(id: 1) }
        group.addTask { try await downloadImage(id: 2) }
        group.addTask { try await downloadImage(id: 3) }
        group.addTask { try await downloadImage(id: 4) }
        group.addTask { try await downloadImage(id: 5) }
        group.addTask { try await downloadImage(id: 6) }
        
        var images: [String] = []
        for try await result in group {
            images.append(result)
            // when id 3 throws:
            // 1. error propagates to withThrowingTaskGroup ✅
            // 2. ALL other tasks cancelled automatically ✅
            // 3. error thrown to caller ✅
            // 4. remaining results discarded ✅
        }
        return images
    }
}

do {
    let images = try await imageDownloader()
    print(images)
} catch {
    print(error)
}

// withTaskGroup Error Handling

// try? converts error to nil -> No crash
func imageDownloader2() async -> [String] {
    await withTaskGroup(of: String?.self) { group in
        group.addTask { try? await downloadImage(id: 1) }   // "Image 1" ✅
        group.addTask { try? await downloadImage(id: 2) }   // "Image 1" ✅
        group.addTask { try? await downloadImage(id: 3) }   // nil (error converted) ✅
        group.addTask { try? await downloadImage(id: 4) }   // "Image 1" ✅
        group.addTask { try? await downloadImage(id: 5) }   // "Image 1" ✅
        
        var images: [String] = []
        for await result in group {
            if let image = result {
                images.append(image)    // only successful results added
            }
            // nil results silently skipped ✅
            // other tasks NOT cancelled ✅
            // all tasks complete ✅
        }
        return images
    }
}

print(await imageDownloader2())

// Real world example

func downloadImages(ids: [Int]) async -> [String] {
    await withTaskGroup(of: String?.self) { group in
        for id in ids {
            group.addTask {
                do {
                    return try await downloadImage(id: id)
                } catch {
                    print("Failed to download image - \(id): \(error)")
                    return nil
                }
            }
        }
        
        var images: [String] = []
        for await result in group {
            if let image = result {
                images.append(image)
            }
        }
        return images
    }
}

let images = await downloadImages(ids: [1, 2, 3, 4, 5, 6])
print(images)

/*
 withTaskGroup
   └─ no throwing
   └─ use try? to handle errors
   └─ failed task returns nil
   └─ other tasks continue ✅
   └─ good for: download all, skip failed

 withThrowingTaskGroup
   └─ can throw
   └─ one failure cancels ALL tasks
   └─ error propagates to caller
   └─ good for: all or nothing operations

 Both:
   └─ run tasks concurrently ✅
   └─ collect results via for await ✅
   └─ results in completion order ✅
   └─ structured lifecycle ✅
 */


