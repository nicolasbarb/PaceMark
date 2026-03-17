import Foundation
import StructuredQueries

// MARK: - Trail

@Table("trail")
struct Trail: Hashable, Identifiable, Sendable {
    let id: Int64?
    var name: String
    var createdAt: Double // Unix timestamp
    var distance: Double // meters
    var dPlus: Int // meters

    nonisolated init(
        id: Int64? = nil,
        name: String,
        createdAt: Date = Date(),
        distance: Double,
        dPlus: Int
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt.timeIntervalSince1970
        self.distance = distance
        self.dPlus = dPlus
    }

    // Init with raw timestamp (for database reconstruction)
    nonisolated init(
        id: Int64?,
        name: String,
        createdAtTimestamp: Double,
        distance: Double,
        dPlus: Int
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAtTimestamp
        self.distance = distance
        self.dPlus = dPlus
    }

    nonisolated var createdAtDate: Date {
        Date(timeIntervalSince1970: createdAt)
    }
}

// MARK: - TrackPoint

@Table("trackPoint")
struct TrackPoint: Hashable, Identifiable, Sendable {
    let id: Int64?
    var trailId: Int64
    var index: Int
    var latitude: Double
    var longitude: Double
    var elevation: Double // meters
    var distance: Double // cumulative distance from start, meters

    nonisolated init(
        id: Int64? = nil,
        trailId: Int64 = 0,
        index: Int,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        distance: Double
    ) {
        self.id = id
        self.trailId = trailId
        self.index = index
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.distance = distance
    }
}

// MARK: - MilestoneType

enum MilestoneType: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case montee
    case descente
    case plat
    case ravito
    case danger
    case info
}

// MARK: - SegmentType

enum SegmentType: String, CaseIterable, Sendable {
    case climbing
    case descending
    case flat

    var milestoneType: MilestoneType {
        switch self {
        case .climbing: return .montee
        case .descending: return .descente
        case .flat: return .plat
        }
    }
}

// MARK: - Segment

@Table("segment")
struct Segment: Hashable, Identifiable, Sendable {
    let id: Int64?
    var trailId: Int64
    var type: String
    var startIndex: Int
    var endIndex: Int
    var startDistance: Double
    var endDistance: Double

    nonisolated init(
        id: Int64? = nil,
        trailId: Int64 = 0,
        type: String,
        startIndex: Int,
        endIndex: Int,
        startDistance: Double,
        endDistance: Double
    ) {
        self.id = id
        self.trailId = trailId
        self.type = type
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startDistance = startDistance
        self.endDistance = endDistance
    }

    nonisolated var segmentType: SegmentType {
        SegmentType(rawValue: type) ?? .flat
    }

    nonisolated var distance: Double {
        endDistance - startDistance
    }

    static func computeStats(segment: Segment, trackPoints: [TrackPoint]) -> SegmentStats {
        let start = segment.startIndex
        let end = segment.endIndex
        guard start >= 0, end < trackPoints.count, start < end else {
            return SegmentStats(distance: 0, elevationGain: 0, elevationLoss: 0, averageSlope: 0)
        }

        var gain: Double = 0
        var loss: Double = 0
        for i in start..<end {
            let delta = trackPoints[i + 1].elevation - trackPoints[i].elevation
            if delta > 0 { gain += delta }
            else { loss += Swift.abs(delta) }
        }

        let distance = trackPoints[end].distance - trackPoints[start].distance
        let netElevation = trackPoints[end].elevation - trackPoints[start].elevation
        let slope = distance > 0 ? netElevation / distance : 0

        return SegmentStats(
            distance: distance,
            elevationGain: gain,
            elevationLoss: loss,
            averageSlope: slope
        )
    }

    static func findSegment(containing pointIndex: Int, in segments: [Segment]) -> Segment? {
        segments.first { $0.startIndex <= pointIndex && pointIndex <= $0.endIndex }
    }

    static func overlaps(_ segment: Segment, with existing: [Segment]) -> Bool {
        existing.contains { other in
            if let selfId = segment.id, selfId == other.id { return false }
            return segment.startIndex < other.endIndex && segment.endIndex > other.startIndex
        }
    }
}

// MARK: - SegmentStats

struct SegmentStats: Equatable, Sendable {
    let distance: Double
    let elevationGain: Double
    let elevationLoss: Double
    let averageSlope: Double
}

// MARK: - Milestone

@Table("milestone")
struct Milestone: Hashable, Identifiable, Sendable {
    let id: Int64?
    var trailId: Int64
    var pointIndex: Int
    var latitude: Double
    var longitude: Double
    var elevation: Double
    var distance: Double // cumulative distance
    var type: String // MilestoneType raw value
    var message: String
    var name: String?

    nonisolated init(
        id: Int64? = nil,
        trailId: Int64 = 0,
        pointIndex: Int,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        distance: Double,
        type: MilestoneType,
        message: String,
        name: String? = nil
    ) {
        self.id = id
        self.trailId = trailId
        self.pointIndex = pointIndex
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.distance = distance
        self.type = type.rawValue
        self.message = message
        self.name = name
    }

    nonisolated var milestoneType: MilestoneType {
        MilestoneType(rawValue: type) ?? .info
    }
}

// MARK: - TrailListItem (for list display with milestone count)

struct TrailListItem: Equatable, Identifiable, Sendable {
    let trail: Trail
    let milestoneCount: Int

    var id: Int64? { trail.id }
}

// MARK: - TrailDetail (Aggregated view)

struct TrailDetail: Equatable, Sendable {
    var trail: Trail
    var trackPoints: [TrackPoint]
    var milestones: [Milestone]
    var segments: [Segment]

    nonisolated init(trail: Trail, trackPoints: [TrackPoint], milestones: [Milestone], segments: [Segment] = []) {
        self.trail = trail
        self.trackPoints = trackPoints
        self.milestones = milestones
        self.segments = segments
    }

    nonisolated var distKm: String {
        String(format: "%.1f", trail.distance / 1000)
    }

    nonisolated var milestoneCount: Int {
        milestones.count
    }
}
