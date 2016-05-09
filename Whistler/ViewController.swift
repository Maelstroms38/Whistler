//
//  ViewController.swift
//  Whistler
//
//  Created by Michael Stromer on 5/3/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    static var dirty = true
    var tableView: UITableView!
    var whistles = [Whistle]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Breeds", style: .Plain, target: self, action: #selector(ViewController.selectGenre))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ViewController.addWhistle))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Home", style: .Plain, target: nil, action: nil)
        // Do any additional setup after loading the view, typically from a nib.
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    func selectGenre() {
       let vc = BreedsTableViewController()
       navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        if ViewController.dirty {
            loadWhistles()
        }
    }
    
    func loadWhistles() {
        //1 Predicate, Query, Operation
        let pred = NSPredicate(value: true) // true records
        let sort = NSSortDescriptor(key: "creationDate", ascending: false) // sorted by the date
        let query = CKQuery(recordType: "Whistles", predicate: pred) //Combines both NSPredicate and sortDescriptor
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["genre", "comments"]
        operation.resultsLimit = 50
        
        var newWhistles = [Whistle]()
        
        //Operation Block
        operation.recordFetchedBlock = { (record) in
            let whistle = Whistle()
            whistle.recordID = record.recordID
            whistle.genre = record["genre"] as! String
            whistle.comments = record["comments"] as! String
            newWhistles.append(whistle)
        }
        //Completion Block
        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    ViewController.dirty = false
                    self.whistles = newWhistles
                    self.tableView.reloadData()
                } else {
                    let ac = UIAlertController(title: "Fetch Error", message: "Please check your connection: \(error!.localizedDescription)", preferredStyle: .Alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(ac, animated: true, completion: nil)
                }
            }
        }
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(operation)
        
    }
    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline), NSForegroundColorAttributeName: UIColor.purpleColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)", attributes: titleAttributes)
        
        if subtitle.characters.count > 0 {
            let subtitleString = NSAttributedString(string: "\n\(subtitle)", attributes: subtitleAttributes)
            titleString.appendAttributedString(subtitleString)
        }
        
        return titleString
    }
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.whiteColor()
        
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        fillWithView(tableView)
        
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let vc = ResultsTableViewController()
        vc.whistle = whistles[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func addWhistle() {
        let vc = RecordVoiceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: TableView DataSource / Delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.accessoryType = .DisclosureIndicator
        cell.textLabel?.attributedText = makeAttributedString(title: whistles[indexPath.row].genre, subtitle: whistles[indexPath.row].comments)
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.whistles.count
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }


}

