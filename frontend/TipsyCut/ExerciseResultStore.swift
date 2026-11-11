//
//  ExerciseResultStore.swift
//  TipsyCut
//
//  운동 세션들을 누적해서 보관한다.
//  예) 런지 → 레그레이즈 순서로 운동하면 sessions에 2개가 쌓이고,
//      분석 화면은 accumulatedResultData(두 운동 합산)를 보여준다.
//

import Foundation
import Combine

final class ExerciseResultStore: ObservableObject {

    static let shared = ExerciseResultStore()

    /// 오늘 끝낸 운동 세션들 (오래된 순)
    @Published private(set) var sessions: [ExerciseResultData] = []

    /// 사용자가 "운동 기록 추가"로 직접 입력한 운동 (AI 세션과 별도로 보관)
    @Published private(set) var manualSets: [SetAnalysis] = []

    /// 분석 화면으로 보여줄 기록이 하나라도 있는지 (AI 세션 또는 직접 추가)
    var hasAnyRecord: Bool {
        !sessions.isEmpty || !manualSets.isEmpty
    }

    private var currentDay = Calendar.current.startOfDay(for: Date())

    // MARK: - 오늘 운동 소비 칼로리 (홈 화면 링)

    /// 오늘 소비한 총 칼로리.
    /// 세션별 칼로리는 Spring Boot의 caloriesBurned가 도착하면 서버 값으로 교체되고,
    /// 도착 전에는 로컬 추정값이 들어간다. 앱을 껐다 켜면 0부터 다시 시작한다.
    @Published private(set) var todayBurnedCalories: Double = 0

    /// 이전 실행에서 이어받는 값 (앱을 껐다 켜면 0부터 다시 시작하므로 항상 0)
    private var baselineBurned: Double = 0

    private init() {
        // 예전 버전이 저장해 둔 값이 남아 있으면 정리
        UserDefaults.standard.removeObject(forKey: "exercise.burned.total")
        UserDefaults.standard.removeObject(forKey: "exercise.burned.day")
    }

    /// 홈 화면이 나타날 때 호출 → 날짜가 바뀌었으면 0으로 초기화
    func refreshForToday() {
        onMain {
            self.resetIfNewDay()
            self.recomputeBurned()
        }
    }

    private func recomputeBurned() {
        var sessionTotal: Double = 0
        for session in sessions {
            sessionTotal += session.totalCalories
        }

        var manualTotal: Double = 0
        for set in manualSets {
            manualTotal += set.calories
        }

        let total: Double = baselineBurned + sessionTotal + manualTotal

        todayBurnedCalories = total
    }

    // MARK: - 조회

    /// 가장 최근 세션
    var latestResultData: ExerciseResultData? {
        sessions.last
    }

    /// 분석 화면에 넘길 누적 결과 (세션이 없으면 nil)
    var accumulatedResultData: ExerciseResultData? {
        sessions.isEmpty
        ? nil
        : ExerciseResultData.merged(from: sessions)
    }

    func session(id: UUID) -> ExerciseResultData? {
        sessions.first { $0.id == id }
    }

    // MARK: - 변경 (항상 메인 스레드)

    /// 세션 하나를 누적에 추가
    func add(_ resultData: ExerciseResultData) {
        onMain {
            self.resetIfNewDay()
            self.sessions.append(resultData)
            self.recomputeBurned()
        }
    }

    /// 직접 입력한 운동 하나를 추가 → 분석 화면 + 홈 운동 링에 바로 반영
    func addManual(_ set: SetAnalysis) {
        onMain {
            self.resetIfNewDay()

            var newSet = set
            var existingCount: Int = self.manualSets.count
            for session in self.sessions {
                existingCount += session.setAnalyses.count
            }
            newSet.setNumber = existingCount + 1

            self.manualSets.append(newSet)
            self.recomputeBurned()
        }
    }

    /// Spring Boot가 계산한 caloriesBurned가 도착하면 해당 세션의 칼로리를 확정 값으로 교체
    func updateCalories(sessionID: UUID, calories: Double) {
        onMain {
            guard let index = self.sessions.firstIndex(where: { $0.id == sessionID }) else {
                return
            }

            var session = self.sessions[index]

            session.totalCalories = calories
            session.caloriesFromServer = true

            // 세트별 칼로리도 서버 값으로 맞춘다 (세션당 세트는 1개)
            for i in session.setAnalyses.indices {
                session.setAnalyses[i].calories =
                    calories / Double(max(session.setAnalyses.count, 1))
            }

            self.sessions[index] = session
            self.recomputeBurned()
        }
    }

    /// 누적 기록 전체 삭제
    func clear() {
        onMain {
            self.sessions = []
            self.manualSets = []
            self.baselineBurned = 0
            self.recomputeBurned()
        }
    }

    // MARK: - Helpers

    /// 날짜가 바뀌면 어제 기록은 비우고 새로 시작
    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())

        if today != currentDay {
            currentDay = today
            sessions = []
            manualSets = []
            baselineBurned = 0
        }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}


// MARK: - 세션 합치기

extension ExerciseResultData {

    static func merged(from sessions: [ExerciseResultData]) -> ExerciseResultData {

        var setCounter: [String: Int] = [:]

        var sets: [SetAnalysis] = []
        var feedbacks: [PostureFeedback] = []
        var scores: [ExerciseItemScore] = []
        var names: [String] = []

        for session in sessions {

            if !names.contains(session.exerciseName) {
                names.append(session.exerciseName)
            }

            // 같은 운동을 또 하면 2세트, 3세트로 번호가 이어진다
            for var set in session.setAnalyses {

                let next = (setCounter[set.exerciseName] ?? 0) + 1
                setCounter[set.exerciseName] = next

                set.setNumber = next
                set.sessionID = session.id

                sets.append(set)
            }

            feedbacks += session.feedbacks

            scores += session.itemScores.map {
                var item = $0
                item.exerciseName = session.exerciseName
                return item
            }
        }

        let totalSecs = sets
            .compactMap { $0.totalSeconds }
            .reduce(0, +)

        let totalTime = String(
            format: "%02d:%02d",
            totalSecs / 60,
            totalSecs % 60
        )

        let totalCalories = sessions
            .map { $0.totalCalories }
            .reduce(0, +)

        let averageAccuracy = sessions.isEmpty
            ? 0
            : Int(
                (
                    Double(sessions.map { $0.averageAccuracy }.reduce(0, +))
                    / Double(sessions.count)
                ).rounded()
            )

        var merged = ExerciseResultData(
            exerciseName: names.joined(separator: " · "),
            totalTime: totalTime,
            totalCalories: totalCalories,
            averageAccuracy: averageAccuracy,
            setCount: sets.count,
            repsPerSet: sessions.last?.repsPerSet ?? 0,
            setAnalyses: sets,
            feedbacks: feedbacks,
            itemScores: scores
        )

        merged.caloriesFromServer =
            sessions.allSatisfy { $0.caloriesFromServer }

        return merged
    }
}
