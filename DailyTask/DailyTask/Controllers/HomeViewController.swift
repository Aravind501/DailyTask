//
//  HomeViewController.swift
//  FireBaseDB
//
//  Created by MAC on 11/02/19.
//  Copyright © 2019 Appoets. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class HomeViewController: UIViewController {
    
    var ref: DatabaseReference!
    var han: DatabaseHandle!
    var isDate: Bool!
    var  categoryArray = ["Running","Reading","Movie","Meeting","Shopping"]
    var selectedCategory = String()
    var selectedDate = String()
    var selDate = Date()
    var selectedTime = String()
    var remind = String()
    

    @IBOutlet var innerBaseView: UIView!
    @IBOutlet var baseViewOutlet: UIView!
    @IBOutlet var datePickerBaseView: UIView!
    @IBOutlet var categoryLbl: UILabel!
    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var categoryPickerBaseView: UIView!
    @IBOutlet var timePickerView: UIDatePicker!
    @IBOutlet var datePickerOutlet: UIDatePicker!
    @IBOutlet var dateLblOutlet: UILabel!
    @IBOutlet var saveBtn: UIButton!
    @IBOutlet var remindSwitch: UISwitch!
    
    
    // MARK:- Controller Defults
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ref = Database.database().reference()
        isDate = false
        self.datePickerBaseView.isHidden = true
        self.categoryPickerBaseView.isHidden = true
        self.datePickerOutlet?.datePickerMode = UIDatePicker.Mode.date
        datePickerOutlet.setValue(UIColor.white, forKeyPath: "textColor")
        categoryPicker.setValue(UIColor.white, forKeyPath: "textColor")
        self.datePickerOutlet.minimumDate = NSDate() as Date
        baseViewOutlet.layer.cornerRadius = 10
        innerBaseView.layer.cornerRadius = 10
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        let currentDate = formatter.string(from: date)
        dateLblOutlet.text = currentDate
        formatter.dateFormat =  "HH:mm"
        timePickerView.date = date
        print("\(timePickerView.date)") // 10:30 PM
        timePickerView.setDate(timePickerView.date, animated: false) // 2
        selectedDate = currentDate
        selectedTime = formatter.string(from: timePickerView.date)
        selectedCategory = "Running"
        categoryLbl.text = "Running"
        remind = "0"

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.getAllEvents()
        
    }
    
    // MARK:- IB Actions
    
    @IBAction func dateCancelAction(_ sender: Any) {
        
        isDate = false
        self.datePickerBaseView.isHidden = true
    }
    @IBAction func closeAction(_ sender: Any) {
        
        self.dismiss(animated:true, completion: nil);
    }
    @IBAction func dateDoneAction(_ sender: Any) {
        
        isDate = false
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        selectedDate = formatter.string(from: self.datePickerOutlet.date)
        self.datePickerFromValueChanged(sender: self.datePickerOutlet)
        self.datePickerBaseView.isHidden = true
    }
    @IBAction func categoryBtnAction(_ sender: Any) {
        
        isDate = false
        categoryPickerBaseView.isHidden = false
        datePickerBaseView.isHidden = true
        categoryPicker.delegate = self
    }
    @IBAction func saveBtnAction(_ sender: Any) {
        
        selectedCategory = categoryLbl.text!
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        selectedTime = formatter.string(from: timePickerView.date)
        if remindSwitch.isOn {
            remind = "1"
        }
        else{
        remind = "0"
        }
        let date = self.selDate
        let objDateformat: DateFormatter = DateFormatter()
        objDateformat.dateFormat = "yyyy-MM-dd"
        let strTime: String = objDateformat.string(from: date as Date)
        let objUTCDate: NSDate = objDateformat.date(from: strTime)! as NSDate
        let milliseconds: Int64 = Int64(objUTCDate.timeIntervalSince1970)
        var strTimeStamp: String = "\(milliseconds)"
        if let dotRange = strTimeStamp.range(of: ".") {
            strTimeStamp.removeSubrange(dotRange.lowerBound..<strTimeStamp.endIndex)
        }
        let post = ["date": selectedDate,"currentDate": strTimeStamp,
                                        "time": selectedTime,
                            "category": selectedCategory,
                            "remind": remind] as [String : Any]
    self.addToDatabase(dict: post)
        
    }
    
    @IBAction func doneBtnAction(_ sender: Any) {
        
        self.categoryPickerBaseView.isHidden = true
        
        categoryLbl.text = selectedCategory
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.categoryPickerBaseView.isHidden = true
    }
    @IBAction func dateBtnAction(_ sender: Any) {
        
        categoryPickerBaseView.isHidden = true
        
        if isDate {
            self.datePickerBaseView.isHidden = true
            isDate = false
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.short
            self.datePickerFromValueChanged(sender: self.datePickerOutlet)
        }
        else{
            self.datePickerBaseView.isHidden = false
            isDate = true
        }
    }
    
    // MARK:- Custom Methods
    
    func getCurrentTimeStampWOMiliseconds(dateToConvert: NSDate) -> String {
        let objDateformat: DateFormatter = DateFormatter()
        objDateformat.dateFormat = "yyyy-MM-dd"
        let strTime: String = objDateformat.string(from: dateToConvert as Date)
        let objUTCDate: NSDate = objDateformat.date(from: strTime)! as NSDate
        let milliseconds: Int64 = Int64(objUTCDate.timeIntervalSince1970)
        let strTimeStamp: String = "\(milliseconds)"
        return strTimeStamp
    }
    
    func datePickerFromValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy  EEEE"
        dateLblOutlet.text = dateFormatter.string(from: sender.date)
        selectedDate = dateFormatter.string(from: sender.date)
        self.selDate = sender.date
        
    }
    
    // MARK:- Firebase
    
    func getAllEvents() {
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() { return }
            print(snapshot)
        })
    }
    func getEvents() {
        
        han = ref.child("name").observe(.value, with: { (data) in
            print(data.value as Any)
            print(data.key)
        })
    }
    
    func addToDatabase(dict : [String: Any]) {
        
        let now = NSDate().timeIntervalSince1970
        var timeStr = "\(now)"
        if let dotRange = timeStr.range(of: ".") {
            timeStr.removeSubrange(dotRange.lowerBound..<timeStr.endIndex)
        }
        ref.child(timeStr).setValue(dict)
        self.dismiss(animated:true, completion: nil);
    }
}

// MARK:- Extension class

extension HomeViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == self.categoryPicker {
            
            return categoryArray.count
        }
        else{
        return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView == self.categoryPicker {
            
            return self.categoryArray[row]
        }
        else{
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == self.categoryPicker {
            
            selectedCategory = self.categoryArray[row]
        }
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let value = self.categoryArray[row] 
        
        let attributedString = NSAttributedString(string: value, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        if pickerView == self.categoryPicker {
            
            return attributedString
        }
        else{
            return attributedString
        }
    }
}
