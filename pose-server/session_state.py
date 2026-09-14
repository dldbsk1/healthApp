# -*- coding: utf-8 -*-
from time import time


class ExerciseSession:
    """
    운동 종류를 사용자가 미리 선택해서 들어오는 구조 (LSTM 자동분류 없음).
    exercise_name 은 연결 시점에 확정되어 세션 내내 고정된다.
    """

    def __init__(self, exercise_name: str):
        self.exercise_name = exercise_name

        self.frame_count = 0
        self.miss_streak = 0   # 사람이 연속으로 안 잡힌 프레임 수

        self.result_history: list[list[dict]] = []
        self.phase_history: list[tuple] = []   # (phase, timestamp)
        self.score_history: list[int] = []

        self.started_at = time()

    def mark_person_seen(self):
        self.miss_streak = 0

    def mark_person_missed(self):
        self.miss_streak += 1

    def record_frame(self, results: list, phase: str, score: int):
        now = time()
        if results:
            self.result_history.append(results)
            self.score_history.append(score)
        self.phase_history.append((phase, now))

    @staticmethod
    def _most_common(items: list):
        if not items:
            return None
        counts = {}
        for item in items:
            counts[item] = counts.get(item, 0) + 1
        return max(counts, key=counts.get)

    def compute_summary(self) -> dict:
        duration_sec = time() - self.started_at

        item_ok: dict[str, list[int]] = {}
        item_weight: dict[str, int] = {}
        item_bad_desc: dict[str, list[str]] = {}

        for frame_results in self.result_history:
            for r in frame_results:
                item_ok.setdefault(r["label"], []).append(1 if r["ok"] else 0)
                item_weight[r["label"]] = r.get("weight", 1)
                if not r["ok"]:
                    item_bad_desc.setdefault(r["label"], []).append(r["desc"])

        item_scores = []
        for label, oks in item_ok.items():
            ratio = sum(oks) / len(oks)
            item_scores.append({
                "label": label,
                "score": int(ratio * 100),
                "weight": item_weight.get(label, 1),
            })
        item_scores.sort(key=lambda x: x["score"])

        if item_scores:
            total_weight = sum(s["weight"] for s in item_scores)
            avg_score = int(sum(s["score"] * s["weight"] for s in item_scores) / total_weight) \
                if total_weight else 0
        else:
            avg_score = 0

        feedbacks = []
        for s in item_scores:
            label, score = s["label"], s["score"]
            common_desc = self._most_common(item_bad_desc.get(label, []))
            if score >= 80:
                title, text = "✅ " + label, "대부분 잘 수행되고 있어요. 지금처럼 유지하세요!"
            elif score >= 50:
                title, text = "⚠️ " + label, "조금만 더 다듬으면 될 것 같아요."
                if common_desc:
                    text += " " + common_desc.split("(")[0].strip()
            else:
                title, text = "❌ " + label, "이 부분은 교정이 필요해요."
                if common_desc:
                    text += " " + common_desc.split("(")[0].strip()
            feedbacks.append({"title": title, "text": text})

        rep_count = None
        hold_seconds = None

        if self.exercise_name == "플랭크":
            hold_seconds = 0.0
            for i in range(1, len(self.phase_history)):
                prev_phase, prev_t = self.phase_history[i - 1]
                cur_phase, cur_t = self.phase_history[i]
                if prev_phase == "down" and cur_phase == "down":
                    hold_seconds += (cur_t - prev_t)
            hold_seconds = round(hold_seconds, 1)
        else:
            # "none"(인식 실패)은 제외하고, 실제 판독된 것만 시간순으로 모음
            valid_phases = [p for p, _ in self.phase_history if p != "none"]

            # 프레임 단위 흔들림(노이즈) 제거: 최근 SMOOTH_WINDOW개 판독값의 다수결로 스무딩
            SMOOTH_WINDOW = 2
            smoothed = []
            for i in range(len(valid_phases)):
                lo = max(0, i - SMOOTH_WINDOW + 1)
                window_vals = valid_phases[lo:i + 1]
                majority = max(set(window_vals), key=window_vals.count)
                smoothed.append(majority)

            rep_count = 0
            stable_phase = "up"
            for phase in smoothed:
                if phase != stable_phase:
                    if stable_phase == "up" and phase == "down":
                        rep_count += 1
                    stable_phase = phase

        return {
            "status": "session_summary",
            "exercise": self.exercise_name,
            "avgScore": avg_score,
            "durationMin": max(1, round(duration_sec / 60)),
            "durationSec": round(duration_sec, 1),
            "repCount": rep_count,
            "holdSeconds": hold_seconds,
            "itemScores": item_scores,
            "feedbacks": feedbacks,
        }