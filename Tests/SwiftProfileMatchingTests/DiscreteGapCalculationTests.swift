import Testing
@testable import SwiftProfileMatching

// MARK: - Discrete Gap Calculation Tests

@Suite("Discrete Gap Calculation")
struct DiscreteGapCalculationTests {
    
    @Test("Laboratory Assistant Selection Case Study")
    func testLabAssistantSelection() throws {
        // Step 1: Define criteria with target values and weights
        let criteria = [
            ProfileMatching.Criterion(name: "IPK", targetValue: 4.0, type: .coreFactor, weight: 25),
            ProfileMatching.Criterion(name: "Penguasaan Jaringan Komputer", targetValue: 4.0, type: .coreFactor, weight: 20),
            ProfileMatching.Criterion(name: "Penguasaan Bahasa Pemrograman", targetValue: 5.0, type: .coreFactor, weight: 20),
            ProfileMatching.Criterion(name: "Komunikasi dan Kerjasama Tim", targetValue: 4.0, type: .coreFactor, weight: 20),
            ProfileMatching.Criterion(name: "Kedisiplinan dan Tanggung Jawab", targetValue: 4.0, type: .coreFactor, weight: 15)
        ]
        
        // Step 2: Create discrete gap mapping to match the manual calculation exactly
        let gapScoreMap: [Double: Double] = [
            -4.0: 1.0,     // Gap -4 or below → Score 1
            -3.0: 2.0,     // Gap -3 → Score 2
            -2.0: 3.0,     // Gap -2 → Score 3
            -1.0: 4.0,     // Gap -1.0 → Score 4 (exact)
            -0.9: 3.0,     // Gap -0.9 to -0.4 → Score 3
            -0.4: 3.0,     // Gap -0.4 → Score 3 (Dedi's IPK)
            -0.3: 4.0,     // Gap -0.3 to -0.1 → Score 4
            -0.1: 4.0,     // Gap -0.1 → Score 4 (Citra's IPK)
            0.0: 5.0,      // Gap 0 → Score 5
            1.0: 5.0,      // Gap +1 → Score 5
            2.0: 5.0,      // Gap +2 or more → Score 5
        ]
        
        let mappingPairs = ProfileMatchingConfiguration.createDiscreteMapping(gapToScoreMap: gapScoreMap)
        
        // Create configuration with enhanced discrete gap mapping using threshold method
        // This perfectly matches the manual calculation approach
        let config = ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: .threshold),
            coreFactorWeight: 1.0,  // Weight for all factors (100%)
            secondaryFactorWeight: 0.0,  // No secondary factors
            normalizationMethod: .none,  // No normalization needed as all values are on the same 0-5 scale
            weightCalculation: .direct
        )
        
        // Step 3: Create alternatives (candidates)
        let candidates = [
            ProfileMatching.Alternative(
                id: "A001",
                name: "Andi",
                criteriaValues: [
                    "IPK": 3.8,
                    "Penguasaan Jaringan Komputer": 3.0,
                    "Penguasaan Bahasa Pemrograman": 4.0,
                    "Komunikasi dan Kerjasama Tim": 4.0,
                    "Kedisiplinan dan Tanggung Jawab": 5.0
                ]
            ),
            ProfileMatching.Alternative(
                id: "A002",
                name: "Budi",
                criteriaValues: [
                    "IPK": 3.5,
                    "Penguasaan Jaringan Komputer": 4.0,
                    "Penguasaan Bahasa Pemrograman": 5.0,
                    "Komunikasi dan Kerjasama Tim": 3.0,
                    "Kedisiplinan dan Tanggung Jawab": 4.0
                ]
            ),
            ProfileMatching.Alternative(
                id: "A003",
                name: "Citra",
                criteriaValues: [
                    "IPK": 3.9,
                    "Penguasaan Jaringan Komputer": 4.0,
                    "Penguasaan Bahasa Pemrograman": 4.0,
                    "Komunikasi dan Kerjasama Tim": 5.0,
                    "Kedisiplinan dan Tanggung Jawab": 5.0
                ]
            ),
            ProfileMatching.Alternative(
                id: "A004",
                name: "Dedi",
                criteriaValues: [
                    "IPK": 3.6,
                    "Penguasaan Jaringan Komputer": 3.0,
                    "Penguasaan Bahasa Pemrograman": 5.0,
                    "Komunikasi dan Kerjasama Tim": 4.0,
                    "Kedisiplinan dan Tanggung Jawab": 3.0
                ]
            )
        ]
        
        // Step 4: Initialize Profile Matching and calculate results
        let profileMatching = ProfileMatching(criteria: criteria, configuration: config)
        let results = profileMatching.calculateMatching(for: candidates)
        
        // Step 5: Verify results
        #expect(results.count == 4, "Should have 4 candidates ranked")
        
        // Expected order of candidates based on the problem statement (could be different based on gap mapping)
        // We will verify the expected winner
        let winner = results.first
        #expect(winner != nil, "Should have a winner")
        #expect(winner?.alternative.name == "Citra", "Citra should be the winner")
        
        // Verify gap value calculations
        // Check a few gap values to ensure discrete mapping is working correctly
        
        // Find Citra's result
        let citraResult = results.first { $0.alternative.name == "Citra" }
        #expect(citraResult != nil, "Should find Citra in results")
        
        if let citra = citraResult {
            // Check IPK gap calculation (Citra has 3.9, target is 4.0, gap is -0.1)
            // According to the manual: gap -0.1 gets score 4.0
            #expect(citra.gapDetails["IPK"]! == 4.0, "IPK gap value should be 4.0 (matching manual calculation)")
            
            // Check Bahasa Pemrograman gap (4.0 vs 5.0, gap is -1.0)
            // For gap -1.0, the score should be 4.0 with the Likert scale
            #expect(citra.gapDetails["Penguasaan Bahasa Pemrograman"]! == 4.0, "Programming gap value should be 4.0")
            
            // Print detailed results for debugging
            print("Detailed results for \(citra.alternative.name):")
            print("- Core Factor Score: \(citra.coreFactorScore)")
            print("- Secondary Factor Score: \(citra.secondaryFactorScore)")
            print("- Final Score: \(citra.finalScore)")
            print("- Gap Details:")
            for (criterion, score) in citra.gapDetails {
                print("  - \(criterion): \(score)")
            }
        }
        
        // Print overall ranking to console for debugging
        print("\nFinal ranking:")
        for (index, result) in results.enumerated() {
            print("\(index + 1). \(result.alternative.name): \(result.finalScore)")
        }
        
        // Tampilkan hasil dalam format persentase
        let percentReport = RankingHelper.createReport(from: results)
        
        // Tampilkan hasil lengkap
        print(percentReport.generateTextSummary())
    }
    
    @Test("Test Convenience Methods for Discrete Mapping")
    func testDiscreteConvenienceMethods() {
        // Test symmetric discrete mapping
        let symmetricConfig = ProfileMatchingConfiguration.discreteSymmetric(
            perfectMatchScore: 5.0,
            maxGap: 3,
            maxScore: 5.0
        )
        
        // Verify configuration has discrete strategy
        switch symmetricConfig.gapCalculationStrategy {
        case .discrete(let mappingPairs, _):
            #expect(mappingPairs.count == 7, "Should have 7 mapping pairs (0, ±1, ±2, ±3)")
            
            // Verify values at key points
            let zero = mappingPairs.first { $0.gap == 0 }
            #expect(zero?.score == 5.0, "Perfect match should score 5.0")
            
            let plusOne = mappingPairs.first { $0.gap == 1 }
            let minusOne = mappingPairs.first { $0.gap == -1 }
            #expect(plusOne?.score == minusOne?.score, "Symmetric mapping should treat +1 and -1 the same")
            
        default:
            #expect(false, "Should have discrete gap calculation strategy")
        }
        
        // Test asymmetric discrete mapping
        let asymmetricConfig = ProfileMatchingConfiguration.discreteAsymmetric(
            perfectMatchScore: 5.0,
            maxGap: 3,
            exceedPenalty: 0.5,  // Lower penalty for exceeding
            belowPenalty: 1.0,   // Higher penalty for below
            maxScore: 5.0
        )
        
        // Verify configuration has discrete strategy with asymmetric values
        switch asymmetricConfig.gapCalculationStrategy {
        case .discrete(let mappingPairs, _):
            #expect(mappingPairs.count == 7, "Should have 7 mapping pairs (0, ±1, ±2, ±3)")
            
            // Verify values at key points
            let plusOne = mappingPairs.first { $0.gap == 1 }
            let minusOne = mappingPairs.first { $0.gap == -1 }
            
            // Safely unwrap optionals before comparison
            if let plusOneScore = plusOne?.score, let minusOneScore = minusOne?.score {
                #expect(plusOneScore > minusOneScore, "Asymmetric mapping should penalize below target more")
            } else {
                #expect(false, "Should have found +1 and -1 gap mappings")
            }
            
        default:
            #expect(false, "Should have discrete gap calculation strategy")
        }
        
        // Test creating from dictionary
        let gapScoreMap: [Double: Double] = [
            -2.0: 1.0,
            -1.0: 3.0,
             0.0: 5.0,
             1.0: 4.0,
             2.0: 2.0
        ]
        
        let mappingPairs = ProfileMatchingConfiguration.createDiscreteMapping(gapToScoreMap: gapScoreMap)
        #expect(mappingPairs.count == 5, "Should have 5 mapping pairs")
        #expect(mappingPairs.sorted().first?.gap == -2.0, "First gap should be -2.0")
        #expect(mappingPairs.sorted().last?.gap == 2.0, "Last gap should be 2.0")
    }
    
    @Test("Test Enhanced Discrete Gap Handling Methods")
    func testEnhancedDiscreteGapHandlingMethods() {
        // Define a simple discrete mapping with gaps
        let gapScoreMap: [Double: Double] = [
            -2.0: 3.0,
            -1.0: 4.0,
             0.0: 5.0,
             1.0: 5.0
        ]
        let mappingPairs = ProfileMatchingConfiguration.createDiscreteMapping(gapToScoreMap: gapScoreMap)
        
        // Create a test gap that falls between defined points
        let testGap = -1.5  // Between -2.0 (score 3.0) and -1.0 (score 4.0)
        
        // Test different handling methods
        
        // 1. Interpolation method - should linearly interpolate (50% between 3.0 and 4.0 = 3.5)
        let interpolationConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: .interpolation),
            coreFactorWeight: 1.0,
            secondaryFactorWeight: 0.0
        )
        
        // 2. Nearest neighbor method - should use closest gap (-2.0 with score 3.0)
        let nearestConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: .nearestNeighbor),
            coreFactorWeight: 1.0,
            secondaryFactorWeight: 0.0
        )
        
        // 3. Threshold method - should use the threshold gap (-2.0 with score 3.0)
        let thresholdConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: .threshold),
            coreFactorWeight: 1.0,
            secondaryFactorWeight: 0.0
        )
        
        // 4. Default value method - should use the specified default value (2.0)
        let defaultConfig = ProfileMatchingConfiguration(
            gapCalculationStrategy: .discrete(mappingPairs: mappingPairs, handlingMethod: .defaultValue(score: 2.0)),
            coreFactorWeight: 1.0,
            secondaryFactorWeight: 0.0
        )
        
        // Create a simple criterion
        let criterion = ProfileMatching.Criterion(name: "Test", targetValue: 5.0, type: .coreFactor, weight: 100)
        
        // Create a simple alternative with a calculated gap of -1.5
        let alternative = ProfileMatching.Alternative(
            id: "test",
            name: "Test",
            criteriaValues: ["Test": 3.5]  // Gap = 3.5 - 5.0 = -1.5
        )
        
        // Calculate results with different methods
        let interpolationResult = ProfileMatching(criteria: [criterion], configuration: interpolationConfig)
            .calculateMatching(for: [alternative]).first!
        
        let nearestResult = ProfileMatching(criteria: [criterion], configuration: nearestConfig)
            .calculateMatching(for: [alternative]).first!
            
        let thresholdResult = ProfileMatching(criteria: [criterion], configuration: thresholdConfig)
            .calculateMatching(for: [alternative]).first!
            
        let defaultResult = ProfileMatching(criteria: [criterion], configuration: defaultConfig)
            .calculateMatching(for: [alternative]).first!
        
        // Verify the different scores based on the handling method
        #expect(interpolationResult.gapDetails["Test"]! == 3.5, "Interpolation should give 3.5 (halfway between 3.0 and 4.0)")
        #expect(nearestResult.gapDetails["Test"]! == 3.0, "Nearest neighbor should give 3.0 (nearest to -1.5 is -2.0)")
        #expect(thresholdResult.gapDetails["Test"]! == 3.0, "Threshold should give 3.0 (threshold at -2.0)")
        #expect(defaultResult.gapDetails["Test"]! == 2.0, "Default should give 2.0 (specified default value)")
        
        // Print results for comparison
        print("Gap -1.5 handled by different methods:")
        print("- Interpolation: \(interpolationResult.gapDetails["Test"]!)")
        print("- Nearest Neighbor: \(nearestResult.gapDetails["Test"]!)")
        print("- Threshold: \(thresholdResult.gapDetails["Test"]!)")
        print("- Default Value: \(defaultResult.gapDetails["Test"]!)")
    }
} 
