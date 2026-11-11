# -*- coding: utf-8 -*-
"""
학습 스크립트(lstm_velo 최종 버전)의 feature 생성 로직을 실시간 서버용으로 그대로 이식.
학습 때와 추론 때 feature 공식이 한 글자라도 다르면 모델이 엉뚱한 입력을 받는 셈이라,
이 파일은 학습 코드와 최대한 동일하게 유지해야 합니다.

원본: 사용자가 제공한 최종 LSTM 학습 스크립트의 make_features / feature_weight_vec.
"""

import numpy as np

SEQUENCE_LENGTH = 35
INPUT_SIZE = 71          # 좌표34 + 속도34 + 정적특징3
NUM_CLASSES = 4
CLASS_NAMES = ["레그레이즈", "런지", "플랭크", "푸쉬업"]

SMOOTH_WIN = 3
VEL_GAP = 5

JOINT_WEIGHTS = np.ones(17, dtype=np.float32)
JOINT_WEIGHTS[[11, 12, 13, 14, 15, 16]] = 2.0   # 엉덩이·무릎·발목
JOINT_WEIGHTS[[0, 1, 2, 3, 4]] = 0.5            # 얼굴


def coord_weight_vec():
    return np.repeat(JOINT_WEIGHTS, 2).astype(np.float32)   # (34,)


def feature_weight_vec():
    """71차원 전체(좌표34+속도34+정적3)에 곱할 가중치 벡터. 정적 특징엔 가중치 안 곱함(학습 코드와 동일)."""
    cw = coord_weight_vec()
    return np.concatenate([cw, cw, np.ones(3, dtype=np.float32)])


def smooth_coords(win34: np.ndarray, k: int = SMOOTH_WIN) -> np.ndarray:
    """좌표 시퀀스 이동평균 스무딩 (T,34). 학습 코드와 동일한 알고리즘."""
    T = len(win34)
    if T < k or k <= 1:
        return win34.copy()
    out = win34.copy()
    half = k // 2
    for t in range(T):
        s = max(0, t - half)
        e = min(T, t + half + 1)
        out[t] = win34[s:e].mean(axis=0)
    return out


def make_features(win34: np.ndarray, gap: int = VEL_GAP) -> np.ndarray:
    """
    (T,34) → (T,71)
    좌표34 + 속도34 + 정적특징3(joint_var, lower_var, upper_speed_mean)
    학습 스크립트의 make_features와 완전히 동일 (가중치는 여기서 곱하지 않음 — feature_weight_vec()로 별도 적용).
    """
    win34 = np.asarray(win34, dtype=np.float32)
    if win34.shape[1] != 34:
        raise ValueError(f"win34는 (T,34)여야 합니다. 현재 shape: {win34.shape}")

    coords = smooth_coords(win34)
    T = len(coords)

    vel = np.zeros_like(coords)
    for t in range(T):
        prev = max(0, t - gap)
        vel[t] = coords[t] - coords[prev]

    joint_var = coords.var(axis=0).mean()

    lower_idx = []
    for j in [11, 12, 13, 14, 15, 16]:
        lower_idx += [j * 2, j * 2 + 1]
    lower_var = coords[:, lower_idx].var(axis=0).mean()

    upper_idx = []
    for j in [5, 6, 7, 8, 9, 10]:
        upper_idx += [j * 2, j * 2 + 1]
    upper_vel = vel[:, upper_idx]
    upper_vel_xy = upper_vel.reshape(T, -1, 2)
    upper_speed_mean = np.linalg.norm(upper_vel_xy, axis=2).mean()

    static = np.tile([joint_var, lower_var, upper_speed_mean], (T, 1)).astype(np.float32)

    out = np.concatenate([win34, vel, static], axis=1)
    if out.shape[1] != INPUT_SIZE:
        raise ValueError(f"입력 차원 오류: {out.shape}, INPUT_SIZE={INPUT_SIZE}")
    return out


def build_weighted_features(chunk_norm_17x2: list) -> np.ndarray:
    """
    실시간 서버에서 쓰는 진입점.
    chunk_norm_17x2: 길이 SEQUENCE_LENGTH인 (17,2) 정규화 keypoint 프레임 리스트
    반환: (SEQUENCE_LENGTH, 71) — 모델에 바로 넣을 수 있는, 가중치까지 적용된 최종 입력
    """
    win34 = np.array([f.flatten() for f in chunk_norm_17x2], dtype=np.float32)  # (T,34)
    features = make_features(win34)                                             # (T,71)
    return features * feature_weight_vec()                                       # 학습 때와 동일하게 가중치 적용