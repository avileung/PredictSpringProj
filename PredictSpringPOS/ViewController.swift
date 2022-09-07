//
//  ViewController.swift
//  PredictSpringPOS
//
//  Created by Avi L on 9/4/22.
//

import UIKit
import SQLite3
import SQLite
import Foundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var productIDLabel: UILabel!
    
    var products: [String] = []
    
    var searching = false
    
    var searchedVal = ""
    
    var db: OpaquePointer?
    
    let productsTab = Table("ProductsTab")
    
    let productID = Expression<Int64>("productID")
    let titleVal = Expression<String?>("title")
    let listPrice = Expression<Double>("listPrice")
    let salesPrice = Expression<Double>("salesPrice")
    let color = Expression<String?>("color")
    let size = Expression<String>("size")
    
    let DB = try? Connection()
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    


    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                 for: indexPath) //as! ProductCell
//        var cell: ProductCell
//        if let dequeuedcell = tableView.dequeueReusableCell(withIdentifier: "Cell",
//                                                        for: indexPath) as? ProductCell {
//                    cell = dequeuedcell
//                } else {
//                    cell = ProductCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "Cell")
//                }
        
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.tableView.register(ProductCell.self,
                               forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.searchBar.delegate = self
        
        self.searchBar.showsCancelButton = true
        
        //the database file
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("ProductDatabase.sqlite")
 
//        //opening the database
//        let rc = sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil)
//
//        guard rc == SQLITE_OK else {        //sqlite3_open(fileURL.path, &db)
//            print("error opening database")
//            sqlite3_close(db)
//            db = nil
//            return
//        }
//
//        //Delete table if previously created
//        if sqlite3_exec(db, "DROP TABLE IF EXISTS Products;", nil, nil, nil) != SQLITE_OK {
//            let errmsg = String(cString: sqlite3_errmsg(db)!)
//            print("error deleting table: \(errmsg)")
//        }
//
//        //creating table
//        if sqlite3_exec(db, "CREATE TABLE Products (productID INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, listPrice FLOAT, salesPrice FLOAT, color TEXT, size TEXT)", nil, nil, nil) != SQLITE_OK {
//            let errmsg = String(cString: sqlite3_errmsg(db)!)
//            print("error creating table: \(errmsg)")
//        }
        
        
        //Read Data from CSV File and upload ito Products Table
        if let data = readDataFromCSV(fileName: "prod1M", fileType: "csv") {
            let csvRows = csv(data: data, db: db)
        } else{
            print("Error loading File")
        }
        


    }
    
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
    /*Function uploads to SQL Database in less than 30 seconds on currett devices tested. However, if processsor was slower or data sett was larger I would look more inot concurency andd multi threading.  */
    func csv(data: String, db: OpaquePointer?) {
        var result: [String] = []
        let rows = data.components(separatedBy: "\n")
        let dataLength = 10000 //rows.count - 1 //
//        try db.transaction {
//            let rowid = try db.run(users.insert(email <- "betty@icloud.com"))
//            try db.run(users.insert(email <- "cathy@icloud.com", managerId <- rowid))
//        }
        //DispatchQueue.concurrentPerform(iterations: dataLength) { (i) in
        //for i in 1..<dataLength {
        //TODO currently a print statement, might want to also display in UI
        
        //To do, should address case where canot cast properly
        //Inserting columnns into table as we iterate for efficiency, so that do not have
        //to go back over
        //insert(db: db, productID: Int(columns[0]) ?? 0, title: columns[1], listPrice: Double(columns[2]) ?? 0.0, salesPrice: Double(columns[3]) ?? 0.0, color: columns[4], size: columns[5])
//        let DB = try? Connection("ProductDatabaseTest.sqlite")
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!

        

        
        
        
        

        try? DB?.run(productsTab.create { t in
                t.column(productID, primaryKey: true)
                t.column(titleVal)
                t.column(listPrice)
                t.column(salesPrice)
                t.column(color)
                t.column(size)
            })
        let docsTrans = try? DB?.prepare("INSERT INTO ProductsTab (productID, title, listPrice, salesPrice, color, size) VALUES (?, ?, ?, ?, ?, ?);")
            
        try? DB?.transaction(.deferred) {
          //DispatchQueue.concurrentPerform(iterations: dataLength) { (i) in
         for i in 1...dataLength {

     
             let uploadPercentage = (i * 100)/dataLength
             print("Upload Percentage: " + String(uploadPercentage) + "%", i, dataLength)
             let row = rows[i]
             //TODO Malloc issue with array
             products.append(row)
             let columns = row.components(separatedBy: ",")
             //try docsTrans?.run(Int(columns[0]) ?? 0, columns[1], Double(columns[2]) ?? 0.0, Double(columns[3]) ?? 0.0, columns[4], columns[5])
             
             let insert = productsTab.insert(productID <- Int64(columns[0]) ?? 0, titleVal <- columns[1], listPrice <- Double(columns[2]) ?? 0.0, salesPrice <- Double(columns[3]) ?? 0.0, color <- columns[4], size <- columns[5])
             let rowid = try? DB?.run(insert)
          }
            
        }
        
//        let insert = productsTab.insert(productID <- 5, title <- "alice@mac.com", listPrice <- 5.5, salesPrice <- 5.5, color <- "dsf", size <- "FDS")
//            let rowid = try? DB?.run(insert)
        
//        for i in 1..<dataLength {
//            //TODO currently a print statement, might want to also display in UI
//            let uploadPercentage = (i * 100)/dataLength
//            print("Upload Percentage: " + String(uploadPercentage) + "%", i, dataLength)
//            let row = rows[i]
//            products.append(row)
//            let columns = row.components(separatedBy: ",")
//            //To do, should address case where canot cast properly
//            //Inserting columnns into table as we iterate for efficiency, so that do not have
//            //to go back over
//            insert(db: db, productID: Int(columns[0]) ?? 0, title: columns[1], listPrice: Double(columns[2]) ?? 0.0, salesPrice: Double(columns[3]) ?? 0.0, color: columns[4], size: columns[5])
//        }
    }
    
    func insert(db: OpaquePointer?, productID: Int, title: String, listPrice: Double, salesPrice: Double, color: String, size: String) {
        
      let insertStatementString = "INSERT INTO Products (productID, title, listPrice, salesPrice, color, size) VALUES (?, ?, ?, ?, ?, ?);"
      var insertStatement: OpaquePointer?
      // 1
      if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) ==
          SQLITE_OK {
        // 2
        sqlite3_bind_int64(insertStatement, 1, sqlite3_int64(productID))
        sqlite3_bind_text(insertStatement, 2, title,-1, nil)
        sqlite3_bind_double(insertStatement, 3, listPrice)
        sqlite3_bind_double(insertStatement, 4, salesPrice)
        sqlite3_bind_text(insertStatement, 5, color,-1, nil)
        sqlite3_bind_text(insertStatement, 6, size, -1, nil)
        // 4
        if sqlite3_step(insertStatement) == SQLITE_DONE {
          print("\nSuccessfully inserted row.")
        } else {
          print("\nCould not insert row.")
        }
      } else {
        print("\nINSERT statement is not prepared.")
      }
      // 5
      sqlite3_finalize(insertStatement)
        
    }

     
    func query() {
        products.removeAll()
      var queryStatement: OpaquePointer?
      // 1
        var queryStatementString: String
        if searchedVal == ""{
            queryStatementString = "SELECT * FROM Products"
        }else{
            //name like "Mr.%"
            queryStatementString = "SELECT * FROM Products WHERE productID LIKE '" + searchedVal + "%'"
        }
        
      if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) ==
          SQLITE_OK {
        // 2
        while sqlite3_step(queryStatement) == SQLITE_ROW {
          // 3
          var retrievedString = ""
          retrievedString += String(sqlite3_column_int64(queryStatement, 0))
            retrievedString += String(cString: sqlite3_column_text(queryStatement, 1))
            retrievedString += String(sqlite3_column_double(queryStatement, 2))
            retrievedString += String(sqlite3_column_double(queryStatement, 3))
            retrievedString += String(cString: sqlite3_column_text(queryStatement, 4))
            retrievedString += String(cString: sqlite3_column_text(queryStatement, 5))
            products.append(retrievedString)
          
      } } else {
          // 6
        let errorMessage = String(cString: sqlite3_errmsg(db))
          print("\nQuery is not prepared \(errorMessage)")
      }
      // 7
      sqlite3_finalize(queryStatement)
        tableView.reloadData()
    }
    
    func query2(){
        products.removeAll()
        let query = productsTab.select(productsTab[*])
        //products = query
       // for piece in try? DB?.prepare(query){
            //products.append(
        //}
        let mapRowIterator = try? DB!.prepareRowIterator(query)
        while let row = try? mapRowIterator?.failableNext() {
                // Handle row
            print(row[productID], row[listPrice], row[titleVal], row[salesPrice], row[color], row[size])
            //let str = row[productID] + row[titleVal] + String(row[listPrice])
            //let str2 = String(row[salesPrice]) + row[color] + row[size]
            //var retrievedString = ""
            //var fPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer.alloc(1)
            //retrievedString += String(sqlite3_column_int64(&row, 0))
            //if let name = row[0] as? String { products.append(name) }
            products.append(row[titleVal]! + row[color]! + row[size])
            //"title")
//            let listPrice = Expression<Double>("listPrice")
//            let salesPrice = Expression<Double>("salesPrice")
//            let color = Expression<String?>("color")
//            let size = Expression<String>("size")
            //products.append( String(row[productID])) //+ row[1] + String(row[2]))// + String(row[3]) + row[4] + row[5])
            //products.append("\String(row[0])\(row[1]) + String(row[2]) + String(row[3]) + row[4] + row[5])
            }
        tableView.reloadData()
        //let query = productsTab.filter(productID = searchedVal)    //select("*")
            //.filter(productID = searchedVal)
                         //.order(email.desc, name) // ORDER BY "email" DESC, "name"
                            
    }


    
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("SEARCHED")
        searchedVal = searchText
        query2()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("CANNCELLED")
        searchBar.text = ""
    }
}
