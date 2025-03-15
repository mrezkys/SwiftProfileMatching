# SwiftProfileMatching

A Swift Package for implementing Profile Matching Method - a popular technique used in Decision Support Systems (DSS).

## Overview

Profile Matching is a DSS method that compares alternatives against an ideal profile (criteria) to calculate scores and rankings. It's widely applicable in various decision-making scenarios:

- Employee recruitment and selection
- Supplier evaluation
- Product/service selection
- Technology assessment
- Performance appraisal
- Project prioritization
- Site location selection
- Scholarship recipient selection
- And many other multi-criteria decision-making scenarios

This package provides a complete implementation of the Profile Matching method with flexible configuration options designed to be general-purpose and adaptable to your specific needs.

## Development Status

> ⚠️ **Important Notice**: This library is currently under active development and testing. While the core functionality is implemented, you may encounter bugs or changes to the Package. Use in production environments with caution.
>
> **Current Limitations**:
> - Some components still contain hardcoded values that need to be made configurable
> - The gap calculation strategy needs more flexibility for custom implementations
> - Some normalization methods are still being refined
>
> We welcome feedback, bug reports, and contributions as we work toward a stable 1.0 release. Please check the issues section for known limitations and planned improvements.

## Features

- Calculate profile matching scores based on core and secondary factors
- Customizable gap calculation strategies
- Normalization utilities for input data with multiple methods
- Configuration options for weights, scoring methods, and score ranges
- Ranking tools to analyze and present results
- Comprehensive analysis tools (identifying strengths/weaknesses, influential criteria)
- Z-score normalization for comparative analysis

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftProfileMatching.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/SwiftProfileMatching.git`
3. Click "Add Package"

<details>
<summary><h2>Quick Start</h2></summary>

Here's a quick example of how to use the package:

```swift
import SwiftProfileMatching

// 1. Define your criteria
let criteria = [
    ProfileMatching.Criterion(name: "Experience", targetValue: 4.0, type: .coreFactor, weight: 60),
    ProfileMatching.Criterion(name: "Education", targetValue: 5.0, type: .coreFactor, weight: 40),
    ProfileMatching.Criterion(name: "Communication", targetValue: 3.0, type: .secondaryFactor, weight: 70),
    ProfileMatching.Criterion(name: "Teamwork", targetValue: 4.0, type: .secondaryFactor, weight: 30)
]

// 2. Create alternatives to evaluate
let alternatives = [
    ProfileMatching.Alternative(
        id: "A001", 
        name: "Option One", 
        criteriaValues: [
            "Experience": 5.0,
            "Education": 5.0,
            "Communication": 4.0,
            "Teamwork": 5.0
        ]
    ),
    ProfileMatching.Alternative(
        id: "A002", 
        name: "Option Two", 
        criteriaValues: [
            "Experience": 3.0,
            "Education": 5.0,
            "Communication": 5.0,
            "Teamwork": 3.0
        ]
    )
]

// 3. Create the profile matching calculator
let profileMatching = ProfileMatching(criteria: criteria)

// 4. Calculate matching results
let results = profileMatching.calculateMatching(for: alternatives)

// 5. Generate a ranking report
let report = RankingHelper.createReport(
    from: results, 
    scoreFormat: .percentage
)

// 6. Print the summary
print(report.generateTextSummary())
```
</details>

<details>
<summary><h2>Advanced Usage</h2></summary>

### Custom Configuration

You can customize the profile matching calculation with a configuration:

```swift
let config = ProfileMatchingConfiguration(
    gapCalculationStrategy: .custom(
        perfectMatchScore: 10.0,
        exceedsPenalty: 1.0,
        belowPenalty: 2.0,
        maxScore: 10.0
    ),
    coreFactorWeight: 0.7,
    secondaryFactorWeight: 0.3,
    normalizationMethod: .global,
    weightCalculation: .normalized,
    scoreRange: (0.0, 10.0)
)

let profileMatching = ProfileMatching(criteria: criteria, configuration: config)
```

### Normalizing Input Values

Use the Normalization utilities to standardize raw input values:

```swift
// Normalize values from different scales to the standard 0-5 scale
let rawValues = ["Criterion1": 75.0, "Criterion2": 80.0]

let ranges = [
    "Criterion1": (min: 0.0, max: 100.0),
    "Criterion2": (min: 0.0, max: 100.0)
]

let normalized = Normalization.normalizeCriteriaValues(
    rawValues, 
    criteriaRanges: ranges,
    targetMin: 0.0,
    targetMax: 5.0
)
// Result: ["Criterion1": 3.75, "Criterion2": 4.0]

