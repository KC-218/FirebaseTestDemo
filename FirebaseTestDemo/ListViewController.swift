//
//  ListViewController.swift
//  FirebaseTestDemo
//
//  Created by Bruce Chen on 2018/4/18.
//  Copyright © 2018年 bruce. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ListViewController: UIViewController {

    //畫面
    @IBOutlet weak var tableView: UITableView!
    
    //變數物件
    var ref: DatabaseReference! //關聯DB物件
    var items: [GroceryItem] = [] //物品陣列
    var currentUser: User? //當前使用者
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference(withPath: "groceryItems") //拿到DB資料
        
        ref.queryOrdered(byChild: "time").observe(.value, with: { snapshot in //依照時間排序取出
            
            var newItems: [GroceryItem] = []
            
            for item in snapshot.children {
                
                let groceryItem = GroceryItem(snapshot: item as! DataSnapshot)
                newItems.append(groceryItem)
            }
            
            self.items = newItems //把取出的Item陣列設為自定義的陣列
            self.tableView.reloadData() //重整顯示在View上
        })
        
        firebaseCheckState() //取得現在登入的使用者
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: 按鈕相關事件

    @IBAction func addBtnClicked(_ sender: Any) {
      
        let alert = UIAlertController(title: "請輸入購買物品", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "您想買什麼？"
        }
        
        let okAction = UIAlertAction(title: "儲存", style: .default) { (alertVC) in
            
            guard let textField = alert.textFields?.first,let text = textField.text else { return }
            
            //新增當下時間的格式轉換
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyy/MM/dd/ hh:mm:ss"
            let timeZone = TimeZone(identifier: "UTC")
            dateFormatter.timeZone = timeZone
            let timeString = dateFormatter.string(from: Date())
            
            //準備資料物件
            let groceryItem = GroceryItem(name: text,
                                          addedByUser: (self.currentUser?.email)!,
                                          completed: false,
                                          time:timeString)
            
            let groceryItemRef = self.ref.child(text.lowercased())
            
            groceryItemRef.setValue(groceryItem.toAnyObject())
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func editBtnClicked(_ sender: Any) {

        //切換編輯模式
        if tableView.isEditing {
            tableView.isEditing = false //變回正常模式
            navigationItem.leftBarButtonItem?.title = "編輯"
        }else{
            tableView.isEditing = true //變成編輯模式
            navigationItem.leftBarButtonItem?.title = "完成"
        }
    }
    
    //MARK: Firebase相關事件
    
    func firebaseCheckState() {
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            
            guard user != nil else { return }
            self.currentUser = User(authData: auth) //取得現在登入使用者
        }
    }
    
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].name
        cell.detailTextLabel?.text = items[indexPath.row].addedByUser + " , " + items[indexPath.row].time
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing == false { //在非編輯狀態
            self.performSegue(withIdentifier: "toDetailView", sender: self) //跳轉到下一頁
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //設定可以進入編輯模式
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        if tableView.isEditing { //設定編輯模式為刪除模式
            return .delete
        }
        
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        //設定點擊側滑按鈕刪除
        if editingStyle == .delete {
            let groceryItem = items[indexPath.row]
            groceryItem.ref?.removeValue()
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        //設定側滑刪除
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            let groceryItem = self.items[indexPath.row]
            groceryItem.ref?.removeValue()
        }
        
        return [delete]
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toDetailView" {
            
            if let indexPath = tableView.indexPathForSelectedRow{ //取得點擊的Indexpath
                let selectedRow = indexPath.row
                let detailVC = segue.destination as! DetailViewController
                detailVC.string = items[selectedRow].name //傳遞資料到下一頁
            }
            
        }
    }
}