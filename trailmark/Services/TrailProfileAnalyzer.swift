import SwiftUI
import UIKit

// MARK: - Terrain Type

enum TerrainType: Equatable {
    case climbing, descending, flat

    var color: Color {
        switch self {
        case .climbing: return MilestoneType.montee.color
        case .descending: return MilestoneType.descente.color
        case .flat: return MilestoneType.plat.color
        }
    }

    var uiColor: UIColor {
        UIColor(color)
    }
}

// MARK: - Trail Profile Analyzer

/// Analyzes trail elevation profile to classify terrain segments
enum TrailProfileAnalyzer {

    // MARK: - Configuration

    /// Slope threshold for terrain classification (5%)
    static let slopeThreshold: Double = 0.05

    /// Window size for slope calculation in meters (smooths out micro-variations)
    static let slopeWindowSize: Double = 500

    /// Minimum segment length in meters (removes tiny segments)
    static let minSegmentLength: Double = 200

    /// Window size for instantaneous slope calculation in meters
    static let slopeCalcWindow: Double = 100

    // MARK: - Public API

    /// Classifies terrain type for each track point
    /// - Parameter trackPoints: Array of track points to analyze
    /// - Returns: Array of terrain types, one per track point
    static func classify(trackPoints: [TrackPoint]) -> [TerrainType] {
        guard trackPoints.count >= 2 else { return [] }

        var terrainTypes = [TerrainType](repeating: .flat, count: trackPoints.count)
        let halfWindow = slopeWindowSize / 2

        // First pass: compute raw terrain types based on slope
        for i in 0..<trackPoints.count {
            let currentDistance = trackPoints[i].distance

            // Find window boundaries
            var startIdx = i
            var endIdx = i

            for j in (0..<i).reversed() {
                if currentDistance - trackPoints[j].distance <= halfWindow {
                    startIdx = j
                } else {
                    break
                }
            }

            for j in (i + 1)..<trackPoints.count {
                if trackPoints[j].distance - currentDistance <= halfWindow {
                    endIdx = j
                } else {
                    break
                }
            }

            let distanceDelta = trackPoints[endIdx].distance - trackPoints[startIdx].distance
            guard distanceDelta > 0 else { continue }

            let slope = (trackPoints[endIdx].elevation - trackPoints[startIdx].elevation) / distanceDelta

            if slope > slopeThreshold {
                terrainTypes[i] = .climbing
            } else if slope < -slopeThreshold {
                terrainTypes[i] = .descending
            }
        }

        // Second pass: merge small segments with previous segment
        var i = 0
        while i < trackPoints.count {
            let segmentStart = i
            let segmentType = terrainTypes[i]

            // Find end of this segment
            var segmentEnd = i
            while segmentEnd < trackPoints.count && terrainTypes[segmentEnd] == segmentType {
                segmentEnd += 1
            }

            let segmentLength = trackPoints[min(segmentEnd, trackPoints.count - 1)].distance - trackPoints[segmentStart].distance

            // If segment is too short, merge with previous type
            if segmentLength < minSegmentLength && segmentStart > 0 {
                let prevType = terrainTypes[segmentStart - 1]
                for j in segmentStart..<segmentEnd {
                    terrainTypes[j] = prevType
                }
            }

            i = segmentEnd
        }

        return terrainTypes
    }

    /// Computes instantaneous slope at a given index using a smaller window
    /// - Parameters:
    ///   - index: The track point index
    ///   - trackPoints: Array of track points
    /// - Returns: Slope as a ratio (e.g., 0.08 for 8%)
    static func computeSlope(at index: Int, trackPoints: [TrackPoint]) -> Double {
        guard index > 0, trackPoints.count > 1 else { return 0 }

        let halfWindow = slopeCalcWindow / 2
        let currentDistance = trackPoints[index].distance

        var startIdx = index
        var endIdx = index

        for j in (0..<index).reversed() {
            if currentDistance - trackPoints[j].distance <= halfWindow {
                startIdx = j
            } else {
                break
            }
        }

        for j in (index + 1)..<trackPoints.count {
            if trackPoints[j].distance - currentDistance <= halfWindow {
                endIdx = j
            } else {
                break
            }
        }

        let distanceDelta = trackPoints[endIdx].distance - trackPoints[startIdx].distance
        guard distanceDelta > 0 else { return 0 }

        return (trackPoints[endIdx].elevation - trackPoints[startIdx].elevation) / distanceDelta
    }
}
