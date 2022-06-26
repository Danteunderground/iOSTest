//
//  TableViewController.swift
//  ShoppingList
//
//  Created by Luiz Valdemar on 25/06/22.
//

import UIKit
import Firebase

class TableViewController: UITableViewController {
    
    let shoppingListCollection = "shoppingList"
    var shoppingList: [ShoppingItem] = []
    
    lazy var firestore: Firestore = {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        // settings.areTimestampInSnapshotsEnabled = true
        let firestore = Firestore.firestore()
        firestore.settings = settings
        return firestore
    }()
    
    var firestoreListener: ListenerRegistration!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()

    }
    
    func loadItems(){
        firestoreListener = firestore.collection(shoppingListCollection).order(by: "name").addSnapshotListener(includeMetadataChanges: true, listener: {
            (snapshot, error) in
            if error != nil {
                print("Firestore error: ", error!)
            } else {
                guard let snapshot = snapshot else {return}
                print("Total de mudanças:", snapshot.documentChanges.count)
                
                if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                    self.showItems(snapshot: snapshot)
                }
            }
        })
    } // Fim do metodo loadItems
    
    func showItems(snapshot: QuerySnapshot){
        shoppingList.removeAll()
        
        for document in snapshot.documents {
            let data = document.data()
            let name = data["name"] as! String
            let quantity = data["quantity"] as! Int
            let shoppingItem = ShoppingItem(name: name, quantity: quantity, id: document.documentID)
            shoppingList.append(shoppingItem)
        }
        tableView.reloadData()
    }
    
    func showAlert(item: ShoppingItem?){
        let alert = UIAlertController(title: "Produto", message: "Entre com as informacoes do produto", preferredStyle: .alert)
        
        alert.addTextField{(textField) in
            textField.placeholder = "Nome"
            textField.text = item?.name
        }
        alert.addTextField{(textField) in
            textField.placeholder = "Quantidade"
            textField.text = "\(item?.quantity ?? 1)"
            textField.keyboardType = .numberPad
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) {(_) in
            guard let name = alert.textFields?.first?.text,
                  let quantity = alert.textFields?.first?.text else {return}
            
            let data: [String: Any] = [
                "name" : name,
                "quantity" : Int(quantity)! // ?? 0 - removido
            ]
            
            if let item = item {
                self.firestore.collection(self.shoppingListCollection).document(item.id).updateData(data)
            } else{
                self.firestore.collection(self.shoppingListCollection).addDocument(data: data)
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addItem(_ sender: Any) {
        showAlert(item: nil)
    }
    
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return shoppingList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let shoppingItem = shoppingList[indexPath.row]
        cell.textLabel?.text = shoppingItem.name
        cell.detailTextLabel?.text = "\(shoppingItem.quantity)"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let shoppingItem = shoppingList[indexPath.row]
        showAlert(item: shoppingItem)
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let shoppingItem = shoppingList[indexPath.row]
            firestore.collection(shoppingListCollection).document(shoppingItem.id).delete()
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
