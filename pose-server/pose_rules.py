# -*- coding: utf-8 -*-
"""
규칙 기반 자세 교정 모듈
YOLO Pose 17개 관절 인덱스 (0-based):
  0: 코, 1: 왼눈, 2: 오른눈, 3: 왼귀, 4: 오른귀
  5: 왼어깨, 6: 오른어깨
  7: 왼팔꿈치, 8: 오른팔꿈치
  9: 왼손목, 10: 오른손목
  11: 왼엉덩이, 12: 오른엉덩이
  13: 왼무릎, 14: 오른무릎
  15: 왼발목, 16: 오른발목
"""

import numpy as np


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


def check_leg_raise(kpts):
    results = []
    nose      = get_kp(kpts, 0)
    l_hip     = get_kp(kpts, 11)
    r_hip     = get_kp(kpts, 12)
    l_knee    = get_kp(kpts, 13)
    r_knee    = get_kp(kpts, 14)
    l_ankle   = get_kp(kpts, 15)
    r_ankle   = get_kp(kpts, 16)
    l_shoulder = get_kp(kpts, 5)
    r_shoulder = get_kp(kpts, 6)
    hip_mid        = midpoint(l_hip, r_hip)
    shoulder_mid   = midpoint(l_shoulder, r_shoulder)

    if is_visible(kpts, 0, 5, 6, 11, 12):
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= 160)
        results.append({"label": "목~골반 일직선", "ok": ok,
                         "desc": (f"몸통이 일직선으로 잘 유지되고 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"몸통이 휘어져 있어요. 허리를 바닥에 밀착시키세요. (각도: {spine_angle:.1f}°)")})

    if is_visible(kpts, 11, 13, 15):
        l_leg_angle = calc_angle(l_hip, l_knee, l_ankle)
        ok = bool(l_leg_angle >= 160)
        results.append({"label": "다리 펴기 (왼쪽)", "ok": ok,
                         "desc": (f"왼쪽 다리가 잘 펴져 있어요. ({l_leg_angle:.1f}°)" if ok
                                  else f"왼쪽 다리를 더 펴주세요. (각도: {l_leg_angle:.1f}°, 목표: 160° 이상)")})

    if is_visible(kpts, 12, 14, 16):
        r_leg_angle = calc_angle(r_hip, r_knee, r_ankle)
        ok = bool(r_leg_angle >= 160)
        results.append({"label": "다리 펴기 (오른쪽)", "ok": ok,
                         "desc": (f"오른쪽 다리가 잘 펴져 있어요. ({r_leg_angle:.1f}°)" if ok
                                  else f"오른쪽 다리를 더 펴주세요. (각도: {r_leg_angle:.1f}°, 목표: 160° 이상)")})

    if is_visible(kpts, 15, 16):
        ankle_diff = abs(l_ankle[1] - r_ankle[1])
        ok = bool(ankle_diff <= 0.05)
        results.append({"label": "양발 대칭", "ok": ok,
                         "desc": (f"양발이 대칭적으로 잘 올라가 있어요. (차이: {ankle_diff:.3f})" if ok
                                  else f"양발 높이가 다릅니다. 좌우 균형을 맞춰주세요. (차이: {ankle_diff:.3f})")})
    return results


def check_lunge(kpts):
    results = []
    nose       = get_kp(kpts, 0)
    l_shoulder = get_kp(kpts, 5)
    r_shoulder = get_kp(kpts, 6)
    l_hip      = get_kp(kpts, 11)
    r_hip      = get_kp(kpts, 12)
    l_knee     = get_kp(kpts, 13)
    r_knee     = get_kp(kpts, 14)
    l_ankle    = get_kp(kpts, 15)
    r_ankle    = get_kp(kpts, 16)
    hip_mid      = midpoint(l_hip, r_hip)
    shoulder_mid = midpoint(l_shoulder, r_shoulder)

    if is_visible(kpts, 11, 12, 13, 14, 15, 16):
        if l_knee[1] < r_knee[1]:
            front_hip, front_knee, front_ankle = l_hip, l_knee, l_ankle
        else:
            front_hip, front_knee, front_ankle = r_hip, r_knee, r_ankle

        knee_angle = calc_angle(front_hip, front_knee, front_ankle)
        ok = bool(abs(knee_angle - 90) <= 25)
        results.append({"label": "앞무릎 각도", "ok": ok,
                         "desc": (f"앞무릎 각도가 적절해요. ({knee_angle:.1f}°)" if ok
                                  else f"앞무릎 각도가 90도가 아니에요. 더 깊게 내려가세요. (현재: {knee_angle:.1f}°)")})

        knee_over = front_knee[0] - front_ankle[0]
        ok = bool(knee_over <= 0.05)
        results.append({"label": "무릎-발끝 위치", "ok": ok,
                         "desc": ("무릎이 발끝을 넘지 않아요. 좋아요!" if ok
                                  else f"앞무릎이 발끝을 넘었어요. 무릎을 뒤로 당겨주세요. (초과: {knee_over:.3f})")})

    if is_visible(kpts, 0, 5, 6, 11, 12):
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= 160)
        results.append({"label": "상체 일직선", "ok": ok,
                         "desc": (f"상체가 곧게 펴져 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"상체가 앞으로 기울어졌어요. 허리를 세워주세요. (각도: {spine_angle:.1f}°)")})
    return results


def check_plank(kpts):
    results = []
    nose       = get_kp(kpts, 0)
    l_shoulder = get_kp(kpts, 5)
    r_shoulder = get_kp(kpts, 6)
    l_elbow    = get_kp(kpts, 7)
    r_elbow    = get_kp(kpts, 8)
    l_wrist    = get_kp(kpts, 9)
    r_wrist    = get_kp(kpts, 10)
    l_hip      = get_kp(kpts, 11)
    r_hip      = get_kp(kpts, 12)
    l_ankle    = get_kp(kpts, 15)
    r_ankle    = get_kp(kpts, 16)
    shoulder_mid = midpoint(l_shoulder, r_shoulder)
    hip_mid      = midpoint(l_hip, r_hip)
    ankle_mid    = midpoint(l_ankle, r_ankle)

    if is_visible(kpts, 5, 7, 9):
        l_arm_angle = calc_angle(l_shoulder, l_elbow, l_wrist)
        ok = bool(abs(l_arm_angle - 90) <= 20)
        results.append({"label": "팔 각도 (왼쪽)", "ok": ok,
                         "desc": (f"왼팔 각도가 적절해요. ({l_arm_angle:.1f}°)" if ok
                                  else f"왼팔 각도가 90도가 아니에요. (현재: {l_arm_angle:.1f}°, 목표: 90°)")})

    if is_visible(kpts, 6, 8, 10):
        r_arm_angle = calc_angle(r_shoulder, r_elbow, r_wrist)
        ok = bool(abs(r_arm_angle - 90) <= 20)
        results.append({"label": "팔 각도 (오른쪽)", "ok": ok,
                         "desc": (f"오른팔 각도가 적절해요. ({r_arm_angle:.1f}°)" if ok
                                  else f"오른팔 각도가 90도가 아니에요. (현재: {r_arm_angle:.1f}°, 목표: 90°)")})

    if is_visible(kpts, 0, 5, 6, 11, 12):
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= 160)
        results.append({"label": "목~골반 일직선", "ok": ok,
                         "desc": (f"목~골반이 일직선으로 잘 유지되고 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"목과 골반이 일직선이 아니에요. (각도: {spine_angle:.1f}°)")})

    if is_visible(kpts, 5, 6, 11, 12, 15, 16):
        body_angle = calc_angle(shoulder_mid, hip_mid, ankle_mid)
        if body_angle < 160:
            if hip_mid[1] < shoulder_mid[1] and hip_mid[1] < ankle_mid[1]:
                results.append({"label": "엉덩이 높이", "ok": False,
                                 "desc": f"엉덩이가 너무 올라가 있어요. 내려주세요. (각도: {body_angle:.1f}°)"})
            else:
                results.append({"label": "엉덩이 높이", "ok": False,
                                 "desc": f"엉덩이가 처져 있어요. 올려주세요. (각도: {body_angle:.1f}°)"})
        else:
            results.append({"label": "엉덩이 높이", "ok": True,
                             "desc": f"몸통이 일직선으로 잘 유지되고 있어요. ({body_angle:.1f}°)"})
    return results


def check_knee_pushup(kpts):
    results = []
    nose       = get_kp(kpts, 0)
    l_shoulder = get_kp(kpts, 5)
    r_shoulder = get_kp(kpts, 6)
    l_elbow    = get_kp(kpts, 7)
    r_elbow    = get_kp(kpts, 8)
    l_wrist    = get_kp(kpts, 9)
    r_wrist    = get_kp(kpts, 10)
    l_hip      = get_kp(kpts, 11)
    r_hip      = get_kp(kpts, 12)
    shoulder_mid = midpoint(l_shoulder, r_shoulder)
    hip_mid      = midpoint(l_hip, r_hip)

    if is_visible(kpts, 0, 5, 6, 11, 12):
        spine_angle = calc_angle(nose, shoulder_mid, hip_mid)
        ok = bool(spine_angle >= 160)
        results.append({"label": "목~골반 일직선", "ok": ok,
                         "desc": (f"몸통이 일직선으로 잘 유지되고 있어요. ({spine_angle:.1f}°)" if ok
                                  else f"몸통이 휘어져 있어요. 허리를 곧게 펴주세요. (각도: {spine_angle:.1f}°)")})

    if is_visible(kpts, 5, 7, 9):
        l_arm_angle = calc_angle(l_shoulder, l_elbow, l_wrist)
        ok = bool(l_arm_angle >= 160)
        results.append({"label": "팔 펴기 (왼쪽)", "ok": ok,
                         "desc": (f"왼팔이 잘 펴져 있어요. ({l_arm_angle:.1f}°)" if ok
                                  else f"왼팔을 더 펴주세요. (현재: {l_arm_angle:.1f}°, 목표: 170° 이상)")})

    if is_visible(kpts, 6, 8, 10):
        r_arm_angle = calc_angle(r_shoulder, r_elbow, r_wrist)
        ok = bool(r_arm_angle >= 160)
        results.append({"label": "팔 펴기 (오른쪽)", "ok": ok,
                         "desc": (f"오른팔이 잘 펴져 있어요. ({r_arm_angle:.1f}°)" if ok
                                  else f"오른팔을 더 펴주세요. (현재: {r_arm_angle:.1f}°, 목표: 170° 이상)")})

    if is_visible(kpts, 5, 6):
        shoulder_diff = abs(l_shoulder[1] - r_shoulder[1])
        ok = bool(shoulder_diff <= 0.05)
        results.append({"label": "어깨 좌우 균형", "ok": ok,
                         "desc": (f"어깨가 수평으로 잘 유지되고 있어요. (차이: {shoulder_diff:.3f})" if ok
                                  else f"어깨가 한쪽으로 기울었어요. 균형을 맞춰주세요. (차이: {shoulder_diff:.3f})")})
    return results


EXERCISE_RULES = {
    "레그레이즈": check_leg_raise,
    "런지":       check_lunge,
    "플랭크":     check_plank,
    "푸쉬업":     check_knee_pushup,
}

PHASE_LABEL = {"down": "운동 중", "up": "대기 자세", "none": "자세 인식 안 됨"}


def _phase_leg_raise(kpts):
    if not is_visible(kpts, 11, 12, 15, 16):
        return "none"
    hip_mid   = midpoint(get_kp(kpts, 11), get_kp(kpts, 12))
    ankle_mid = midpoint(get_kp(kpts, 15), get_kp(kpts, 16))
    return "down" if ankle_mid[1] < hip_mid[1] - 0.05 else "up"

def _phase_lunge(kpts):
    if not is_visible(kpts, 11, 12, 13, 14, 15, 16):
        return "none"
    l_knee = get_kp(kpts, 13)
    r_knee = get_kp(kpts, 14)
    if l_knee[1] < r_knee[1]:
        front_hip, front_knee, front_ankle = get_kp(kpts, 11), l_knee, get_kp(kpts, 15)
    else:
        front_hip, front_knee, front_ankle = get_kp(kpts, 12), r_knee, get_kp(kpts, 16)
    knee_angle = calc_angle(front_hip, front_knee, front_ankle)
    return "down" if knee_angle < 120 else "up"

def _phase_plank(kpts):
    if not is_visible(kpts, 5, 6, 11, 12):
        return "none"
    return "down"

def _phase_knee_pushup(kpts):
    """
    ⚠️ 임계값 150 (원래 160).
    실측 로그에서 팔이 최대로 펴졌을 때도 각도가 150~151도 정도까지만 나왔고
    160도 근처를 넘은 적이 없어서, "위(up)" 상태가 아예 감지되지 않아 반복횟수가
    안 세어지는 문제가 있었음. 카운팅 목적의 phase 판정 기준만 낮춘 것이고,
    check_knee_pushup()의 자세 채점 기준(170도)은 코칭 목적이라 그대로 둠.
    """
    angles = []
    if is_visible(kpts, 5, 7, 9):
        angles.append(calc_angle(get_kp(kpts, 5), get_kp(kpts, 7), get_kp(kpts, 9)))
    if is_visible(kpts, 6, 8, 10):
        angles.append(calc_angle(get_kp(kpts, 6), get_kp(kpts, 8), get_kp(kpts, 10)))
    if not angles:
        return "none"
    if np.mean(angles) < 145:
        return "down"
    return "up"


PHASE_RULES = {
    "레그레이즈": _phase_leg_raise,
    "런지":       _phase_lunge,
    "플랭크":     _phase_plank,
    "푸쉬업":     _phase_knee_pushup,
}


def get_phase(exercise_name: str, kpts: np.ndarray) -> str:
    func = PHASE_RULES.get(exercise_name)
    return func(kpts) if func else "none"


def evaluate_pose(exercise_name: str, kpts: np.ndarray, only_active: bool = True):
    func = EXERCISE_RULES.get(exercise_name)
    if func is None:
        return [], "none"
    phase = get_phase(exercise_name, kpts)
    if only_active and phase != "down":
        return [], phase
    results = func(kpts)
    for r in results:
        r["weight"] = get_weight(exercise_name, r["label"])
    return results, phase


RULE_WEIGHTS = {
    "레그레이즈": {"다리 펴기 (왼쪽)": 3, "다리 펴기 (오른쪽)": 3, "목~골반 일직선": 2, "양발 대칭": 1},
    "런지":       {"앞무릎 각도": 3, "상체 일직선": 2, "무릎-발끝 위치": 1},
    "플랭크":     {"목~골반 일직선": 3, "엉덩이 높이": 3, "팔 각도 (왼쪽)": 1, "팔 각도 (오른쪽)": 1},
    "푸쉬업":     {"팔 펴기 (왼쪽)": 3, "팔 펴기 (오른쪽)": 3, "목~골반 일직선": 2, "어깨 좌우 균형": 1},
}
DEFAULT_WEIGHT = 1


def get_weight(exercise_name: str, label: str) -> int:
    table = RULE_WEIGHTS.get(exercise_name, {})
    if label in table:
        return table[label]
    base = label.split(" (")[0] if " (" in label else label
    return table.get(base, DEFAULT_WEIGHT)


def calc_score(results: list) -> int:
    if not results:
        return 0
    total_w = sum(r.get("weight", 1) for r in results)
    if total_w == 0:
        return 0
    ok_w = sum(r.get("weight", 1) for r in results if r["ok"])
    return int((ok_w / total_w) * 100)