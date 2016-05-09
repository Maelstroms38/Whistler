//
//  ResultsTableViewController.swift
//  Whistler
//
//  Created by Michael Stromer on 5/4/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import UIKit
import AVFoundation
import CloudKit

class ResultsTableViewController: UITableViewController {
    
    var whistle: Whistle!
    var suggestions = [String]()
    
    var whistlePlayer: AVAudioPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Genre: \(whistle.genre)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .Plain, target: self, action: #selector(downloadTapped))
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        //Sort and Display Results
        let reference = CKReference(recordID: whistle.recordID, action: CKReferenceAction.DeleteSelf)
        let pred = NSPredicate(format: "owningWhistle == %@", reference)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        let query = CKQuery(recordType: "Suggestions", predicate: pred)
        query.sortDescriptors = [sort]
        
        //Fetch and Parse Results
        CKContainer.defaultContainer().publicCloudDatabase.performQuery(query, inZoneWithID: nil) { [unowned self] (results, error) -> Void in
            if error == nil {
                if let results = results {
                    self.parseResults(results)
                }
            } else {
                print(error!.localizedDescription)
            }
        }

    }
    func parseResults(records: [CKRecord]) {
        var newSuggestions = [String]()
        
        for record in records {
            newSuggestions.append(record["text"] as! String)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.suggestions = newSuggestions
            self.tableView.reloadData()
        }
    }
    func downloadTapped() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        spinner.tintColor = UIColor.blackColor()
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        
        CKContainer.defaultContainer().publicCloudDatabase.fetchRecordWithID(whistle.recordID) { [unowned self] (record, error) -> Void in
            if error == nil {
                if let record = record {
                    if let asset = record["audio"] as? CKAsset {
                        self.whistle.audio = asset.fileURL
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Listen", style: .Plain, target: self, action: #selector(self.listenTapped))
                        }
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    let ac = UIAlertController(title: "Error", message: "There was a problem downloading: \(error!.localizedDescription)", preferredStyle: .Alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(ac, animated: true, completion: nil)
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .Plain, target: self, action: #selector(self.downloadTapped))
                }
            }
        }
    }
    func listenTapped() {
        do {
            whistlePlayer = try AVAudioPlayer(contentsOfURL: whistle.audio)
            whistlePlayer.play()
        } catch {
            let ac = UIAlertController(title: "Playback failed", message: "There was a problem playing your whistle; please try re-recording.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return max(1, suggestions.count + 1)
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Selected Music"
        }
        return nil
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.selectionStyle = .None
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.section == 0 {
            //user's whistle comments
            cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
            if whistle.comments.characters.count == 0 {
                cell.textLabel?.text = "Comments: None"
            } else {
                cell.textLabel?.text = whistle.comments
            }
        } else {
            cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            if indexPath.row == suggestions.count {
                //This is our extra row for suggestions
                cell.textLabel?.text = "Add suggestion"
                cell.selectionStyle = .Gray
            } else {
                cell.textLabel?.text = suggestions[indexPath.row]
            }
        }

        return cell
    }
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 1 && indexPath.row == suggestions.count else {return}
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let ac = UIAlertController(title: "Suggest A Song...", message: nil, preferredStyle: .Alert)
        
        var suggestion: UITextField!
        
        ac.addTextFieldWithConfigurationHandler { (textField) in
            suggestion = textField
            textField.autocorrectionType = .Yes
        }
        ac.addAction(UIAlertAction(title: "Submit", style: .Default) { (action) -> Void in
            if suggestion.text?.characters.count > 0 {
                self.addSuggestion(suggestion.text!)
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    func addSuggestion(suggest: String) {
        //Reference between CKRecord and Suggestions  /\/\
        let whistleRecord = CKRecord(recordType: "Suggestions")
        let reference = CKReference(recordID: whistle.recordID, action: .DeleteSelf)
        whistleRecord["text"] = suggest
        whistleRecord["owningWhistle"] = reference
        
        //Save Reference to CloudKit
        CKContainer.defaultContainer().publicCloudDatabase.saveRecord(whistleRecord) { [unowned self] (record, error) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    self.suggestions.append(suggest)
                    self.tableView.reloadData()
                } else {
                    let ac = UIAlertController(title: "Error", message: "There was a problem submitting your suggestion: \(error!.localizedDescription)", preferredStyle: .Alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(ac, animated: true, completion: nil)
                }
            }
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
