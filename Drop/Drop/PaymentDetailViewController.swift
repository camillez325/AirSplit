//
//  PaymentDetailViewController.swift
//  Drop
//
//  Created by Yunong Jiang on 12/9/17.
//  Copyright © 2017 Camille Zhang. All rights reserved.
//

import UIKit

class PaymentDetailViewController: UIViewController {

    @IBOutlet weak var PaymentDetail: UITableView!
    var person = ""
    
    var data:[String] = ["Item 1", "Item 2", "Item 3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.PaymentDetail.delegate = self
        self.PaymentDetail.dataSource = self
        print(person)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PaymentDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.detailTextLabel?.text = "price"
        //cell.detailTextLabel?.textColor = UIColor.init(red: 0.1924, green: 0.8, blue: 0.056, alpha: 1)
        cell.detailTextLabel?.textColor = UIColor.init(red: 0.8, green: 0.056, blue: 0.056, alpha: 1)
        return cell
    }
}
