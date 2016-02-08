//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Oscar G.M on 1/22/16.
//  Copyright © 2016 GMStudios. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchResultsUpdating {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorView: UIView!
    var movies: [NSDictionary]?
    var apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
    var session = NSURLSession(
        configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
        delegate: nil,
        delegateQueue: NSOperationQueue.mainQueue()
    )
    var endpoint: String!
    var searchController: UISearchController!
    var filteredData: [NSDictionary]?

    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        
        
        var title = ""
        if(endpoint == "now_playing"){
            title = "Now Playing"
        }
        else{
            title = "Top Rated"
        }
        
        self.navigationItem.title = "\(title)"
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = UIColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 0.8)
            navigationBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFontOfSize(22),
                NSForegroundColorAttributeName : UIColor(red: 0.5, green: 0.15, blue: 0.15, alpha: 0.8),
            ]
        }
        
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)

        
        tableView.dataSource = self
        tableView.delegate = self
        errorView.hidden = true
        
        // Do any additional setup after loading the view.
        loadInitialData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let movies = filteredData{
            return movies.count
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell",forIndexPath: indexPath) as! MovieCell
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        
        let movie = self.filteredData![indexPath.row]
        let title = movie["title"] as! String
        cell.titleLabel.text = title
        
        let overview = movie["overview"] as! String
        cell.overviewLabel.text = overview
        
        if let posterPath = movie["poster_path"] as? String{
            let baseUrl = "http://image.tmdb.org/t/p/w500"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        else{
            cell.posterView.image = nil
        }
        
        return cell
    }
    
    
    
    func loadInitialData(){
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = responseDictionary["results"] as? [NSDictionary]
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            self.tableView.reloadData()
                            self.errorView.hidden = true
                    }
                    
                }
                if let returnedError = error{
                    self.errorView.hidden = false
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    print(returnedError)
                }
        })
        task.resume()
        

    }
    
    
    func refreshControlAction(refreshControl: UIRefreshControl){
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)

        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = responseDictionary["results"] as? [NSDictionary]
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            self.errorView.hidden = true
                            self.tableView.reloadData()
                            refreshControl.endRefreshing()
                    }
                }
                if let returnedError = error{
                    self.errorView.hidden = false
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    refreshControl.endRefreshing()
                    print(returnedError)
                }
        })
        task.resume()
    }

    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text{
            self.filteredData = searchText.isEmpty ? self.movies! : self.movies!.filter({
                ($0["title"]! as! String).rangeOfString(searchText,options: .CaseInsensitiveSearch) != nil
            })
            tableView.reloadData()
        }
       
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        tableView.deselectRowAtIndexPath(indexPath!, animated: false)
        let movie = movies![indexPath!.row]
        let detailVC = segue.destinationViewController as! DetailViewController
        detailVC.movie = movie
        
        
    }

}
