//
//  Smoother.swift
//  DVBespoke
//
//  Created by Konrad Feiler on 10.11.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation

/// Smoother averages out noisy signals
/// for more background check out https://en.wikipedia.org/wiki/Moving_average#Simple_moving_average
public class Smoother<X> where X: AverageAble {
    
    public enum Method {
        case movingAverage
        case weightedAverage
    }
    
    public let timeInterval: TimeInterval
    public let method: Method
    
    public init(timeInterval: TimeInterval, method: Method = .movingAverage) {
        self.timeInterval = timeInterval
        self.method = method
    }
    
    /// This method saves the new datapoint and returns the smoothed value
    ///
    /// - Parameter value: the input datapoint
    /// - Returns: the value smoothed by combining the new value with the values inside the timeInterval
    public func smooth(value: X) -> X {
        timeSeries.append((value, Date()))
        clearOldValues()
        return smoothedValue
    }
    
    var smoothedValue: X {
        guard !timeSeries.isEmpty else {
            print("WARNING: Accessing smoothed value before entering data")
            return X.zero
        }
        
        guard timeSeries.count > 1 else { return timeSeries.first?.0 ?? X.zero }
        
        switch method {
        case .movingAverage: return calculateMovingAverage()
        case .weightedAverage: return calculateWeigthedAverage()
        }
    }
    
    // MARK: - Implementation Details
    
    private var timeSeries = ArraySlice<(X, Date)>()
    
    private func clearOldValues() {
        let now = Date()
        timeSeries = timeSeries.drop(while: { now.timeIntervalSince($0.1) > timeInterval })
    }
    
    /// Simple moving average
    ///
    /// - Returns: the calculated moving average
    private func calculateMovingAverage() -> X {
        let sum = timeSeries.reduce(X.zero) { (sum, dataPoint) -> X in
            return sum + dataPoint.0
        }
        return sum * (1 / Float(timeSeries.count))
    }
    
    /// Triangular weighted moving average
    /// if n is the number of points, n is also the weight for the newest point
    /// every point after is multiplied by weights n-1, n-2 ...
    ///
    /// - Returns: the calculated moving average
    private func calculateWeigthedAverage() -> X {
        let count = timeSeries.count
        
        let sum = timeSeries.reversed().enumerated().reduce(X.zero) { (result, argument) -> X in
            let (offset, (value, _)) = argument
            let weight = Float(count - offset)
            return result + value * weight
        }
        let fullWeight = Float(count * (count + 1)) / 2
        return sum * (1 / fullWeight)
    }
}

public protocol AverageAble {
    static func + (left: Self, right: Self) -> Self
    static func * (left: Self, right: Float) -> Self
    static var zero: Self { get }
}
