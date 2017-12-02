//
//  EventViewController.swift
//  Drop
//
//  Created by Camille Zhang on 10/22/17.
//  Copyright © 2017 Camille Zhang. All rights reserved.
//

import UIKit

/// controller that handles user's actions on event creating page
class EventViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UISearchBarDelegate{
    
    let itemCellIdentifier = "ItemCell"
    let participantPopIdentifier = "ParticipantPopCell"
    //var people = [String]()
    var actionSheet: UIAlertController!
    var imagePickerController: UIImagePickerController!
    var deleteItemIndexPath : NSIndexPath? = nil
    
    @IBOutlet weak var ItemTableView: UITableView!
    @IBOutlet weak var PeopleCollectionView: UICollectionView!
    @IBOutlet weak var SearchButton: UISearchBar!
    
    private var appDelegate : AppDelegate
    private var multipeer : MultipeerManager
    
    private var splitable : Bool
    private var assignees = [PeopleCollectionViewCell]()
    
    /// Returns a newly initialized view controller with the nib file in the specified bundle.
    ///
    /// - Parameters:
    ///   - nibNameOrNil: The name of the nib file to associate with the view controller. The nib file name should not contain any leading path information. If you specify nil, the nibName property is set to nil.
    ///   - nibBundleOrNil: The bundle in which to search for the nib file. This method looks for the nib file in the bundle's language-specific project directories first, followed by the Resources directory. If this parameter is nil, the method uses the heuristics described below to locate the nib file.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.multipeer = appDelegate.multipeer
        self.splitable = false
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.multipeer = appDelegate.multipeer
        self.splitable = false
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("didLoad")
        
        SearchButton.delegate = self
        
        actionSheet = UIAlertController(title: "Image Source", message: "Choose a source", preferredStyle: .actionSheet)
        
        imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action: UIAlertAction) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.present(self.imagePickerController, animated: true, completion: nil)
            } else {
                print("Camera not available")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action: UIAlertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
        }))
        
        //related to item table view
        self.appDelegate.items.append("item")
        
    }
    
    /// clear the detected devices array and start browsing when we get to the event creating page every time
    ///
    /// - Parameter animated: boolean
    override func viewWillAppear(_ animated: Bool) {
        self.appDelegate.people.removeAll()
//        self.appDelegate.items.removeAll()
        self.ItemTableView.reloadData()
//        self.appDelegate.items.append("item")
        self.multipeer.delegate = self
        self.multipeer.startBrowsing()
        print("will load")
        print("item array has" + String(appDelegate.items.count) + "elements at view will appear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// handler for canceling a split event
    ///
    /// - Parameter sender: Any
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.appDelegate.people.removeAll()
        self.appDelegate.items.removeAll()
        self.performSegue(withIdentifier: "unwindToHome", sender: self)
    }
    
    /// The callback function for when the Camera button is clicked
    ///
    /// - Parameter sender: The object that initiates the action
    @IBAction func addImage(_ sender: Any) {
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    /// Fetches the picked image and uploads it to the server for processing
    ///
    /// - Parameters:
    ///   - picker: The picker manages user interactions and delivers the results of those interactions to a delegate object.
    ///   - info: A dictionary containing the original image and the edited image, if an image was picked; or a filesystem URL for the movie, if a movie was picked.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let receipt = info[UIImagePickerControllerOriginalImage] as! UIImage
        let url = URL(string: "https://api.taggun.io/api/receipt/v1/verbose/file")!
//        let url = URL(string: "https://api.taggun.io/api/receipt/v1/simple/file")!
        var request = URLRequest(url: url)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("a445ca40c4a311e7a0ebfdc7a5da208a", forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        let params = [
            "refresh": "false",
            "incognito": "false"
        ];
        
        request.httpBody = createBody(
            parameters: params,
            boundary: boundary,
            data: UIImageJPEGRepresentation(receipt, 0.5)!,
            mimeType: "image/jpg",
            filename: "receipt.jpg"
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error!)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response!)")
            }
            
            let result = self.convertToDictionary(text: data)!
//            print("responseString = \(responseJSON!)")
//            dump(result)
            print(((result["totalAmount"] as AnyObject)["regions"] as! [AnyObject])[0])
        }
        task.resume()
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// Creates the body for the POST request that conforms with the HTTP standard
    ///
    /// - Parameters:
    ///   - parameters: The parameters to add as the form-data
    ///   - boundary: The boundary string which should be generated randomly to separate different parts of the request body
    ///   - data: The file's data to send, in our case the receipt image's data
    ///   - mimeType: The mimeType of the body, in our case it will set to 'image/jpg'
    ///   - filename: The filename of the to-be uploaded receipt image
    /// - Returns: The generated body string encoded as byte stream
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        print(NSString(data: body as Data, encoding: String.Encoding.utf8.rawValue)!)
        body.append(data)
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        
        return body as Data
    }
    
    /// Callback when the user cancels the image picking
    ///
    /// - Parameter picker: The picker manages user interactions and delivers the results of those interactions to a delegate object.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func convertToDictionary(text: Data) -> [String: Any]? {
        do {
            return try (JSONSerialization.jsonObject(with: text, options: []) as! [String: Any])
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchText \(searchText)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchText \(searchBar.text)")
    }
}


