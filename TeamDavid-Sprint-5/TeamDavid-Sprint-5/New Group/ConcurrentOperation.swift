//
//  ConcurrentOperation.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class ConcurrentOperation: Operation {
    
    // MARK: Types
    
    enum State: String {
        case isReady, isExecuting, isFinished
    }
    
    // MARK: Properties
    
    private var _state = State.isReady
    
    private let stateQueue = DispatchQueue(label: "com.LambdaSchool.Astronomy.ConcurrentOperationStateQueue")
    var state: State {
        get {
            var result: State?
            let queue = self.stateQueue
            queue.sync {
                result = _state
            }
            return result!
        }
        
        set {
            let oldValue = state
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: oldValue.rawValue)
            
            stateQueue.sync { self._state = newValue }
            
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: newValue.rawValue)
        }
    }
    
    // MARK: NSOperation
    
    override dynamic var isReady: Bool {
        return super.isReady && state == .isReady
    }
    
    override dynamic var isExecuting: Bool {
        return state == .isExecuting
    }
    
    override dynamic var isFinished: Bool {
        return state == .isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
}

class FetchImageOperation: ConcurrentOperation {
    
    init(randomUser: RandomUser, imageType: RandomUser.Images) {
        self.randomUser = randomUser
        self.imageType = imageType
    }
    
    var randomUser: RandomUser
    var imageType: RandomUser.Images
    var image: UIImage?
    
    private var dataTask: URLSessionDataTask?
    
    override func start() {
        state = .isExecuting
        
        var imageURL: URL?
        if imageType == .large {
            imageURL = randomUser.largeURL
        } else if imageType == .thumbnail {
            imageURL = randomUser.thumbnailURL
        }
        
        guard let url = imageURL else { return }
        dataTask = URLSession.shared.dataTask(with: url) { (data, _, error) in
            defer { self.state = .isFinished }
            if let error = error {
                NSLog("Error retrieving image from url: \(error)")
                return
            }
            guard let data = data else { return }
            self.image = UIImage(data: data)
        }
        
        dataTask?.resume()
    }
    
    override func cancel() {
        dataTask?.cancel()
    }
}
