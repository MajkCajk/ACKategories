import UIKit
import os.log

extension Base {
    
    /// Turn on/off logging of init/deinit of all FCs
    /// ⚠️ Has no effect when Base.memoryLoggingEnabled is true
    public static var flowCoordinatorMemoryLoggingEnabled: Bool = true
    
    /** Handles view controllers connections and flow
     
     Starts with one of `start()` methods and ends with `stop()`.
     
     All start methods are supposed to be overriden and property `rootViewController` must be set in the end of the overriden implementation to avoid memory leaks.
     Don't forget to call super.start().
     */
    open class FlowCoordinator<DeepLinkType>: NSObject, UINavigationControllerDelegate {
        
        /// Reference to the navigation controller used within the flow
        public weak var navigationController: UINavigationController?
        
        /// First VC of the flow. Must be set when FC starts.
        public weak var rootViewController: UIViewController!
        
        /// Parent coordinator
        public weak var parentCoordinator: FlowCoordinator?
        
        /// Array of child coordinators
        public var childCoordinators = [FlowCoordinator]()

        /// Currently active coordinator
        public weak var activeChild: FlowCoordinator?
        
        // MARK: - Lifecycle
        
        /// Just start and return rootViewController. Object calling this method will connect returned view controller to the flow.
        @discardableResult
        open func start() -> UIViewController {
            checkRootViewController()
            
            return UIViewController()
        }
        
        /// Start in window. Window's root VC is supposed to be set.
        open func start(in window: UIWindow) {
            checkRootViewController()
        }
        
        /// Start within existing navigation controller.
        open func start(with navigationController: UINavigationController) {
            self.navigationController = navigationController
            navigationController.delegate = self
            
            checkRootViewController()
        }
        
        /// Start by presenting from given VC. This method must be overriden by subclass.
        open func start(from viewController: UIViewController) {
            checkRootViewController()
        }
        
        /// Clean up. Must be called when FC finished the flow to avoid memory leaks and unexpcted behavior.
        open func stop(animated: Bool = false) {
            
            // stop all children
            childCoordinators.forEach { $0.stop(animated: animated) }
            
            // dismiss all VCs presented from root or nav
            if rootViewController.presentedViewController != nil {
                rootViewController.dismiss(animated: animated)
            }
            
            // dismiss when root was presented
            rootViewController.presentingViewController?.dismiss(animated: animated)
            
            // pop all view controllers when started within navigation controller
            if let index = navigationController?.viewControllers.firstIndex(of: rootViewController) {
                // VCs to be removed from navigation stack
                let toRemoveViewControllers = navigationController.flatMap { Array($0.viewControllers[index..<$0.viewControllers.count]) } ?? []
                
                // dismiss all presented VCs on VCs to be removed
                toRemoveViewControllers.forEach { vc in
                    if vc.presentedViewController != nil {
                        vc.dismiss(animated: animated)
                    }
                }
                
                // VCs to remain in the navigation stack
                let remainingViewControllers = Array(navigationController?.viewControllers[0..<index] ?? [])
                navigationController?.setViewControllers(remainingViewControllers, animated: animated)
            }
            
            // stopping FC doesn't need to be nav delegate anymore -> pass it to parent
            navigationController?.delegate = parentCoordinator
            
            parentCoordinator?.removeChild(self)
        }
        
        // MARK: - Child coordinators
        
        public func addChild(_ flowController: FlowCoordinator) {
            if !childCoordinators.contains { $0 === flowController } {
                childCoordinators.append(flowController)
                flowController.parentCoordinator = self
            }
        }
        
        public func removeChild(_ flowController: FlowCoordinator) {
            if let index = childCoordinators.firstIndex(where: { $0 === flowController }) {
                childCoordinators.remove(at: index)
            }
        }
        
        // MARK: - UINavigationControllerDelegate
        
        public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            
            // ensure the view controller is popping
            guard
                let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
                !navigationController.viewControllers.contains(fromViewController)
                else { return }
            
            if let firstViewController = rootViewController, fromViewController == firstViewController {
                navigationController.delegate = parentCoordinator
                stop()
            }
        }

        // MARK: - DeepLink

        /// Handle deep link with currently active coordinator. If not handled, function returns false
        @discardableResult open func handleDeeplink(_ deeplink: DeepLinkType) -> Bool {
            return activeChild?.handleDeeplink(deeplink) ?? false
        }
        
        // MARK: - Debug
        
        override public init() {
            super.init()
            if Base.memoryLoggingEnabled && Base.flowCoordinatorMemoryLoggingEnabled {
                if #available(iOS 10.0, *) {
                    os_log("🔀 👶 %@", log: Logger.lifecycleLog(), type: .info, "\(self)")
                } else {
                    NSLog("🔀 👶 \(self)")
                }
            }
        }
        
        deinit {
            if Base.memoryLoggingEnabled && Base.flowCoordinatorMemoryLoggingEnabled {
                if #available(iOS 10.0, *) {
                    os_log("🔀 ⚰️ %@", log: Logger.lifecycleLog(), type: .info, "\(self)")
                } else {
                    NSLog("🔀 ⚰️ \(self)")
                }
            }
        }
        
        /// Wait for a second and check whether rootViewController was set
        private func checkRootViewController() {
            DispatchQueue(label: "rootViewController").asyncAfter(deadline: .now() + 1) { [weak self] in
                if self?.rootViewController == nil { assertionFailure("rootViewController is nil") }
            }
        }
    }

    /// Empty class for Base.FlowCoordinator with no deep link handling
    public enum NoDeepLink {}

    /// Base VC with no VM
    open class FlowCoordinatorNoDeepLink: Base.FlowCoordinator<NoDeepLink> {

    }
}
