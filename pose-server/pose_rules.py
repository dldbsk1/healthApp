# -*- coding: utf-8 -*-
"""
규칙 기반 자세 교정 모듈 (v2)

YOLO Pose 17개 관절 인덱스 (0-based):
  0: 코, 1: 왼눈, 2: 오른눈, 3: 왼귀, 4: 오른귀
  5: 왼어깨, 6: 오른어깨
  7: 왼팔꿈치, 8: 오른팔꿈치
  9: 왼손목, 10: 오른손목
  11: 왼엉덩이, 12: 오른엉덩이
  13: 왼무릎, 14: 오른무릎
  15: 왼발목, 16: 오른발목

■ v2에서 달라진 점
  1) 운동별 평가 항목 개편 (플랭크 / 푸쉬업 / 레그레이즈. 런지는 규칙 그대로)
  2) "카메라에 더 가까운 한쪽"만 평가 (NearSideSelector, 프레임마다 좌우가 튀지 않게 고정)
  3) 반복(rep)당 한 번 재는 항목 추가 — 푸쉬업 굽힘 깊이/펴짐, 레그레이즈 들어올린/내린 높이
     (ZoneTracker가 한 반복 동안의 최저/최고 각도를 확정해서 평가)
  4) 화면 비율 보정: 좌표를 w, h 각각으로 나눠 정규화하면 세로 영상에서 각도가 찌그러진다.
     evaluate(..., aspect=w/h)로 x에 w/h를 곱해 실제 각도로 복원.

■ 사용법 (실시간 서버)
    evaluator = ExerciseEvaluator("푸쉬업")          # 세션당 1개 (상태를 가짐)
    results, phase = evaluator.evaluate(norm, conf=conf, aspect=w / h, only_active=False)

  results의 각 항목: {label, ok, desc, weight, [per_rep], [carry]}
    - per_rep=True : 반복당 한 번 재는 항목
    - carry=True   : 직전 반복의 결과를 화면 표시용으로 다시 실어 보낸 것.
                     세션 통계(item_ok)에는 carry=False 인 것만 반영해야 중복 집계가 안 된다.
"""

from collections import deque

import numpy as np


# ══════════════════════════════════════════════════════════
# 기준값 (여기만 고치면 됨)
# ══════════════════════════════════════════════════════════
# 플랭크
PLANK_SPINE_MIN = 160        # 코-어깨-엉덩이 (목~골반 일직선)
PLANK_BODY_MIN = 160         # 어깨-엉덩이-발목 (엉덩이 높이)
PLANK_LEG_MIN = 160          # 엉덩이-무릎-발목 (다리 일직선)
PLANK_ARM_TARGET = 90        # 팔꿈치 각도 목표
PLANK_ARM_TOL = 20

# 푸쉬업(무릎)
PUSHUP_BACK_MIN = 160        # 어깨-엉덩이-무릎 (허리 정렬)
PUSHUP_DEPTH_MAX = 100       # 내려갔을 때 팔꿈치 각도가 이 값 이하여야 통과
PUSHUP_EXTEND_MIN = 160      # 올라왔을 때 팔꿈치 각도가 이 값 이상이어야 통과
PUSHUP_LOW_ENTER = 135       # 이 값 미만이면 "내려간 구간" (화면의 '운동 중/대기' 표시용)
PUSHUP_HIGH_ENTER = 150      # 이 값 초과면 "올라온 구간" (사이는 직전 상태 유지)
PUSHUP_MIN_AMP = 30          # 횟수 인정: 팔꿈치 각도가 이만큼 이상 내려갔다가
PUSHUP_RISE_FRAC = 0.6       #            그 변화량의 이 비율 이상 되돌아오면 1회 (절대 각도 기준 없음)

# 레그레이즈
LEGRAISE_KNEE_MIN = 160      # 엉덩이-무릎-발목 (무릎 펴짐)
LEGRAISE_SPINE_MIN = 160     # 코-어깨-엉덩이
LEGRAISE_TOP_MAX = 110       # 들어올렸을 때 몸통-다리 각도(어깨-엉덩이-발목)가 이 값 이하여야 통과
LEGRAISE_BOTTOM_MIN = 150    # 내렸을 때 몸통-다리 각도가 이 값 이상이어야 통과
LEGRAISE_LOW_ENTER = 130     # 이 값 미만이면 "들어올린 구간"
LEGRAISE_HIGH_ENTER = 145    # 이 값 초과면 "내린 구간"

# 실시간 안내 (레그레이즈·푸쉬업 공통, 점수에는 반영 안 함)
HINT_DROP = 15               # 한 방향으로 이만큼 이상 움직여야 '의미 있는 동작'으로 봄 (대기 중 떨림 무시)
HINT_TURN = 8                # 극값에서 이만큼 반대로 움직이면 '방향 전환'으로 판단
HINT_FRAMES = 15             # 안내를 화면에 유지하는 프레임 수

# 런지 반복 횟수 세기용 (뒷무릎 각도)
LUNGE_REP_LOW = 120          # 이 값 미만이면 "내려간 구간" (_phase_lunge 의 down 기준과 동일)
LUNGE_REP_HIGH = 145         # 이 값 초과면 "다시 선 구간" (사이는 직전 상태 유지)


