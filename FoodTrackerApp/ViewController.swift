//
//  ViewController.swift
//  FoodTrackerApp
//
//  Created by Adriel Carsete on 6/5/15.
//  Copyright (c) 2015 Adriel Carsete. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    var searchController:UISearchController!
    
    var suggestedSearchFoods:[String] = []
    var filteredSuggestedSearchFoods:[String] = []
    var apiSearchForFoods:[(name : String, idValue : String)] = []
    
    var scopeButtonTitles = ["Recommended", "Search Results","Saved"]
    
    let kAppID = "470a6984"
    let kAppKey = "95c0402567cceec58a8c56ac831d66e7"
    
    @IBOutlet weak var tableView: UITableView!
    
    var jsonResponse:NSDictionary!
    
    var dataController = DataController()
    
    var favoriteUSDAItems:[USDAItem] = []
    
    var filteredFavoriteUSDAItems:[USDAItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.searchController = UISearchController(searchResultsController: nil)
        
        self.searchController.searchResultsUpdater = self
        
        self.searchController.dimsBackgroundDuringPresentation = false
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        
        self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.width, 44.0)
        
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        //create buttons after search is touched
        self.searchController.searchBar.scopeButtonTitles = scopeButtonTitles
        self.searchController.searchBar.delegate = self
        
        self.definesPresentationContext = true
        //array with suggested search foods to find
        self.suggestedSearchFoods = ["apple", "bagel", "banana", "beer", "bread", "carrots", "cheddar cheese", "chicken breast", "chili with beans", "chocolate chip cookie", "coffee", "cola", "corn", "egg", "graham cracker", "granola bar", "green beans", "ground beef patty", "hot dog", "ice cream", "jelly doughnut", "ketchup", "milk", "mixed nuts", "mustard", "oatmeal", "orange juice", "peanut butter", "pizza", "pork chop", "potato", "potato chips", "pretzels", "raisins", "ranch salad dressing", "red wine", "rice", "salsa", "shrimp", "spaghetti", "white wine", "yellow cake"]
        
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "usdaItemDidComplete:", name: kUSDAItemComplete, object: nil)
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toDetailViewSegue" {
            if sender != nil {
                var detailVC = segue.destinationViewController as! DetailViewController
                detailVC.usdaItem = sender as? USDAItem
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Mark - UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        var foodName:String
        
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            if self.searchController.active {
                foodName = filteredSuggestedSearchFoods[indexPath.row]
                
            }
            else {
                foodName = suggestedSearchFoods[indexPath.row]
            }
        }
        else if selectedScopeButtonIndex == 1 {
            foodName = apiSearchForFoods[indexPath.row].name
        }
        else {
            
            if self.searchController.active {
                foodName = self.filteredFavoriteUSDAItems[indexPath.row].name
                
            }
            else {
                foodName = self.favoriteUSDAItems[indexPath.row].name
                
            }
        }

        cell.textLabel?.text = foodName
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
        
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            if self.searchController.active {
                return self.filteredSuggestedSearchFoods.count
            }
            else {
                return self.suggestedSearchFoods.count
            }
        }
        else if selectedScopeButtonIndex == 1 {
            return self.apiSearchForFoods.count
        }
        else {
            
            if self.searchController.active {
                return self.filteredFavoriteUSDAItems.count
            }
            else {
                return self.favoriteUSDAItems.count
            }
            
        }
        
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            var searchFoodName:String
            
            if self.searchController.active {
                searchFoodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                searchFoodName = suggestedSearchFoods[indexPath.row]
            }
            self.searchController.searchBar.selectedScopeButtonIndex = 1
            makePostRequest(searchFoodName)
            
        }
        else if selectedScopeButtonIndex == 1 {
            self.performSegueWithIdentifier("toDetailViewSegue", sender: nil)
            let idValue = apiSearchForFoods[indexPath.row].idValue
            self.dataController.saveUSDAItemForId(idValue, json: self.jsonResponse)
        }
        else if selectedScopeButtonIndex == 2 {
            if self.searchController.active {
                let usdaItem = filteredFavoriteUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailViewSegue", sender: usdaItem)
                
            }
            else {
                let usdaItem = favoriteUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailViewSegue", sender: usdaItem)
            }
        }
    }

    //MARK: - UISearch Results Updating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        let searchString = searchController.searchBar.text.lowercaseString //LOWERCASE
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        self.filterContentForSearch(searchString, scope: selectedScopeButtonIndex)
        self.tableView.reloadData()
    }
    
    func filterContentForSearch(searchText:String, scope:Int) {
        
        if scope == 0 {
            self.filteredSuggestedSearchFoods = self.suggestedSearchFoods.filter({ (food : String) -> Bool in
                var foodMatch = food.rangeOfString(searchText)
                
                return foodMatch != nil
            })
        }
        else if scope == 2 {
            self.filteredFavoriteUSDAItems = self.filteredFavoriteUSDAItems.filter({ (item: USDAItem) -> Bool in
                
                var stringMatch = item.name.rangeOfString(searchText)
                
                return stringMatch != nil
            })
        }
        
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        self.searchController.searchBar.selectedScopeButtonIndex = 1
        makePostRequest(searchBar.text)
        
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if selectedScope == 2 {
            requestFavoriteUSDAItems()
        }
        
        self.tableView.reloadData()
        
    }
    
    //MARK: - GET REQUEST API
    func makeGetRequest(searchString:String) {
        let url = NSURL(string: "https://api.nutritionix.com/v1_1/search/\(searchString)?results=0%3A20&cal_min=0&cal_max=50000&fields=item_name%2Cbrand_name%2Citem_id%2Cbrand_id&appId=\(kAppID)&appKey=\(kAppKey)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
            
            println(stringData)
            println(response)
            
            
        })
        task.resume()
        
    }
    //MARK: - POST REQUEST API
    func makePostRequest(searchString:String) {
        
        var request = NSMutableURLRequest(URL: NSURL(string: "https://api.nutritionix.com/v1_1/search/")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        //dictionary
        var params = ["appId" : kAppID, "appKey" : kAppKey, "fields" : ["item_name", "brand name", "keywords", "usda_fields"], "limits" : "50", "query" : searchString, "filters" : ["exists":["usda_fields" : true]]]
        
        var error: NSError?
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &error)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var task = session.dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
            
            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
            
            println(stringData)
            
            var conversionError:NSError?
            var jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: &conversionError) as? NSDictionary
            
            //println(jsonDictionary)
            
            if conversionError != nil {
                println(conversionError!.localizedDescription)
                let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Error in Parsing \(errorString)")
            }
            else {
                if jsonDictionary != nil {
                    self.jsonResponse = jsonDictionary!
                    self.apiSearchForFoods = DataController.jsonAsUSDAIdAndNameSearchResults(jsonDictionary!)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                    
                    
                }
                else {
                    let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not Parse JSON \(errorString)")
                    
                }
            }
            
        })
        task.resume()
        
    }
    
    // MARK: - Setup CoreData
    
    func requestFavoriteUSDAItems() {
        let fetchRequest = NSFetchRequest(entityName: "USDAItem")
        let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
        let managedObjectContext = appDelegate.managedObjectContext
        self.favoriteUSDAItems = managedObjectContext?.executeFetchRequest(fetchRequest, error: nil) as! [USDAItem]
        
    }
    
    // MARK: - NSNotification Center
    
    func usdaItemDidComplete(notification: NSNotification) {
        println("usdaItemDidComplete in ViewController")
        requestFavoriteUSDAItems()
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 2 {
            self.tableView.reloadData()
        }
    }
}
