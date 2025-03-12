//
//  SwiftProfileMatching.swift
//  SwiftProfileMatching
//
//  Created by Muhammad Rezky Sulihin on 11/03/25.
//

import Foundation

/// Main class for Profile Matching algorithm
public class ProfileMatching: @unchecked Sendable {
    
    /// Types of gap calculation supported by the package
    public enum GapType: Sendable {
        /// Core Factor gap type (used for essential criteria)
        case coreFactor
        
        /// Secondary Factor gap type (used for supporting criteria)
        case secondaryFactor
    }
    
    /// Model representing a criterion in the profile matching process
    public struct Criterion: Sendable {
        /// Name of the criterion
        public let name: String
        
        /// Target/ideal value for this criterion
        public let targetValue: Double
        
        /// Type of criterion (core or secondary factor)
        public let type: GapType
        
        /// Weight of this criterion (percentage, should sum to 100% across all criteria)
        public let weight: Double
        
        /// Initialize a new criterion
        /// - Parameters:
        ///   - name: Name of the criterion
        ///   - targetValue: Target/ideal value for this criterion
        ///   - type: Type of criterion (core or secondary factor)
        ///   - weight: Weight of this criterion (percentage)
        public init(name: String, targetValue: Double, type: GapType, weight: Double) {
            self.name = name
            self.targetValue = targetValue
            self.type = type
            self.weight = weight
        }
    }
    
    /// Model representing an alternative/option in the profile matching process
    public struct Alternative: Sendable {
        /// Identifier for the alternative
        public let id: String
        
        /// Name or description of the alternative
        public let name: String
        
        /// Values for each criterion
        public let criteriaValues: [String: Double]
        
        /// Initialize a new alternative
        /// - Parameters:
        ///   - id: Identifier for the alternative
        ///   - name: Name or description of the alternative
        ///   - criteriaValues: Dictionary mapping criterion names to their values
        public init(id: String, name: String, criteriaValues: [String: Double]) {
            self.id = id
            self.name = name
            self.criteriaValues = criteriaValues
        }
    }
    
    /// For backward compatibility - alias of Alternative
    public typealias Candidate = Alternative
    
    /// Model representing the result of profile matching for an alternative
    public struct MatchingResult: Sendable {
        /// Reference to the original alternative
        public let alternative: Alternative
        
        /// Final score after profile matching calculation
        public let finalScore: Double
        
        /// Scores for core factors only
        public let coreFactorScore: Double
        
        /// Scores for secondary factors only
        public let secondaryFactorScore: Double
        
        /// Detailed gap calculations per criterion
        public let gapDetails: [String: Double]
        
        /// For backward compatibility - access to alternative as candidate
        public var candidate: Alternative {
            return alternative
        }
    }
    
    // MARK: - Properties
    
    /// The criteria used for evaluation
    private let criteria: [Criterion]
    
    /// Configuration for the profile matching algorithm
    private let configuration: ProfileMatchingConfiguration
    
    // MARK: - Initialization
    
    /// Initialize the Profile Matching calculator with default configuration
    /// - Parameters:
    ///   - criteria: Array of criteria for evaluation
    ///   - coreFactorWeight: Weight for core factors in the final calculation (default: 0.6)
    ///   - secondaryFactorWeight: Weight for secondary factors in the final calculation (default: 0.4)
    public convenience init(criteria: [Criterion], coreFactorWeight: Double = 0.6, secondaryFactorWeight: Double = 0.4) {
        // Use the standard configuration but override the weight factors
        let config = ProfileMatchingConfiguration(
            gapCalculationStrategy: .standard,
            coreFactorWeight: coreFactorWeight,
            secondaryFactorWeight: secondaryFactorWeight,
            normalizationMethod: .none,
            weightCalculation: .direct,
            scoreRange: (0.0, 5.0)
        )
        self.init(criteria: criteria, configuration: config)
    }
    
