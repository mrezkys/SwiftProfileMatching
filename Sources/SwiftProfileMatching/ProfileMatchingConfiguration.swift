//
//  ProfileMatchingConfiguration.swift
//  SwiftProfileMatching
//
//  Created by Muhammad Rezky Sulihin on 11/03/25.
//

import Foundation

/// Configuration for the Profile Matching process.
/// Controls how gap values and weights are calculated.
public struct ProfileMatchingConfiguration: Sendable {
    
    /// Strategies for calculating gap values between target and actual values
    public enum GapCalculationStrategy: Sendable {
        /// Simple absolute difference normalization
        case simple
        
        /// Standard GAP method from decision theory
        case standard
        
        /// Custom implementation with configurable penalties
        case custom(perfectMatchScore: Double, exceedsPenalty: Double, belowPenalty: Double, maxScore: Double)
    }
    
    /// Methods for normalizing values
    public enum NormalizationMethod: Sendable {
        /// No normalization applied
        case none
        
        /// Global normalization across all alternatives
        case global
        
        /// Local normalization for each criterion separately
        case local
    }
    
    /// Methods for handling weights
    public enum WeightCalculation: Sendable {
        /// Use weights directly as provided
        case direct
        
        /// Normalize weights to ensure they sum to 1.0
        case normalized
    }
    
    /// The strategy to use for calculating gap values
    public let gapCalculationStrategy: GapCalculationStrategy
    
    /// The weight of core factor criteria (0.0-1.0)
    public let coreFactorWeight: Double
    
    /// The weight of secondary factor criteria (0.0-1.0)
    public let secondaryFactorWeight: Double
    
    /// The normalization method to use for criteria values
    public let normalizationMethod: NormalizationMethod
    
    /// The method to use for handling weights
    public let weightCalculation: WeightCalculation
    
    /// The range for scores (min, max)
    public let scoreRange: (min: Double, max: Double)
    
    /// Default configuration with standard settings
    public static let standard = ProfileMatchingConfiguration(
        gapCalculationStrategy: .standard,
        coreFactorWeight: 0.6,
        secondaryFactorWeight: 0.4,
        normalizationMethod: .none,
        weightCalculation: .direct,
        scoreRange: (0.0, 5.0)
    )
    
    /// Creates a new configuration with specified parameters
    /// - Parameters:
    ///   - gapCalculationStrategy: Strategy for calculating gaps between target and actual values
    ///   - coreFactorWeight: Weight of core factors (default: 0.6)
    ///   - secondaryFactorWeight: Weight of secondary factors (default: 0.4)
    ///   - normalizationMethod: Method for normalizing values (default: .none)
    ///   - weightCalculation: Method for handling weights (default: .direct)
    ///   - scoreRange: Min and max range for final scores (default: (0.0, 5.0))
    public init(
        gapCalculationStrategy: GapCalculationStrategy = .standard,
        coreFactorWeight: Double = 0.6,
        secondaryFactorWeight: Double = 0.4,
        normalizationMethod: NormalizationMethod = .none,
        weightCalculation: WeightCalculation = .direct,
        scoreRange: (min: Double, max: Double) = (0.0, 5.0)
    ) {
        self.gapCalculationStrategy = gapCalculationStrategy
        self.coreFactorWeight = coreFactorWeight
        self.secondaryFactorWeight = secondaryFactorWeight
        self.normalizationMethod = normalizationMethod
        self.weightCalculation = weightCalculation
        self.scoreRange = scoreRange
        
        // Validate weights sum to 1.0
        precondition(abs(coreFactorWeight + secondaryFactorWeight - 1.0) < 0.001,
                    "Core factor weight and secondary factor weight must sum to 1.0")
    }
} 
