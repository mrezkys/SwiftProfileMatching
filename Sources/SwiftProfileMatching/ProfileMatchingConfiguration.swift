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
    
    /// Structure representing a discrete gap-to-score mapping pair
    public struct GapScorePair: Sendable, Comparable {
        /// The gap value (difference between actual and target)
        public let gap: Double
        
        /// The score assigned to this gap
        public let score: Double
        
        /// Initialize a new gap-score pair
        /// - Parameters:
        ///   - gap: The gap value (actual - target)
        ///   - score: The score to assign to this gap
        public init(gap: Double, score: Double) {
            self.gap = gap
            self.score = score
        }
        
        // Implement Comparable for sorting
        public static func < (lhs: GapScorePair, rhs: GapScorePair) -> Bool {
            return lhs.gap < rhs.gap
        }
    }
    
    /// Methods for handling undefined gap values in discrete mapping
    public enum DiscreteGapHandlingMethod: Sendable {
        /// Basic gap handling - uses nearest neighbor approach
        case basic
        
        /// Use linear interpolation between nearest defined points
        case interpolation
        
        /// Find the nearest defined point and use its score
        case nearestNeighbor
        
        /// Use thresholds where each defined point represents the start of a range
        case threshold
        
        /// Use a default score for any undefined gaps
        case defaultValue(score: Double)
    }
    
    /// Types of continuous calculation methods for gap values
    public enum ContinuousCalculationType: Sendable {
        /// Simple absolute difference normalization
        case simple
        
        /// Standard GAP method from decision theory
        case standard
        
        /// Custom implementation with configurable penalties
        case custom(perfectMatchScore: Double, exceedsPenalty: Double, belowPenalty: Double, maxScore: Double)
    }
    
    /// Strategies for calculating gap values between target and actual values
    public enum GapCalculationStrategy: Sendable {
        /// Continuous calculation methods (formula-based)
        case continuous(type: ContinuousCalculationType)
        
        /// Discrete calculation methods (mapping-based)
        case discrete(mappingPairs: [GapScorePair], handlingMethod: DiscreteGapHandlingMethod = .basic)
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
        gapCalculationStrategy: .continuous(type: .standard),
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
        gapCalculationStrategy: GapCalculationStrategy = .continuous(type: .standard),
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
    
    /// Creates a discrete gap mapping from a dictionary of gaps to scores
    /// - Parameters:
    ///   - gapToScoreMap: Dictionary mapping gap values to their corresponding scores
    ///   - defaultScore: Default score to use for gaps not explicitly defined
    /// - Returns: An array of GapScorePair objects sorted by gap value
    public static func createDiscreteMapping(gapToScoreMap: [Double: Double], defaultScore: Double = 0.0) -> [GapScorePair] {
        return gapToScoreMap.map { GapScorePair(gap: $0.key, score: $0.value) }.sorted()
    }
    
    /// Creates a discrete gap mapping from a dictionary of gaps to scores
    /// - Parameter gapToScoreMap: Dictionary mapping gap values to their corresponding scores
    /// - Returns: An array of GapScorePair objects sorted by gap value
    public static func createDiscreteMapping(gapToScoreMap: [Double: Double]) -> [GapScorePair] {
        return gapToScoreMap.map { GapScorePair(gap: $0.key, score: $0.value) }.sorted()
    }
    
    /// Creates a symmetric discrete gap mapping for a standard scale
    /// - Parameters:
    ///   - perfectMatchScore: Score to assign for a perfect match (gap = 0)
    ///   - maxGap: Maximum gap value to include in the mapping
    ///   - maxScore: Maximum possible score (typically 5.0)
    ///   - handlingMethod: Method for handling undefined gap values (default: .basic)
    /// - Returns: A configuration with discrete gap mapping
    public static func discreteSymmetric(
        perfectMatchScore: Double = 5.0,
        maxGap: Int = 5,
        maxScore: Double = 5.0,
        handlingMethod: DiscreteGapHandlingMethod = .basic
    ) -> ProfileMatchingConfiguration {
        var mappingPairs: [GapScorePair] = []
        
        // Perfect match
        mappingPairs.append(GapScorePair(gap: 0, score: perfectMatchScore))
        
        // Generate symmetric scores for positive and negative gaps
        for i in 1...maxGap {
            let gapScore = max(0, perfectMatchScore - Double(i))
            
            // For positive gaps (exceeding target)
            mappingPairs.append(GapScorePair(gap: Double(i), score: gapScore))
            
            // For negative gaps (below target)
            mappingPairs.append(GapScorePair(gap: Double(-i), score: gapScore))
        }
        
        return ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs.sorted(), handlingMethod: handlingMethod),
            scoreRange: (0.0, maxScore)
        )
    }
    
    /// Creates an asymmetric discrete gap mapping with different penalties for exceeding vs. falling below target
    /// - Parameters:
    ///   - perfectMatchScore: Score to assign for a perfect match (gap = 0)
    ///   - maxGap: Maximum gap value to include in the mapping
    ///   - exceedPenalty: Score reduction per unit above target
    ///   - belowPenalty: Score reduction per unit below target
    ///   - maxScore: Maximum possible score
    ///   - handlingMethod: Method for handling undefined gap values (default: .basic)
    /// - Returns: A configuration with discrete gap mapping
    public static func discreteAsymmetric(
        perfectMatchScore: Double = 5.0,
        maxGap: Int = 5,
        exceedPenalty: Double = 0.5,
        belowPenalty: Double = 1.0,
        maxScore: Double = 5.0,
        handlingMethod: DiscreteGapHandlingMethod = .basic
    ) -> ProfileMatchingConfiguration {
        var mappingPairs: [GapScorePair] = []
        
        // Perfect match
        mappingPairs.append(GapScorePair(gap: 0, score: perfectMatchScore))
        
        // Generate asymmetric scores
        for i in 1...maxGap {
            // For positive gaps (exceeding target)
            let exceedScore = max(0, perfectMatchScore - (Double(i) * exceedPenalty))
            mappingPairs.append(GapScorePair(gap: Double(i), score: exceedScore))
            
            // For negative gaps (below target)
            let belowScore = max(0, perfectMatchScore - (Double(i) * belowPenalty))
            mappingPairs.append(GapScorePair(gap: Double(-i), score: belowScore))
        }
        
        return ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs.sorted(), handlingMethod: handlingMethod),
            scoreRange: (0.0, maxScore)
        )
    }
    
    /// Creates a configuration with discrete gap calculation
    /// - Parameters:
    ///   - gapToScoreMap: Dictionary mapping gap values to their corresponding scores
    ///   - handlingMethod: Method for handling undefined gap values (default: .basic)
    ///   - coreFactorWeight: Weight of core factors (default: 0.6)
    ///   - secondaryFactorWeight: Weight of secondary factors (default: 0.4)
    /// - Returns: A configuration with discrete gap calculation
    public static func discreteMapping(
        gapToScoreMap: [Double: Double],
        handlingMethod: DiscreteGapHandlingMethod = .basic,
        coreFactorWeight: Double = 0.6,
        secondaryFactorWeight: Double = 0.4
    ) -> ProfileMatchingConfiguration {
        let mappingPairs = createDiscreteMapping(gapToScoreMap: gapToScoreMap)
        
        return ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: handlingMethod),
            coreFactorWeight: coreFactorWeight,
            secondaryFactorWeight: secondaryFactorWeight
        )
    }
} 