// Compare alternatives using Z-scores
let scores = ["A001": 4.5, "A002": 3.8, "A003": 4.1]
let zScores = Normalization.normalizeToZScores(scores)
// Compares each alternative's performance relative to the mean
```

### Analysis Tools

Identify strengths and weaknesses of alternatives:

```swift
let (strengths, weaknesses) = RankingHelper.identifyStrengthsAndWeaknesses(
    for: result,
    threshold: 4.0  // Criteria scored 4.0 or higher are strengths
)

print("Strengths: \(strengths)")
print("Weaknesses: \(weaknesses)")
```

Find which criteria had the most influence on the results:

```swift
let influential = RankingHelper.findMostInfluentialCriteria(from: results)

// Measure how well each criterion differentiates between alternatives
let differentiationPower = RankingHelper.calculateCriteriaDifferentiationPower(from: results)
```

### Formatting Results

Format scores in different ways:

```swift
// Create reports with different formatting options
let rawReport = RankingHelper.createReport(from: results, scoreFormat: .raw)
let percentReport = RankingHelper.createReport(from: results, scoreFormat: .percentage)
let starsReport = RankingHelper.createReport(from: results, scoreFormat: .stars(maxStars: 5))

// Format a specific score
print(rawReport.formatScore(4.5))      // "4.50"
print(percentReport.formatScore(4.5))  // "90.0%"
print(starsReport.formatScore(4.5))    // "⭐⭐⭐⭐⭐"
```
</details>

<details>
<summary><h2>Theory</h2></summary>

### Profile Matching Fundamentals

Profile Matching is a multi-criteria decision-making method used to evaluate alternatives by comparing their attribute values against an ideal profile. The process involves several key steps:

1. **Define criteria and target values** - Establish what factors are important and what their ideal values should be
2. **Categorize criteria** - Typically divided into "core factors" (essential criteria) and "secondary factors" (supporting criteria)
3. **Assign weights** - Determine the relative importance of each criterion
4. **Optional: Normalize input values** - Standardize values across different scales (optional, disabled by default)
5. **Calculate gap values** - Measure how closely each alternative matches the ideal profile for each criterion
6. **Calculate weighted scores** - Combine gap values using appropriate weighting schemes
7. **Rank alternatives** - Order alternatives based on their final scores

### Step-by-Step Process

Let's walk through a complete Profile Matching calculation using this package, assuming a job candidate selection scenario:

#### 1. Define Criteria and Target Values

First, we define what we're looking for by specifying criteria and their ideal values:

```swift
let criteria = [
    ProfileMatching.Criterion(name: "Experience", targetValue: 4.0, type: .coreFactor, weight: 60),
    ProfileMatching.Criterion(name: "Education", targetValue: 5.0, type: .coreFactor, weight: 40),
    ProfileMatching.Criterion(name: "Communication", targetValue: 3.0, type: .secondaryFactor, weight: 70),
    ProfileMatching.Criterion(name: "Teamwork", targetValue: 4.0, type: .secondaryFactor, weight: 30)
]
```

In this example:
- We have 4 criteria: Experience, Education, Communication, and Teamwork
- Values are on a scale of 0-5
- Experience and Education are core factors (essential requirements)
- Communication and Teamwork are secondary factors (desirable but not critical)

#### 2. Create Alternatives to Evaluate

Next, we define our alternatives to evaluate:

```swift
let alternatives = [
    ProfileMatching.Alternative(
        id: "A001", 
        name: "John Smith", 
        criteriaValues: [
            "Experience": 5.0,  // Exceeds target
            "Education": 5.0,   // Matches target
            "Communication": 4.0, // Exceeds target
            "Teamwork": 5.0     // Exceeds target
        ]
    ),
    ProfileMatching.Alternative(
        id: "A002", 
        name: "Jane Doe", 
        criteriaValues: [
            "Experience": 3.0,  // Below target
            "Education": 5.0,   // Matches target
            "Communication": 5.0, // Exceeds target
            "Teamwork": 3.0     // Below target
        ]
    )
]
```

#### 3. Configure Profile Matching (Optional)

By default, the package uses standard settings, but you can optionally configure various aspects including normalization:

```swift
// Optional: Create a custom configuration with normalization enabled
let config = ProfileMatchingConfiguration(
    gapCalculationStrategy: .standard,
    coreFactorWeight: 0.6,
    secondaryFactorWeight: 0.4,
    normalizationMethod: .global,  // Enable normalization
    weightCalculation: .direct,
    scoreRange: (0.0, 5.0)
)

// Initialize with custom configuration
let profileMatching = ProfileMatching(criteria: criteria, configuration: config)

