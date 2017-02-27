//
//  ContainerViewController.swift
//  DDDispatcher
//
//  Created by Woo Jin Kye on 2017. 2. 27..
//  Copyright © 2017년 DD Dispatcher. All rights reserved.
//

import UIKit
import QuartzCore
import Firebase

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


enum SlideOutState {
    case menuCollapsed
    case menuExpanded
}


class ContainerViewController: UIViewController, HubViewControllerDelegate, UIGestureRecognizerDelegate {
    
    var HubNavigationController: UINavigationController!
    var HubViewController: HubViewController!
    
    var currentState: SlideOutState = .menuCollapsed {
        didSet {
            let shouldShowShadow = currentState != .menuCollapsed
            showShadowForHubViewController(shouldShowShadow)
        }
    }
    
    var menuViewController: MenuViewController?
    
    // This defines how much the center view will show on the right when the menu is shown on the left.
    let centerPanelExpandedOffset: CGFloat = 60
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Create a HubViewController object using UIStoryboard's private extension class method and
         store its object reference into the instance variable HubViewController.
         */
        HubViewController = UIStoryboard.HubViewController()
        
        // Designate self as the delegate to implement and execute the HubViewControllerDelegate protocol methods.
        HubViewController.delegate = self
        
        HubNavigationController = UINavigationController(rootViewController: HubViewController)
        view.addSubview(HubNavigationController.view)
        
        // Add HubNavigationController as a child view controller
        addChildViewController(HubNavigationController)
        
        // didMoveToParentViewController is called after a view controller is added to or removed from a container view controller.
        HubNavigationController.didMove(toParentViewController:self)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(ContainerViewController.handlePanGesture(_:)))
        
        // Attach the pan gesture recognizer object to the HubNavigationController object.
        HubNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    /*
     ---------------------------------------------------
     MARK: - HubViewControllerDelegate Protocol Methods
     ---------------------------------------------------
     */
    func toggleMenuView() {
        
        let notAlreadyExpanded = (currentState != .menuExpanded)
        
        if notAlreadyExpanded {
            addMenuViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func collapseMenuView() {
        
        switch (currentState) {
        case .menuExpanded:
            toggleMenuView()
        default:
            break
        }
    }
    
    /*
     --------------------------------
     MARK: - Add Menu View Controller
     --------------------------------
     */
    func addMenuViewController() {
        
        if (menuViewController == nil) {
            
            /*
             Create a MenuViewController object using UIStoryboard's private extension class method and
             store its object reference into the instance variable menuViewController.
             */
            menuViewController = UIStoryboard.menuViewController()
            
            // Designate HubViewController as the delegate to implement and execute the MenuViewControllerDelegate protocol methods.
            menuViewController!.delegate = HubViewController
            
            view.insertSubview(menuViewController!.view, at: 0)
            
            // Add menuViewController as a child view controller
            addChildViewController(menuViewController!)
            
            // didMoveToParentViewController is called after a view controller is added to or removed from a container view controller.
            menuViewController!.didMove(toParentViewController: self)
        }
    }
    
    /*
     ---------------------------
     MARK: - Animate Pan Gesture
     ---------------------------
     */
    func animateLeftPanel(shouldExpand: Bool) {
        
        if (shouldExpand) {
            currentState = .menuExpanded
            
            animateCenterPanelXPosition(targetPosition:HubNavigationController.view.frame.width - centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.currentState = .menuCollapsed
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options:UIViewAnimationOptions(), animations: {
            self.HubNavigationController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func showShadowForHubViewController(_ shouldShowShadow:Bool) {
        
        if (shouldShowShadow) {
            HubNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            HubNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
    /*
     --------------------------
     MARK: - Handle Pan Gesture
     --------------------------
     */
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in:view).x > 0)
        let gestureIsDraggingFromRightToLeft = (recognizer.velocity(in:view).x < 0)
        
        switch(recognizer.state) {
        case .began:
            if (currentState == .menuCollapsed) {
                if (gestureIsDraggingFromLeftToRight) {
                    addMenuViewController()
                    showShadowForHubViewController(true)
                }
            }
        case .changed:
            if menuViewController != nil && ((gestureIsDraggingFromRightToLeft && recognizer.view?.center.x > 187.5) || (gestureIsDraggingFromLeftToRight && recognizer.translation(in: view).x >= 0)) {
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
                recognizer.setTranslation(CGPoint.zero, in: view)
            }
        case .ended:
            if menuViewController != nil {
                // Animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        }
    }
}

/*
 ------------------------------------
 MARK: - Storyboard Private Extension
 ------------------------------------
 */
private extension UIStoryboard {
    
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func menuViewController() -> MenuViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier:"MenuViewController") as? MenuViewController
    }
    
    class func HubViewController() -> HubViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier:"HubViewController") as? HubViewController
    }
    
}
