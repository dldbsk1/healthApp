import Foundation

// MARK: - Live Pose

enum PoseStatus: String, Decodable {
    case noPerson = "no_person"
    case collecting
    case analyzing
    case uncertain
    case error
}

struct PoseCheckItem: Decodable, Identifiable {
    var id: String { label }

    let label: String
    let ok: Bool
    let desc: String
    let weight: Int?
}

struct PoseCheckResult: Decodable, Identifiable {
    var id: String { label }

    let label: String
    let ok: Bool
    let desc: String
    let weight: Int?
}

struct LiveAnalysisMessage: Decodable {
    let status: PoseStatus
    let exercise: String?
    let phase: String?
    let phaseLabel: String?
    let score: Int?
    let results: [PoseCheckItem]?
    let keypoints: [[Double]]?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case exercise
        case phase
        case results
        case keypoints
        case message
        case phaseLabel = "phase_label"
        case score
    }

    /// 한 필드의 타입이 어긋나도(예: score가 87.5) 메시지 전체가 버려져
    /// 스켈레톤이 안 그려지는 일이 없도록 필드별로 따로 디코딩한다.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // 모르는 status 문자열이 와도 실패하지 않도록
        let rawStatus = (try? c.decode(String.self, forKey: .status)) ?? ""
        status = PoseStatus(rawValue: rawStatus) ?? .analyzing

        exercise = try? c.decodeIfPresent(String.self, forKey: .exercise)
        phase = try? c.decodeIfPresent(String.self, forKey: .phase)
        phaseLabel = try? c.decodeIfPresent(String.self, forKey: .phaseLabel)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        results = try? c.decodeIfPresent([PoseCheckItem].self, forKey: .results)
        keypoints = try? c.decodeIfPresent([[Double]].self, forKey: .keypoints)

        if let i = try? c.decodeIfPresent(Int.self, forKey: .score) {
            score = i
        } else if let d = try? c.decodeIfPresent(Double.self, forKey: .score) {
            score = Int(d.rounded())
        } else {
            score = nil
        }
    }
}


// MARK: - Exercise Kind

enum ExerciseKind {

    /// 횟수가 아니라 "버틴 시간"을 기록하는 운동인지
    static func isHold(_ name: String?) -> Bool {
        guard let name = name?.lowercased() else {
            return false
        }
        return name.contains("플랭크") || name.contains("plank")
    }
}


// MARK: - Exercise Analysis

struct ExerciseItemScore: Decodable, Identifiable {
    let uid = UUID()
    var id: UUID { uid }

    let label: String
    let score: Int
    let weight: Int

    /// 누적 화면에서 어떤 운동의 항목인지 표시하기 위한 값 (서버 응답에는 없음)
    var exerciseName: String? = nil

    enum CodingKeys: String, CodingKey {
        case label, score, weight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        score = Int((c.flexDouble(.score) ?? 0).rounded())
        weight = Int((c.flexDouble(.weight) ?? 0).rounded())
    }
}

struct ExerciseFeedback: Decodable, Identifiable {
    var id: String { title }

    let title: String
    let text: String
}


// MARK: - Exercise Result Data

struct ExerciseResultData: Identifiable {

    /// 한 번의 운동 세션을 구분하는 id (서버 칼로리가 늦게 와도 해당 세션을 찾아 갱신)
    var id = UUID()

    /// totalCalories가 Spring Boot의 caloriesBurned로 확정된 값인지
    var caloriesFromServer = false

    let exerciseName: String
    let totalTime: String
    var totalCalories: Double
    let averageAccuracy: Int
    let setCount: Int
    let repsPerSet: Int

    var setAnalyses: [SetAnalysis]
    var feedbacks: [PostureFeedback]
    var itemScores: [ExerciseItemScore]

