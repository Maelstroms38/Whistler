//
//  BreedsTableViewController.swift
//  Whistler
//
//  Created by Michael Stromer on 5/9/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import UIKit
import CloudKit

class BreedsTableViewController: UITableViewController {

    var myBreeds: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Breeds"
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let savedBreeds = defaults.objectForKey("myBreeds") as? [String] {
            myBreeds = savedBreeds
        } else {
            myBreeds = [String]()
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action:(#selector(BreedsTableViewController.savedTapped)))
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    func savedTapped() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(myBreeds, forKey: "myBreeds")
        
        let database = CKContainer.defaultContainer().publicCloudDatabase
        database.fetchAllSubscriptionsWithCompletionHandler { (subscriptions, error) in
            if error == nil {
                if let subscriptions = subscriptions {
                    for subscription in subscriptions {
                        database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: { (str, error) in
                            if error != nil {
                                print(error?.localizedDescription)
                            }
                        })
                    }
                    // Download Breeds from Cloudkit
                    for breed in self.myBreeds {
                        let predicate = NSPredicate(format: "genre = %@", breed)
                        let subscription = CKSubscription(recordType: "Whistles", predicate: predicate, options: .FiresOnRecordCreation)
                        let notification = CKNotificationInfo()
                        notification.alertBody = "Woof! There's a new dog in town: \(breed)"
                        notification.soundName = UILocalNotificationDefaultSoundName
                        subscription.notificationInfo = notification
                        
                        database.saveSubscription(subscription) {  (result, error) -> Void in
                            if error != nil {
                                print(error?.localizedDescription)
                            }
                            
                        }
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SelectGenreViewController.genres.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let breed = SelectGenreViewController.genres[indexPath.row]
        cell.textLabel?.text = breed
        
        if myBreeds.contains(breed) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let selectedGenre = SelectGenreViewController.genres[indexPath.row]
            
            if cell.accessoryType == .None {
                cell.accessoryType = .Checkmark
                myBreeds.append(selectedGenre)
            } else {
                cell.accessoryType = .None
                
                if let index = myBreeds.indexOf(selectedGenre) {
                    myBreeds.removeAtIndex(index)
                }
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
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
