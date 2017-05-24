//
//  ViewController.swift
//  oper_syst_2
//
//  Created by Aleksandr Kozhevnikov on 26/02/2017.
//  Copyright © 2017 Aleksandr Kozhevnikov. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var runnedTableView: NSTableView!
    @IBOutlet weak var quiueTableView: NSTableView!
    @IBOutlet weak var logScrollView: NSScrollView!
    @IBOutlet weak var logTable: NSTableView!
    
    @IBOutlet var logWindow: NSTextView!
    
    @IBOutlet weak var startBtn: NSButton!
    
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logTable.delegate = self
        logTable.dataSource = self
        quiueTableView.delegate = self
        quiueTableView.dataSource = self
        runnedTableView.delegate = self
        runnedTableView.dataSource = self

        
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func click(_ sender: NSButton) {
        spinner.startAnimation(self)
        startTM(sender: self)
    }
    
    @IBAction func clickStopBtn(_ sender: NSButton) {
        spinner.stopAnimation(self)
        stopTM()
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView.identifier == "logTableView"{
            return logItems.count
        }else if tableView.identifier == "quiueTableView"{
            let tm = TaskManager.sharedInstance
            let quiue = Array(tm.processQuiue!)
            return quiue.count
        } else{
            let tm = TaskManager.sharedInstance
            let runned = Array(tm.runned!)
            return runned.count
        }
        
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let tableColumn = tableColumn else{
            return nil
        }
        
        var cellId: String
        var text: String
        
        if tableView.identifier == "logTableView"{
            
            let item = logItems[row]
            
            switch tableColumn.identifier {
            case "timeColumn":
                cellId = "timeCell"
                text = item.time
                break
            case "operationColumn":
                cellId = "operationCell"
                text = item.operation
                break
            default:
                return nil
            }
        }else if tableView.identifier == "quiueTableView"{
            let tm = TaskManager.sharedInstance
            var processes = Array(tm.processQuiue!.values)
            guard processes.count > row else {
                return nil
            }
          //  processes.sort{ $0.priority > $1.priority }
            let process = processes[row]

            switch tableColumn.identifier {
            case "pidColumn":
                cellId = "pidCell"
                text = process.id
                break
            case "taskColumn":
                cellId = "taskCell"
                text = process.description
                break
            case "priorityColumn":
                cellId = "priorityCell"
                text = String(process.priority)
                break
            default:
                return nil
            }

        }else if tableView.identifier == "runnedTableView"{
            let tm = TaskManager.sharedInstance
            var processes = Array(tm.runned!.values)
          //  processes.sort{ $0.priority > $1.priority }
            let process = processes[row]
            switch tableColumn.identifier {
            case "pidColumn":
                cellId = "runnedpidCell"
                text = process.id
                break
            case "taskColumn":
                cellId = "runnedtaskCell"
                text = process.description
                break
            case "priorityColumn":
                cellId = "runnedpriorityCell"
                text = String(process.priority)
                break
            default:
                return nil
            }
        }else{
            return nil
        }
        
        if let cell = tableView.make(withIdentifier: cellId, owner: nil) as? NSTableCellView{
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
}