    init(
        exerciseName: String = "스쿼트",
        totalTime: String = "00:45:28",
        totalCalories: Double = 238.0,
        averageAccuracy: Int = 92,
        setCount: Int = 3,
        repsPerSet: Int = 15,
        setAnalyses: [SetAnalysis]? = nil,
        feedbacks: [PostureFeedback]? = nil,
        itemScores: [ExerciseItemScore] = []
    ) {
        self.itemScores = itemScores
        self.exerciseName = exerciseName
        self.totalTime = totalTime
        self.totalCalories = totalCalories
        self.averageAccuracy = averageAccuracy
        self.setCount = setCount
        self.repsPerSet = repsPerSet

        if let sets = setAnalyses {
            self.setAnalyses = sets
        } else {
            let perSetCal =
                totalCalories / Double(max(setCount, 1))

            self.setAnalyses = (1...setCount).map { setNum in
                SetAnalysis(
                    exerciseName: exerciseName,
                    category: .strength,
                    setNumber: setNum,
                    weight: nil,
                    completed: repsPerSet,
                    total: repsPerSet,
                    accuracy: averageAccuracy,
                    calories: perSetCal
                )
            }
        }

        self.feedbacks = feedbacks ?? [
            PostureFeedback(
                exerciseName: exerciseName,
                imageName: "figure.strengthtraining.functional",
                title: "자세 양호",
                description: "전반적으로 안정적인 동작을 유지했습니다."
            )
        ]
    }
}


// MARK: - Exercise Session Summary
// pose-server에서 운동 종료 시 내려오는 데이터

struct ExerciseSessionSummary: Decodable {

    let status: String
    let exercise: String?
    let avgScore: Double
    let durationMin: Int
    let durationSec: Double
    let repCount: Int?
    let holdSeconds: Double?
    let itemScores: [ExerciseItemScore]
    let feedbacks: [ExerciseFeedback]

    enum CodingKeys: String, CodingKey {
        case status, exercise, avgScore, durationMin, durationSec
        case repCount, holdSeconds, itemScores, feedbacks
    }

    /// 숫자 타입(정수/실수/문자열)이나 일부 누락 때문에 summary 전체가
    /// 버려져서 결과 화면이 전부 0으로 나오는 일이 없도록 필드별로 관대하게 디코딩.
    /// (JSONDecoder에 .convertFromSnakeCase를 쓰면 avg_score / avgScore 둘 다 받는다)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        status = (try? c.decode(String.self, forKey: .status)) ?? "session_summary"
        exercise = try? c.decodeIfPresent(String.self, forKey: .exercise)
        avgScore = c.flexDouble(.avgScore) ?? 0

        let sec = c.flexDouble(.durationSec) ?? 0
        durationSec = sec
        durationMin = Int((c.flexDouble(.durationMin) ?? (sec / 60)).rounded())

        repCount = c.flexDouble(.repCount).map { Int($0.rounded()) }
        holdSeconds = c.flexDouble(.holdSeconds)

