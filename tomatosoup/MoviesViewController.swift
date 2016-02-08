//
//  MoviesViewController.swift
//  tomatosoup
//
//  Created by Andrew Yu on 1/31/16.
//  Copyright © 2016 Andrew Yu. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var tableView         : UITableView!
    @IBOutlet weak var networkErrorView  : UIView!
    @IBOutlet weak var searchBar         : UISearchBar!
    @IBOutlet weak var moviesGridView    : UICollectionView!
    @IBOutlet weak var navigationBarItem : UINavigationItem!
    @IBOutlet weak var gridOrListViewSegmentedControl: UISegmentedControl!

    // Instance vars to be used throughout
    var movies            : [NSDictionary]?
    var endpoint          : String!
    var filteredMovieList : [NSDictionary]?
    var refreshControlTableView = UIRefreshControl()
    var refreshControlGridView  = UIRefreshControl()
    
    func fetch(){

        let apiKey  = "d23bc0006baa4989f2aa2827a78bd40e"
        let url     = NSURL(string: "http://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                if error == nil {

                    self.networkErrorView.hidden = true
                    
                    if let data = dataOrNil {
    
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
    
                        if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data, options:[]) as? NSDictionary {
                            // NSLog("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredMovieList = self.movies!
                            self.tableView.reloadData()
                        }
                    }
                }
                else {
                    self.networkErrorView.hidden = false
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
        })
        task.resume()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateNavBarTitleAndStyling()
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Initialize cells as the movie's view controller to be the data source and delegate
        tableView.dataSource = self
        tableView.delegate   = self
        searchBar.delegate   = self
        moviesGridView.dataSource = self
        moviesGridView.delegate   = self
        
        gridOrListViewSegmentedControl.selectedSegmentIndex = 0
        
        // Fetch all data
        fetch()
        
        // RefreshControl for table and collection view
        refreshControlTableView = UIRefreshControl()
        refreshControlTableView.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.insertSubview(refreshControlTableView, atIndex: 0)
        
        refreshControlGridView = UIRefreshControl()
        refreshControlGridView.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.moviesGridView.insertSubview(refreshControlGridView, atIndex: 0)
    }

    @IBAction func onChangeListOrGrid(sender: AnyObject) {
        if gridOrListViewSegmentedControl.selectedSegmentIndex == 1 {
            tableView.hidden = true
            moviesGridView.reloadData()
        }
        else {
            tableView.hidden = false
            tableView.reloadData()
        }
    }

    func onRefresh() -> Void {
        self.fetch()
        if gridOrListViewSegmentedControl.selectedSegmentIndex == 0 {
            self.refreshControlTableView.endRefreshing()
        } else {
            self.refreshControlGridView.endRefreshing()
        }
    }
    
    func updateNavBarTitleAndStyling(){
        // Set navbar title
        if(endpoint == "now_playing"){
            navigationBarItem.title = "Now Playing"
        }
        else {
            navigationBarItem.title = "Top Rated"
        }
        
        // set navbar styling
        if let navigationBar = navigationController?.navigationBar {
            
            navigationBar.backgroundColor = UIColor(red:0.55, green:0.65, blue:0.73, alpha:1.0)
        }

    }
    
    
    // MARK: - Table View delegate and data methods
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = filteredMovieList {
            return movies.count
        }
        // Case for nil
        else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        cell.backgroundColor = UIColor(red:0.81, green:0.89, blue:0.95, alpha:1.0)
        // Custom selectedBackgroundView
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red:0.55, green:0.65, blue:0.73, alpha:1.0)
        cell.selectedBackgroundView = backgroundView
        
        // Create movie object
        let movie    = filteredMovieList![indexPath.row]
        let title    = movie["title"] as! String
        let overview = movie["overview"] as! String

        // Set values of labels on interface
        cell.titleLabel.text    = title
        cell.overviewLabel.text = overview
        
        // Set image: following code grabs image from url
        let baseUrl    = "http://image.tmdb.org/t/p/w500"

        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath )!
            let imageRequest = NSURLRequest(URL: imageUrl)

            // Set image with animations for image loading
            cell.posterView.setImageWithURLRequest(
                imageRequest,
                placeholderImage: nil,
                success: {(imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if image is cached
                    if imageResponse != nil {
                        // image was NOT cached so fade in the image
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animateWithDuration(0.7, animations: {() -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    }
                    else {
                        print("image was cached so just update the image")
                        cell.posterView.image = image
                    }
                
                },
                failure: {(imageRequest, imageResponse, image) -> Void in
                    // do something for failure condition
                }
            )
            
        }
        
        // print("row \(indexPath.row)")
        return cell
    }
    
    // Deselects cell once selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: - Collection View delegate and data methods
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movies = filteredMovieList {
            return movies.count
        }
            // Case for nil
        else {
            return 0
        }

    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = moviesGridView.dequeueReusableCellWithReuseIdentifier("MovieGridCell", forIndexPath: indexPath) as! MovieCollectionViewCell
        let movie    = filteredMovieList![indexPath.row]
        
        cell.backgroundColor = UIColor(red:0.81, green:0.89, blue:0.95, alpha:1.0)
        
        // Custom selectedBackgroundView
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red:0.55, green:0.65, blue:0.73, alpha:1.0)
        cell.selectedBackgroundView = backgroundView
        
        
        let title    = movie["title"] as! String
        
        // Set values of labels on interface
        cell.titleLabel.text    = title
        
        // Set image: following code grabs image from url
        let baseUrl    = "http://image.tmdb.org/t/p/w500"
        
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath )!
            let imageRequest = NSURLRequest(URL: imageUrl)
            
            // Set image with animations for image loading
            cell.posterView.setImageWithURLRequest(
                imageRequest,
                placeholderImage: nil,
                success: {(imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if image is cached
                    if imageResponse != nil {
                        print("image was NOT cached so lets fade in the image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animateWithDuration(0.7, animations: {() -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    }
                    else {
                        print("image was cached so just update the image")
                        cell.posterView.image = image
                    }
                    
                },
                failure: {(imageRequest, imageResponse, image) -> Void in
                    // do something for failure condition
                }
            )
            
        }
        
        // print("row \(indexPath.row)")
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Search bar related
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        filteredMovieList = searchText.isEmpty ? movies : movies!.filter({(movie: NSDictionary) -> Bool in
            let title = movie["title"] as? String
            return title!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        
        // Reload data depending on which view type
        if gridOrListViewSegmentedControl.selectedSegmentIndex == 1 {
            moviesGridView.reloadData()
        } else {
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: - Navigation
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        print("prepare for segue called")
        
        if gridOrListViewSegmentedControl.selectedSegmentIndex == 1 {
            let cell      = sender as! UICollectionViewCell
            let indexPath = moviesGridView.indexPathForCell(cell)
            let movie = movies![indexPath!.row]
            // Define var casted to custom class DetailViewController
            let detailViewController = segue.destinationViewController as! DetailViewController
            // Set NSDict that we created in detailViewCtrl to movie data populated here
            detailViewController.movie = movie
            
        }
        else {
            let cell      = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            let movie     = movies![indexPath!.row]
            // Define var casted to custom class DetailViewController
            let detailViewController = segue.destinationViewController as! DetailViewController
            // Set NSDict that we created in detailViewCtrl to movie data populated here
            detailViewController.movie = movie
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
