// Or use default configuration (no normalization)
// let profileMatching = ProfileMatching(criteria: criteria)
```

#### 4. Optional: Normalize Input Values

If normalization is enabled in the configuration (it's disabled by default), the package will automatically normalize input values before gap calculation.

**Mathematical Formula:**

$$\text{Normalized Value} = \frac{\text{Value} - \text{Min}}{\text{Max} - \text{Min}} \times (\text{TargetMax} - \text{TargetMin}) + \text{TargetMin}$$

SwiftProfileMatching supports three normalization approaches:

1. **No Normalization (`none`)** - Use raw values directly (default)
2. **Global Normalization (`global`)** - Standardize values across all alternatives
3. **Local Normalization (`local`)** - Normalize each criterion separately

When enabled, the package internally performs normalization:

```swift
// This happens internally if normalization is enabled
// Excerpt from calculateMatchingForAlternative() method
let processedValues = normalizeInputValues(alternative.criteriaValues)
```

In our default example, normalization is skipped since we're using the same 0-5 scale for all criteria.

#### 5. Calculate Gap Values

For each criterion, we calculate how closely the alternative matches the target.

**Mathematical Formula (Standard Method):**

For core factors:

For perfect match (Δ = 0):
$$g_i = 5.0$$

For exceeding target (Δ > 0):
$$g_i = \min(4.5, 5.0 - 0.5 \times \Delta)$$

For below target (Δ < 0):
$$g_i = \max(0, 5.0 + \Delta)$$

For secondary factors:

For perfect match (Δ = 0):
$$g_i = 5.0$$

For exceeding target (Δ > 0):
$$g_i = \min(5.0, 5.0 - 0.25 \times \Delta)$$

For below target (Δ < 0):
$$g_i = \max(0, 5.0 + 0.75 \times \Delta)$$

Where $\Delta = \text{Actual Value} - \text{Target Value}$

**Custom Gap Calculation Method:**

For perfect match (Δ = 0):
$$g_i = P$$

For exceeding target (Δ > 0):
$$g_i = \max(0, \min(M, P - E \times \Delta))$$

For below target (Δ < 0):
$$g_i = \max(0, \min(M, P + B \times \Delta))$$

Where:
- $P$ = Perfect match score
- $E$ = Exceeds penalty
- $B$ = Below penalty
- $M$ = Maximum possible score
- $\Delta = \text{Actual Value} - \text{Target Value}$

For John Smith:
- Experience: Target 4.0, Actual 5.0, Gap = +1.0
  - Core factor exceeding target: 5.0 - (0.5 × 1.0) = 4.5
- Education: Target 5.0, Actual 5.0, Gap = 0
  - Perfect match: 5.0
- Communication: Target 3.0, Actual 4.0, Gap = +1.0
  - Secondary factor exceeding target: 5.0 - (0.25 × 1.0) = 4.75
- Teamwork: Target 4.0, Actual 5.0, Gap = +1.0
  - Secondary factor exceeding target: 5.0 - (0.25 × 1.0) = 4.75

For Jane Doe:
- Experience: Target 4.0, Actual 3.0, Gap = -1.0
  - Core factor below target: 5.0 + (-1.0) = 4.0
- Education: Target 5.0, Actual 5.0, Gap = 0
  - Perfect match: 5.0
- Communication: Target 3.0, Actual 5.0, Gap = +2.0
  - Secondary factor exceeding target: 5.0 - (0.25 × 2.0) = 4.5
- Teamwork: Target 4.0, Actual 3.0, Gap = -1.0
  - Secondary factor below target: 5.0 + (0.75 × -1.0) = 4.25

These calculations are performed by the `calculateGap()` method:

```swift
// The package internally calculates the gap values
for criterion in criteria {
    if let value = processedValues[criterion.name] {
        let gap = calculateGap(targetValue: criterion.targetValue, 
                              actualValue: value, 
                              type: criterion.type)
        gapDetails[criterion.name] = gap
    }
}
```

#### 6. Calculate Core Factor and Secondary Factor Scores

Next, we calculate weighted scores for core and secondary factors separately.

**Mathematical Formula:**

$$\text{Factor Score} = \frac{\sum_{i=1}^{n} (w_i \times g_i)}{\sum_{i=1}^{n} w_i}$$

Where:
- $w_i$ = Weight of criterion $i$ (in decimal form)
- $g_i$ = Gap value for criterion $i$
- $n$ = Number of criteria in the factor group

For John Smith:
- Core Factor Score: 
  - Experience (weight 60%): 4.5
  - Education (weight 40%): 5.0
  - Weighted Average: (4.5 × 0.6) + (5.0 × 0.4) = 4.7
- Secondary Factor Score:
  - Communication (weight 70%): 4.75
  - Teamwork (weight 30%): 4.75
  - Weighted Average: (4.75 × 0.7) + (4.75 × 0.3) = 4.75

For Jane Doe:
- Core Factor Score:
  - Experience (weight 60%): 4.0
  - Education (weight 40%): 5.0
  - Weighted Average: (4.0 × 0.6) + (5.0 × 0.4) = 4.4
- Secondary Factor Score:
  - Communication (weight 70%): 4.5
  - Teamwork (weight 30%): 4.25
  - Weighted Average: (4.5 × 0.7) + (4.25 × 0.3) = 4.425

The package automatically handles these weighted calculations:

```swift
// Calculated by the package through the calculateWeightedScore() method
let coreFactorScore = calculateWeightedScore(for: coreFactors, using: gapDetails)
let secondaryFactorScore = calculateWeightedScore(for: secondaryFactors, using: gapDetails)
```

#### 7. Calculate Final Scores

Finally, we combine core and secondary factor scores with their respective weights.

**Mathematical Formula:**

$$\text{Final Score} = (W_{cf} \times \text{CF}) + (W_{sf} \times \text{SF})$$

Where:
- $W_{cf}$ = Weight for core factors (typically 0.6 or 60%)
- $\text{CF}$ = Core factor score
- $W_{sf}$ = Weight for secondary factors (typically 0.4 or 40%)
- $\text{SF}$ = Secondary factor score

For John Smith:
- Final Score: (4.7 × 0.6) + (4.75 × 0.4) = 2.82 + 1.9 = 4.72

For Jane Doe:
- Final Score: (4.4 × 0.6) + (4.425 × 0.4) = 2.64 + 1.77 = 4.41

The package performs this calculation:

```swift
// Calculated by the package
finalScore = (configuration.coreFactorWeight * coreFactorScore) +
             (configuration.secondaryFactorWeight * secondaryFactorScore)