//======================
//related to table view
//======================
extension EventViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appDelegate.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // your cell coding
        let cell = tableView.dequeueReusableCell(withIdentifier: itemCellIdentifier, for: indexPath) as! ItemTableViewCell
        cell.delegate = self
        cell.AddButton.isHidden = false
        cell.ItemName.isHidden = true
        cell.ItemName.text = ""
        cell.ItemPrice.isHidden = true
        cell.ItemPrice.text = ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItemIndexPath = indexPath as NSIndexPath
            confirmDelete()
        }
    }
    
    func confirmDelete() {
        let alert = UIAlertController(title: "Delete Item", message: "Are you sure you want to delete the item?", preferredStyle: .actionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteItem)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteItem)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleDeleteItem(alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteItemIndexPath {
            self.ItemTableView.beginUpdates()
            self.appDelegate.items.remove(at: indexPath.row)
            // Note that indexPath is wrapped in an array:  [indexPath]
            self.ItemTableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            deleteItemIndexPath = nil
            self.ItemTableView.endUpdates()
        }
    }
    
    func cancelDeleteItem(alertAction: UIAlertAction!) {
        deleteItemIndexPath = nil
    }
//    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
//        // cell selected code here
//    }
}


//related to Collection view
extension EventViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    /// Asks your data source object for the number of items in the specified section.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information.
    ///   - section: An index number identifying a section in collectionView. This index value is 0-based.
    /// - Returns: number of detected devices in the people array if collectionView == PeopleCollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.appDelegate.people.count
        
    }

    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information.
    ///   - indexPath: The index path that specifies the location of the item.
    /// - Returns: a peopleCollectionViewCell if collectionView == PeopleCollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: participantPopIdentifier, for: indexPath) as! PeopleCollectionViewCell
        if indexPath.row < self.appDelegate.people.count {
            cell.accountImageView.image = #imageLiteral(resourceName: "icons8-User Male-48")
            cell.accountName.text = self.appDelegate.people[indexPath.row]
        }
        return cell
    }
    
    /// Asks your data source object for the number of sections in the collection view.
    ///
    /// - Parameter collectionView: The collection view requesting this information.
    /// - Returns: 1 by default
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    // Select and de-select people during splitting
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard self.splitable else {
            print("Not splittable")
            return
        }
        
        let person = self.PeopleCollectionView.cellForItem(at: indexPath) as! PeopleCollectionViewCell
        
        // toggle color
        person.accountImageView.alpha = (person.accountImageView.alpha == 1) ? 0.5 : 1
        
        // de-select
        if (assignees.contains(person)) {
            print(person.accountName.text! + " is de-selected")
            assignees = assignees.filter({ $0.accountName != person.accountName })
        }
            // select
        else {
            print(person.accountName.text! + " is selected")
            assignees.append(person)
        }
        
        // DEBUG
        print("Assignees: ")
        for assignee in assignees as [PeopleCollectionViewCell] {
            print(assignee.accountName.text! + " ")
        }
    }
}

//Related to Multipeer API
extension EventViewController : MultipeerManagerDelegate {
    /// handler for detecting a new device and updating people collection view
    ///
    /// - Parameters:
    ///   - manager: MultipeerManager
    ///   - detectedDevice: detected device's user's name
    func deviceDetection(manager : MultipeerManager, detectedDevice: String) {
        if self.appDelegate.people.contains(detectedDevice) {
            return
        }
        self.appDelegate.people.append(detectedDevice)
        self.PeopleCollectionView.reloadData()
    }
    
    /// handler for losing a device and updating people collection view
    ///
    /// - Parameters:
    ///   - manager: MultipeerManager
    ///   - removedDevice: lost device's user's name
    func loseDevice(manager : MultipeerManager, removedDevice: String) {
        if let index = self.appDelegate.people.index(of: removedDevice) {
            self.appDelegate.people.remove(at: index)
        }
        self.PeopleCollectionView.reloadData()
    }
}

extension EventViewController : ItemTableViewCellDelegate {
    func cell_did_add_people(_ sender: ItemTableViewCell) {
        
        self.splitable = !self.splitable
        
        // Unselect
        guard self.splitable else {
            print("Splitting finished")
            for person in PeopleCollectionView.visibleCells as! [PeopleCollectionViewCell] {
                let icon = person.accountImageView
                icon?.alpha = 1
            }
            self.assignees.removeAll()
            self.PeopleCollectionView.allowsMultipleSelection = false
            return
        }
        
        // Select
        print("Start splitting")
        for person in PeopleCollectionView.visibleCells as! [PeopleCollectionViewCell] {
            let icon = person.accountImageView
            icon?.alpha = 0.5
        }
        self.PeopleCollectionView.allowsMultipleSelection = true
        let row = sender.tag
        let indexPath = IndexPath(row: row, section: 0)
        let cell = self.ItemTableView.cellForRow(at: indexPath) as! ItemTableViewCell
        cell.assignees = self.assignees
        self.ItemTableView.reloadData()
    }
    
    func cell_did_add_item(_ sender: ItemTableViewCell) {
        sender.AddButton.isHidden = true
        sender.ItemName.placeholder = "Item Name"
        sender.ItemName.isHidden = false
        sender.ItemPrice.placeholder = "Item Price"
        sender.ItemPrice.isHidden = false
        let row = self.appDelegate.items.count
        let indexPath = IndexPath.init(row: row, section: 0)
        self.ItemTableView.beginUpdates()
        self.appDelegate.items.append("Item")
        print(self.appDelegate.items.count)
        // Note that indexPath is wrapped in an array:  [indexPath]
        self.ItemTableView.insertRows(at: [indexPath as IndexPath], with: .automatic)
        self.ItemTableView.endUpdates()
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
