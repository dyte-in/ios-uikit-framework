//
//  DyteGridView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 06/01/23.
//

import UIKit


class GridView<CellContainerView: UIView>: UIView {
    
    struct Paddings {
        let top: CGFloat = 20
        let bottom: CGFloat = 20
        let leading: CGFloat = 10
        let trailing: CGFloat = 10
        let interimPadding: CGFloat = 10
    }
    
    let maxItems: UInt
    private let maxItemsInRow: UInt = 2
    private let paddings = Paddings()
    private var views: [CellContainerView]!
    private var frames: [CGRect]!
    
    private var currentVisibleItem: UInt
    private var previousAnimation = true
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    private let getChildView: ()->CellContainerView
    private let scrollView = UIScrollView()
    private let scrollContentView = UIView()

    init(maxItems: UInt = 9, showingCurrently: UInt, getChildView: @escaping()->CellContainerView) {
        self.maxItems = maxItems
        self.getChildView = getChildView
        if isDebugModeOn {
            print("Debug DyteUIKit | Creating GridView showingCurrently \(showingCurrently)")
        }
        self.currentVisibleItem = showingCurrently
        super.init(frame: .zero)
        self.createSubView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func settingFrames(visibleItemCount: UInt, animation: Bool = true, completion:@escaping(Bool)->Void) {
    
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        self.layoutIfNeeded()
        self.frames = self.frame(itemsCount: visibleItemCount, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
        self.scrollContentView.get(.width)?.constant = self.scrollView.frame.width
        self.initialize(views: self.views, frames: self.frames, animation: animation, completion: completion)
    }
    
    func settingFramesForHorizontal(visibleItemCount: UInt, animation: Bool = true, completion:@escaping(Bool)->Void) {
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        self.frames = self.getFramesForHorizontal(itemsCount: visibleItemCount, height: self.scrollContentView.frame.height)
        self.scrollContentView.get(.width)?.constant = (self.frames.last?.maxX ?? 0) + paddings.trailing
        self.initialize(views: self.views, frames: self.frames, animation: animation, completion: completion)
    }
    
    func childView(index: Int) -> CellContainerView? {
        if index >= 0 && index < maxItems {
            return self.views[index]
        }
        return nil
    }
    
}

extension GridView {
    
   private func getFramesForHorizontal(itemsCount: UInt, height: CGFloat) -> [CGRect] {
        var x = paddings.leading
        let interimSpacing = paddings.interimPadding * (CGFloat(itemsCount) - 1)
        let widthSpace = (paddings.leading + paddings.trailing + interimSpacing)
        let width = height * 0.8
        let height = height - (paddings.top + paddings.bottom)
        
        var result = [CGRect]()
        for _ in 0..<itemsCount {
            let frame = CGRect(x: x, y: paddings.top, width: width, height: height)
            x += (paddings.interimPadding + width)
            result.append(frame)
        }
        return result
    }
}

extension GridView {
    
    private func createSubView() {
        self.addSubViews(self.scrollView)
        self.scrollView.set(.fillSuperView(self))
        self.scrollView.addSubview(self.scrollContentView)
        self.scrollContentView.set(.fillSuperView(self.scrollView), .width(0))
        self.scrollContentView.set(.equateAttribute(.height, toView: self.scrollView, toAttribute: .height, withRelation: .equal))
        self.views = self.createView(baseView: self.scrollContentView)
    }
    
    private func createView(baseView: UIView) -> [CellContainerView] {
        var result = [CellContainerView] ()
        for i in 0..<maxItems {
            let view = self.getChildView()
            view.tag = Int(i)
            view.translatesAutoresizingMaskIntoConstraints = false
            baseView.addSubview(view)
            result.append(view)
            if isDebugModeOn {
                let label = UIUTility.createLabel(text:"View No: \(i) test \(view)")
                label.textColor = .black
                label.layer.zPosition = 1.0
                view.addSubview(label)
                label.numberOfLines = 0
                label.set(.centerY(view), .sameLeadingTrailing(view, 20))
            }
        }
        return result
    }
    
    private func initialize(views: [CellContainerView], frames: [CGRect], animation: Bool, completion:@escaping(Bool)->Void) {
        
        if animation {
            if isDebugModeOn {
                print("Debug DyteUIKit | loading Child view with Animations == true")
            }
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                let viewToShow = frames.count
                for i in 0..<views.count {
                    let view = views[i]
                    
                    if i < viewToShow {
                        if view.get(.top) == nil {
                            view.set(.top(self.scrollContentView,frames[i].minY))
                        }
                        if view.get(.leading) == nil {
                            view.set(.leading(self.scrollContentView, frames[i].minX))
                        }
                        if view.get(.width) == nil {
                            view.set(.width(frames[i].width))
                        }
                        if view.get(.height) == nil {
                            view.set(.height(frames[i].height))
                        }
                        view.get(.top)?.constant = frames[i].minY
                        view.get(.leading)?.constant = frames[i].minX
                        view.get(.width)?.constant = frames[i].width
                        view.get(.height)?.constant = frames[i].height
                    }
                    else {
                        
                        if view.get(.width) == nil {
                            view.set(.width(0))
                        }
                        if view.get(.height) == nil {
                            view.set(.height(0))
                        }
                        view.get(.width)?.constant = 0
                        view.get(.height)?.constant = 0
                    }
                }
                self.scrollContentView.layoutIfNeeded()
            } completion: { finish in
                completion(finish)
            }
        }
        else {
            if isDebugModeOn {
                print("Debug DyteUIKit | loading Child view with Animations == false")
            }
            
            let viewToShow = frames.count
            for i in 0..<views.count {
                let view = views[i]
                if i < viewToShow {
                    if view.get(.top) == nil {
                        view.set(.top(self.scrollContentView,frames[i].minY))
                    }
                    if view.get(.leading) == nil {
                        view.set(.leading(self.scrollContentView, frames[i].minX))
                    }
                    if view.get(.width) == nil {
                        view.set(.width(frames[i].width))
                    }
                    if view.get(.height) == nil {
                        view.set(.height(frames[i].height))
                    }
                    view.get(.top)?.constant = frames[i].minY
                    view.get(.leading)?.constant = frames[i].minX
                    view.get(.width)?.constant = frames[i].width
                    view.get(.height)?.constant = frames[i].height
                } else {
                    
                    if view.get(.width) == nil {
                        view.set(.width(0))
                    }
                    if view.get(.height) == nil {
                        view.set(.height(0))
                    }
                    view.get(.width)?.constant = 0
                    view.get(.height)?.constant = 0
                }
            }
            completion(true)
        }
        
    }
    
    private func frame(itemsCount: UInt, width: CGFloat , height: CGFloat) -> [CGRect] {
        if isDebugModeOn {
            print("Debug DyteUIKit | frame(itemsCount Width \(width) Height \(height) ")
        }
        let itemsCount = itemsCount > maxItems ? maxItems : itemsCount
        let rows = numOfRows(itemsCount: itemsCount, width: width, height: height)
        if rows == 1 {
            if itemsCount == 1 {
                let itemWidth = width - (paddings.leading + paddings.trailing)
                let itemHeight = height - (paddings.top + paddings.bottom)
                return [CGRect(x: paddings.leading, y: paddings.top, width: itemWidth, height: itemHeight)]
            } else {
                let rowHeight = height
                let rowWidht = width
                let firsRowFrame = CGRect(x: paddings.leading, y: paddings.top, width: rowWidht, height: rowHeight)
                let framesFirstRow = self.getFrameForOnlyTwoViewInRow(items: UInt(itemsCount), rowFrame: firsRowFrame)
                return framesFirstRow
            }
        }
        
        if rows == 2 && itemsCount <= (2 * maxItemsInRow) {
            var result = [CGRect]()
            
            let itemCountIsEven = itemsCount%2 == 0 ? true : false
            var firstRowCount = CGFloat(itemsCount)/2.0
            let secondRowCount = firstRowCount
            if itemCountIsEven == false {
                firstRowCount = firstRowCount + 1
            }
            
            let rowHeight = height/CGFloat(rows)
            let rowWidht = width
            let firsRowFrame = CGRect(x: paddings.leading, y: paddings.top, width: rowWidht, height: rowHeight)
            let framesFirstRow = self.getFrameForFirstRow(items: UInt(firstRowCount), rowFrame: firsRowFrame)
            let framesSecondRow = self.getFrameForLastRow(items: UInt(secondRowCount), rowFrame: CGRect(x: paddings.leading, y: rowHeight, width: rowWidht, height: rowHeight))
            result.append(contentsOf: framesFirstRow)
            result.append(contentsOf: framesSecondRow)
            return result
        }
        
        return self.frame(itemsCount: itemsCount, rows: rows, width: width, height: height)
    }
    
    private func frame(itemsCount: UInt, rows: UInt, width: CGFloat , height: CGFloat) -> [CGRect]  {
        let rowHeight = height/CGFloat(rows)
        let rowWidth = width
        var result = [CGRect]()
        var items: UInt = 0
        var y: CGFloat = 0.0
        for row in 1...rows {
            if row == 1 {
                // First row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForFirstRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow
                
            }else if row == rows {
                
                // Last row items can be less than 'maxItemsInRow'
                var itemsLeft = itemsCount - items
                if itemsLeft > maxItemsInRow {
                    itemsLeft = maxItemsInRow
                }
                result.append(contentsOf: getFrameForLastRow(items: itemsLeft, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += itemsLeft
                
            }else {
                // Middle row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForMiddleRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow
            }
            y += rowHeight
        }
        
        return result
    }
    
    private func getFrameForOnlyTwoViewInRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let top = paddings.top
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame:CGRect?
        
        let totalInterimSpace = (CGFloat(items)-1)*paddings.interimPadding
        let itemWidht = (rowFrame.width - (paddings.leading + paddings.trailing + totalInterimSpace))/CGFloat(items)
        let itemHeight = rowFrame.height - (paddings.top + paddings.bottom)
        
        for _ in 0..<items {
            if let preFrame = preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidht, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }
        
        return result
    }
    
    private func getFrameForFirstRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let top = paddings.top
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame:CGRect?
        
        let totalInterimSpace = (CGFloat(items)-1)*paddings.interimPadding
        let itemWidht = (rowFrame.width - (paddings.leading + paddings.trailing + totalInterimSpace))/CGFloat(items)
        let itemHeight = rowFrame.height - (paddings.top) - (paddings.interimPadding/2.0)
        
        for _ in 0..<items {
            if let preFrame = preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidht, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }
        
        return result
    }
    
    private func getFrameForMiddleRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let halfInterimSpace = paddings.interimPadding/2.0
        let top = rowFrame.origin.y + halfInterimSpace
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame:CGRect?
        
        let totalInterimSpace = (CGFloat(items)-1)*paddings.interimPadding
        let totalPaddingSpace = paddings.leading + paddings.trailing + totalInterimSpace
        let itemWidht = (rowFrame.width - totalPaddingSpace)/CGFloat(items)
        let itemHeight = rowFrame.height - paddings.interimPadding
        
        for _ in 0..<items {
            if let preFrame = preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidht, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }
        
        return result
    }
    
    private func getFrameForLastRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let top = rowFrame.origin.y + (paddings.interimPadding/2.0)
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame:CGRect?
        let totalInterimSpace = (CGFloat(items)-1)*paddings.interimPadding
        let totalPaddingSpace = paddings.leading + paddings.trailing + totalInterimSpace
        
        let itemWidht = (rowFrame.width - totalPaddingSpace)/CGFloat(items)
        let itemHeight = rowFrame.height - (paddings.bottom) - (paddings.interimPadding/2.0)
        
        for _ in 0..<items {
            if let preFrame = preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidht, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }
        return result
    }
    
    private func numOfRows(itemsCount: UInt, width: CGFloat , height: CGFloat) -> UInt {
        if itemsCount == 1 {
            return 1
        }
        if itemsCount == 2 && width >= height {
            return 1
        }
        let maxElementsInTwoRows = maxItemsInRow * 2
        if itemsCount <= maxElementsInTwoRows {
            return 2
        }
        return UInt(ceil(Float64(itemsCount)/CGFloat(maxItemsInRow)))
    }
    
}


class DyteMeetingGridView {
    
}
