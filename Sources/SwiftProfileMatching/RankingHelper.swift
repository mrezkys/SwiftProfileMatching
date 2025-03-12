//
//  RankingHelper.swift
//  SwiftProfileMatching
//
//  Created by Muhammad Rezky Sulihin on 12/03/25.
//

import Foundation

/// Helper for working with Profile Matching results
public struct RankingHelper: Sendable {
    
    /// Format used for presenting scores
    public enum ScoreFormat: Sendable {
        /// Raw score, e.g. 4.25
        case raw
        
        /// Percentage, e.g. 85.0%
        case percentage
        
        /// Star rating, e.g. ⭐⭐⭐⭐
        case stars(maxStars: Int)
    }
    
    /// Structure for a detailed ranking report
    public struct RankingReport: Sendable {
        /// Ranked results
        public let rankedResults: [ProfileMatching.MatchingResult]
        
        /// The score format used
        public let scoreFormat: ScoreFormat
        
        /// The score range to use for formatting (min, max)
        public let scoreRange: (min: Double, max: Double)
        
        /// Format a score according to the format specification
        /// - Parameter score: The raw score to format
        /// - Returns: Formatted score as a string
        public func formatScore(_ score: Double) -> String {
            switch scoreFormat {
            case .raw:
                return String(format: "%.2f", score)
                
            case .percentage:
                // Calculate percentage based on the actual score range
                let scoreRange = self.scoreRange.max - self.scoreRange.min
                let normalizedScore = (score - self.scoreRange.min) / scoreRange
                let percentage = normalizedScore * 100.0
                return String(format: "%.1f%%", percentage)
                
            case .stars(let maxStars):
                // Convert score to stars based on the actual score range
                let scoreRange = self.scoreRange.max - self.scoreRange.min
                let normalizedScore = (score - self.scoreRange.min) / scoreRange
                let scaledStars = Int(round(normalizedScore * Double(maxStars)))
                return String(repeating: "⭐", count: max(0, min(maxStars, scaledStars)))
            }
        }
        
        /// Generate a text summary of the rankings
        /// - Returns: A multi-line string with the ranking summary
        public func generateTextSummary() -> String {
            var summary = "Profile Matching Ranking Results:\n"
            summary += "===================================\n\n"
            
            for (index, result) in rankedResults.enumerated() {
                summary += "Rank #\(index + 1): \(result.alternative.name) (ID: \(result.alternative.id))\n"
                summary += "Overall Score: \(formatScore(result.finalScore))\n"
                summary += "Core Factor Score: \(formatScore(result.coreFactorScore))\n"
                summary += "Secondary Factor Score: \(formatScore(result.secondaryFactorScore))\n"
                
                summary += "Criteria Scores:\n"
                
                // Sort criteria by score (highest first) for better readability
                let sortedCriteria = result.gapDetails.sorted { $0.value > $1.value }
                for (criterion, score) in sortedCriteria {
                    summary += "  - \(criterion): \(formatScore(score))\n"
                }
                
                summary += "\n"
            }
            
            return summary
        }
    }
    
    /// Create a ranking report from profile matching results
    /// - Parameters:
    ///   - matchingResults: The results from profile matching
    ///   - scoreFormat: Format to use for scores in the report
    ///   - scoreRange: Min and max range for scores (default: (0.0, 5.0))
    ///   - limit: Maximum number of results to include (nil for no limit)
    /// - Returns: A ranking report
    public static func createReport(
        from matchingResults: [ProfileMatching.MatchingResult],
        scoreFormat: ScoreFormat = .raw,
        scoreRange: (min: Double, max: Double) = (0.0, 5.0),
        limit: Int? = nil
    ) -> RankingReport {
        let limitedResults: [ProfileMatching.MatchingResult]
        
        if let limit = limit, limit < matchingResults.count {
            limitedResults = Array(matchingResults.prefix(limit))
        } else {
            limitedResults = matchingResults
        }
        
        return RankingReport(rankedResults: limitedResults, scoreFormat: scoreFormat, scoreRange: scoreRange)
    }
    
