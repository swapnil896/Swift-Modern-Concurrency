import UIKit

//MARK: - =========== Q1 ===============
/*
 Q1. Whats wrong with this code
 
 actor BankAccount {
    var bankBalance: Double = 1000.0
    
    func getBankBalance() -> Double {
        return bankBalance
    }
 }
 
 let bankAccount = BankAccount()
 print(bankAccount.getBankBalance())
 */

// A1. Should be wrapped inside Task and call using await
// As getBankBalance() is in isolated domain, and we are calling it from non isolated domain
actor BankAccount {
    var bankBalance: Double = 1000.0
    
    func getBankBalance() -> Double {
        return bankBalance
    }
}

let bankAccount = BankAccount()
Task {
    print(await bankAccount.getBankBalance())
}

//MARK: - =========== Q2 ===============
/* Q2. Whats wrong with this code? */

//actor NetworkManager {
//    var baseURL = "https://example.com"
//    let apikey = "123"
//    
//    nonisolated func getBaseUrl() -> String {
//        return baseURL
//    }
//    
//    nonisolated func getAPIkey() -> String {
//        return apikey
//    }
//}
/*
 
 A. It will give a compile time error for getBaseUrl(), because baseURL is a var which is mutable, so it can be read as well as written from different threads
 eg: Thread A -> Reads baseURL
     Thread B -> Reads baseURL
     Thread C -> at the same time, writes to baseURL
 
 nonisolated means — runs OUTSIDE actor isolation
 */

//MARK: - =========== Q3 ===============
/*
 Q3.
 Three questions:

 1. Will this code compile?
 2. Do you need await inside addOrder to access kitchen.orders and kitchen.chef?
 3. What is the difference between this and calling a method directly on the actor?
 */

actor Kitchen {
    var orders: [String] = []
    var chef: String = "Gordon"
}

func addOrder(_ order: String, to kitchen: isolated Kitchen) {
    kitchen.orders.append(order)
    print(kitchen.chef)
}

/*
 A.
    1. Yes, this code will compile
    2. No, await is not needed inside this because function runs ON the actor
    3. If you write this method inside actor Kitchen and call it, then that method is tied to that paritcular Kitchen instance. And here, you are writing a free function so that it can be called from anywhere and can pass any Kitchen instance to it
 */

//MARK: - =========== Q4 ===============
/*
 Q4.
 Three questions:

 1. ViewModel is @MainActor and APIService is an actor — when fetchItems() calls await APIService.shared.fetch(), which thread does it run on?
 2. After fetch() returns, where does items = result run?
 3. Is this code safe? Why?
 */

@MainActor
class ViewModel {
    var title = ""
    var items: [String] = []
    
    func fetchItems() async {
        let result = await APIService.shared.fetch()
        items = result
    }
}

actor APIService {
    static let shared = APIService()
    
    func fetch() async -> [String] {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return ["Item2", "Item2", "Item3"]
    }
}

/*
 A.
    1. When you create an instance of ViewModel and call fetchItems() on it, it starts execution on Main thread.
       Then, when it goes to this line -> let result = await APIService.shared.fetch(), execution suspends and Main thread is free to use anywhere now.
       fetch() method is then executed in the actor executor, not necessarily on background thread, any thread which is available in the pool
    2. Then items = result again executes on Main thread
    3. Yes
 */

//MARK: - =========== Q5 ===============
/*
 Q5.
 Four questions:

 1. Does processDatabase need await to access db.records and db.identifier?
 2. getIdentifier(_ db: Database) — will this compile? Why?
 3. db.getIdentifier() at the bottom — does it need await?
 4. What is the difference between getIdentifier(_ db: Database) and db.getIdentifier()?
 */

actor Database {
    var records: [String] = []
    let identifier: String = "DB-001"
    
    nonisolated func getIdentifier() -> String {
        return identifier
    }
}

func processDatabase(_ db: isolated Database) async {
    db.records.append("New Record")
    print(db.identifier)
    print(getIdentifier(db))
}

func getIdentifier(_ db: Database) -> String {
    return db.identifier
}

Task {
    let db = Database()
    await processDatabase(db)
    print(db.getIdentifier())
}

/*
 Answers :
    1. No processDatabase dont need await to access records and identifier as it has parameter database as isolated
    2. accessing `let` property, let is IMMUTABLE, safe from any context ✅
    3. nonisolated — no await needed
    4. free function is flexible and reusable, can be called by anyone. whereas optionB is tied to specific Database actor
 */

//===========================================================================================
