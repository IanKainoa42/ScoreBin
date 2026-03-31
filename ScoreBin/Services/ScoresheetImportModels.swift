import CoreGraphics
import Foundation
import UniformTypeIdentifiers

enum ScoresheetImportSourceType: String, Codable, CaseIterable, Sendable {
    case cameraScan
    case photoLibrary
    case pdf

    var displayName: String {
        switch self {
        case .cameraScan:
            return "Camera Scan"
        case .photoLibrary:
            return "Photo Library"
        case .pdf:
            return "PDF"
        }
    }
}

enum ScoresheetFieldValue: Codable, Equatable, Hashable, Sendable {
    case score(Double)
    case deduction(Int)

    var displayString: String {
        switch self {
        case .score(let value):
            return value.scoreFormatted
        case .deduction(let value):
            return String(value)
        }
    }

    var doubleValue: Double? {
        guard case .score(let value) = self else { return nil }
        return value
    }

    var intValue: Int? {
        guard case .deduction(let value) = self else { return nil }
        return value
    }
}

enum ParsedFieldStatus: String, Codable, Sendable {
    case accepted
    case needsReview
    case confirmed
}

enum ScoresheetFieldID: String, CaseIterable, Codable, Identifiable, Sendable {
    case stuntDifficulty
    case stuntExecution
    case stuntDriverDegree
    case stuntDriverMaxPart
    case pyramidDifficulty
    case pyramidExecution
    case tossDifficulty
    case tossExecution
    case buildingCreativity
    case buildingShowmanship
    case standingDifficulty
    case standingExecution
    case standingDrivers
    case runningDifficulty
    case runningExecution
    case runningDrivers
    case runningDriverMaxPart
    case jumpsDifficulty
    case jumpsExecution
    case tumblingCreativity
    case tumblingShowmanship
    case danceDifficulty
    case danceExecution
    case formations
    case overallCreativity
    case overallShowmanship
    case athleteFalls
    case majorAthleteFalls
    case buildingBobbles
    case buildingFalls
    case majorBuildingFalls
    case boundaryViolations
    case timeLimitViolations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stuntDifficulty:
            return "Stunt Difficulty"
        case .stuntExecution:
            return "Stunt Execution"
        case .stuntDriverDegree:
            return "Stunt DoD"
        case .stuntDriverMaxPart:
            return "Stunt MPD"
        case .pyramidDifficulty:
            return "Pyramid Difficulty"
        case .pyramidExecution:
            return "Pyramid Execution"
        case .tossDifficulty:
            return "Toss Difficulty"
        case .tossExecution:
            return "Toss Execution"
        case .buildingCreativity:
            return "Building Creativity"
        case .buildingShowmanship:
            return "Building Showmanship"
        case .standingDifficulty:
            return "Standing Difficulty"
        case .standingExecution:
            return "Standing Execution"
        case .standingDrivers:
            return "Standing Drivers"
        case .runningDifficulty:
            return "Running Difficulty"
        case .runningExecution:
            return "Running Execution"
        case .runningDrivers:
            return "Running Drivers"
        case .runningDriverMaxPart:
            return "Running Max Part"
        case .jumpsDifficulty:
            return "Jumps Difficulty"
        case .jumpsExecution:
            return "Jumps Execution"
        case .tumblingCreativity:
            return "Tumbling Creativity"
        case .tumblingShowmanship:
            return "Tumbling Showmanship"
        case .danceDifficulty:
            return "Dance Difficulty"
        case .danceExecution:
            return "Dance Execution"
        case .formations:
            return "Formations"
        case .overallCreativity:
            return "Overall Creativity"
        case .overallShowmanship:
            return "Overall Showmanship"
        case .athleteFalls:
            return "Athlete Falls"
        case .majorAthleteFalls:
            return "Major Athlete Falls"
        case .buildingBobbles:
            return "Building Bobbles"
        case .buildingFalls:
            return "Building Falls"
        case .majorBuildingFalls:
            return "Major Building Falls"
        case .boundaryViolations:
            return "Boundary Violations"
        case .timeLimitViolations:
            return "Time Limit Violations"
        }
    }

    var isIntegerField: Bool {
        switch self {
        case .athleteFalls, .majorAthleteFalls, .buildingBobbles, .buildingFalls,
            .majorBuildingFalls, .boundaryViolations, .timeLimitViolations:
            return true
        default:
            return false
        }
    }

    var isTossField: Bool {
        self == .tossDifficulty || self == .tossExecution
    }

    var scoreRange: ScoringRules.ScoreRange? {
        switch self {
        case .stuntDifficulty:
            return ScoringRules.stuntDifficultyRange
        case .stuntExecution:
            return ScoringRules.stuntExecutionRange
        case .stuntDriverDegree:
            return ScoringRules.stuntDriverDegreeRange
        case .stuntDriverMaxPart:
            return ScoringRules.stuntDriverMaxPartRange
        case .pyramidDifficulty:
            return ScoringRules.pyramidDifficultyRange
        case .pyramidExecution:
            return ScoringRules.pyramidExecutionRange
        case .tossDifficulty:
            return ScoringRules.tossDifficultyRange
        case .tossExecution:
            return ScoringRules.tossExecutionRange
        case .buildingCreativity:
            return ScoringRules.creativityRange
        case .buildingShowmanship:
            return ScoringRules.showmanshipRange
        case .standingDifficulty:
            return ScoringRules.standingDifficultyRange
        case .standingExecution:
            return ScoringRules.standingExecutionRange
        case .standingDrivers:
            return ScoringRules.standingDriversRange
        case .runningDifficulty:
            return ScoringRules.runningDifficultyRange
        case .runningExecution:
            return ScoringRules.runningExecutionRange
        case .runningDrivers:
            return ScoringRules.runningDriversRange
        case .runningDriverMaxPart:
            return ScoringRules.runningDriverMaxPartRange
        case .jumpsDifficulty:
            return ScoringRules.jumpsDifficultyRange
        case .jumpsExecution:
            return ScoringRules.jumpsExecutionRange
        case .tumblingCreativity:
            return ScoringRules.creativityRange
        case .tumblingShowmanship:
            return ScoringRules.showmanshipRange
        case .danceDifficulty:
            return ScoringRules.danceDifficultyRange
        case .danceExecution:
            return ScoringRules.danceExecutionRange
        case .formations:
            return ScoringRules.formationsRange
        case .overallCreativity:
            return ScoringRules.creativityRange
        case .overallShowmanship:
            return ScoringRules.showmanshipRange
        case .athleteFalls, .majorAthleteFalls, .buildingBobbles, .buildingFalls,
            .majorBuildingFalls, .boundaryViolations, .timeLimitViolations:
            return nil
        }
    }

    var reviewHint: String {
        if let range = scoreRange {
            return "Expected \(range.min.scoreFormatted) - \(range.max.scoreFormatted)"
        }
        return "Enter a whole-number count"
    }

    func currentValue(in scoresheet: Scoresheet) -> ScoresheetFieldValue {
        switch self {
        case .stuntDifficulty:
            return .score(scoresheet.stuntDifficulty)
        case .stuntExecution:
            return .score(scoresheet.stuntExecution)
        case .stuntDriverDegree:
            return .score(scoresheet.stuntDriverDegree)
        case .stuntDriverMaxPart:
            return .score(scoresheet.stuntDriverMaxPart)
        case .pyramidDifficulty:
            return .score(scoresheet.pyramidDifficulty)
        case .pyramidExecution:
            return .score(scoresheet.pyramidExecution)
        case .tossDifficulty:
            return .score(scoresheet.tossDifficulty)
        case .tossExecution:
            return .score(scoresheet.tossExecution)
        case .buildingCreativity:
            return .score(scoresheet.buildingCreativity)
        case .buildingShowmanship:
            return .score(scoresheet.buildingShowmanship)
        case .standingDifficulty:
            return .score(scoresheet.standingDifficulty)
        case .standingExecution:
            return .score(scoresheet.standingExecution)
        case .standingDrivers:
            return .score(scoresheet.standingDrivers)
        case .runningDifficulty:
            return .score(scoresheet.runningDifficulty)
        case .runningExecution:
            return .score(scoresheet.runningExecution)
        case .runningDrivers:
            return .score(scoresheet.runningDrivers)
        case .runningDriverMaxPart:
            return .score(scoresheet.runningDriverMaxPart)
        case .jumpsDifficulty:
            return .score(scoresheet.jumpsDifficulty)
        case .jumpsExecution:
            return .score(scoresheet.jumpsExecution)
        case .tumblingCreativity:
            return .score(scoresheet.tumblingCreativity)
        case .tumblingShowmanship:
            return .score(scoresheet.tumblingShowmanship)
        case .danceDifficulty:
            return .score(scoresheet.danceDifficulty)
        case .danceExecution:
            return .score(scoresheet.danceExecution)
        case .formations:
            return .score(scoresheet.formations)
        case .overallCreativity:
            return .score(scoresheet.overallCreativity)
        case .overallShowmanship:
            return .score(scoresheet.overallShowmanship)
        case .athleteFalls:
            return .deduction(scoresheet.athleteFalls)
        case .majorAthleteFalls:
            return .deduction(scoresheet.majorAthleteFalls)
        case .buildingBobbles:
            return .deduction(scoresheet.buildingBobbles)
        case .buildingFalls:
            return .deduction(scoresheet.buildingFalls)
        case .majorBuildingFalls:
            return .deduction(scoresheet.majorBuildingFalls)
        case .boundaryViolations:
            return .deduction(scoresheet.boundaryViolations)
        case .timeLimitViolations:
            return .deduction(scoresheet.timeLimitViolations)
        }
    }

    func manualValue(from input: String, teamLevel: String?) -> ScoresheetFieldValue? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if isIntegerField {
            guard let value = Int(trimmed), value >= 0 else { return nil }
            return .deduction(value)
        }

        if isTossField && !ScoringRules.isTossAllowed(forLevel: teamLevel) {
            return .score(0)
        }

        guard let range = scoreRange, let rawValue = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }

        let clampedValue = min(max(rawValue, range.min), range.max)
        let stepCount = ((clampedValue - range.min) / range.step).rounded()
        let snapped = (range.min + (stepCount * range.step)).roundedToStepPrecision(range.step)
        guard snapped >= range.min - 0.0001 && snapped <= range.max + 0.0001 else { return nil }
        return .score(snapped)
    }

    func apply(_ value: ScoresheetFieldValue, to scoresheet: Scoresheet) {
        switch (self, value) {
        case (.stuntDifficulty, .score(let value)):
            scoresheet.stuntDifficulty = value
        case (.stuntExecution, .score(let value)):
            scoresheet.stuntExecution = value
        case (.stuntDriverDegree, .score(let value)):
            scoresheet.stuntDriverDegree = value
        case (.stuntDriverMaxPart, .score(let value)):
            scoresheet.stuntDriverMaxPart = value
        case (.pyramidDifficulty, .score(let value)):
            scoresheet.pyramidDifficulty = value
        case (.pyramidExecution, .score(let value)):
            scoresheet.pyramidExecution = value
        case (.tossDifficulty, .score(let value)):
            scoresheet.tossDifficulty = value
        case (.tossExecution, .score(let value)):
            scoresheet.tossExecution = value
        case (.buildingCreativity, .score(let value)):
            scoresheet.buildingCreativity = value
        case (.buildingShowmanship, .score(let value)):
            scoresheet.buildingShowmanship = value
        case (.standingDifficulty, .score(let value)):
            scoresheet.standingDifficulty = value
        case (.standingExecution, .score(let value)):
            scoresheet.standingExecution = value
        case (.standingDrivers, .score(let value)):
            scoresheet.standingDrivers = value
        case (.runningDifficulty, .score(let value)):
            scoresheet.runningDifficulty = value
        case (.runningExecution, .score(let value)):
            scoresheet.runningExecution = value
        case (.runningDrivers, .score(let value)):
            scoresheet.runningDrivers = value
        case (.runningDriverMaxPart, .score(let value)):
            scoresheet.runningDriverMaxPart = value
        case (.jumpsDifficulty, .score(let value)):
            scoresheet.jumpsDifficulty = value
        case (.jumpsExecution, .score(let value)):
            scoresheet.jumpsExecution = value
        case (.tumblingCreativity, .score(let value)):
            scoresheet.tumblingCreativity = value
        case (.tumblingShowmanship, .score(let value)):
            scoresheet.tumblingShowmanship = value
        case (.danceDifficulty, .score(let value)):
            scoresheet.danceDifficulty = value
        case (.danceExecution, .score(let value)):
            scoresheet.danceExecution = value
        case (.formations, .score(let value)):
            scoresheet.formations = value
        case (.overallCreativity, .score(let value)):
            scoresheet.overallCreativity = value
        case (.overallShowmanship, .score(let value)):
            scoresheet.overallShowmanship = value
        case (.athleteFalls, .deduction(let value)):
            scoresheet.athleteFalls = value
        case (.majorAthleteFalls, .deduction(let value)):
            scoresheet.majorAthleteFalls = value
        case (.buildingBobbles, .deduction(let value)):
            scoresheet.buildingBobbles = value
        case (.buildingFalls, .deduction(let value)):
            scoresheet.buildingFalls = value
        case (.majorBuildingFalls, .deduction(let value)):
            scoresheet.majorBuildingFalls = value
        case (.boundaryViolations, .deduction(let value)):
            scoresheet.boundaryViolations = value
        case (.timeLimitViolations, .deduction(let value)):
            scoresheet.timeLimitViolations = value
        default:
            break
        }
    }
}

