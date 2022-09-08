//
//  ViewController.swift
//  PredictSpringPOS
//
//  Created by Avi L on 9/4/22.
//

import UIKit
/*Originally used Sqlite3, but then found SQlite library to be more efficient as there is functionality for bulk inserts.
 Bulk inserts significantly reduce runtime*/
import SQLite3
import SQLite
import Foundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //Table view where products will be displayed
    @IBOutlet weak var tableView: UITableView!
    //SearchBar to query from database
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var productIDLabel: UILabel!
    
    //Array of products used to for the table
    var products: [String] = []
    //Current value beign searched -- corresponds to product ID
    var searchedVal = ""
    
    //Table where products will be stored
    let productsTab = Table("ProductsTab")
    
    //Constants used for storing variables in Table, 'ProductsTab'
    let productID = Expression<String>("productID")
    let size = Expression<String>("size")
    
    //Database connection
    let DB = try? Connection()
    
    override func viewDidLoad() {
        //Loads the view
        super.viewDidLoad()
        /*Initialize table searchbar, delegates and data sources*/
        self.tableView.register(ProductCell.self,
                               forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.searchBar.delegate = self
        self.searchBar.showsCancelButton = true
        

        //Read Data from CSV File and upload ito Products Table
        if let data = readDataFromCSV(fileName: "prod1M", fileType: "csv") {
            let csvRows = csv(data: data)
        } else{
            print("Error loading File")
        }
    }
    /*Function that returns data from csv file in String format*/
    func readDataFromCSV(fileName:String, fileType: String)-> String!{
            guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
                else {
                    return nil
            }
            do {
                var contents = try String(contentsOfFile: filepath, encoding: .utf8)
                return contents
            } catch {
                print("File Read Error for file \(filepath)")
                return nil
            }
        }
    
    /*Function uploads to SQL Database in about 90 seconds on currett devices tested. However, if processsor was slower or data sett was larger I would look more inot concurency andd multi threading.  */
    func csv(data: String) {
        var result: [String] = []
        let rows = data.components(separatedBy: "\n")
        let dataLength = 10000 //rows.count - 1 //
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        try? DB?.run(productsTab.create { t in
                t.column(productID, primaryKey: true)
                t.column(size)
            })
        let docsTrans = try? DB?.prepare("INSERT INTO ProductsTab (productID, size) VALUES (?, ?);")
        try? DB?.transaction(.deferred) {
          //DispatchQueue.concurrentPerform(iterations: dataLength) { (i) in
         for i in 1...dataLength {
             let uploadPercentage = (i * 100)/dataLength
             print("Upload Percentage: " + String(uploadPercentage) + "%")
             var row = rows[i]
             products.append(row)
             let columns = row.components(separatedBy: ",")
             while !row.isEmpty && row.removeFirst() != ","{
             }
             let insert = productsTab.insert(productID <- columns[0], size <- row)
             let rowid = try? DB?.run(insert)
          }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    


    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                 for: indexPath) //as! ProductCell
        let test = ["fdsfdss", "fsfdsd", "fdsfd"]
        cell.textLabel?.text = products[indexPath.row]
        cell.textLabel?.font = cell.textLabel?.font.withSize(8)
        //cell.detailTextLabel?.text = products[indexPath.row]
        return cell
    }
    
    // Create a standard header that includes the returned text.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            
            let label = UILabel()
            label.frame = CGRect.init(x: 0, y: 0, width: headerView.frame.width, height: headerView.frame.height)
            label.text = "Notification Times"
            label.font = .systemFont(ofSize: 16)
            //label.textColor = .yellow
            
            headerView.addSubview(label)
            
            return headerView
        }
    
    func query(){
        products.removeAll()
        let queryPattern = Expression<String>(searchedVal + "%")
        let query = productsTab.filter(productID.like(queryPattern))
        let mapRowIterator = try? DB!.prepareRowIterator(query)
        while let row = try? mapRowIterator?.failableNext() {
            products.append(String(row[productID]) + row[size])
            }
        tableView.reloadData()
    }


    
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchedVal = searchText
        query()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchedVal = ""
        query()
    }
}
