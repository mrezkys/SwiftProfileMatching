//
//  Normalization.swift
//  SwiftProfileMatching
//
//  Created by Muhammad Rezky Sulihin on 12/03/25.
//


import Foundation

/// Normalization utilities for the ProfileMatching system
/// Provides methods to normalize values to different scales.
public struct Normalization {
    
    /// Normalize a single value from its original range to the standard ProfileMatching scale (0-5)
    /// - Parameters:
    ///   - value: The value to normalize
    ///   - originalMin: The minimum value in the original scale
    ///   - originalMax: The maximum value in the original scale
    ///   - targetMin: The minimum value in the target scale (default: 0.0)
    ///   - targetMax: The maximum value in the target scale (default: 5.0)
    /// - Returns: The normalized value
    public static func normalize(
        value: Double,
        originalMin: Double,
        originalMax: Double,
        targetMin: Double = 0.0,
        targetMax: Double = 5.0
    ) -> Double {
        // Handle division by zero
        guard originalMax > originalMin else {
            return targetMin
        }
        
        // Basic min-max normalization formula
        let normalizedValue = ((value - originalMin) / (originalMax - originalMin)) 
            * (targetMax - targetMin) + targetMin
        
        // Clamp value to target range
        return min(max(normalizedValue, targetMin), targetMax)
    }
    
    /// Normalize a collection of values to the standard ProfileMatching scale (0-5)
    /// - Parameters:
    ///   - values: The collection of values to normalize
    ///   - targetMin: The minimum value in the target scale (default: 0.0)
    ///   - targetMax: The maximum value in the target scale (default: 5.0)
    /// - Returns: Array of normalized values
    public static func normalizeValues(
        _ values: [Double],
        targetMin: Double = 0.0,
        targetMax: Double = 5.0
    ) -> [Double] {
        guard !values.isEmpty else { return [] }
        
        let min = values.min() ?? 0
        let max = values.max() ?? 5
        
        return values.map { normalize(value: $0, originalMin: min, originalMax: max, targetMin: targetMin, targetMax: targetMax) }
    }
    
    /// Normalize criteria values based on provided ranges for each criterion
    /// - Parameters:
    ///   - criteriaValues: Dictionary mapping criteria names to their values
    ///   - criteriaRanges: Dictionary mapping criteria names to their min/max ranges
    ///   - targetMin: The minimum value in the target scale (default: 0.0)
    ///   - targetMax: The maximum value in the target scale (default: 5.0)
    /// - Returns: Dictionary of normalized criteria values
    public static func normalizeCriteriaValues(
        _ criteriaValues: [String: Double],
        criteriaRanges: [String: (min: Double, max: Double)],
        targetMin: Double = 0.0,
        targetMax: Double = 5.0
    ) -> [String: Double] {
        var normalizedValues = [String: Double]()
        
        for (criterionName, value) in criteriaValues {
            // Get range for this criterion, or use default if not provided
            let range = criteriaRanges[criterionName] ?? (min: 0.0, max: 5.0)
            
            // Normalize the value based on its range
            let normalizedValue = normalize(
                value: value,
                originalMin: range.min,
                originalMax: range.max,
                targetMin: targetMin,
                targetMax: targetMax
            )
            
            normalizedValues[criterionName] = normalizedValue
        }
        
        return normalizedValues
    }
    
    /// Normalize a set of scores for alternatives to standard deviation units (z-scores)
    /// Useful for comparing how alternatives perform relative to each other.
    /// - Parameter scores: Dictionary mapping alternative IDs to their scores
    /// - Returns: Dictionary of z-scores for each alternative
    public static func normalizeToZScores(_ scores: [String: Double]) -> [String: Double] {
        guard !scores.isEmpty else { return [:] }
        
        // Calculate mean
        let values = Array(scores.values)
        let mean = values.reduce(0.0, +) / Double(values.count)
        
        // Calculate standard deviation
        let variance = values.reduce(0.0) { sum, value in
            let diff = value - mean
            return sum + (diff * diff)
        } / Double(values.count)
        
        let stdDev = sqrt(variance)
        
        // Handle case where there's no variation
        guard stdDev > 0 else {
            var result = [String: Double]()
            for key in scores.keys {
                result[key] = 0.0  // All scores are at the mean
            }
            return result
        }
        
        // Calculate z-scores
        var zScores = [String: Double]()
        for (id, score) in scores {
            zScores[id] = (score - mean) / stdDev
        }
        
        return zScores
    }
} 
