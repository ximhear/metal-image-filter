//
//  MasterViewController.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/8/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: ImageFilterViewController? = nil
    var objects = [GImageFilterType]()
    var image: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        objects.append(.gaussianBlur2D)
        objects.append(.saturationAdjustment)
        objects.append(.rotation)
        objects.append(.colorGBR)
        objects.append(.sepia)
        objects.append(.pixellation)
        objects.append(.luminance)
        objects.append(.normalMap)
        objects.append(.invert)
        objects.append(.mpsUnaryImageKernel(type: .sobel))
        objects.append(.mpsUnaryImageKernel(type: .gaussianBlur))
        // Do any additional setup after loading the view.
        
        image = UIImage(named: "autumn")

        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ImageFilterViewController
            detailViewController?.image = self.image
            detailViewController?.imageChanged = {[weak self] image in
                self?.image = image
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let type = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! ImageFilterViewController
                controller.filterType = type
                controller.image = self.image
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.imageChanged = {[weak self] image in
                    self?.image = image
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel!.text = object.name
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

