# AI분리수거

<!-- 한 줄에 4개 이미지, 크기 작게 -->
<div style="display: flex; justify-content: center; gap: 10px; flex-wrap: nowrap; overflow-x: auto;">
  <img src="https://github.com/user-attachments/assets/ebb9f7c6-4025-40dc-b991-a1a89b82b49f" width="180" alt="이미지1" />
  <img src="https://github.com/user-attachments/assets/d6de90bd-79ea-494c-974e-ec752f9d4002" width="180" alt="이미지2" />
  <img src="https://github.com/user-attachments/assets/54769263-e853-494e-997e-a1d1acd50bff" width="178" alt="이미지3" />
  <img src="https://github.com/user-attachments/assets/dbe0027b-9c2f-427c-b332-60ae346696de" width="175.5" alt="이미지4" />
</div>


## 문제의식
한국 내 분리배출 규칙에 대한 인식 부족과 실제 재활용률 저조 문제 인식함.  
사람들이 분리배출 규칙을 잘 모르거나 헷갈려 재활용이 제대로 이루어지지 않음에 따라 환경 오염 발생함.  
선별시설의 비효율성과 폐플라스틱 증가가 환경 문제 악화 요인임.

- **출처**: [KoreaScience](https://www.koreascience.or.kr/article/JAKO202209542000695.pdf?utm_source=chatgpt.com), [해피캠퍼스](https://www.happycampus.com/paper-doc/32470884/?utm_source=chatgpt.com)

## 앱 소개
Flutter 기반 모바일 앱 개발 및 TensorFlow Lite 기반 이미지 분류 모델 적용을 통한 재활용 품목 자동 분류 기능 구현함.  
플라스틱·종이·캔 등 재활용 품목 분류 시 사용자의 올바른 분리배출 시 포인트 부여 및 포인트에 따른 식물 성장 시스템 적용함.

## 주요 기능
- **이미지 분류 기능 제공**: 사용자가 촬영한 이미지의 AI 분석을 통한 재활용 품목 분류 기능 제공함.  
- **식물 성장 시스템 도입**: 올바른 분리배출 시 포인트 적립, 포인트 기반 식물 성장 시스템 도입함.  
- **지역별 배출 규칙 제공**: 사용자의 지역별 분리배출 규칙 조회 기능 제공함.  
- **게임화 요소 적용**: 포인트 및 보상 시스템 도입을 통한 사용자 참여 유도 기능 제공함.

## 기술 스택
- **Flutter** 사용함 (앱 UI 및 크로스플랫폼 개발용)  
- **TensorFlow Lite** 사용함 (모바일 경량화된 이미지 분류 모델 적용용)  
- **Dart** 사용함 (Flutter 코어 언어)  
- **Python** 사용함 (TensorFlow 기반 모델 훈련용)  
- **Firebase** 사용함 (사용자 데이터 및 앱 상태 관리용)

/////////////////////////////////////////진행중/계획//////////////////////////////////////////////////////////

### 1. 학급 및 학교 단위 경쟁 시스템
- 학급별·학교별 분리수거 실천 점수 경쟁 시스템 개발
- 기업·교육청·학교 연계 보상 시스템 기획
- 점수·랭킹·배지 시스템 설계

### 2. 가정 연계 분리수거 인증
- 학생 개인 폰 연동을 통한 가정 내 분리수거 사진 업로드 기능 구현
- 업로드 사진 기반 학습 포인트 산정 기능 개발
- 인증 기록의 학습 진도 및 실천 성과 반영 기능 설계

### 3. 환경 센터 지도 연동
- Google Maps API 연동을 통한 환경 관련 센터(아름다운 가게 등) 위치 마커 표시 기능 구현
- 센터 리스트 기능 및 방문/기부 시 포인트 연동 기능 설계

### 4. 카메라 기반 AI 분류 모델 구축
- 분리수거 촬영 이미지 기반 재질(플라스틱·캔·종이·유리·일반쓰레기) 자동 판별 모델 개발 계획
- 학습 데이터 수집 및 라벨링 파이프라인 구축 계획
- 모델 성능 모니터링 및 지속적 개선 프로세스 설계

### 5. 디자인 및 UX 개선