struct ParsedField: Identifiable, Equatable, Sendable {
    let fieldID: ScoresheetFieldID
    var rawText: String
    var candidateValue: ScoresheetFieldValue?
    var confidence: Double
    var status: ParsedFieldStatus
    var sourceRect: CGRect?
    var failureReason: String?

    var id: ScoresheetFieldID { fieldID }

    var requiresReview: Bool {
        status == .needsReview
    }
}

struct ScoresheetImportContext: Equatable, Sendable {
    let teamID: UUID?
    let competitionID: UUID?
    let round: String
    let teamLevel: String?
}

enum ScoresheetImportInput: Sendable {
    case image(
        data: Data,
        sourceType: ScoresheetImportSourceType,
        suggestedFileName: String,
        utType: UTType?
    )
    case pdf(url: URL)
}

struct ScoresheetImportDraft: Identifiable, Equatable, Sendable {
    let id: UUID
    let teamID: UUID?
    let competitionID: UUID?
    let round: String
    let teamLevel: String?
    let sourceType: ScoresheetImportSourceType
    let sourceRelativePath: String
    let previewRelativePath: String
    let sourceDisplayName: String
    let parserVersion: String
    let createdAt: Date
    var parsedFields: [ScoresheetFieldID: ParsedField]

    var unresolvedFieldIDs: [ScoresheetFieldID] {
        ScoresheetFieldID.allCases.filter { parsedFields[$0]?.requiresReview == true }
    }

