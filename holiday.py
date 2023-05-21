import os
import json
from datetime import datetime, timedelta
from lunardate import LunarDate
import pytz

# 음력 날짜를 양력으로 변환하는 함수
def lunar_to_solar(year, month, day):
    lunar_date = LunarDate(year, month, day)
    return lunar_date.toSolarDate()


# 설날, 추석, 부처님 오신날의 음력 날짜 설정
lunar_holidays = {
    "설날": {"month": 1, "day": 1},
    "추석": {"month": 8, "day": 15},
    "부처님_오신날": {"month": 4, "day": 8},
}

# 양력 기준의 공휴일 설정
solar_holidays = {
    "신년": {"month": 1, "day": 1},
    "삼일절": {"month": 3, "day": 1},
    "어린이날": {"month": 5, "day": 5},
    "광복절": {"month": 8, "day": 15},
    "개천절": {"month": 10, "day": 3},
    "한글날": {"month": 10, "day": 9},
    "크리스마스": {"month": 12, "day": 25},
}

# 결과를 저장할 딕셔너리 생성
result = {}

# 2023년부터 2033년까지 반복
for year in range(2000, 2050):
    result[year] = {}

    # 음력 공휴일 처리
    for holiday_name, lunar_date in lunar_holidays.items():
        # 음력 날짜를 양력으로 변환
        solar_date = lunar_to_solar(year, lunar_date["month"], lunar_date["day"])

        # 전날과 다음날도 공휴일로 설정
        if holiday_name == "설날" or holiday_name == "추석":
            before_date = solar_date - timedelta(days=1)
            after_date = solar_date + timedelta(days=1)

            # 날짜를 문자열로 변환
            before_date_str = before_date.strftime("%Y-%m-%d")
            solar_date_str = solar_date.strftime("%Y-%m-%d")
            after_date_str = after_date.strftime("%Y-%m-%d")

            # 결과 딕셔너리에 추가
            result[year][before_date_str] = f"{holiday_name}_before"
            result[year][solar_date_str] = holiday_name
            result[year][after_date_str] = f"{holiday_name}_after"
        else:
            # 날짜를 문자열로 변환
            solar_date_str = solar_date.strftime("%Y-%m-%d")

            # 결과 딕셔너리에 추가
            result[year][solar_date_str] = holiday_name
    # 양력 공휴일 처리
    for holiday_name, solar_date in solar_holidays.items():
        holiday_date = datetime(year, solar_date["month"], solar_date["day"])

        # 날짜를 문자열로 변환
        holiday_date_str = holiday_date.strftime("%Y-%m-%d")

        # 결과 딕셔너리에 추가
        result[year][holiday_date_str] = holiday_name

    # 결과를 JSON 파일에 저장
    if not os.path.exists("holidays"):
        os.makedirs("holidays")

    with open(f"holidays/{year}.json", "w", encoding="utf-8") as f:
        json.dump(result[year], f, ensure_ascii=False, indent=4)

print("JSON 파일 저장 완료")
