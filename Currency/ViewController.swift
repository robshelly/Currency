//
//  ViewController.swift
//  Currency
//
//  Created by Robert O'Connor on 18/10/2017.
//  Copyright © 2017 WIT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK Model holders
    var currencyDict:Dictionary = [String:Currency]()
    var currencyArray = [Currency]()
    var baseCurrency:Currency = Currency.init(name:"EUR", rate:1, flag:"🇪🇺", symbol:"€")!
    var lastUpdatedDate:Date = Date()
    
    var eur:Currency = Currency.init(name:"EUR", rate:1, flag:"🇪🇺", symbol:"€")!
    var aud:Currency = Currency.init(name:"AUD", rate:1, flag:"🇦🇺", symbol:"A$")!
    var brl:Currency = Currency.init(name:"BRL", rate:1, flag:"🇧🇷", symbol:"R$")!
    var cad:Currency = Currency.init(name:"CAD", rate:1, flag:"🇨🇦", symbol:"C$")!
    var cny:Currency = Currency.init(name:"CNY", rate:1, flag:"🇨🇳", symbol:"元")!
    var chf:Currency = Currency.init(name:"CHF", rate:1, flag:"🇨🇭", symbol:"Fr")!
    var czk:Currency = Currency.init(name:"CZK", rate:1, flag:"🇨🇿", symbol:"Kč")!
    var dkk:Currency = Currency.init(name:"DKK", rate:1, flag:"🇩🇰", symbol:"kr")!
    var gbp:Currency = Currency.init(name:"GBP", rate:1, flag:"🇬🇧", symbol:"£")!
    var hkd:Currency = Currency.init(name:"HKD", rate:1, flag:"🇭🇰", symbol:"HK$")!
    var hrk:Currency = Currency.init(name:"HRK", rate:1, flag:"🇭🇷", symbol:"kn")!
    var huf:Currency = Currency.init(name:"HUF", rate:1, flag:"🇭🇺", symbol:"Ft")!
    var idr:Currency = Currency.init(name:"IDR", rate:1, flag:"🇮🇩", symbol:"Rp")!
    var ils:Currency = Currency.init(name:"ILS", rate:1, flag:"🇮🇱", symbol:"₪")!
    var inr:Currency = Currency.init(name:"INR", rate:1, flag:"🇮🇳", symbol:"₹")!
    var jpy:Currency = Currency.init(name:"JPY", rate:1, flag:"🇯🇵", symbol:"¥")!
    var rub:Currency = Currency.init(name:"RUB", rate:1, flag:"🇷🇺", symbol:"₽")!
    var usd:Currency = Currency.init(name:"USD", rate:1, flag:"🇺🇸", symbol:"$")!
    
    var convertValue:Double = 0
    
    @IBOutlet weak var baseSymbol: UILabel!
    @IBOutlet weak var baseTextField: UITextField!
    @IBOutlet weak var baseFlag: UILabel!
    @IBOutlet weak var lastUpdatedDateLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var refresher: UIRefreshControl!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create currency dictionary
        self.createCurrencyDictionary()
        
        // get latest currency values
//        getConversionTable()
        convertValue = 1
        
        // set up base currency screen items
        baseTextField.text = String(format: "%.02f", baseCurrency.rate)
        baseTextField.font = UIFont.boldSystemFont(ofSize: 30.0)
        baseSymbol.text = baseCurrency.symbol
        baseSymbol.font = UIFont.boldSystemFont(ofSize: 40.0)
        baseFlag.text = baseCurrency.flag
        baseFlag.font = UIFont.boldSystemFont(ofSize: 30.0)
        baseFlag.textAlignment = NSTextAlignment.right;
        