    var hasUnresolvedFields: Bool {
        !unresolvedFieldIDs.isEmpty
    }

    func parsedField(for fieldID: ScoresheetFieldID) -> ParsedField {
        parsedFields[fieldID]
            ?? ParsedField(
                fieldID: fieldID,
                rawText: "",
                candidateValue: nil,
                confidence: 0,
                status: .needsReview,
                sourceRect: nil,
                failureReason: "Field was not parsed"
            )
    }

    mutating func confirmSuggestedValue(for fieldID: ScoresheetFieldID) {
        guard var field = parsedFields[fieldID], field.candidateValue != nil else { return }
        field.status = .confirmed
        field.failureReason = nil
        parsedFields[fieldID] = field
    }

    mutating func confirmManualValue(_ value: ScoresheetFieldValue, for fieldID: ScoresheetFieldID) {
        var field = parsedField(for: fieldID)
        field.candidateValue = value
        field.rawText = value.displayString
        field.status = .confirmed
        field.failureReason = nil
        field.confidence = max(field.confidence, 1)
        parsedFields[fieldID] = field
    }
}

protocol ScoresheetImporting {
    func importScoresheet(from input: ScoresheetImportInput, context: ScoresheetImportContext) async
        throws -> ScoresheetImportDraft
}

enum ScoresheetImportError: LocalizedError, Equatable, Sendable {
    case teamSelectionRequired
    case fileLoadFailed
    case imageDecodeFailed
    case previewGenerationFailed
    case unsupportedScanPageCount(Int)
    case unsupportedPDFPageCount(Int)
    case noTextFound
    case storageFailure

    var errorDescription: String? {
        switch self {
        case .teamSelectionRequired:
            return "Select a team before importing a scoresheet."
        case .fileLoadFailed:
            return "The selected file could not be loaded."
        case .imageDecodeFailed:
            return "The image could not be decoded."
        case .previewGenerationFailed:
            return "A preview image could not be generated."
        case .unsupportedScanPageCount(let count):
            return "V1 only supports a single scanned page. This scan has \(count) pages."
        case .unsupportedPDFPageCount(let count):
            return "V1 only supports single-page PDFs. This file has \(count) pages."
        case .noTextFound:
            return "No readable scoresheet text was found."
        case .storageFailure:
            return "The imported scoresheet could not be saved locally."
        }
    }
}

private extension Double {
    func roundedToStepPrecision(_ step: Double) -> Double {
        let decimals: Int
        switch step {
        case 0.01:
            decimals = 2
        case 0.1, 0.5:
            decimals = 1
        default:
            decimals = 2
        }

        let multiplier = pow(10.0, Double(decimals))
        return (self * multiplier).rounded() / multiplier
    }
}
