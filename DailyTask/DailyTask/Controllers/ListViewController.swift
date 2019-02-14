//
//  ListViewController.swift
//  FireBaseDB
//
//  Created by MAC on 11/02/19.
//  Copyright © 2019 Appoets. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UserNotifications

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UNUserNotificationCenterDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    
    var ref: DatabaseReference!
    var han: DatabaseHandle!
    var eventArray = [[String:AnyObject]]()
    var eventKeyArray = [String]()
    var responseDict  = [String : AnyObject]()
    
    @IBOutlet var dateLbl: UILabel!
    @IBOutlet var monthLbl: UILabel!
    @IBOutlet var daylbl: UILabel!
    @IBOutlet var calender: FSCalendar!
    @IBOutlet var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tableviewOutlet: UITableView!
    
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calender, action: #selector(self.calender.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
        }()
    
    // MARK:- Controller Defults
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ref = Database.database().reference()
        self.tableviewOutlet.delegate = self
        self.tableviewOutlet.dataSource = self
        self.calender.select(Date())
        self.view.addGestureRecognizer(self.scopeGesture)
        self.tableviewOutlet.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calender.scope = .week
        self.calender.accessibilityIdentifier = "calendar"
        
        let timeDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        let currentDate = dateFormatter.string(from: timeDate)
        dateLbl.text = currentDate
        dateFormatter.dateFormat = "EEEE"
        let currentDay = dateFormatter.string(from: timeDate)
        daylbl.text = currentDay
        dateFormatter.dateFormat = "MMMM yyyy"
        let currentMonth = dateFormatter.string(from: timeDate)
        monthLbl.text = currentMonth

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.getAllEvents(Date())
    }
    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableviewOutlet.contentOffset.y <= -self.tableviewOutlet.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calender.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
    // MARK:- CalendarDelegates
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("did select date \(self.dateFormatter.string(from: date))")
        let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        print("selected dates is \(selectedDates)")
        
        if monthPosition == .next || monthPosition == .previous {
            calendar.setCurrentPage(date, animated: true)
        }
    self.getAllEvents(date)
        
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("\(self.dateFormatter.string(from: calendar.currentPage))")
    }
    
    // MARK:- UITableviewDelegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = (self.tableviewOutlet.dequeueReusableCell(withIdentifier: "Cell"))!
        
        var dict = self.eventArray[indexPath.row]
        
        let timeLbl: UILabel = cell.viewWithTag(2) as! UILabel
        timeLbl.text = dict["time"] as? String
        let categoryLbl: UILabel = cell.viewWithTag(3) as! UILabel
        categoryLbl.text = dict["category"] as? String
        
        let categoryImgView: UIImageView = cell.viewWithTag(1) as! UIImageView
        
        if dict["category"]as!String == "Running" {
            categoryImgView.image = UIImage.init(named: "running")
        }
        else if dict["category"]as!String == "Reading" {
            categoryImgView.image = UIImage.init(named: "reading")
        }
        else if dict["category"]as!String == "Movie" {
            categoryImgView.image = UIImage.init(named: "movie")
        }
        else if dict["category"]as!String == "Meeting" {
            categoryImgView.image = UIImage.init(named: "meating")
        }
        else
        {
           categoryImgView.image = UIImage.init(named: "shopping")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80.0;
    }
    
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            
            self.removeToDataBase(child: self.eventKeyArray[indexPath.row])
            self.eventKeyArray.remove(at: indexPath.row)
            self.eventArray.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
    }
    
    // MARK:- Firebase Actions
    
    func getAllEvents(_ date: Date) {
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            
            if !snapshot.exists() { return }
            
            print(snapshot)
            
            self.responseDict = snapshot.value as! [String : AnyObject]
            
            self.eventArray.removeAll()
            self.eventKeyArray.removeAll()
            
            for (key, value) in self.responseDict {
                
                var dict = value as! [String : AnyObject]
                let time = dict["currentDate"] as! String
                let double = NumberFormatter().number(from: time)?.doubleValue
                let timeDate = Date(timeIntervalSince1970: double!)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let localDate = dateFormatter.string(from: timeDate)
                let currentDate = dateFormatter.string(from: date)
                if (currentDate == localDate){
                    
                    self.eventArray.append(value as! [String : AnyObject])
                    self.eventKeyArray.append(key)
                }
            }
            
            self.tableviewOutlet.reloadData()
            
        })
    }
    
    func removeToDataBase(child: String) {
        
        let ref = Database.database().reference()
        ref.child(child).removeValue { error, _ in
            print("\(String(describing: error))")
        }
    }
    
    // MARK:- IB Actions
    
    @IBAction func addBtnAction(_ sender: Any) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    @IBAction func calenderBtnAction(_ sender: Any) {
        
        if self.calender.scope == .month {
            self.calender.setScope(.week, animated: true)
        } else {
            self.calender.setScope(.month, animated: true)
        }
    }

}