# ══════════════════════════════════════════════════════════
# 기본 유틸
# ══════════════════════════════════════════════════════════
def get_kp(kpts, idx):
    return kpts[idx]


def calc_angle(a, b, c):
    ba = a - b
    bc = c - b
    cos_a = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    return np.degrees(np.arccos(np.clip(cos_a, -1.0, 1.0)))


def is_visible(kpts, *idxs, threshold=0.1):
    for i in idxs:
        if np.linalg.norm(kpts[i]) < threshold:
            return False
    return True


def midpoint(a, b):
    return (a + b) / 2


def _mid_of(kpts, i, j):
    """두 관절의 중점. 옆모습에서 먼 쪽이 가려져 하나만 잡히면 보이는 쪽 좌표를 쓴다. 둘 다 없으면 None."""
    pts = [kpts[x] for x in (i, j) if is_visible(kpts, x)]
    return np.mean(pts, axis=0) if pts else None


def angle_from_vertical(p_top, p_bottom):
    """p_top→p_bottom 벡터가 수직선과 이루는 각도. 0도=완벽히 수직(똑바로 섬)."""
    dx = p_top[0] - p_bottom[0]
    dy = p_top[1] - p_bottom[1]
    return np.degrees(np.arctan2(abs(dx), abs(dy)))


# ══════════════════════════════════════════════════════════
# 가까운 쪽(near side) 선택
# ══════════════════════════════════════════════════════════
SIDE_IDX = {
    "left":  dict(shoulder=5, elbow=7, wrist=9, hip=11, knee=13, ankle=15),
    "right": dict(shoulder=6, elbow=8, wrist=10, hip=12, knee=14, ankle=16),
}
SIDE_KO = {"left": "왼쪽", "right": "오른쪽"}


def _other(side):
    return "right" if side == "left" else "left"


def _pt(kpts, side, part):
    return kpts[SIDE_IDX[side][part]]


def _side_visible(kpts, side, *parts):
    return is_visible(kpts, *[SIDE_IDX[side][p] for p in parts])


def _default_side(kpts):
    """상태 없이 단독 호출될 때: 보이는 관절이 더 많은 쪽."""
    def n_vis(s):
        return sum(1 for i in SIDE_IDX[s].values() if is_visible(kpts, i))
    return "left" if n_vis("left") >= n_vis("right") else "right"


class NearSideSelector:
    """카메라에 더 가까운 쪽(=더 또렷하게 잡히는 쪽)을 고른다.

    옆모습 촬영에서는 가려진 먼 쪽 팔다리의 YOLO 신뢰도가 낮아지므로,
    좌/우 6개 관절(어깨·팔꿈치·손목·엉덩이·무릎·발목)의 평균 신뢰도로 비교한다.
    conf를 못 받으면 '보이는 관절 수'로 대신한다(이 경우 좌우가 같으면 왼쪽 유지).
    프레임마다 좌우가 바뀌면 각도가 튀므로, 상대가 MARGIN 이상 앞설 때만 바꾼다.
    """
    MARGIN = 0.08

    def __init__(self):
        self.side = None

    @staticmethod
    def _score(kpts, conf, side):
        total = 0.0
        for i in SIDE_IDX[side].values():
            if is_visible(kpts, i):
                total += float(conf[i]) if conf is not None else 1.0
        return total / 6.0

    def update(self, kpts, conf=None):
        sl = self._score(kpts, conf, "left")
        sr = self._score(kpts, conf, "right")
        if self.side is None:
            self.side = "left" if sl >= sr else "right"
        else:
            cur, oth = (sl, sr) if self.side == "left" else (sr, sl)
            if oth > cur + self.MARGIN:
                self.side = _other(self.side)
        return self.side

    def pick(self, kpts, preferred, *parts):
        """선호하는 쪽의 필요 관절이 안 보이면 반대쪽으로 대체. 둘 다 안 보이면 None."""
        for s in (preferred, _other(preferred)):
            if _side_visible(kpts, s, *parts):
                return s
        return None


# ══════════════════════════════════════════════════════════
# 반복(rep)당 극값 추적기
# ══════════════════════════════════════════════════════════
class ZoneTracker:
    """측정값 m(예: 팔꿈치 각도)이 'low 구간'과 'high 구간'을 오갈 때,
    구간이 끝나는 순간 그 구간의 극값(low=최소, high=최대)을 확정해서 돌려준다.

    - low_enter 미만이면 low, high_enter 초과면 high, 사이(데드밴드)는 직전 구간 유지
    - 구간 전환은 confirm 프레임 연속으로 확인될 때만 인정 (한 프레임짜리 튐 무시)
    - 최근 smooth 프레임의 중앙값으로 측정 노이즈를 줄임
    update() → (현재 구간, finished) ; finished = ("low"|"high", 극값) 또는 None
    """

    def __init__(self, low_enter, high_enter, confirm=2, smooth=3):
        self.low_enter = low_enter
        self.high_enter = high_enter
        self.confirm = confirm
        self._hist = deque(maxlen=smooth)
        self.zone = None
        self.extreme = None
        self._pending = None
        self._pending_n = 0

    def update(self, m):
        self._hist.append(float(m))
        s = float(np.median(self._hist))

        cand = "low" if s < self.low_enter else ("high" if s > self.high_enter else None)
        finished = None

        if cand is not None and cand != self.zone:
            if cand == self._pending:
                self._pending_n += 1
            else:
                self._pending, self._pending_n = cand, 1
            if self._pending_n >= self.confirm:
                if self.zone is not None and self.extreme is not None:
                    finished = (self.zone, self.extreme)
                self.zone, self.extreme = cand, None
                self._pending, self._pending_n = None, 0
        else:
            self._pending, self._pending_n = None, 0

        if self.zone == "low":
            self.extreme = s if self.extreme is None else min(self.extreme, s)
        elif self.zone == "high":
            self.extreme = s if self.extreme is None else max(self.extreme, s)

        return self.zone, finished


