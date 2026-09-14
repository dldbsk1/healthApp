# -*- coding: utf-8 -*-
"""
서버 → Swift 로 보내는 웹소켓 JSON 메시지의 스펙 문서화용.
FastAPI가 강제하진 않지만(웹소켓은 raw dict를 보냄), Swift 쪽 Codable 모델을
이 필드명 그대로 맞추면 된다.
"""

from typing import Optional, Literal
from pydantic import BaseModel


class PoseCheckItem(BaseModel):
    label: str          # 예: "앞무릎 각도"
    ok: bool
    desc: str            # 사용자에게 보여줄 피드백 문구
    weight: int           # 규칙 중요도 (점수 계산용, Swift에서 굳이 안 써도 됨)


class LiveAnalysisMessage(BaseModel):
    status: Literal["no_person", "collecting", "analyzing"]
    buffered: Optional[int] = None          # status=collecting 일 때만
    exercise: Optional[str] = None          # status=analyzing 일 때만
    confidence: Optional[float] = None
    phase: Optional[str] = None             # "down" | "up" | "none"
    phase_label: Optional[str] = None       # 한글 라벨
    score: Optional[int] = None
    results: Optional[list[PoseCheckItem]] = None


class SessionSummary(BaseModel):
    """웹소켓 연결 종료 시 마지막으로 한 번 보내는 요약 메시지"""
    status: Literal["session_ended"] = "session_ended"
    exercise_name: Optional[str] = None
    duration_min: int
    avg_score: float
