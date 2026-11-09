# -*- coding: utf-8 -*-
from collections import deque
from time import time

# ── 플랭크 '정상 자세 유지 시간' 판정 ──
GOOD_CORE_MIN_WEIGHT = 2    # 가중치 2 이상 항목(목~골반 / 엉덩이 높이 / 다리 일직선)이 전부 통과해야 '정상'
GOOD_WINDOW = 5             # 최근 5프레임 중
GOOD_MIN_RATIO = 0.6        # 60% 이상이 정상이면 정상 유지로 인정 (한두 프레임 튐 무시)
GOOD_MAX_DT = 1.0           # 프레임 간격이 이보다 길면(끊김) 1초까지만 인정


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

        # 반복 운동: 실시간 반복 횟수 (ExerciseEvaluator.rep_count 를 main 에서 매 프레임 복사)
        self.rep_count = 0

        # 플랭크: 자세를 잡고 버틴 시간 / 그중 정상 자세로 버틴 시간
        self.hold_seconds = 0.0
        self._last_hold_t = None
        self.good_seconds = 0.0
        self._good_hist = deque(maxlen=GOOD_WINDOW)
        self._last_t = None

    def mark_person_seen(self):
        self.miss_streak = 0

    def mark_person_missed(self):
        self.miss_streak += 1
        self._last_t = None          # 끊긴 구간은 유지 시간에 넣지 않음
        self._last_hold_t = None
        self._good_hist.clear()

    def record_frame(self, results: list, phase: str, score: int):
        now = time()
        # carry=True 는 '직전 반복 결과를 화면에 다시 띄운 것'이라 통계에서 제외 (반복당 항목이 중복 집계되지 않게)
        scored = [r for r in results if not r.get("carry")]
        if scored:
            self.result_history.append(scored)
            self.score_history.append(score)
        self.phase_history.append((phase, now))

        if self.exercise_name == "플랭크":
            self._update_hold(phase, now)
            self._update_good_hold(scored, now)

    def _update_hold(self, phase: str, now: float):
        """자세를 잡고 운동 중(down)인 시간 누적. 프레임 간격이 너무 길면(끊김) 1초까지만 인정."""
        if phase == "down":
            if self._last_hold_t is not None:
                self.hold_seconds += min(now - self._last_hold_t, GOOD_MAX_DT)
            self._last_hold_t = now
        else:
            self._last_hold_t = None

    def live_stats(self) -> dict:
        """프레임마다 앱으로 보내는 실시간 집계. 해당 없는 값은 None."""
        if self.exercise_name == "플랭크":
            return {"rep_count": None,
                    "hold_seconds": round(self.hold_seconds, 1),
                    "good_hold_seconds": round(self.good_seconds, 1)}
        return {"rep_count": self.rep_count, "hold_seconds": None, "good_hold_seconds": None}

    def _update_good_hold(self, results: list, now: float):
        dt = 0.0 if self._last_t is None else min(now - self._last_t, GOOD_MAX_DT)
        self._last_t = now

        core = [r for r in results if r.get("weight", 1) >= GOOD_CORE_MIN_WEIGHT]
        good = bool(core) and all(r["ok"] for r in core)
        self._good_hist.append(good)

        if (dt > 0 and len(self._good_hist) >= 3
                and sum(self._good_hist) / len(self._good_hist) >= GOOD_MIN_RATIO):
            self.good_seconds += dt

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
        good_hold_seconds = None

        if self.exercise_name == "플랭크":
            good_hold_seconds = round(self.good_seconds, 1)
            hold_seconds = round(self.hold_seconds, 1)
        else:
            # 실시간 화면에 보여준 횟수와 같은 값 (ExerciseEvaluator 가 센 것)
            rep_count = self.rep_count

        return {
            "status": "session_summary",
            "exercise": self.exercise_name,
            "avgScore": avg_score,
            "durationMin": max(1, round(duration_sec / 60)),
            "durationSec": round(duration_sec, 1),
            "repCount": rep_count,
            "holdSeconds": hold_seconds,
            "goodHoldSeconds": good_hold_seconds,   # 플랭크만: 정상 자세로 버틴 시간(추정치)
            "itemScores": item_scores,
            "feedbacks": feedbacks,
        }