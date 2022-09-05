//
//  ViewController.swift
//  PredictSpringPOS
//
//  Created by Avi L on 9/4/22.
//

import UIKit
import SQLite3
import Foundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //the database file
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("ProductDatabase.sqlite")
 
        //opening the database
        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return
        }
        
        
        //Delete table if previously created
        if sqlite3_exec(db, "DROP TABLE Products;", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error deleting table: \(errmsg)")
        }
 
        //creating table
        if sqlite3_exec(db, "CREATE TABLE Products (productID INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, listPrice FLOAT, salesPrice FLOAT, color TEXT, size TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
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
    
    func csv(data: String, db: OpaquePointer?) {
        var result: [String] = []
        var rows = data.components(separatedBy: "\n")
        rows.removeFirst()
        for row in rows {
            let columns = row.components(separatedBy: ",")
            //To do, should address case where canot cast properly
            insert(db: db, productID: Int(columns[0]) ?? 0, title: columns[1], listPrice: Double(columns[2]) ?? 0.0, salesPrice: Double(columns[3]) ?? 0.0, color: columns[4], size: columns[5])
        }
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


    
}

