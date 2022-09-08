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
    
    @IBOutlet weak var testLabel: UILabel!
    //Table view where products will be displayed
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var tableView: UITableView!
    //SearchBar to query from database
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var productIDLabel: UILabel!
    
    //Array of products
    var products: [String] = []
    //Array of products used to for the table
    var productsForTable: [String] = []
    //Current value beign searched -- corresponds to product ID
    var searchedVal = ""
    
    //Table where products will be stored
    let productsTab = Table("ProductsTab")
    
    //Constants used for storing variables in Table, 'ProductsTab'
    let productID = Expression<String>("productID")
    let values = Expression<String>("values")
    
    //Database connection
    let DB = try? Connection()
    
    var uploadPercentage = 0
    
    var timer = Timer()
    
    override func viewDidLoad() {
        //Loads the view
        super.viewDidLoad()
        /*Initialize table searchbar, delegates and data sources*/
        self.tableView.register(UITableViewCell.self,
                               forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.searchBar.delegate = self
        self.searchBar.showsCancelButton = true

        testLabel.text = "HERE"
        progressBar.progress = 0.0
        progressBar.isHidden = false
        DispatchQueue.global(qos: .userInitiated).async {
            //Read Data from CSV File and upload ito Products Table
            if let data = self.readDataFromCSV(fileName: "prod1M", fileType: "csv") {
                self.csv(data: data)
            } else{
                print("Error loading File")
            }
        }
        tableView.reloadData()
        startTimer()
        //
        

    }
    
    func startTimer() {
        timer.invalidate() // just in case this button is tapped multiple times
       // start the timer
       timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    // called every time interval from the timer
    @objc func timerAction() {
            print("TIMER")
        testLabel.text = String(uploadPercentage)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if uploadPercentage == 100{
            timer.invalidate()
        }
        }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*Function that returns data from csv file in String format*/
    func readDataFromCSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType) else {
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
    
    /*This function takes the string returned by the previous function, converts the string into an iterable value, and then iterates over the individual values to upload them into a SQL database. The function uses bulk insert from SQlite library. Originally I was using the SQLite3 library which did not have functionality for bulk inserts, making hte upload time significantly slower. Function uploads to SQL Database in about 90 seconds on current devices tested. However, if processsor was slower or data set was larger I would look more into concurency andd multi threading. */
    func csv(data: String) {
        //Format the data into an iterable
        let rows = data.components(separatedBy: "\n")
        //Constant that gives the length of the data set
        let dataLength = 100000 //rows.count - 1 //100000 //
        /*Create the table -> table has 2 columns, one for the product ID which is used to order and filter the values,
        and the other which just stores the rest of the values. Originally I had 6 columns, but decreasing the amount of tables made the inserts significantly more efficient */
        try? DB?.run(productsTab.create { t in
                t.column(productID, primaryKey: true)
                t.column(values)
        })
        let docsTrans = try? DB?.prepare("INSERT INTO ProductsTab (productID, values) VALUES (?, ?);")
        try? DB?.transaction(.deferred) {
        /*When working with the SQLite3 library, there was no functionality for bulk inserts so I used the
         function below to perfrom things concurrently. However, doing bulk inserts in SQlite library improved time
         a lo, but kepy old commented code for reference */
        //DispatchQueue.concurrentPerform(iterations: dataLength) { (i) in
         for i in 1...dataLength {
             uploadPercentage = (i * 100)/dataLength
             //progressBar.progress = Float(uploadPercentage/100)
             //progressBar.setProgress(progressBar.progress, animated: true)
             print("Upload Percentage: " + String(uploadPercentage) + "%")
             var row = rows[i]
             let columns = row.components(separatedBy: ",")
             while !row.isEmpty && row.removeFirst() != ","{
             }
             products.append(columns[0] + row)
             let insert = productsTab.insert(productID <- columns[0], values <- row)
             let rowid = try? DB?.run(insert)
          }
        }
        self.productsForTable = products
        
    }
    /*Function to tell the tableview how many total rows there will be*/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productsForTable.count
    }
    /*Function that returns the specific text to be displayed in the tableview cell*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                 for: indexPath) 
        cell.textLabel?.text = productsForTable[indexPath.row]
        cell.textLabel?.font = cell.textLabel?.font.withSize(8)
        return cell
    }
    
    /*Header for the tableview*/
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            
            let label = UILabel()
            label.frame = CGRect.init(x: 16, y: -20, width: headerView.frame.width, height: headerView.frame.height)
            label.text = "Product ID"
            label.font = .systemFont(ofSize: 16)
            headerView.addSubview(label)
            return headerView
        }
    /*Function that gets called everytime the user changes the text value to search for the product id.
     This function first makes a query to the database, and then changes the products array displayed
     that is then displayed by the tableview. */
    func query(){
        //products.removeAll()
        let queryPattern = Expression<String>(searchedVal + "%")
        let query = productsTab.filter(productID.like(queryPattern))
        func startsWith(word: String) -> Bool{
            word.starts(with: searchedVal)
        }
        productsForTable = products.filter(startsWith)
//        for piece in 0...products.count - 1{
//            products[i] = "TESTTT"
//        }
        //let mapRowIterator = try? DB!.prepareRowIterator(query)
//        while let row = try? mapRowIterator?.failableNext() {
//            products.append(String(row[productID]) + row[values])
//        }
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
