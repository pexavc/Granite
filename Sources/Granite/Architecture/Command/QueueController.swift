////
////  QueueController.swift
////  Deperecated
////
////  Created by PEXAVC on 2/11/21.
////  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
////
//
//import Foundation
//
//protocol DispatchWorkItemControllerDelegate: class {
//    func workСompleted(delegatedFrom controller: DispatchWorkItemController)
// }
//
// class DispatchWorkItemController {
//
//    weak var delegate: DispatchWorkItemControllerDelegate?
//    private(set) var workItem: DispatchWorkItem?
//    private var semaphore = DispatchSemaphore(value: 1)
//    var needToStop: Bool {
//        get {
//            semaphore.wait(); defer { semaphore.signal() }
//            return workItem?.isCancelled ?? true
//        }
//    }
//
//    init (block: @escaping (_ needToStop: ()->Bool) -> Void) {
//        let workItem = DispatchWorkItem { [weak self] in
//            block { return self?.needToStop ?? true }
//        }
//        self.workItem = workItem
//        workItem.notify(queue: DispatchQueue.global(qos: .utility)) { [weak self] in
//            guard let self = self else { return }
//            self.semaphore.wait(); defer { self.semaphore.signal() }
//            self.workItem = nil
//            self.delegate?.workСompleted(delegatedFrom: self)
//        }
//    }
//
//    func setNeedsStop() { workItem?.cancel() }
//    func setNeedsStopAndWait() { setNeedsStop(); workItem?.wait() }
//}
//
//protocol QueueControllerDelegate: class {
//    func tasksСompleted(delegatedFrom controller: QueueController)
//}
//
//class QueueController {
//
//    weak var delegate: QueueControllerDelegate?
//    private var queue: DispatchQueue
//    private var workItemControllers = [DispatchWorkItemController]()
//    private var semaphore = DispatchSemaphore(value: 1)
//    var runningTasksCount: Int {
//        semaphore.wait(); defer { semaphore.signal() }
//        return workItemControllers.filter { $0.workItem != nil } .count
//    }
//
//    func setNeedsStopTasks() {
//        semaphore.wait(); defer { semaphore.signal() }
//        workItemControllers.forEach { $0.setNeedsStop() }
//    }
//
//    func setNeedsStopTasksAndWait() {
//        semaphore.wait(); defer { semaphore.signal() }
//        workItemControllers.forEach { $0.setNeedsStopAndWait() }
//    }
//
//    init(queue: DispatchQueue) { self.queue = queue }
//
//    func async(block: @escaping (_ needToStop: ()->Bool) -> Void) {
//        queue.async(execute: initWorkItem(block: block))
//    }
//
//    private func initWorkItem(block: @escaping (_ needToStop: ()->Bool) -> Void) -> DispatchWorkItem {
//        semaphore.wait(); defer { semaphore.signal() }
//        workItemControllers = workItemControllers.filter { $0.workItem != nil }
//        let workItemController = DispatchWorkItemController(block: block)
//        workItemController.delegate = self
//        workItemControllers.append(workItemController)
//        return workItemController.workItem!
//    }
//}
//
//extension QueueController: DispatchWorkItemControllerDelegate {
//    func workСompleted(delegatedFrom controller: DispatchWorkItemController) {
//        semaphore.wait(); defer { semaphore.signal() }
//        if let index = self.workItemControllers.firstIndex (where: { $0.workItem === controller.workItem }) {
//            workItemControllers.remove(at: index)
//        }
//        if workItemControllers.isEmpty { delegate?.tasksСompleted(delegatedFrom: self) }
//    }
//}
