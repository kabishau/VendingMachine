import Foundation

enum VendingSelection: String {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
}

protocol VendingItem {
    var quantity: Int { get set }
    var price: Double { get }
}

protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: VendingItem])
    func vend(_ quantity: Int, _ selection: VendingSelection) throws
    func deposit(_ amount: Double)
}

struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

enum InventoryError: Error {
    case invalidResourse
    case conversionFailure
    case invalidSelection
}

// object that converts data from plist to dictionary
class PlistConventer {
    // static method because we don't need this data once conversion is done
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw InventoryError.invalidResourse
        }
        // the best option is to use NSDictionary with contentsOffile method
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            throw InventoryError.conversionFailure
        }
        return dictionary
    }
}

class InventoryUnarchiver {
    static func vendingInvetory(fromDictionary dictionary: [String: AnyObject]) throws -> [VendingSelection: VendingItem] {
        
        var inventory: [VendingSelection: VendingItem] = [:]
        
        for (key, value) in dictionary {
            if let itemDictionary = value as? [String: Any], let price = itemDictionary["price"] as? Double, let quantity = itemDictionary["quantity"] as? Int {
                
                let item = Item(price: price, quantity: quantity)
                
                guard let selection = VendingSelection(rawValue: key) else {
                    throw InventoryError.invalidSelection
                }
                
                inventory.updateValue(item, forKey: selection)
            }
        }
        
        return inventory
    }
}

// object that converts data from dictionary to inventory Vending Item

class FoodVendingMachine: VendingMachine {
    
    let selection: [VendingSelection] = [.soda, .dietSoda, .chips,. cookie, .sandwich, .wrap, .candyBar, .popTart, .water, .fruitJuice, .sportsDrink, .gum]
    var inventory: [VendingSelection : VendingItem]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : VendingItem]) {
        self.inventory = inventory
    }
    
    func vend(_ quantity: Int, _ selection: VendingSelection) throws {
        
    }
    func deposit(_ amount: Double) {
        
    }
}
