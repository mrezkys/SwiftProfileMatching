import Testing
@testable import SwiftProfileMatching

// MARK: - Basic Profile Matching Tests

@Suite("Basic Profile Matching")
struct ProfileMatchingTests {
    
    @Test("Initialize with valid criteria")
    func testInitialization() {
        let criteria = [
            ProfileMatching.Criterion(name: "Experience", targetValue: 4.0, type: .coreFactor, weight: 60),
            ProfileMatching.Criterion(name: "Education", targetValue: 5.0, type: .coreFactor, weight: 40),
            ProfileMatching.Criterion(name: "Communication", targetValue: 3.0, type: .secondaryFactor, weight: 70),
            ProfileMatching.Criterion(name: "Teamwork", targetValue: 4.0, type: .secondaryFactor, weight: 30)
        ]
        
        let profileMatching = ProfileMatching(criteria: criteria)
        #expect(profileMatching != nil)
    }
    
    @Test("Calculate matching results for alternatives")
    func testCalculateMatching() {
        // Create criteria
        let criteria = [
            ProfileMatching.Criterion(name: "Experience", targetValue: 4.0, type: .coreFactor, weight: 60),
            ProfileMatching.Criterion(name: "Education", targetValue: 5.0, type: .coreFactor, weight: 40),
            ProfileMatching.Criterion(name: "Communication", targetValue: 3.0, type: .secondaryFactor, weight: 70),
            ProfileMatching.Criterion(name: "Teamwork", targetValue: 4.0, type: .secondaryFactor, weight: 30)
        ]
        
        // Create alternatives
        let alternatives = [
            ProfileMatching.Alternative(
                id: "C001", 
                name: "John Doe", 
                criteriaValues: [
                    "Experience": 5.0,
                    "Education": 5.0,
                    "Communication": 4.0,
                    "Teamwork": 5.0
                ]
            ),
            ProfileMatching.Alternative(
                id: "C002", 
                name: "Jane Smith", 
                criteriaValues: [
                    "Experience": 3.0,
                    "Education": 5.0,
                    "Communication": 5.0,
                    "Teamwork": 3.0
                ]
            )
        ]
        
        // Calculate matching
        let profileMatching = ProfileMatching(criteria: criteria)
        let results = profileMatching.calculateMatching(for: alternatives)
        
        // Verify results
        #expect(results.count == 2)
        #expect(results[0].alternative.id == "C001") // John should rank first
        #expect(results[1].alternative.id == "C002") // Jane should rank second
        
        // Verify scores are in expected range
        #expect(results[0].finalScore >= 0 && results[0].finalScore <= 5)
        #expect(results[1].finalScore >= 0 && results[1].finalScore <= 5)
    }
    
    @Test("Perfect match alternative should get maximum score")
    func testPerfectMatch() {
        // Create criteria
        let criteria = [
            ProfileMatching.Criterion(name: "Criterion1", targetValue: 3.0, type: .coreFactor, weight: 100)
        ]
        
        // Create a perfect match alternative
        let alternative = ProfileMatching.Alternative(
            id: "P001", 
            name: "Perfect Match", 
            criteriaValues: ["Criterion1": 3.0] // Exact match to target
        )
        
        // Calculate matching
        let profileMatching = ProfileMatching(criteria: criteria)
        let results = profileMatching.calculateMatching(for: [alternative])
        
        // Verify results
        #expect(results.count == 1)
        #expect(results[0].finalScore == 5.0)
        #expect(results[0].gapDetails["Criterion1"] == 5.0)
    }
}

// MARK: - Configuration Tests

@Suite("Configuration Tests")
struct ConfigurationTests {
    
    @Test("Test custom configuration")
    func testCustomConfiguration() {
        // Create criteria
        let criteria = [
            ProfileMatching.Criterion(name: "C1", targetValue: 3.0, type: .coreFactor, weight: 100)
        ]
        
        // Create a custom configuration
        let customConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .simple,
            coreFactorWeight: 0.7,
            secondaryFactorWeight: 0.3,
            normalizationMethod: .global,
            weightCalculation: .normalized
        )
        
        // Create profile matching with custom config
        let profileMatching = ProfileMatching(criteria: criteria, configuration: customConfig)
        