    /// Initialize the Profile Matching calculator with custom configuration
    /// - Parameters:
    ///   - criteria: Array of criteria for evaluation
    ///   - configuration: Configuration for the profile matching algorithm
    public init(criteria: [Criterion], configuration: ProfileMatchingConfiguration = .standard) {
        self.criteria = criteria
        self.configuration = configuration
        
        // Validate that weights sum to 100% if using direct weight calculation
        if configuration.weightCalculation == .direct {
            validateWeights()
        }
    }
    
    // MARK: - Public Methods
    
    /// Calculate matching results for a list of alternatives/candidates
    /// - Parameter alternatives: Array of alternatives to evaluate
    /// - Returns: Array of matching results sorted by final score (highest first)
    public func calculateMatching(for alternatives: [Alternative]) -> [MatchingResult] {
        let results = alternatives.map { calculateMatchingForAlternative($0) }
        return results.sorted { $0.finalScore > $1.finalScore }
    }
    
    // The deprecated calculateMatching(for: [Candidate]) method is removed because
    // it's redundant when Candidate is just a type alias for Alternative.
    
    // MARK: - Private Methods
    
    /// Validates that criteria weights sum to 100%
    private func validateWeights() {
        // For each type (core and secondary), sum should be 100%
        let coreFactors = criteria.filter { $0.type == .coreFactor }
        let coreSum = coreFactors.reduce(0.0) { $0 + $1.weight }
        
        let secondaryFactors = criteria.filter { $0.type == .secondaryFactor }
        let secondarySum = secondaryFactors.reduce(0.0) { $0 + $1.weight }
        
        // Allow a small margin of error for floating point calculations
        if !coreFactors.isEmpty && abs(coreSum - 100.0) > 0.01 {
            print("Warning: Core factor weights sum to \(coreSum), not 100%")
        }
        
        if !secondaryFactors.isEmpty && abs(secondarySum - 100.0) > 0.01 {
            print("Warning: Secondary factor weights sum to \(secondarySum), not 100%")
        }
    }
    
    /// Calculate the matching result for a single alternative
    /// - Parameter alternative: The alternative to evaluate
    /// - Returns: Matching result for the alternative
    private func calculateMatchingForAlternative(_ alternative: Alternative) -> MatchingResult {
        // Normalize input values if needed
        let processedValues = normalizeInputValues(alternative.criteriaValues)
        var gapDetails: [String: Double] = [:]
        
        // Calculate gaps and convert to weighted gap values
        for criterion in criteria {
            if let value = processedValues[criterion.name] {
                let gap = calculateGap(targetValue: criterion.targetValue, 
                                      actualValue: value, 
                                      type: criterion.type)
                gapDetails[criterion.name] = gap
            }
        }
        
        // If we have just a single criterion, special handling for perfect match and custom range
        if criteria.count == 1, let criterion = criteria.first, let gapValue = gapDetails[criterion.name] {
            // Single criterion case - just return the gap value directly
            return MatchingResult(
                alternative: alternative,
                finalScore: gapValue,
                coreFactorScore: criterion.type == .coreFactor ? gapValue : 0,
                secondaryFactorScore: criterion.type == .secondaryFactor ? gapValue : 0,
                gapDetails: gapDetails
            )
        }
        
        // Calculate core factor score
        let coreFactors = criteria.filter { $0.type == .coreFactor }
        let coreFactorScore = calculateWeightedScore(for: coreFactors, using: gapDetails)
        
        // Calculate secondary factor score
        let secondaryFactors = criteria.filter { $0.type == .secondaryFactor }
        let secondaryFactorScore = calculateWeightedScore(for: secondaryFactors, using: gapDetails)
        
        // Calculate final score based on core and secondary factor weights
        var finalScore: Double
        
        if coreFactors.isEmpty {
            // If there are no core factors, use only secondary factor score
            finalScore = secondaryFactorScore
        } else if secondaryFactors.isEmpty {
            // If there are no secondary factors, use only core factor score
            finalScore = coreFactorScore
        } else {
            // If we have both, apply the configured weights
            finalScore = (configuration.coreFactorWeight * coreFactorScore) +
                        (configuration.secondaryFactorWeight * secondaryFactorScore)
        }
        
        return MatchingResult(
            alternative: alternative,
            finalScore: finalScore,
            coreFactorScore: coreFactorScore,
            secondaryFactorScore: secondaryFactorScore,
            gapDetails: gapDetails
        )
    }
    
