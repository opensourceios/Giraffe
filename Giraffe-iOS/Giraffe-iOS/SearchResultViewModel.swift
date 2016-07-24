//
//  SearchResultViewModel.swift
//  Giraffe-iOS
//
//  Created by Evgen Dubinin on 7/24/16.
//  Copyright © 2016 Yevhen Dubinin. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import GiraffeKit

struct SearchResultViewModel: ViewModelType {
    private let model: SearchResult
    private let response                = MutableProperty<Response?>(nil)
    
    private let fetchErrorMsg           = "Something went wrong while getting trending"
    private let blankMsg                = ""
    private let emptyResponseMsg        = "No items were found"
    
    // MARK: - ViewModelType -
    
    let isActive                        = MutableProperty<Bool>(false)
    
    // MARK: - ViewModel Public Properties -
    
    let headline                    = MutableProperty<String?>(nil)
    let items                       = MutableProperty<[Item]>([])
    let message                     = MutableProperty("")
    let shouldHideItemsView         = MutableProperty<Bool>(true)
    
    // MARK: - Initialization -
    
    init(model: SearchResult) {
        self.model = model
        
        // Setup RAC bindings.
        self.setupBindings()
    }
    
    // MARK: - RAC -
    
    func setupBindings() {
        
        self.isActive.producer
            .filter { $0 }
            .mapError { _ in
                return GiraffeError.UnknownError
            }
            .flatMap(.Latest) { _ in
                return self.model.startPage()
            }
            .on(failed: { _ in
                self.message.value = self.fetchErrorMsg
            })
            // HACK: We'd like to receive an error and update the UI, but it well known
            // that SignalProducer stops upon failure, thus we have to retry it.
            // For now, retry as much as we can (Int.max times). There has to be more correct way to do this
            .retry(Int.max)
            .startWithResult { result in
                self.response.value = result.value!
                self.message.value = self.response.value!.zeroItems ? self.emptyResponseMsg : self.blankMsg
        }
        
        self.items <~ self.response.producer
            .ignoreNil()
            .map { response in
                response.data
        }
        
        // Make sure, we're only showing the trending view if there are actually some results
        self.shouldHideItemsView <~ self.items.producer.map { items in
            items.count == 0
        }
    }
}