        // Test with an alternative
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: ["C1": 4.0] // Not an exact match
        )
        
        // Calculate matching
        let results = profileMatching.calculateMatching(for: [alternative])
        
        // Simple strategy should use normalized difference
        #expect(results[0].finalScore < 5.0)
    }
    
    @Test("Test custom gap calculation")
    func testCustomGapCalculation() {
        // Create criteria
        let criteria = [
            ProfileMatching.Criterion(name: "C1", targetValue: 3.0, type: .coreFactor, weight: 100)
        ]
        
        // Create a custom configuration with custom gap calculation
        let customConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .custom(
                perfectMatchScore: 10.0,
                exceedsPenalty: 1.0,
                belowPenalty: 2.0,
                maxScore: 10.0
            ),
            scoreRange: (0.0, 10.0) // Match the score range to our custom scores
        )
        
        // Create profile matching with custom config
        let profileMatching = ProfileMatching(criteria: criteria, configuration: customConfig)
        
        // Test with alternatives
        let perfectAlternative = ProfileMatching.Alternative(
            id: "P001", 
            name: "Perfect", 
            criteriaValues: ["C1": 3.0] // Exact match
        )
        
        let exceedsAlternative = ProfileMatching.Alternative(
            id: "E001", 
            name: "Exceeds", 
            criteriaValues: ["C1": 4.0] // Exceeds by 1
        )
        
        let belowAlternative = ProfileMatching.Alternative(
            id: "B001", 
            name: "Below", 
            criteriaValues: ["C1": 2.0] // Below by 1
        )
        
        // Calculate matching
        let results = profileMatching.calculateMatching(for: [
            perfectAlternative, exceedsAlternative, belowAlternative
        ])
        
        // Verify custom scoring works as expected
        #expect(results.count == 3)
        
        // Find each alternative's result
        let perfectResult = results.first { $0.alternative.id == "P001" }!
        let exceedsResult = results.first { $0.alternative.id == "E001" }!
        let belowResult = results.first { $0.alternative.id == "B001" }!
        
        #expect(perfectResult.finalScore == 10.0) // Perfect match should get 10.0
        #expect(exceedsResult.finalScore == 9.0)  // 10.0 - (1.0 * 1.0) = 9.0
        #expect(belowResult.finalScore == 8.0)    // 10.0 - (2.0 * 1.0) = 8.0
    }
}

// MARK: - Normalization Tests

@Suite("Normalization Tests")
struct NormalizationTests {
    
    @Test("Normalize a single value")
    func testNormalizeValue() {
        let result = Normalization.normalize(value: 50, originalMin: 0, originalMax: 100)
        #expect(result == 2.5)
    }
    
    @Test("Normalize a collection of values")
    func testNormalizeValues() {
        let values = [10.0, 20.0, 30.0, 40.0, 50.0]
        let normalized = Normalization.normalizeValues(values)
        
        #expect(normalized.count == 5)
        #expect(normalized[0] == 0.0)
        #expect(normalized[4] == 5.0)
    }
    
    @Test("Normalize criteria values with custom ranges")
    func testNormalizeCriteriaValues() {
        let criteriaValues = [
            "Criterion1": 75.0,
            "Criterion2": 80.0
        ]
        
        let ranges = [
            "Criterion1": (min: 0.0, max: 100.0),
            "Criterion2": (min: 0.0, max: 100.0)
        ]
        
        let normalized = Normalization.normalizeCriteriaValues(criteriaValues, criteriaRanges: ranges)
        
        #expect(normalized["Criterion1"] == 3.75)
        #expect(normalized["Criterion2"] == 4.0)
    }
}

// MARK: - Ranking Helper Tests

@Suite("Ranking Helper Tests")
struct RankingHelperTests {
    
    @Test("Create a ranking report")
    func testCreateReport() {
        // Create a test result
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: ["Test": 3.0]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 4.5,
            coreFactorScore: 4.2,
            secondaryFactorScore: 4.8,
            gapDetails: ["Test": 4.5]
        )
        
        // Create report
        let report = RankingHelper.createReport(
            from: [result],
            scoreRange: (0.0, 5.0)
        )
        
