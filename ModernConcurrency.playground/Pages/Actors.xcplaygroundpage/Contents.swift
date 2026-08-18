//: [Previous](@previous)

import Foundation

//MARK: - =========== Q1 ===============
actor BankAccount {
    var balance = 0.0
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) {
        balance -= amount
    }
    
    func transfer(_ amount: Double, to otherAccount: BankAccount) async {
        balance -= amount
        await otherAccount.deposit(amount)
    }
    
    // Solution for q3, q4
//    func transfer(_ amount: Double, to otherAccount: BankAccount) async {
//        guard balance >= amount else {
//            print("Insufficient funds")
//            return
//        }
//        
//        balance -= amount
//        await otherAccount.deposit(amount)
//        
//        print("Transfer complete, balance after transfer = \(balance)")
//    }
}

let account1 = BankAccount()
let account2 = BankAccount()

Task { await account1.deposit(1000) }
Task { await account1.withdraw(500) }
Task {
    await account1.transfer(300, to: account2)
}

/*
 Four questions:

    1. Are deposit and withdraw safe from data races? Why?
    2. In transfer function — why does other.deposit need await but balance -= amount does not?
    3. What happens to account1.balance during await other.deposit(amount) — is it locked or accessible?
    4. Can another task modify account1.balance while transfer is suspended at await other.deposit?
 
 Answers :
    1. Yes, they are safe from data races because they are inside actor which prevents parallel read write (serialized access)
 
    2.
    func transfer(amount: Double, to other: BankAccount) async {
        balance -= amount        // same actor, no await ✅
        await other.deposit()    // different actor, needs await ✅
    }
 
    3 & 4. It is accessible
        Initial balance = 0

        Task 1: deposit(1000)
            └─ balance = 0 + 1000 = 1000

        Task 2: withdraw(500)
            └─ balance = 1000 - 500 = 500

        Task 3: transfer(200) starts
            └─ balance -= 200 (balance = 300)
            └─ hits await ──────────────────> SUSPENDED
                                    actor is FREE ⚠️

        Some other Task: withdraw(300) comes in
            └─ actor is free!
            └─ balance = 300 - 300 = 0  ← happens during suspension!

        Task 3: resumes
            └─ transfer completes
            └─ balance = 0 ← unexpected! ⚠️
 
 Actor is FREE during await
 State CAN change during suspension
 balance was 300 before await
 balance could be anything after await
 */

//MARK: - =========== Q2 ===============

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