        itemScores = (try? c.decodeIfPresent([ExerciseItemScore].self, forKey: .itemScores)) ?? []
        feedbacks = (try? c.decodeIfPresent([ExerciseFeedback].self, forKey: .feedbacks)) ?? []
    }

    /// 운동 총 시간(초).
    /// ExerciseLiveView가 durationSec을 "총 경과 초"로 쓰고 있으므로 그 기준으로 통일.
    /// (예전 durationMin*60 + durationSec 는 분이 이중으로 더해져 시간이 부풀려졌음)
    var totalSeconds: Double {
        durationSec > 0 ? durationSec : Double(durationMin * 60)
    }

    /// 플랭크 같은 유지형 운동인지.
    /// 서버가 hold_seconds를 안 보내거나 0으로 보내는 경우가 있어서 운동 이름으로도 판단한다.
    var isHold: Bool {
        (holdSeconds ?? 0) > 0 || ExerciseKind.isHold(exercise)
    }

    /// 유지형 운동에서 화면에 보여줄 "버틴 초".
    /// hold_seconds가 있으면 그 값, 없으면 총 운동 시간을 사용.
    var holdDisplaySeconds: Double {
        if let hold = holdSeconds, hold > 0 {
            return hold
        }
        return totalSeconds
    }

    var formattedDuration: String {
        let totalSec = Int(totalSeconds)

        let min = totalSec / 60
        let sec = totalSec % 60

        return String(
            format: "%02d:%02d",
            min,
            sec
        )
    }

    /*
     serverCalories : Spring Boot가 계산해 준 caloriesBurned (없으면 로컬 추정값 사용)
     displayName    : 화면에 표시할 운동 이름 (UI에서 고른 이름, 예: "플랭크")
     isHold         : 유지형 운동 여부를 호출한 쪽에서 확정해서 넘길 때
     */
    func toResultData(
        serverCalories: Double? = nil,
        displayName: String? = nil,
        isHold forcedHold: Bool? = nil
    ) -> ExerciseResultData {

        let name = displayName ?? self.exercise ?? "운동"
        let hold = forcedHold ?? self.isHold
        let reps = self.repCount ?? 0
        let holdSec = Int(holdDisplaySeconds)

        let calcCalories = serverCalories
            ?? (Double(reps * 2) + (totalSeconds * 0.1))

        let customFeedbacks: [PostureFeedback] =
            self.feedbacks.map {
                PostureFeedback(
                    exerciseName: name,
                    imageName: "figure.strengthtraining.functional",
                    title: $0.title,
                    description: $0.text
                )
            }

        let setAnalysis = SetAnalysis(
            exerciseName: name,
            category: hold ? .cardio : .strength,
            setNumber: 1,
            weight: nil,
            completed: hold ? holdSec : reps,
            total: hold ? holdSec : (reps > 0 ? reps : 15),
            durationString: self.formattedDuration,
            accuracy: Int(self.avgScore),
            calories: calcCalories
        )

        var result = ExerciseResultData(
            exerciseName: name,
            totalTime: self.formattedDuration,
            totalCalories: calcCalories,
            averageAccuracy: Int(self.avgScore),
            setCount: 1,
            repsPerSet: hold ? holdSec : reps,
            setAnalyses: [setAnalysis],
            feedbacks: customFeedbacks,
            itemScores: self.itemScores
        )

        result.caloriesFromServer = (serverCalories != nil)

        return result
    }
}


// MARK: - 관대한 숫자 디코딩 헬퍼

extension KeyedDecodingContainer {

    /// 정수 / 실수 / "87.5" 같은 문자열 모두 Double로 읽는다. 없으면 nil.
    func flexDouble(_ key: Key) -> Double? {
        if let d = try? decodeIfPresent(Double.self, forKey: key) {
            return d
        }
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            return Double(s)
        }
        return nil
    }
}


// MARK: - Spring Boot API Response

struct StatusOnly: Decodable {
    let status: String
}


// 서버가 ApiResponse<T> 형태로 감싸서 반환하는 경우
//
// {
//     "success": true,
//     "message": "...",
//     "data": {
//         "exerciseLogId": 1,
//         ...
//     }
// }

struct BackendApiResponse<T: Decodable>: Decodable {
    let data: T
}


// MARK: - Exercise Log Response

struct ExerciseLogResponse: Decodable {

    let exerciseLogId: Int?
    let exerciseName: String?

    let durationMin: Int?
    let sets: Int?
    let reps: Int?

    let caloriesBurned: Double?

    let score: Double?
    let feedback: String?

    let exercisedAt: String?
    let createdAt: String?
}


// MARK: - Exercise Log Create Request

struct ExerciseLogCreateRequest: Encodable {

    let exerciseName: String
    let durationMin: Int

    var sets: Int?
    var reps: Int?
    var caloriesBurned: Int?
    var score: Double?
    var feedback: String?

    let exercisedAt: String
}