//        self.setDate()
        
        // Add notifitcations for keyboard
        let centre: NotificationCenter = NotificationCenter.default;
        centre.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        centre.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        baseTextField.delegate = self
        configureKeypadToolBar()
        
        currencyArray = [gbp, usd, cny, aud, brl, cad, chf, czk, dkk, hkd, hrk, huf, idr, ils, inr, jpy, rub]
        
        // Setup table
        tableView.delegate = self
        tableView.dataSource = self
        
        refresher = UIRefreshControl()
        setupTableView()
        tableRefresh()
    }
    
    private func setupTableView() {
        // Hide tableview until after initial rates are retrieved
        tableView.isHidden = true
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refresher
        } else {
            tableView.addSubview(refresher)
        }
        refresher.addTarget(self, action: #selector(tableRefresh), for: .valueChanged)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencyArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CustomTableViewCell
        let currency = currencyArray[indexPath.row]
        
        cell.currencySymbol.text = "\(currency.name) \(currency.symbol)"
        cell.currencySymbol.font = UIFont.boldSystemFont(ofSize: 30.0)
        
        cell.currencyValue.text = String(format: "%.02f", currency.rate)
        cell.currencyValue.font = UIFont.boldSystemFont(ofSize: 30.0)
        cell.currencyValue.textAlignment = NSTextAlignment.right;
        
        cell.currencyFlag.text = currency.flag
        cell.currencyFlag.font = UIFont.boldSystemFont(ofSize: 30.0)
        cell.currencyFlag.textAlignment = NSTextAlignment.right;
        return cell
    }
    
    @objc func tableRefresh() {
        self.getConversionTable()
    }
    
    @objc func updateUI() {
        
        // Table view is hidden before initial rates are retrieved
        // show them now
        tableView.isHidden = false
        print("Last Updated: \(lastUpdatedDate)")
        
        
        self.setDate()
        self.convert()
        
        // Update table view with latest values
        self.tableView.reloadData()
        
        // End refreshing
        self.refresher.endRefreshing()
    }
    
    // Add toolbar to with done button to keypad
    func configureKeypadToolBar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self,  action: #selector(self.doneClicked))

        toolbar.sizeToFit()
        baseTextField.inputAccessoryView = toolbar
        toolbar.setItems([flexibleSpace, doneButton], animated: true)
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        // Move frame when keyboard appears if textbox is would be obscured
        let info:NSDictionary = notification.userInfo! as NSDictionary
        let keyBoardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        let keyBoardY = self.view.frame.size.height - keyBoardSize.height

        let baseTextFieldY:CGFloat! = self.baseTextField.superview!.frame.origin.y

        moveView(distance: self.view.frame.origin.y - (baseTextFieldY! - (keyBoardY - baseTextField.frame.height - 5)))
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        // Move frame to origin when keyboard disappears
        moveView(distance: 0.0)
    }
    
    func moveView(distance: CGFloat) {
        // Move the frame by a vertical amount
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: UIViewAnimationOptions.curveEaseIn,
            animations: {
                self.view.frame = CGRect(
                    x:0,
                    y:distance,
                    width:self.view.bounds.width,
                    height: self.view.bounds.height
                )
        },
            completion: nil
        )
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func doneClicked() {
        view.endEditing(true)
        updateUI()
//        convert()
//        self.tableView.reloadData()
    }
    
    func createCurrencyDictionary(){
        currencyDict["AUD"] = Currency(name:"AUD", rate:1, flag:"🇦🇺", symbol:"A$")
        currencyDict["BRL"] = Currency(name:"BRL", rate:1, flag:"🇧🇷", symbol:"R$")
        currencyDict["CAD"] = Currency(name:"CAD", rate:1, flag:"🇨🇦", symbol:"C$")
        currencyDict["CNY"] = Currency(name:"CNY", rate:1, flag:"🇨🇳", symbol:"元")
        currencyDict["CHF"] = Currency(name:"CHF", rate:1, flag:"🇨🇭", symbol:"Fr")
        currencyDict["CZK"] = Currency(name:"CZK", rate:1, flag:"🇨🇿", symbol:"Kč")
        currencyDict["DKK"] = Currency(name:"DKK", rate:1, flag:"🇩🇰", symbol:"kr")
        currencyDict["GBP"] = Currency(name:"GBP", rate:1, flag:"🇬🇧", symbol:"£")
        currencyDict["HKD"] = Currency(name:"HKD", rate:1, flag:"🇭🇰", symbol:"HK$")
        currencyDict["HRK"] = Currency(name:"HRK", rate:1, flag:"🇭🇷", symbol:"kn")
        currencyDict["HUF"] = Currency(name:"HUF", rate:1, flag:"🇭🇺", symbol:"Ft")
        currencyDict["IDR"] = Currency(name:"IDR", rate:1, flag:"🇮🇩", symbol:"Rp")
        currencyDict["ILS"] = Currency(name:"ILS", rate:1, flag:"🇮🇱", symbol:"₪")
        currencyDict["INR"] = Currency(name:"INR", rate:1, flag:"🇮🇳", symbol:"₹")
        currencyDict["JPY"] = Currency(name:"JPY", rate:1, flag:"🇯🇵", symbol:"¥")
        currencyDict["RUB"] = Currency(name:"RUB", rate:1, flag:"🇷🇺", symbol:"₽")
        currencyDict["USD"] = Currency(name:"USD", rate:1, flag:"🇺🇸", symbol:"$")
    }
    
    
    // https://gist.github.com/cmoulton/149b03b5ea2f4c870a44526a02618a30
    func getConversionTable() {

        let urlStr:String = "https://api.fixer.io/latest"
        
        guard let url = URL(string: urlStr) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // Make request
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // Check for errors
            guard error == nil else {
                print("Error fetching rates!")
                return
            }
            
            // Testing activity indicator
            sleep(3)
            
            // Ensure response contained data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // Parse JSON
            do {
                // Safely get dict from JSON
                guard let jsonDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    print("Error parsing JSON")
                    return
                }
                
                // Update the date now that valid data is confirmed
                self.lastUpdatedDate = Date()
                
                if let rates = jsonDict["rates"] as? NSDictionary {
                    // Set individual rates
                    for rate in rates{
                        let name = String(describing: rate.key)
                        let rate = (rate.value as? NSNumber)?.doubleValue
                        
                        if let c = self.currencyDict[name] {
                            c.rate = rate!
                        }
//                        else {
//                            print("Ignoring currency: \(String(describing: rate))")
//                        }
                    }
                }
                
            } catch  {
                print("Error reading JSON")
                return
            }
            // Now update the UI
            // https://www.hackingwithswift.com/read/9/4/back-to-the-main-thread-dispatchqueuemain
            DispatchQueue.main.async {
                print("Finished fetching rates")
                self.updateUI()
            }
        }
        task.resume()
    }
    
    func convert() {
        if let euro = Double(baseTextField.text!) {
            convertValue = euro
            for c in currencyArray {
                var result = 0.0
                if let cDict = self.currencyDict[c.name] {
                    result = convertValue * cDict.rate
                }
                c.rate = result
            }
        }
    }
    
    func setDate() {
        // set up last updated date
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd/MM/yyyy hh:mm a"
        lastUpdatedDateLabel.text = dateformatter.string(from: lastUpdatedDate)
    }
}

