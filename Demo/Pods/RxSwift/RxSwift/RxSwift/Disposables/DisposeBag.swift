//
//  DisposeBag.swift
//  Rx
//
//  Created by Krunoslav Zaher on 3/25/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

// Thread safe bag that disposes objects once it is being deallocated.
// This returns RAII like resource management to `RxSwift`.
public class DisposeBag: DisposeBase, Disposable {
    typealias State = (
        disposables: [Disposable],
        disposed: Bool
    )
    
    private var lock = Lock()
    var state: State = (
        disposables: [],
        disposed: false
    )
    
    public override init() {
        super.init()
    }
    
    public func addDisposable(disposable: Disposable) {
        let dispose = lock.calculateLocked { () -> Bool in
            if state.disposed {
                return true
            }
            
            state.disposables.append(disposable)
            
            return false
        }
        
        if dispose {
            disposable.dispose()
        }
    }

    public func dispose() {
        let oldDisposables = lock.calculateLocked { () -> [Disposable] in
            var disposables = self.state.disposables
            
            self.state.disposables.removeAll(keepCapacity: false)
            self.state.disposed = true
            
            return disposables
        }
        
        for disposable in oldDisposables {
            disposable.dispose()
        }
    }
    
    deinit {
        dispose()
    }
}