import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    
    let vendineMachine: VendingMachine
    var currentSelection: VendingSelection?
    
    required init?(coder aDecoder: NSCoder) {
        do {
            let dictionary = try PlistConventer.dictionary(fromFile: "VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInvetory(fromDictionary: dictionary)
            self.vendineMachine = FoodVendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionViewCells()
        
        updateDisplayWith(balance: vendineMachine.amountDeposited, price: 0.0, totalPrice: 0.0, itemQuantity: 1)
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Vending Machine
    
    @IBAction func purchase() {
        if let currentSelection = currentSelection {
            do {
                try vendineMachine.vend(selection: currentSelection, quantity: Int(quantityStepper.value))
                updateDisplayWith(balance: vendineMachine.amountDeposited, price: 0.0, totalPrice: 0.0, itemQuantity: 1)
            } catch VendingMachineError.outOfStock {
                showAlert(title: "Out of Stock", message: "This item is unavalable. Please make another selection")
            } catch VendingMachineError.invalidSelection {
                showAlert(title: "Invalid Selection", message: "Please make another selection")
            } catch VendingMachineError.insufficientFunds(let required) {
                let message = "You need $\(required) to complete the transaction"
                showAlert(title: "Insufficient Funds", message: message)
            } catch let error {
                fatalError("\(error)")
            }
            // deselecting item
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                collectionView.deselectItem(at: indexPath, animated: true)
                self.currentSelection = nil
                updateCell(having: indexPath, selected: false)
            }
        } else {
            // FIXME: Alert user about no selection
            showAlert(title: "No Selection", message: "Please select item before making a purchase")
        }
    }
    
    // helper method
    func updateDisplayWith(balance: Double? = nil, price: Double? = nil, totalPrice: Double? = nil, itemQuantity: Int? = nil) {
        
        if let balanceValue = balance {
            balanceLabel.text = "$\(balanceValue)"
        }
        
        if let priceValue = price {
            priceLabel.text = "$\(priceValue)"
        }
        
        if let totalPriceValue = totalPrice {
            totalLabel.text = "$\(totalPriceValue)"
        }
        
        if let quantityValue = itemQuantity {
            quantityLabel.text = "\(quantityValue )"
        }
    }
    
    func updateTotalPrice(for item: VendingItem) {
        let totalPrice = item.price * quantityStepper.value
        updateDisplayWith(totalPrice: totalPrice)
    }
    
    @IBAction func updateQuantity(_ sender: UIStepper) {
        
        let quantity = Int(quantityStepper.value)
        updateDisplayWith(itemQuantity: quantity)
        
        if let currentSelection = currentSelection {
            if let item = vendineMachine.item(forSelection: currentSelection) {
                updateTotalPrice(for: item)
            }
        }
    }
    
    @IBAction func depositFunds() {
        vendineMachine.deposit(5.0)
        updateDisplayWith(balance: vendineMachine.amountDeposited)
    }
   
    func showAlert(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: dismissAlert)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // this function type matches handler type of UIAlertAction init
    func dismissAlert(sender: UIAlertAction) -> Void {
        updateDisplayWith(price: 0.0, totalPrice: 0.0, itemQuantity: 1)
    }
    
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendineMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        
        let item = vendineMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
        
        quantityStepper.value = 1
        updateDisplayWith(totalPrice: 0.0, itemQuantity: 1)
        
        currentSelection = vendineMachine.selection[indexPath.row]
        if let currentSelection = currentSelection {
            if let item = vendineMachine.item(forSelection: currentSelection) {
                priceLabel.text = "$\(item.price)"
                totalLabel.text = "$\(item.price * quantityStepper.value)"
                let totalPrice = item.price * quantityStepper.value
                updateDisplayWith(price: item.price, totalPrice: totalPrice)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
}