    /// Normalize input values based on configuration
    /// - Parameter criteriaValues: Raw criteria values
    /// - Returns: Normalized criteria values
    private func normalizeInputValues(_ criteriaValues: [String: Double]) -> [String: Double] {
        switch configuration.normalizationMethod {
        case .none:
            return criteriaValues
            
        case .global:
            return Normalization.normalizeCriteriaValues(criteriaValues, criteriaRanges: [:])
            
        case .local:
            var normalized: [String: Double] = [:]
            for criterion in criteria {
                if let value = criteriaValues[criterion.name] {
                    // Just copy the original value since we're not doing actual per-criterion normalization yet
                    normalized[criterion.name] = value
                }
            }
            return normalized
        }
    }
    
    /// Calculate a gap value according to profile matching methods
    /// - Parameters:
    ///   - targetValue: The target/ideal value
    ///   - actualValue: The actual value from the alternative
    ///   - type: The type of gap calculation to use
    /// - Returns: A weighted gap value
    private func calculateGap(targetValue: Double, actualValue: Double, type: GapType) -> Double {
        // Calculate raw gap
        let gap = actualValue - targetValue
        
        switch configuration.gapCalculationStrategy {
        case .standard:
            // Standard gap calculation based on DSS literature
            // Scale is typically 0-5 where: 0 = not match at all, 5 = perfect match
            switch type {
            case .coreFactor:
                // Core factors often use a stricter gap calculation
                if gap == 0 {
                    return 5.0  // Perfect match
                } else if gap > 0 {
                    // Exceeds expectations
                    return min(4.5, 5.0 - (0.5 * gap))
                } else {
                    // Below expectations (more severe penalty)
                    return max(0, 5.0 + gap)
                }
                
            case .secondaryFactor:
                // Secondary factors can use a more lenient gap calculation
                if gap == 0 {
                    return 5.0  // Perfect match
                } else if gap > 0 {
                    // Exceeds expectations
                    return min(5.0, 5.0 - (0.25 * gap))
                } else {
                    // Below expectations
                    return max(0, 5.0 + (0.75 * gap))
                }
            }
            
        case .custom(let perfectMatchScore, let exceedsPenalty, let belowPenalty, let maxScore):
            // Custom gap calculation with parameters
            if gap == 0 {
                return perfectMatchScore  // Perfect match gets perfect score
            } else if gap > 0 {
                // Exceeds expectations
                return max(0, min(maxScore, perfectMatchScore - (exceedsPenalty * gap)))
            } else {
                // Below expectations
                return max(0, min(maxScore, perfectMatchScore + (belowPenalty * gap)))
            }
            
        case .simple:
            // Simple gap calculation - just return the normalized difference
            // The closer to 0, the better
            let normalizedGap = 5.0 - min(5.0, abs(gap))
            return normalizedGap
        }
    }
    
    /// Calculate weighted score for a specific set of criteria
    /// - Parameters:
    ///   - criteria: The criteria to include in the calculation
    ///   - gapDetails: Dictionary of gap values per criterion
    /// - Returns: Weighted score for the criteria
    private func calculateWeightedScore(for criteria: [Criterion], using gapDetails: [String: Double]) -> Double {
        guard !criteria.isEmpty else { return 0 }
        
        // For a single criterion, just return its gap value directly
        if criteria.count == 1, let criterion = criteria.first {
            return gapDetails[criterion.name] ?? 0
        }
        
        var totalWeight = 0.0
        var weightedSum = 0.0
        
        for criterion in criteria {
            guard let gapValue = gapDetails[criterion.name] else { continue }
            
            // For percentage weights (0-100), we need to convert to decimal (0-1)
            let normalizedWeight = criterion.weight / 100.0
            weightedSum += normalizedWeight * gapValue
            totalWeight += normalizedWeight
        }
        
        // Normalize by total weight
        return totalWeight > 0 ? weightedSum / totalWeight : 0
    }
}
