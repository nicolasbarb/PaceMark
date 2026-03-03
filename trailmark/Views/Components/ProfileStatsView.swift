import SwiftUI

// MARK: - Pre-computed Profile Data

/// Pre-computes all expensive stats once for O(1) lookups during scroll
final class ProfileStatsData {
    let trackPoints: [TrackPoint]

    // Pre-computed arrays (one value per track point)
    let cumulativeDPlus: [Int]
    let cumulativeDMinus: [Int]
    let slopePercent: [Int]
    let terrainTypes: [TerrainType]
    let segmentIndices: [Int] // Maps each point to its segment index
    let segments: [SegmentData]

    // Settings
    private let slopeThreshold: Double = 0.05
    private let slopeWindowSize: Double = 500
    private let minSegmentLength: Double = 200
    private let slopeCalcWindow: Double = 100

    init(trackPoints: [TrackPoint]) {
        self.trackPoints = trackPoints

        // Pre-compute cumulative D+ and D-
        var dPlusArray = [Int]()
        var dMinusArray = [Int]()
        dPlusArray.reserveCapacity(trackPoints.count)
        dMinusArray.reserveCapacity(trackPoints.count)

        var runningDPlus: Double = 0
        var runningDMinus: Double = 0

        for i in 0..<trackPoints.count {
            if i > 0 {
                let delta = trackPoints[i].elevation - trackPoints[i - 1].elevation
                if delta > 0 {
                    runningDPlus += delta
                } else {
                    runningDMinus += abs(delta)
                }
            }
            dPlusArray.append(Int(runningDPlus))
            dMinusArray.append(Int(runningDMinus))
        }

        self.cumulativeDPlus = dPlusArray
        self.cumulativeDMinus = dMinusArray

        // Pre-compute slopes
        var slopes = [Int]()
        slopes.reserveCapacity(trackPoints.count)

        for i in 0..<trackPoints.count {
            let slope = ProfileStatsData.computeSlope(
                at: i,
                trackPoints: trackPoints,
                windowSize: slopeCalcWindow
            )
            slopes.append(Int(slope * 100))
        }
        self.slopePercent = slopes

        // Pre-compute terrain types with smoothing
        let rawTerrainTypes = ProfileStatsData.computeTerrainTypes(
            trackPoints: trackPoints,
            slopeThreshold: slopeThreshold,
            windowSize: slopeWindowSize,
            minSegmentLength: minSegmentLength
        )
        self.terrainTypes = rawTerrainTypes

        // Pre-compute segments
        var segmentList = [SegmentData]()
        var segmentIndexMap = [Int](repeating: 0, count: trackPoints.count)

        var i = 0
        while i < trackPoints.count {
            let segmentStart = i
            let segmentType = rawTerrainTypes[i]

            // Find end of segment
            var segmentEnd = i
            while segmentEnd < trackPoints.count - 1 && rawTerrainTypes[segmentEnd + 1] == segmentType {
                segmentEnd += 1
            }

            let startPoint = trackPoints[segmentStart]
            let endPoint = trackPoints[segmentEnd]
            let distance = endPoint.distance - startPoint.distance
            let elevationChange = endPoint.elevation - startPoint.elevation
            let avgSlope = distance > 0 ? Int(abs(elevationChange / distance) * 100) : 0

            let milestoneType: MilestoneType
            switch segmentType {
            case .climbing: milestoneType = .montee
            case .descending: milestoneType = .descente
            case .flat: milestoneType = .plat
            }

            let segment = SegmentData(
                startIndex: segmentStart,
                endIndex: segmentEnd,
                type: milestoneType,
                distance: distance,
                elevationChange: Int(abs(elevationChange)),
                avgSlopePercent: avgSlope
            )
            segmentList.append(segment)

            // Map all points in this segment to segment index
            let segmentIdx = segmentList.count - 1
            for j in segmentStart...segmentEnd {
                segmentIndexMap[j] = segmentIdx
            }

            i = segmentEnd + 1
        }

        self.segments = segmentList
        self.segmentIndices = segmentIndexMap
    }