# ══════════════════════════════════════════════════════════
# 런지 (규칙 변경 없음)
# ══════════════════════════════════════════════════════════
def _get_front_back_legs(kpts):
    """엉덩이 중심에서 수평(x)으로 더 벌어진 쪽 = 앞다리, 반대쪽 = 뒷다리."""
    l_hip, r_hip = get_kp(kpts, 11), get_kp(kpts, 12)
    l_knee, r_knee = get_kp(kpts, 13), get_kp(kpts, 14)
    l_ankle, r_ankle = get_kp(kpts, 15), get_kp(kpts, 16)

    hip_mid = midpoint(l_hip, r_hip)
    l_offset = abs(l_ankle[0] - hip_mid[0])
    r_offset = abs(r_ankle[0] - hip_mid[0])

    if l_offset > r_offset:
        front = (l_hip, l_knee, l_ankle, "왼쪽")
        back = (r_hip, r_knee, r_ankle, "오른쪽")
    else:
        front = (r_hip, r_knee, r_ankle, "오른쪽")
        back = (l_hip, l_knee, l_ankle, "왼쪽")
    return front, back


def check_lunge(kpts, side=None):
    results = []
    l_shoulder = get_kp(kpts, 5)
    r_shoulder = get_kp(kpts, 6)
    l_hip      = get_kp(kpts, 11)
    r_hip      = get_kp(kpts, 12)
    hip_mid      = midpoint(l_hip, r_hip)
    shoulder_mid = midpoint(l_shoulder, r_shoulder)

    if is_visible(kpts, 11, 12, 13, 14, 15, 16):
        front, back = _get_front_back_legs(kpts)
        front_hip, front_knee, front_ankle, front_side = front
        back_hip, back_knee, back_ankle, back_side = back

        front_knee_angle = calc_angle(front_hip, front_knee, front_ankle)
        ok = bool(abs(front_knee_angle - 90) <= 25)
        results.append({"label": "앞무릎 각도", "ok": ok,
                         "desc": (f"앞무릎 각도가 적절해요. ({front_knee_angle:.1f}°)" if ok
                                  else f"앞무릎 각도가 90도가 아니에요. 더 깊게 내려가세요. (현재: {front_knee_angle:.1f}°)")})

        back_knee_angle = calc_angle(back_hip, back_knee, back_ankle)
        ok = bool(abs(back_knee_angle - 90) <= 25)
        results.append({"label": "뒷무릎 각도", "ok": ok,
                         "desc": (f"뒷무릎이 알맞게 내려갔어요. ({back_knee_angle:.1f}°)" if ok
                                  else f"뒷무릎이 충분히 안 내려갔어요. 90도 근처까지 내려가세요. (현재: {back_knee_angle:.1f}°)")})

    if is_visible(kpts, 5, 6, 11, 12):
        tilt = angle_from_vertical(shoulder_mid, hip_mid)
        ok = bool(tilt <= 20)
        results.append({"label": "상체 일직선", "ok": ok,
                         "desc": (f"상체가 곧게 펴져 있어요. (기울기: {tilt:.1f}°)" if ok
                                  else f"상체가 앞으로 기울어졌어요. 허리를 세워주세요. (기울기: {tilt:.1f}°)")})
    return results


def _lunge_back_knee_angle(kpts):
    """뒷무릎 각도. 관절이 안 보이면 None."""
    if not is_visible(kpts, 11, 12, 13, 14, 15, 16):
        return None
    _, back = _get_front_back_legs(kpts)
    return calc_angle(back[0], back[1], back[2])


def _phase_lunge(kpts):
    if not is_visible(kpts, 11, 12, 13, 14, 15, 16):
        return "none"
    _, back = _get_front_back_legs(kpts)
    back_hip, back_knee, back_ankle, _ = back
    back_knee_angle = calc_angle(back_hip, back_knee, back_ankle)
    return "down" if back_knee_angle < 120 else "up"