    /// Find the most influential criteria across all alternatives
    /// - Parameters:
    ///   - matchingResults: The results from profile matching
    ///   - scoreRange: Min and max range for scores (default: (0.0, 5.0))
    /// - Returns: Dictionary mapping criterion names to their influence score
    public static func findMostInfluentialCriteria(
        from matchingResults: [ProfileMatching.MatchingResult],
        scoreRange: (min: Double, max: Double) = (0.0, 5.0)
    ) -> [String: Double] {
        guard !matchingResults.isEmpty else { return [:] }
        
        var criteriaInfluence: [String: Double] = [:]
        
        // Calculate mid-point of the score range
        let midPoint = scoreRange.min + (scoreRange.max - scoreRange.min) / 2.0
        
        // Analyze variance for each criterion
        for result in matchingResults {
            for (criterion, score) in result.gapDetails {
                if criteriaInfluence[criterion] == nil {
                    criteriaInfluence[criterion] = 0
                }
                
                // Add the score's distance from the middle of the score range
                // The greater the distance, the more this criterion influenced the results
                criteriaInfluence[criterion]! += abs(score - midPoint)
            }
        }
        
        // Normalize by number of alternatives to get average influence
        for (criterion, _) in criteriaInfluence {
            criteriaInfluence[criterion]! /= Double(matchingResults.count)
        }
        
        return criteriaInfluence
    }
    
    /// Calculate the differentiating power of each criterion
    /// - Parameter matchingResults: The results from profile matching
    /// - Returns: Dictionary mapping criterion names to their differentiation score
    public static func calculateCriteriaDifferentiationPower(
        from matchingResults: [ProfileMatching.MatchingResult]
    ) -> [String: Double] {
        guard matchingResults.count > 1 else { return [:] }
        
        var criteriaVariance: [String: [Double]] = [:]
        
        // Collect all scores for each criterion
        for result in matchingResults {
            for (criterion, score) in result.gapDetails {
                if criteriaVariance[criterion] == nil {
                    criteriaVariance[criterion] = []
                }
                criteriaVariance[criterion]!.append(score)
            }
        }
        
        // Calculate variance for each criterion
        var differentiationPower: [String: Double] = [:]
        
        for (criterion, scores) in criteriaVariance {
            let mean = scores.reduce(0, +) / Double(scores.count)
            let sumSquaredDifferences = scores.reduce(0) { $0 + pow($1 - mean, 2) }
            let variance = sumSquaredDifferences / Double(scores.count)
            
            // Higher variance means the criterion differentiates alternatives more
            differentiationPower[criterion] = variance
        }
        
        return differentiationPower
    }
    
    /// Identify strengths and weaknesses for a specific alternative
    /// - Parameters:
    ///   - result: The matching result for an alternative
    ///   - threshold: The score threshold to determine strengths (default: 4.0)
    ///   - scoreRange: Min and max range for scores (default: (0.0, 5.0))
    /// - Returns: A tuple containing strengths and weaknesses criteria names
    public static func identifyStrengthsAndWeaknesses(
        for result: ProfileMatching.MatchingResult,
        threshold: Double = 4.0,
        scoreRange: (min: Double, max: Double) = (0.0, 5.0)
    ) -> (strengths: [String], weaknesses: [String]) {
        var strengths: [String] = []
        var weaknesses: [String] = []
        
        // Calculate the relative threshold based on the score range
        let relativeThreshold = threshold
        let range = scoreRange.max - scoreRange.min
        
        for (criterion, score) in result.gapDetails {
            if score >= relativeThreshold {
                strengths.append(criterion)
            } else if score <= (scoreRange.max - relativeThreshold) {
                weaknesses.append(criterion)
            }
        }
        
        // Sort by score (highest first for strengths, lowest first for weaknesses)
        strengths.sort { result.gapDetails[$0]! > result.gapDetails[$1]! }
        weaknesses.sort { result.gapDetails[$0]! < result.gapDetails[$1]! }
        
        return (strengths, weaknesses)
    }
} 
