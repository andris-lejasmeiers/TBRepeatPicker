//
//  TBRPPresetRepeatController.swift
//  TBRepeatPicker
//
//  Created by hongxin on 15/9/23.
//  Copyright © 2015年 Teambition. All rights reserved.
//

import UIKit

private let TBRPPresetRepeatCellID = "TBRPPresetRepeatCell"

@objc public protocol TBRepeatPickerDelegate {
    func didPickRecurrence(recurrence: TBRecurrence?, repeatPicker: TBRepeatPicker)
}

public class TBRPPresetRepeatController: UITableViewController, TBRPCustomRepeatControllerDelegate {
    // MARK: - Public properties
    public var occurrenceDate = NSDate()
    public var language: TBRPLanguage = .English
    public var delegate: TBRepeatPickerDelegate?
    
    public var recurrence: TBRecurrence? {
        didSet {
            setupSelectedIndexPath(recurrence)
        }
    }
    public var selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    // MARK: - Private properties
    private var recurrenceBackup: TBRecurrence?
    private var presetRepeats = [String]()
    private var internationalControl: TBRPInternationalControl?
    
    // MARK: - View life cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        commonInit()
    }
    
    private func commonInit() {
        internationalControl = TBRPInternationalControl(language: language)
        navigationItem.title = internationalControl?.localized("TBRPPresetRepeatController.navigation.title", comment: "Repeat")
        
        presetRepeats = TBRPHelper.presetRepeats(language)
        
        if let _ = recurrence {
            recurrenceBackup = recurrence!.recurrenceCopy()
        }
    }
    
    override public func didMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            // navigation was popped
            if TBRecurrence.isEqualRecurrence(recurrence, recurrence2: recurrenceBackup) == false {
                if let _ = delegate {
                    delegate?.didPickRecurrence(recurrence, repeatPicker: self as! TBRepeatPicker)
                }
            }
        }
    }
    
    // MARK: - Helper
    private func setupSelectedIndexPath(recurrence: TBRecurrence?) {
        if recurrence == nil {
            selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        } else if recurrence?.isWeekdayRecurrence() == true {
            selectedIndexPath = NSIndexPath(forRow: 1, inSection: 0)
        } else {
            selectedIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        }
    }
    
    private func updateRecurrence(indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            return
        }
        
        switch indexPath.row {
        case 0:
            recurrence = nil
            
        case 1:
            recurrence = TBRecurrence.weekdayRecurrence(occurrenceDate)
            
        default:
            break
        }
    }
    
    private func updateFooterTitle() {
        let footerView = tableView.footerViewForSection(1)
        
        tableView.beginUpdates()
        footerView?.textLabel?.text = footerTitle()
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }
    
    private func footerTitle() -> String? {
        if let _ = recurrence {
            if selectedIndexPath.section == 0 {
                return nil
            }
            return TBRPHelper.recurrenceString(recurrence!, occurrenceDate: occurrenceDate, language: language)
        }
        return nil
    }
    
    // MARK: - Table view data source
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return presetRepeats.count
        } else {
            return 1
        }
    }
    
    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    override public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && recurrence != nil {
            return footerTitle()
        }
        return nil
    }
    
    override public func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if view.isKindOfClass(UITableViewHeaderFooterView) {
            let tableViewHeaderFooterView = view as! UITableViewHeaderFooterView
            tableViewHeaderFooterView.textLabel?.font = UIFont.systemFontOfSize(CGFloat(13.0))
        }
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(TBRPPresetRepeatCellID)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: TBRPPresetRepeatCellID)
        }
        
        if indexPath.section == 1 {
            cell?.accessoryType = .DisclosureIndicator
            cell?.textLabel?.text = internationalControl?.localized("TBRPPresetRepeatController.textLabel.custom", comment: "Custom")
        } else {
            cell?.accessoryType = .None
            cell?.textLabel?.text = presetRepeats[indexPath.row]
        }
        
        cell?.imageView?.image = UIImage(named: "TBRP-Checkmark", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)?.imageWithRenderingMode(.AlwaysTemplate)
        
        if indexPath == selectedIndexPath {
            cell?.imageView?.hidden = false
        } else {
            cell?.imageView?.hidden = true
        }
        
        return cell!
    }

    // MARK: - Table view delegate
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let lastSelectedCell = tableView.cellForRowAtIndexPath(selectedIndexPath)
        let currentSelectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        lastSelectedCell?.imageView?.hidden = true
        currentSelectedCell?.imageView?.hidden = false
        
        selectedIndexPath = indexPath
        
        if indexPath.section == 1 {
            let customRepeatController = TBRPCustomRepeatController(style: .Grouped)
            customRepeatController.occurrenceDate = occurrenceDate
            customRepeatController.language = language
            
            if let _ = recurrence {
                customRepeatController.recurrence = recurrence!
            } else {
                customRepeatController.recurrence = TBRecurrence.dailyRecurrence(occurrenceDate)
            }
            customRepeatController.delegate = self
            
            navigationController?.pushViewController(customRepeatController, animated: true)
        } else {
            updateRecurrence(indexPath)
            updateFooterTitle()
            
            navigationController?.popViewControllerAnimated(true)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - TBRPCustomRepeatController delegate
    func didFinishPickingCustomRecurrence(recurrence: TBRecurrence) {
        self.recurrence = recurrence
        updateFooterTitle()
        tableView.reloadData()
    }
}