```

#### 8. Rank and Analyze

The package then sorts alternatives by final score:

```swift
// John Smith: 4.72
// Jane Doe: 4.41
let results = profileMatching.calculateMatching(for: alternatives)
// results[0] would be John Smith
// results[1] would be Jane Doe
```

For deeper analysis, we can:

```swift
// Generate a formatted report
let report = RankingHelper.createReport(from: results)

// Find strengths and weaknesses
let (strengths, weaknesses) = RankingHelper.identifyStrengthsAndWeaknesses(
    for: results[0],  // John Smith
    threshold: 4.5    // Criteria with scores above 4.5 are strengths
)
// strengths = ["Education", "Communication", "Teamwork"]
// weaknesses = []

// Identify most influential criteria
let influential = RankingHelper.findMostInfluentialCriteria(from: results)
// Would show which criteria created the most differentiation
```

### Core vs. Secondary Factors

Profile Matching distinguishes between different types of criteria:

- **Core Factors** - Essential criteria that are critical to the decision (e.g., education level for a job position)
- **Secondary Factors** - Supporting criteria that are beneficial but not critical (e.g., communication skills)

These are implemented as the `GapType` enum:

```swift
public enum GapType: Sendable {
    case coreFactor
    case secondaryFactor
}
```

### Weighted Scoring

Once gap values are calculated, they are combined using weighted averages. The package supports two weighting approaches:

1. **Direct Weights** - Use weights as provided (must sum to 100%)
2. **Normalized Weights** - Automatically normalize weights to ensure they sum to 100%

```swift
// Implemented in calculateWeightedScore()
var totalWeight = 0.0
var weightedSum = 0.0

for criterion in criteria {
    guard let gapValue = gapDetails[criterion.name] else { continue }
    
    // Convert percentage weights to decimal
    let normalizedWeight = criterion.weight / 100.0
    weightedSum += normalizedWeight * gapValue
    totalWeight += normalizedWeight
}

// Normalize by total weight
return totalWeight > 0 ? weightedSum / totalWeight : 0
```

### Ranking and Analysis

After scoring alternatives, additional analysis can provide deeper insights:

1. **Influential Criteria Analysis** - Identify which criteria had the most impact on differentiation
2. **Strengths and Weaknesses** - Highlight areas where alternatives perform particularly well or poorly
3. **Z-Score Analysis** - Compare alternatives against the statistical distribution of all alternatives

```swift
// Example of differentiation power calculation
public static func calculateCriteriaDifferentiationPower(from results: [MatchingResult]) -> [String: Double] {
    // Find all unique criteria
    var allCriteria = Set<String>()
    for result in results {
        allCriteria.formUnion(result.gapDetails.keys)
    }
    
    // Calculate standard deviation for each criterion
    var differentiationPower = [String: Double]()
    
    for criterion in allCriteria {
        let values = results.compactMap { $0.gapDetails[criterion] }
        guard values.count > 1 else {
            differentiationPower[criterion] = 0.0
            continue
        }
        
        // Calculate standard deviation
        let mean = values.reduce(0.0, +) / Double(values.count)
        let variance = values.reduce(0.0) { sum, value in
            let diff = value - mean
            return sum + (diff * diff)
        } / Double(values.count)
        
        let stdDev = sqrt(variance)
        differentiationPower[criterion] = stdDev
    }
    
    return differentiationPower
}
```
</details>