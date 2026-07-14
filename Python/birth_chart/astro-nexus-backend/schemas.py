from pydantic import BaseModel, Field
from typing import Literal, Dict, List, Optional

# -------- INPUT SCHEMAS --------

from datetime import date
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Literal, Optional, Dict, List

# Swiss Ephemeris files bundled with this service (seas_18.se1 etc.) only
# cover a bounded historical range. Reject anything clearly outside a sane
# range for a living person's birth chart rather than let Swiss Ephemeris
# fail with a cryptic error deeper in the pipeline.
MIN_BIRTH_YEAR = 1900


class BirthDate(BaseModel):
    year: int = Field(..., example=2004)
    month: int = Field(..., example=3)
    day: int = Field(..., example=6)

    @field_validator("month")
    @classmethod
    def validate_month(cls, v):
        if not 1 <= v <= 12:
            raise ValueError("month must be between 1 and 12")
        return v

    @field_validator("day")
    @classmethod
    def validate_day_range(cls, v):
        # Coarse bound here; the real leap-year/month-length check happens
        # below once year and month are both available.
        if not 1 <= v <= 31:
            raise ValueError("day must be between 1 and 31")
        return v

    @field_validator("year")
    @classmethod
    def validate_year(cls, v):
        current_year = date.today().year
        if v < MIN_BIRTH_YEAR:
            raise ValueError(f"year must be {MIN_BIRTH_YEAR} or later")
        if v > current_year:
            raise ValueError("year cannot be in the future")
        return v

    @model_validator(mode="after")
    def validate_real_calendar_date(self):
        # This is what actually catches leap years and month-length
        # correctly (e.g. Feb 30, or Feb 29 in a non-leap year) instead of
        # us hand-rolling calendar math — Python's date constructor already
        # knows the rules and raises ValueError on anything invalid.
        try:
            resolved_date = date(self.year, self.month, self.day)
        except ValueError:
            raise ValueError(
                f"{self.year}-{self.month:02d}-{self.day:02d} is not a real calendar date"
            )

        if resolved_date > date.today():
            raise ValueError("birth date cannot be in the future")

        return self


class BirthTime(BaseModel):
    hour: int | str = Field(..., example=7)
    minute: int | str = Field(..., example="05")
    ampm: str

    @field_validator("hour", mode="before")
    @classmethod
    def normalize_hour(cls, v):
        v = int(v)
        # ampm is present, so this is a 12-hour clock — 0 isn't valid (that's
        # what 12 is for), and neither is anything above 12.
        if not 1 <= v <= 12:
            raise ValueError("hour must be between 1 and 12 (12-hour format)")
        return v

    @field_validator("minute", mode="before")
    @classmethod
    def normalize_minute(cls, v):
        v = int(v)
        if not 0 <= v <= 59:
            raise ValueError("minute must be between 0 and 59")
        return v

    @field_validator("ampm", mode="before")
    @classmethod
    def normalize_ampm(cls, v):
        v = v.upper()
        if v not in ("AM", "PM"):
            raise ValueError("ampm must be AM or PM")
        return v


class ChartRequest(BaseModel):
    name: str = Field(..., example="Madhav Nimbola")
    gender: Literal["male", "female"]
    birth_date: BirthDate
    birth_time: BirthTime
    place_of_birth: str = Field(..., example="Ujjain, Madhya Pradesh, India")
    astrology_type: Literal["vedic", "western"] = "vedic"
    ayanamsa: Literal["lahiri", "raman", "tropical"] = "lahiri"


# -------- OUTPUT SCHEMAS --------

class PlanetInfo(BaseModel):
    degree: float
    rasi: str
    rasi_lord: str
    nakshatra: Optional[str]
    nakshatra_lord: Optional[str]
    house: int
    retrograde: bool

class ChartResponse(BaseModel):
    name: str
    gender: str
    birth_date: str
    birth_time: str
    place_of_birth: str
    ayanamsa: str

    rashi: str                 # 👈 MOON SIGN
    nakshatra: str

    ascendant: Dict[str, str]

    planets: Dict[str, PlanetInfo]

    houses: Dict[str, Dict[str, List[str]]]
