//
//  ViewController.swift
//  Currency
//
//  Created by Robert O'Connor on 18/10/2017.
//  Copyright © 2017 WIT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    var currencyDict:Dictionary = [String:Currency]()
    var baseCurrency:Currency = Currency.init(name:"EUR", rate:1, flag:"🇪🇺", symbol:"€")!
    var lastUpdatedDate:Date = Date()
    
    var convertValue:Double = 0
    
    @IBOutlet weak var baseSymbol: UILabel!
    @IBOutlet weak var baseTextField: UITextField!
    @IBOutlet weak var baseFlag: UILabel!
    @IBOutlet weak var lastUpdatedDateLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currencyPicker: UIPickerView!
    
    var refresher: UIRefreshControl!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create currency dictionary
        self.createCurrencyDictionary()
        
        // Inialise convert value to 1
        convertValue = 1
        
        // set up some labels/text fields on page
        setBaseCurrencyLabels()
//        baseTextField.text = String(format: "%.02f", baseCurrency.rate)
        baseTextField.font = UIFont.boldSystemFont(ofSize: 30.0)
//        baseSymbol.text = baseCurrency.symbol
        baseSymbol.font = UIFont.boldSystemFont(ofSize: 40.0)
//        baseFlag.text = baseCurrency.flag
        baseFlag.font = UIFont.boldSystemFont(ofSize: 30.0)
        baseFlag.textAlignment = NSTextAlignment.right;
        
        lastUpdatedDateLabel.textAlignment = NSTextAlignment.center;
        
        // Add notifitcations for keyboard
        let centre: NotificationCenter = NotificationCenter.default;
        centre.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        centre.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        baseTextField.delegate = self
        configureKeypadToolBar()
        
        // Setup table
        tableView.delegate = self
        tableView.dataSource = self
        
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        
        refresher = UIRefreshControl()
        setupTableView()
        tableRefresh()
    }
    
    // Set up Table view
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
    
    // Table view methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSortedKeys().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CustomTableViewCell
        let key = getSortedKeys()[indexPath.row]
        
        cell.currencySymbol.text = "\(String(describing: currencyDict[key]!.name)) \(String(describing: currencyDict[key]!.symbol))"
        cell.currencySymbol.font = UIFont.boldSystemFont(ofSize: 25.0)
        
        cell.currencyValue.text = String(format: "%.02f", (currencyDict[key]?.value)!)
        cell.currencyValue.font = UIFont.boldSystemFont(ofSize: 30.0)
        cell.currencyValue.textAlignment = NSTextAlignment.right;
        
        cell.currencyFlag.text = currencyDict[key]?.flag
        cell.currencyFlag.font = UIFont.boldSystemFont(ofSize: 30.0)
        cell.currencyFlag.textAlignment = NSTextAlignment.right;
        return cell
    }

    // Picker view methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide lines on picker view... looks better with implemented layout
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return getSortedKeys().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return getSortedKeys()[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Changed base currency: \(getSortedKeys()[row])")
        self.baseCurrency = currencyDict[getSortedKeys()[row]]!
        setBaseCurrencyLabels()
        updateUI()
    }
    
    // Reload conversion rates when table is refreshed
    @objc func tableRefresh() {
        self.getConversionTable()
        print("Last Updated: \(lastUpdatedDate)")
        self.setDate()
    }
    
    // Update the UI with after a convert or rates refresh
    @objc func updateUI() {
        
        // Table view is hidden before initial rates are retrieved
        // show them now
        tableView.isHidden = false
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
    
    
    // Keyboard methods
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
    
    // Done button on keypad toolbar clicked
    @objc func doneClicked() {
        view.endEditing(true)
        updateUI()
    }
    
    // Get a list of sorted currency keys
    func getSortedKeys() -> Array<String> {
        // this retursn a sorted list of keys from the currencyDic
        // used to display currencies in the tableview in alpahbetical order
        return Array(currencyDict.keys).sorted(by: <)
    }
    
    // Set the base currency
    func setBaseCurrencyLabels() {
        baseTextField.text = String(format: "%.02f", baseCurrency.rate)
        baseSymbol.text = baseCurrency.symbol
        baseFlag.text = baseCurrency.flag
    }
    
    func createCurrencyDictionary(){
        currencyDict["EUR"] = Currency(name:"EUR", rate:1, flag:"🇪🇺", symbol:"€")
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
        // Rates receives are all expressed a ratios to €1
        // therfore to convert any currency to any other currency use the following:
        // targetValue = baseValue * (targetRate / baseRate)
        if let euro = Double(baseTextField.text!) {
            convertValue = euro
            for k in getSortedKeys() {
                var result = 0.0
                if let cDict = self.currencyDict[k] {
                    result = convertValue * (cDict.rate / baseCurrency.rate)
                }
                currencyDict[k]?.value = result
            }
        }
    }
    
    func setDate() {
        // set up last updated date
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd/MM/yyyy hh:mm a"
        lastUpdatedDateLabel.text = "Updated: \(dateformatter.string(from: lastUpdatedDate))"
    }
}