    private static func computeSlope(at index: Int, trackPoints: [TrackPoint], windowSize: Double) -> Double {
        guard index > 0, trackPoints.count > 1 else { return 0 }

        let halfWindow = windowSize / 2
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

    private static func computeTerrainTypes(
        trackPoints: [TrackPoint],
        slopeThreshold: Double,
        windowSize: Double,
        minSegmentLength: Double
    ) -> [TerrainType] {
        guard trackPoints.count >= 2 else { return [] }

        var terrainTypes = [TerrainType](repeating: .flat, count: trackPoints.count)
        let halfWindow = windowSize / 2

        // First pass: compute raw terrain types
        for i in 0..<trackPoints.count {
            let currentDistance = trackPoints[i].distance

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

        // Second pass: remove small segments
        var i = 0
        while i < trackPoints.count {
            let segmentStart = i
            let segmentType = terrainTypes[i]

            var segmentEnd = i
            while segmentEnd < trackPoints.count && terrainTypes[segmentEnd] == segmentType {
                segmentEnd += 1
            }

            let segmentLength = trackPoints[min(segmentEnd, trackPoints.count - 1)].distance - trackPoints[segmentStart].distance

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

    struct SegmentData {
        let startIndex: Int
        let endIndex: Int
        let type: MilestoneType
        let distance: Double
        let elevationChange: Int
        let avgSlopePercent: Int
    }
}

enum TerrainType: Equatable {
    case climbing, descending, flat

    var color: Color {
        switch self {
        case .climbing: return MilestoneType.montee.color
        case .descending: return MilestoneType.descente.color
        case .flat: return MilestoneType.plat.color
        }
    }
}

// MARK: - Profile Stats View

struct ProfileStatsView: View {
    let statsData: ProfileStatsData
    let currentIndex: Int

    private var currentPoint: TrackPoint {
        statsData.trackPoints[currentIndex]
    }

    // O(1) lookups from pre-computed data
    private var slopePercent: Int {
        statsData.slopePercent[currentIndex]
    }

    private var terrainType: TerrainType {
        statsData.terrainTypes[currentIndex]
    }

    private var cumulativeDPlus: Int {
        statsData.cumulativeDPlus[currentIndex]
    }

    private var cumulativeDMinus: Int {
        statsData.cumulativeDMinus[currentIndex]
    }

    private var currentSegment: ProfileStatsData.SegmentData? {
        let segmentIdx = statsData.segmentIndices[currentIndex]
        guard segmentIdx < statsData.segments.count else { return nil }
        return statsData.segments[segmentIdx]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Main stats (Altitude, Distance, Slope)
            HStack(spacing: 0) {
                statItem(label: "ALTITUDE", value: "\(Int(currentPoint.elevation))", unit: "m")
                Divider().frame(height: 30)
                statItem(label: "DISTANCE", value: String(format: "%.2f", currentPoint.distance / 1000), unit: "km")
                Divider().frame(height: 30)
                statItem(
                    label: "PENTE",
                    value: "\(slopePercent > 0 ? "+" : "")\(slopePercent)",
                    unit: "%",
                    color: terrainType.color
                )
            }

            // Row 2: D+ / D- cumulated
            HStack(spacing: 0) {
                statItem(label: "D+ FAIT", value: "\(cumulativeDPlus)", unit: "m", color: MilestoneType.montee.color)
                Divider().frame(height: 30)
                statItem(label: "D- FAIT", value: "\(cumulativeDMinus)", unit: "m", color: MilestoneType.descente.color)
            }

            // Row 3: Current segment info
            if let segment = currentSegment {
                segmentInfoView(segment: segment)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Stat Item

    private func statItem(label: String, value: String, unit: String, color: Color = TM.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .foregroundStyle(TM.textMuted)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(TM.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Segment Info View

    private func segmentInfoView(segment: ProfileStatsData.SegmentData) -> some View {
        let startPoint = statsData.trackPoints[segment.startIndex]
        let progressDistance = currentPoint.distance - startPoint.distance
        let progressPercent = segment.distance > 0 ? Int((progressDistance / segment.distance) * 100) : 0

        let description: String
        let distanceKm = segment.distance / 1000
        if distanceKm >= 1 {
            description = "\(segment.elevationChange)m sur \(String(format: "%.1f", distanceKm))km • \(segment.avgSlopePercent)% moy"
        } else {
            description = "\(segment.elevationChange)m sur \(Int(segment.distance))m • \(segment.avgSlopePercent)% moy"
        }

        return HStack(spacing: 8) {
            // Terrain type indicator
            Text(segment.type.icon)
                .font(.title3)

            // Segment description
            VStack(alignment: .leading, spacing: 2) {
                Text(segment.type.label.uppercased())
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(segment.type.color)

                Text(description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(TM.textSecondary)
            }

            Spacer()

            // Progress in segment
            VStack(alignment: .trailing, spacing: 2) {
                Text("PROGRESSION")
                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    .foregroundStyle(TM.textMuted)
                Text("\(progressPercent)%")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(segment.type.color)
            }
        }
        .padding(12)
        .background(segment.type.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(segment.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}
