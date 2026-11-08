"""요청·응답 스키마 공통 베이스."""

from pydantic import BaseModel, ConfigDict


class RequestModel(BaseModel):
    """모든 요청 본문의 베이스.

    정의되지 않은 필드가 오면 422로 거절한다. 권한 필드(예: role)를 몰래 끼워 넣는
    요청을 막기 위해서다 (08-conventions S3).
    """

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