# ══════════════════════════════════════════════════════════
# 플랭크
#   목~골반 일직선 / 엉덩이 높이 : 기존 그대로
#   팔 각도 : 가까운 한쪽만
#   다리 일직선(엉덩이-무릎-발목) : 신규 — 무릎을 굽힌 채로 버티는 것 방지
# ══════════════════════════════════════════════════════════
def check_plank(kpts, side=None):
    results = []
    side = side or _default_side(kpts)

    nose         = get_kp(kpts, 0)
    shoulder_mid = _mid_of(kpts, 5, 6)
    hip_mid      = _mid_of(kpts, 11, 12)
    ankle_mid    = _mid_of(kpts, 15, 16)

    if is_visible(kpts, 0) and shoulder_mid is not None and hip_mid is not None:
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= PLANK_SPINE_MIN)
        results.append({"label": "목~골반 일직선", "ok": ok,
                         "desc": (f"목~골반이 일직선으로 잘 유지되고 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"목과 골반이 일직선이 아니에요. (각도: {spine_angle:.1f}°)")})

    if shoulder_mid is not None and hip_mid is not None and ankle_mid is not None:
        body_angle = calc_angle(shoulder_mid, hip_mid, ankle_mid)
        if body_angle < PLANK_BODY_MIN:
            if hip_mid[1] < shoulder_mid[1] and hip_mid[1] < ankle_mid[1]:
                results.append({"label": "엉덩이 높이", "ok": False,
                                 "desc": f"엉덩이가 너무 올라가 있어요. 내려주세요. (각도: {body_angle:.1f}°)"})
            else:
                results.append({"label": "엉덩이 높이", "ok": False,
                                 "desc": f"엉덩이가 처져 있어요. 올려주세요. (각도: {body_angle:.1f}°)"})
        else:
            results.append({"label": "엉덩이 높이", "ok": True,
                             "desc": f"몸통이 일직선으로 잘 유지되고 있어요. ({body_angle:.1f}°)"})

    # 팔 각도 — 가까운 한쪽만
    arm_side = side if _side_visible(kpts, side, "shoulder", "elbow", "wrist") else _other(side)
    if _side_visible(kpts, arm_side, "shoulder", "elbow", "wrist"):
        a = calc_angle(_pt(kpts, arm_side, "shoulder"), _pt(kpts, arm_side, "elbow"), _pt(kpts, arm_side, "wrist"))
        ok = bool(abs(a - PLANK_ARM_TARGET) <= PLANK_ARM_TOL)
        results.append({"label": "팔 각도", "ok": ok,
                         "desc": (f"{SIDE_KO[arm_side]} 팔 각도가 적절해요. ({a:.1f}°)" if ok
                                  else f"팔 각도가 90도가 아니에요. (현재: {a:.1f}°, 목표: 90°)")})

    # 다리 일직선 — 엉덩이-무릎-발목
    leg_side = side if _side_visible(kpts, side, "hip", "knee", "ankle") else _other(side)
    if _side_visible(kpts, leg_side, "hip", "knee", "ankle"):
        a = calc_angle(_pt(kpts, leg_side, "hip"), _pt(kpts, leg_side, "knee"), _pt(kpts, leg_side, "ankle"))
        ok = bool(a >= PLANK_LEG_MIN)
        results.append({"label": "다리 일직선", "ok": ok,
                         "desc": (f"다리가 곧게 펴져 있어요. ({a:.1f}°)" if ok
                                  else f"무릎이 굽혀져 있어요. 다리를 곧게 펴주세요. (각도: {a:.1f}°, 목표: {PLANK_LEG_MIN}° 이상)")})
    return results


def _phase_plank(kpts):
    if _mid_of(kpts, 5, 6) is None or _mid_of(kpts, 11, 12) is None:
        return "none"
    return "down"


# ══════════════════════════════════════════════════════════
# 푸쉬업 (무릎 푸쉬업)
#   매 프레임 : 허리 정렬(어깨-엉덩이-무릎)
#   반복당   : 팔꿈치 굽힘 깊이(내려갔을 때 최소 각도), 팔꿈치 펴짐 정도(올라왔을 때 최대 각도)
#   팔은 가까운 한쪽만. 어깨 균형·목~골반은 제외.
# ══════════════════════════════════════════════════════════
def _pushup_elbow_angle(k, side):
    return calc_angle(_pt(k, side, "shoulder"), _pt(k, side, "elbow"), _pt(k, side, "wrist"))


def check_knee_pushup(kpts, side=None):
    results = []
    side = side or _default_side(kpts)
    s = side if _side_visible(kpts, side, "shoulder", "hip", "knee") else _other(side)
    if _side_visible(kpts, s, "shoulder", "hip", "knee"):
        a = calc_angle(_pt(kpts, s, "shoulder"), _pt(kpts, s, "hip"), _pt(kpts, s, "knee"))
        ok = bool(a >= PUSHUP_BACK_MIN)
        results.append({"label": "허리 정렬", "ok": ok,
                         "desc": (f"어깨~무릎이 일직선으로 잘 유지되고 있어요. ({a:.1f}°)" if ok
                                  else f"허리가 꺾였어요. 엉덩이를 어깨~무릎 일직선에 맞춰주세요. (각도: {a:.1f}°)")})
    return results


def _pushup_peak(zone, v):
    if zone == "low":
        ok = bool(v <= PUSHUP_DEPTH_MAX)
        return {"label": "팔꿈치 굽힘 깊이", "ok": ok, "per_rep": True,
                "desc": (f"충분히 내려갔어요. (최소 {v:.0f}°)" if ok
                         else f"더 깊게 내려가세요. 팔꿈치를 {PUSHUP_DEPTH_MAX}° 근처까지 굽혀주세요. (최소: {v:.0f}°)")}
    ok = bool(v >= PUSHUP_EXTEND_MIN)
    return {"label": "팔꿈치 펴짐 정도", "ok": ok, "per_rep": True,
            "desc": (f"팔을 끝까지 잘 폈어요. (최대 {v:.0f}°)" if ok
                     else f"팔을 끝까지 펴주세요. (최대: {v:.0f}°, 목표: {PUSHUP_EXTEND_MIN}° 이상)")}


class RepCounter:
    """절대 각도 기준 없이 '움직임의 크기'로 반복을 센다 (카메라 각도·거리가 달라도 동작).

    고점에서 min_amp 이상 내려갔다가, 그 하강량의 rise_frac 이상 되돌아오면 1회.
    update() → 반복이 완료된 프레임이면 (이번 반복의 고점, 저점), 아니면 None.
    - turn 이내의 떨림은 방향 전환으로 보지 않는다 (최근 3프레임 중앙값으로 평활화)
    - 하강량이 min_amp 미만인 얕은 흔들림은 반복으로 세지 않는다
    - 내려간 채로 시작하면 첫 상승은 세지 않고, 그다음 하강부터 센다
    """

    def __init__(self, min_amp, turn=HINT_TURN, rise_frac=0.6):
        self.min_amp, self.turn, self.rise_frac = min_amp, turn, rise_frac
        self._hist = deque(maxlen=3)
        self._peak = None        # 최근 고점
        self._trough = None      # 내려가는 중이면 그 최저점, 아니면 None

    def update(self, angle):
        self._hist.append(float(angle))
        s = float(np.median(self._hist))

        if self._peak is None:
            self._peak = s
            return None

        if self._trough is None:                          # 위쪽에서 대기/상승 중
            if s > self._peak:
                self._peak = s
            elif self._peak - s >= self.turn:
                self._trough = s
            return None

        if s < self._trough:                              # 계속 내려가는 중
            self._trough = s
            return None

        rise = s - self._trough
        if rise < self.turn:
            return None
        drop = self._peak - self._trough
        if drop < self.min_amp:                           # 진폭 부족 → 흔들림으로 무시
            self._trough = None
            return None
        if rise >= self.rise_frac * drop:                 # 충분히 되돌아옴 → 1회
            done = (self._peak, self._trough)
            self._peak, self._trough = s, None
            return done
        return None


class PeakHint:
    """동작의 방향이 바뀌는 순간, 목표에 못 미쳤으면 바로 안내한다 (레그레이즈·푸쉬업 공통).

    정식 채점(ZoneTracker)은 구간이 끝난 뒤에 극값으로 한 번 하지만, 그러면 피드백이 한 박자 늦고
    low/high 구간에 아예 못 들어간 얕은 동작은 채점 자체가 안 된다. 이 클래스는 그 둘을 보완한다.
    안내는 점수/통계에 들어가지 않는다 (hint=True, carry=True, weight=0).

    cfg: low_max   각도가 줄다가 꺾일 때의 최소값이 이 값 이하여야 통과 (넘으면 low_* 안내)
         high_min  각도가 늘다가 꺾일 때의 최대값이 이 값 이상이어야 통과 (못 미치면 high_* 안내)
         low_label/low_desc, high_label/high_desc : 안내 항목 이름 / 문구 함수(값 -> str)
         low_formal/high_formal : 같은 주제의 정식 채점 항목 이름 (나오면 안내를 거둔다)
    """

    def __init__(self, cfg):
        self.cfg = cfg
        self._hist = deque(maxlen=3)
        self._dir = None        # "dec"(각도 감소 중) / "inc"(각도 증가 중)
        self._origin = None     # 현재 방향이 시작된 값
        self._ext = None        # 현재 방향의 극값(감소 중=최소, 증가 중=최대)
        self._item = None
        self._left = 0
        self._kind = None

    def update(self, angle):
        self._hist.append(float(angle))
        s = float(np.median(self._hist))

        if self._left > 0:
            self._left -= 1
            if self._left == 0:
                self._item = self._kind = None

        if self._origin is None:
            self._origin = self._ext = s
            return

        if self._dir is None:
            if s <= self._origin - HINT_TURN:
                self._dir, self._ext = "dec", s
            elif s >= self._origin + HINT_TURN:
                self._dir, self._ext = "inc", s
            return

        c = self.cfg
        if self._dir == "dec":
            if s < self._ext:
                self._ext = s
            elif s > self._ext + HINT_TURN:                   # 줄다가 늘기 시작 (= 최저점 통과)
                low = self._ext
                if self._origin - low >= HINT_DROP and low > c["low_max"]:
                    self._show("low", c["low_label"], c["low_desc"](low))
                self._dir, self._origin, self._ext = "inc", low, s
        else:
            if s > self._ext:
                self._ext = s
            elif s < self._ext - HINT_TURN:                   # 늘다가 줄기 시작 (= 최고점 통과)
                high = self._ext
                if high - self._origin >= HINT_DROP and high < c["high_min"]:
                    self._show("high", c["high_label"], c["high_desc"](high))
                self._dir, self._origin, self._ext = "dec", high, s

    def _show(self, kind, label, desc):
        self._item = {"label": label, "desc": desc, "ok": False, "hint": True, "carry": True}
        self._kind, self._left = kind, HINT_FRAMES

    def dismiss_formal(self, formal_label):
        """정식 채점 결과가 나오면 같은 주제의 안내는 거둔다 (카드 중복 방지)."""
        c = self.cfg
        kind = "low" if formal_label == c["low_formal"] else ("high" if formal_label == c["high_formal"] else None)
        if kind and self._kind == kind:
            self._item = self._kind = None
            self._left = 0

    @property
    def item(self):
        return dict(self._item) if self._item else None


# ══════════════════════════════════════════════════════════
# 레그레이즈
#   매 프레임 : 무릎 펴짐(= 기존 '다리 펴기', 가까운 한쪽만), 목~골반 일직선(기존 그대로)
#   반복당   : 다리 들어올린 높이(최소 각도), 다리 내린 높이(최대 각도)
#   '높이'는 몸통-다리 각도(어깨-엉덩이-발목)로 잰다. 누운 방향(머리가 왼쪽/오른쪽)과 무관.
#   양발 대칭은 제거.
# ══════════════════════════════════════════════════════════
def _legraise_hip_angle(k, side):
    return calc_angle(_pt(k, side, "shoulder"), _pt(k, side, "hip"), _pt(k, side, "ankle"))


def check_leg_raise(kpts, side=None):
    results = []
    side = side or _default_side(kpts)

    nose = get_kp(kpts, 0)
    shoulder_mid = _mid_of(kpts, 5, 6)
    hip_mid = _mid_of(kpts, 11, 12)

    if is_visible(kpts, 0) and shoulder_mid is not None and hip_mid is not None:
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= LEGRAISE_SPINE_MIN)
        results.append({"label": "목~골반 일직선", "ok": ok,
                         "desc": (f"몸통이 일직선으로 잘 유지되고 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"몸통이 휘어져 있어요. 허리를 바닥에 밀착시키세요. (각도: {spine_angle:.1f}°)")})

    s = side if _side_visible(kpts, side, "hip", "knee", "ankle") else _other(side)
    if _side_visible(kpts, s, "hip", "knee", "ankle"):
        a = calc_angle(_pt(kpts, s, "hip"), _pt(kpts, s, "knee"), _pt(kpts, s, "ankle"))
        ok = bool(a >= LEGRAISE_KNEE_MIN)
        results.append({"label": "무릎 펴짐", "ok": ok,
                         "desc": (f"{SIDE_KO[s]} 다리가 곧게 펴져 있어요. ({a:.1f}°)" if ok
                                  else f"무릎을 더 펴주세요. (각도: {a:.1f}°, 목표: {LEGRAISE_KNEE_MIN}° 이상)")})
    return results


def _legraise_peak(zone, v):
    if zone == "low":
        ok = bool(v <= LEGRAISE_TOP_MAX)
        return {"label": "다리 들어올린 높이", "ok": ok, "per_rep": True,
                "desc": (f"다리를 충분히 들어올렸어요. (몸통-다리 {v:.0f}°)" if ok
                         else f"다리를 더 높이 들어올리세요. (몸통-다리 {v:.0f}°, 목표: {LEGRAISE_TOP_MAX}° 이하)")}
    ok = bool(v >= LEGRAISE_BOTTOM_MIN)
    return {"label": "다리 내린 높이", "ok": ok, "per_rep": True,
            "desc": (f"다리를 끝까지 잘 내렸어요. (몸통-다리 {v:.0f}°)" if ok
                     else f"다리를 더 아래까지 내려주세요. (몸통-다리 {v:.0f}°, 목표: {LEGRAISE_BOTTOM_MIN}° 이상)")}


# ══════════════════════════════════════════════════════════
# 운동 정의
# ══════════════════════════════════════════════════════════
EXERCISE_RULES = {
    "레그레이즈": check_leg_raise,
    "런지":       check_lunge,
    "플랭크":     check_plank,
    "푸쉬업":     check_knee_pushup,
}

PHASE_LABEL = {"down": "운동 중", "up": "대기 자세", "none": "자세를 잡아주세요"}

# ── '운동 자세를 잡았는가' 판정 (이게 없으면 사람이 화면에 보이기만 해도 채점이 시작됨) ──
READY_ENTER_FRAMES = 5       # 자세 조건이 연속 5프레임 맞아야 '준비됨'
READY_EXIT_FRAMES = 8        # 연속 8프레임 어긋나야 '준비 해제'
LYING_MIN_TILT = 50          # 플랭크/푸쉬업/레그레이즈: 몸통이 수직에서 이 각도 이상 기울어야(=누움/엎드림)
LUNGE_MAX_TILT = 35          # 런지: 상체가 수직에서 이 각도 이내(=서 있음)


def _in_position(exercise_name, k):
    """해당 운동의 시작 자세를 잡았는지 (프레임 1장 기준)."""
    # 옆모습에서는 먼 쪽 어깨/엉덩이가 가려져 안 잡힐 수 있어서, 보이는 쪽만으로 몸통 기울기를 잰다.
    sh, hp = _mid_of(k, 5, 6), _mid_of(k, 11, 12)
    if sh is None or hp is None:
        return False
    tilt = angle_from_vertical(sh, hp)
    if exercise_name == "런지":
        return bool(tilt <= LUNGE_MAX_TILT and is_visible(k, 11, 12, 13, 14, 15, 16))
    return bool(tilt >= LYING_MIN_TILT)

# only_active=True 일 때, 매 프레임 항목을 평가하는 단계
CONTINUOUS_PHASES = {
    "레그레이즈": {"down"},
    "런지":       {"down"},
    "플랭크":     {"down"},
    "푸쉬업":     {"down"},
}

# 반복당 항목을 쓰는 운동: (측정 함수, 필요 관절, ZoneTracker 인자, 결과 생성 함수)
_PEAK_SPEC = {
    "푸쉬업": dict(measure=_pushup_elbow_angle, parts=("shoulder", "elbow", "wrist"),
                   low=PUSHUP_LOW_ENTER, high=PUSHUP_HIGH_ENTER, build=_pushup_peak,
                   hint=dict(
                       low_max=PUSHUP_DEPTH_MAX, high_min=PUSHUP_EXTEND_MIN,
                       low_formal="팔꿈치 굽힘 깊이", high_formal="팔꿈치 펴짐 정도",
                       low_label="팔꿈치 굽힘 깊이 안내",
                       low_desc=lambda v: f"조금 더 깊게 내려가 보세요. (이번 최소: {v:.0f}°, 목표: {PUSHUP_DEPTH_MAX}° 이하)",
                       high_label="팔꿈치 펴짐 안내",
                       high_desc=lambda v: f"팔을 끝까지 펴보세요. (이번 최대: {v:.0f}°, 목표: {PUSHUP_EXTEND_MIN}° 이상)")),
    "레그레이즈": dict(measure=_legraise_hip_angle, parts=("shoulder", "hip", "ankle"),
                   low=LEGRAISE_LOW_ENTER, high=LEGRAISE_HIGH_ENTER, build=_legraise_peak,
                   hint=dict(
                       low_max=LEGRAISE_TOP_MAX, high_min=LEGRAISE_BOTTOM_MIN,
                       low_formal="다리 들어올린 높이", high_formal="다리 내린 높이",
                       low_label="다리 들어올린 높이 안내",
                       low_desc=lambda v: f"조금 더 높이 들어올려 보세요. (이번 최고점: {v:.0f}°, 목표: {LEGRAISE_TOP_MAX}° 이하)",
                       high_label="다리 내린 높이 안내",
                       high_desc=lambda v: f"다리를 조금 더 아래까지 내려보세요. (이번 최저점: {v:.0f}°, 목표: {LEGRAISE_BOTTOM_MIN}° 이상)")),
}


RULE_WEIGHTS = {
    "레그레이즈": {"다리 들어올린 높이": 3, "무릎 펴짐": 3, "다리 내린 높이": 2, "목~골반 일직선": 2,
                   "다리 들어올린 높이 안내": 0, "다리 내린 높이 안내": 0},
    "런지":       {"앞무릎 각도": 3, "상체 일직선": 2, "뒷무릎 각도": 1},
    "플랭크":     {"목~골반 일직선": 3, "엉덩이 높이": 3, "다리 일직선": 2, "팔 각도": 1},
    "푸쉬업":     {"팔꿈치 굽힘 깊이": 3, "허리 정렬": 3, "팔꿈치 펴짐 정도": 2,
                   "팔꿈치 굽힘 깊이 안내": 0, "팔꿈치 펴짐 안내": 0},
}
DEFAULT_WEIGHT = 1


def get_weight(exercise_name: str, label: str) -> int:
    table = RULE_WEIGHTS.get(exercise_name, {})
    if label in table:
        return table[label]
    base = label.split(" (")[0] if " (" in label else label
    return table.get(base, DEFAULT_WEIGHT)


def calc_score(results: list) -> int:
    results = [r for r in results if not r.get("hint")]   # 실시간 안내는 점수에서 제외
    if not results:
        return 0
    total_w = sum(r.get("weight", 1) for r in results)
    if total_w == 0:
        return 0
    ok_w = sum(r.get("weight", 1) for r in results if r["ok"])
    return int((ok_w / total_w) * 100)


# ══════════════════════════════════════════════════════════
# 평가기 (세션당 1개)
# ══════════════════════════════════════════════════════════
class ExerciseEvaluator:
    def __init__(self, exercise_name: str):
        self.exercise = exercise_name
        self.selector = NearSideSelector()
        self._spec = _PEAK_SPEC.get(exercise_name)
        self._tracker = self._make_tracker()
        self._carry = {}   # label -> 직전 반복의 결과
        self.ready = False          # 운동 자세를 잡았는가
        self._ok_run = 0
        self._bad_run = 0

        # 실시간 반복 횟수 (플랭크는 반복이 없으므로 계속 0)
        self.rep_count = 0
        self.rep_event = False      # 직전 evaluate() 에서 반복이 1회 완료됐는가 (앱에서 효과음/진동용)
        self._seen_high = False     # '선/내린 구간'을 한 번이라도 거쳤는가 (내려간 채로 시작한 경우 첫 동작을 세지 않기 위함)
        self._hint = PeakHint(self._spec["hint"]) if self._spec else None
        self._amp = self._make_amp()

    def _make_amp(self):
        # 푸쉬업만 진폭 기반으로 횟수·반복당 채점 (구간 기준 135°/150°가 카메라 각도에 따라 안 맞는 문제 회피)
        return RepCounter(PUSHUP_MIN_AMP, rise_frac=PUSHUP_RISE_FRAC) if self.exercise == "푸쉬업" else None

    def _make_tracker(self):
        if self._spec:
            return ZoneTracker(self._spec["low"], self._spec["high"])
        if self.exercise == "런지":
            return ZoneTracker(LUNGE_REP_LOW, LUNGE_REP_HIGH)
        return None

    def _count_rep(self, zone, finished):
        """'낮은 구간(푸쉬업=내려감, 레그레이즈=들어올림, 런지=앉음)'이 끝나는 순간 = 1회 완료."""
        if finished and finished[0] == "low" and self._seen_high:
            self.rep_count += 1
            self.rep_event = True
        if zone == "high":
            self._seen_high = True

    def _update_ready(self, in_pos):
        if in_pos:
            self._ok_run += 1
            self._bad_run = 0
        else:
            self._bad_run += 1
            self._ok_run = 0

        if not self.ready and self._ok_run >= READY_ENTER_FRAMES:
            self.ready = True
            self._carry = {}                     # 새 세트: 이전 반복 결과 비움
        elif self.ready and self._bad_run >= READY_EXIT_FRAMES:
            self.ready = False
            self._tracker = self._make_tracker()  # 반복 추적도 처음부터 (누적 횟수는 유지)
            self._seen_high = False
            if self._hint:
                self._hint = PeakHint(self._spec["hint"])
            self._amp = self._make_amp()

    def evaluate(self, kpts, conf=None, aspect=1.0, only_active=True):
        """kpts: (17,2) 0~1 정규화 좌표 (미검출=0,0). conf: (17,) YOLO 신뢰도(선택).
        aspect: 프레임 w/h — x에 곱해 각도 왜곡을 보정. 반환: (results, phase)"""
        func = EXERCISE_RULES.get(self.exercise)
        if func is None:
            return [], "none"

        k = np.asarray(kpts, dtype=np.float32).copy()
        k[:, 0] *= aspect
        self.rep_event = False

        self._update_ready(_in_position(self.exercise, k))
        if not self.ready:
            return [], "none"        # 자세를 잡기 전에는 채점·반복 추적 모두 안 함

        side = self.selector.update(k, conf)
        phase, fresh = self._phase(k, side)

        if phase == "none":
            return [], phase

        if only_active and phase not in CONTINUOUS_PHASES[self.exercise]:
            cont = []
        else:
            cont = func(k, side)

        # 이번 프레임에 확정된 반복당 항목 + 직전 반복 결과(표시용 carry)
        for r in fresh:
            self._carry[r["label"]] = r
        fresh_labels = {r["label"] for r in fresh}
        if self._hint:
            for label in fresh_labels:
                self._hint.dismiss_formal(label)
        carried = []
        for label, r in self._carry.items():
            if label not in fresh_labels:
                c = dict(r)
                c["carry"] = True
                carried.append(c)
        fresh = [dict(r, carry=False) for r in fresh]

        hint = self._hint.item if self._hint else None
        results = cont + fresh + carried + ([hint] if hint else [])
        for r in results:
            r["weight"] = get_weight(self.exercise, r["label"])
        return results, phase

    def _phase(self, k, side):
        if self.exercise == "런지":
            ang = _lunge_back_knee_angle(k)
            if ang is not None:
                self._count_rep(*self._tracker.update(ang))
            return _phase_lunge(k), []
        if self.exercise == "플랭크":
            return _phase_plank(k), []

        spec = self._spec
        s = self.selector.pick(k, side, *spec["parts"])
        if s is None:
            return "none", []
        measured = spec["measure"](k, s)
        zone, finished = self._tracker.update(measured)
        if self._hint:
            self._hint.update(measured)
        if self._amp is not None:
            done = self._amp.update(measured)
            fresh = []
            if done:
                top, bottom = done
                self.rep_count += 1
                self.rep_event = True
                fresh = [_pushup_peak("low", bottom), _pushup_peak("high", top)]
        else:
            self._count_rep(zone, finished)
            fresh = [spec["build"](*finished)] if finished else []
        phase = "down" if zone == "low" else "up"
        return phase, fresh


# ══════════════════════════════════════════════════════════
# 하위 호환용 (상태 없는 단발 호출)
#   반복당 항목은 이력이 필요해서 나오지 않는다. 실시간/영상 분석은 ExerciseEvaluator를 쓸 것.
# ══════════════════════════════════════════════════════════
def get_phase(exercise_name: str, kpts: np.ndarray) -> str:
    return ExerciseEvaluator(exercise_name).evaluate(kpts, only_active=True)[1]


def evaluate_pose(exercise_name: str, kpts: np.ndarray, only_active: bool = True):
    return ExerciseEvaluator(exercise_name).evaluate(kpts, only_active=only_active)