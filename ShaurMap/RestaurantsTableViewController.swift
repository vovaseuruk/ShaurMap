//
//  RestaurantsTableViewController.swift
//  ShaurMap
//
//  Created by Vova Seuruk on 2/21/17.
//  Copyright © 2017 Vova Seuruk. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase
import Firebase
import Foundation

class RestaurantsTableViewController: UITableViewController, LocationServiceDelegate, RestaurantManagerDelegate {
    @IBOutlet weak var menuButton: UIBarButtonItem!

    private var restaurants = [Restaurant]()
    private var _manager : RestaurantManager!
    var _allRestaurantsAreFetched = false
    
    let numberOfPreloadedCells = 6
    
    private struct Storyboard {
        static let restaurantCellIdentifier = "restaurantCell"
        static let showRestaurant = "show Restaurant"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        
        _manager = RestaurantManager()
        _manager.delegate = self
        _manager.fetchFirstRestaurants(with: numberOfPreloadedCells)

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        LocationService.sharedInstance.delegate = self
        userLocation = LocationService.sharedInstance.currentLocation
    }
    
    //MARK: RestaurantManagerDelegate
    func didReceive(restaurants: [Restaurant]) {
        self.restaurants = restaurants
        tableView.reloadData()
    }
    
    func fetchingRestaurantsDidFail(with error: Error) {
        print("fetching Restaurants Did Fail with \(error.localizedDescription)")
    }

    //MARK: LocationServiceDelegate
    var userLocation : CLLocation?
    
    func tracingLocation(_ currentLocation: CLLocation) {
        userLocation = currentLocation
        tableView.reloadData()
    }
    
    func tracingLocationDidFailtWith(error: NSError) {
        print(error)
    }
    
    //MARK: UITableViewDelegate
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !_allRestaurantsAreFetched {
            _manager.fetchAllRestaurants()
            _allRestaurantsAreFetched = true 
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.restaurantCellIdentifier, for: indexPath) as! RestaurantTableViewCell
        
        let restaurant = restaurants[indexPath.row]
        
        cell.name.text = restaurant.name
        cell.businessHours.text = "Работает с \(restaurant.openHour):00 до \(restaurant.closeHour):00"
        cell.distance.text = getDistanceFrom(restaurant: restaurant)
        cell.adress.text = restaurant.adressString
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: restaurant.smallPicture)
            DispatchQueue.main.async {
                cell.restaurantImageView.image = UIImage(data: data!)!
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Storyboard.showRestaurant, sender: indexPath)
    }
    
    //MARK: Distance func
    func getDistanceFrom(restaurant: Restaurant) -> String{
        if  userLocation != nil{
            let distanceToCafeInKM = userLocation!.distance(from: restaurant.adress) / 1000
            if distanceToCafeInKM > 100{
                return "> 100 км"
            } else if distanceToCafeInKM < 0.1{
                return "< 100 метров"
            } else{
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 1
                return formatter.string(from: NSNumber(value: distanceToCafeInKM))! + " км"
            }
        } else {return "неизвестно"}
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.showRestaurant {
            let destinationVC = segue.destination as! RestaurantViewController
            destinationVC.restaurant = restaurants[(sender as! IndexPath).row]
        }
    }

}