        #expect(report.rankedResults.count == 1)
        #expect(report.rankedResults[0].finalScore == 4.5)
    }
    
    @Test("Format scores in different formats")
    func testFormatScores() {
        // Create a test result
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: ["Test": 3.0]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 4.5,
            coreFactorScore: 4.2,
            secondaryFactorScore: 4.8,
            gapDetails: ["Test": 4.5]
        )
        
        // Test raw format
        let rawReport = RankingHelper.createReport(
            from: [result], 
            scoreFormat: .raw,
            scoreRange: (0.0, 5.0)
        )
        
        #expect(rawReport.formatScore(4.5) == "4.50")
        
        // Test percentage format
        let percentReport = RankingHelper.createReport(
            from: [result], 
            scoreFormat: .percentage,
            scoreRange: (0.0, 5.0)
        )
        
        #expect(percentReport.formatScore(4.5) == "90.0%")
        
        // Test stars format
        let starsReport = RankingHelper.createReport(
            from: [result], 
            scoreFormat: .stars(maxStars: 5),
            scoreRange: (0.0, 5.0)
        )
        
        #expect(starsReport.formatScore(4.5) == "⭐⭐⭐⭐⭐")
    }
    
    @Test("Format scores with custom score range")
    func testFormatScoresWithCustomRange() {
        // Create a test result with custom score range
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: ["Test": 3.0]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 7.5,
            coreFactorScore: 7.2,
            secondaryFactorScore: 7.8,
            gapDetails: ["Test": 7.5]
        )
        
        // Test percentage format with 0-10 scale
        let percentReport = RankingHelper.createReport(
            from: [result], 
            scoreFormat: .percentage,
            scoreRange: (0.0, 10.0)
        )
        
        #expect(percentReport.formatScore(7.5) == "75.0%")
        
        // Test stars format with 0-10 scale
        let starsReport = RankingHelper.createReport(
            from: [result], 
            scoreFormat: .stars(maxStars: 5),
            scoreRange: (0.0, 10.0)
        )
        
        #expect(starsReport.formatScore(7.5) == "⭐⭐⭐⭐")
    }
    
    @Test("Generate text summary")
    func testGenerateTextSummary() {
        // Create test result
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: ["Test": 3.0]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 4.5,
            coreFactorScore: 4.2,
            secondaryFactorScore: 4.8,
            gapDetails: ["Test": 4.5]
        )
        
        // Create report
        let report = RankingHelper.createReport(
            from: [result],
            scoreRange: (0.0, 5.0)
        )
        
        let summary = report.generateTextSummary()
        #expect(summary.contains("Test Alternative"))
        #expect(summary.contains("4.50"))
    }
    
    @Test("Find most influential criteria")
    func testFindMostInfluentialCriteria() {
        // Create test result with multiple criteria
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: [
                "Strong": 5.0,
                "Weak": 1.0,
                "Medium": 3.0
            ]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 3.0,
            coreFactorScore: 3.0,
            secondaryFactorScore: 3.0,
            gapDetails: [
                "Strong": 5.0,
                "Weak": 1.0,
                "Medium": 3.0
            ]
        )
        
        // Find influential criteria
        let influential = RankingHelper.findMostInfluentialCriteria(
            from: [result],
            scoreRange: (0.0, 5.0)
        )
        
        #expect(influential["Strong"]! > influential["Medium"]!)
        #expect(influential["Weak"]! > influential["Medium"]!)
    }
    
    @Test("Identify strengths and weaknesses")
    func testIdentifyStrengthsAndWeaknesses() {
        // Create test result
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: [
                "Strong": 5.0,
                "Weak": 1.0,
                "Medium": 3.0
            ]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 3.0,
            coreFactorScore: 3.0,
            secondaryFactorScore: 3.0,
            gapDetails: [
                "Strong": 5.0,
                "Weak": 1.0,
                "Medium": 3.0
            ]
        )
        
        // Identify strengths and weaknesses
        let (strengths, weaknesses) = RankingHelper.identifyStrengthsAndWeaknesses(
            for: result,
            threshold: 4.0,
            scoreRange: (0.0, 5.0)
        )
        
        #expect(strengths.count == 1)
        #expect(strengths[0] == "Strong")
        #expect(weaknesses.count == 1)
        #expect(weaknesses[0] == "Weak")
    }
    
    @Test("Identify strengths and weaknesses with custom range")
    func testIdentifyStrengthsAndWeaknessesWithCustomRange() {
        // Create a test result with custom score range 0-10
        let alternative = ProfileMatching.Alternative(
            id: "C001", 
            name: "Test Alternative", 
            criteriaValues: [
                "Strength": 8.0,
                "Neutral": 5.0,
                "Weakness": 2.0
            ]
        )
        
        let result = ProfileMatching.MatchingResult(
            alternative: alternative,
            finalScore: 5.0,
            coreFactorScore: 5.0,
            secondaryFactorScore: 5.0,
            gapDetails: [
                "Strength": 8.0,
                "Neutral": 5.0,
                "Weakness": 2.0
            ]
        )
        
        // Using a threshold of 7.0 on a 0-10 scale
        let (strengths, weaknesses) = RankingHelper.identifyStrengthsAndWeaknesses(
            for: result,
            threshold: 7.0,
            scoreRange: (0.0, 10.0)
        )
        
        #expect(strengths.count == 1)
        #expect(strengths[0] == "Strength")
        #expect(weaknesses.count == 1)
        #expect(weaknesses[0] == "Weakness")
    }
    
    @Test("Find most influential criteria with custom range")
    func testMostInfluentialCriteriaWithCustomRange() {
        // Create test results with custom score range 0-10
        let alternative1 = ProfileMatching.Alternative(
            id: "A001", 
            name: "Alternative 1", 
            criteriaValues: [
                "Criterion1": 9.0,
                "Criterion2": 5.0
            ]
        )
        
        let alternative2 = ProfileMatching.Alternative(
            id: "A002", 
            name: "Alternative 2", 
            criteriaValues: [
                "Criterion1": 1.0,
                "Criterion2": 5.0
            ]
        )
        
        let result1 = ProfileMatching.MatchingResult(
            alternative: alternative1,
            finalScore: 7.0,
            coreFactorScore: 7.0,
            secondaryFactorScore: 7.0,
            gapDetails: [
                "Criterion1": 9.0,
                "Criterion2": 5.0
            ]
        )
        
        let result2 = ProfileMatching.MatchingResult(
            alternative: alternative2,
            finalScore: 3.0,
            coreFactorScore: 3.0,
            secondaryFactorScore: 3.0,
            gapDetails: [
                "Criterion1": 1.0,
                "Criterion2": 5.0
            ]
        )
        
        // Find influential criteria
        let influential = RankingHelper.findMostInfluentialCriteria(
            from: [result1, result2],
            scoreRange: (0.0, 10.0)
        )
        
        #expect(influential["Criterion1"]! > influential["Criterion2"]!)
    }
}
