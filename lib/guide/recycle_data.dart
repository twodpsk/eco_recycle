import 'package:flutter/material.dart';
// [중요] 귀여운 아이콘 패키지 import
import 'package:material_symbols_icons/symbols.dart';
import 'recycle_model.dart';

final List<RecycleGuide> recycleData = [
  // 1. 플라스틱
  RecycleGuide(
    id: 'plastic',
    title: '플라스틱류',
    subTitle: '내용물은 비우고, 라벨은 떼고!',
    themeColor: Colors.blueAccent,
    // [변경] 물병 모양 아이콘 (둥글고 꽉 찬 스타일)
    icon: Symbols.water_bottle_rounded,
    steps: ['내용물 비우기', '이물질 헹구기', '라벨/뚜껑 분리', '압축하여 배출'],
    possibleItems: [
      RecycleItem(name: '투명 페트병', description: '라벨 제거 후 찌그러트리기'),
      RecycleItem(name: '샴푸/세제 용기', description: '펌프는 일반쓰레기로 분리'),
      RecycleItem(name: '플라스틱 컵', description: '음료 제거 후 깨끗이 세척'),
    ],
    impossibleItems: [
      RecycleItem(name: '칫솔', description: '여러 재질 혼합 (일반쓰레기)'),
      RecycleItem(name: '장난감/문구류', description: '플라스틱 외 성분 포함'),
      RecycleItem(name: '음식물 묻은 용기', description: '고추기름 등 얼룩이 남은 것'),
    ],
  ),

  // 2. 종이류
  RecycleGuide(
    id: 'paper',
    title: '종이류',
    subTitle: '젖지 않게, 코팅된 건 제외하고!',
    themeColor: const Color(0xFFD4A373),
    // [변경] 신문지 모양 아이콘
    icon: Symbols.newspaper_rounded,
    steps: ['테이프 제거', '철심/스프링 제거', '납작하게 펼치기', '물기 주의'],
    possibleItems: [
      RecycleItem(name: '신문지/책', description: '스프링 노트는 스프링 제거'),
      RecycleItem(name: '택배 박스', description: '송장/테이프 제거 필수'),
      RecycleItem(name: '종이컵', description: '내용물 비우고 물로 헹구기'),
    ],
    impossibleItems: [
      RecycleItem(name: '영수증', description: '감열지(화학품)라 재활용 불가'),
      RecycleItem(name: '기름 묻은 박스', description: '오염 부위는 찢어서 일반쓰레기'),
      RecycleItem(name: '코팅 전단지', description: '비닐 코팅막 때문에 불가'),
    ],
  ),

  // 3. 유리/캔
  RecycleGuide(
    id: 'glass_can',
    title: '유리병·캔류',
    subTitle: '깨지지 않게 조심! 이물질은 쏙!',
    themeColor: Colors.teal,
    // [변경] 유리잔 모양 아이콘
    icon: Symbols.glass_cup_rounded,
    steps: ['담배꽁초 등 이물질 X', '내용물 헹구기', '뚜껑 별도 배출', '파손 주의'],
    possibleItems: [
      RecycleItem(name: '음료수/맥주병', description: '내용물 비우고 뚜껑 제거'),
      RecycleItem(name: '참치캔/통조림', description: '기름기 제거 필수'),
      RecycleItem(name: '부탄가스', description: '구멍 뚫어 가스 제거'),
    ],
    impossibleItems: [
      RecycleItem(name: '깨진 유리', description: '신문지에 싸서 종량제 봉투'),
      RecycleItem(name: '거울/전구', description: '특수 폐기물/불연성 봉투'),
      RecycleItem(name: '도자기/사기그릇', description: '유리병과 녹는점 다름'),
    ],
  ),

  // 4. 비닐류 (데이터 추가 예시)
  RecycleGuide(
    id: 'vinyl',
    title: '비닐류',
    subTitle: '깨끗한 비닐만 모아서!',
    themeColor: Colors.purpleAccent,
    // [변경] 쇼핑백 모양 아이콘
    icon: Symbols.shopping_bag_rounded,
    steps: ['이물질 제거', '물기 제거', '흩날리지 않게', '봉투에 담기'],
    possibleItems: [
      RecycleItem(name: '깨끗한 비닐', description: '투명/불투명 봉투'),
      RecycleItem(name: '뽁뽁이', description: '에어캡도 비닐류'),
    ],
    impossibleItems: [
      RecycleItem(name: '음식물 묻은 비닐', description: '일반쓰레기'),
      RecycleItem(name: '스티커 붙은 비닐', description: '제거 안 되면 일반쓰레기'),
    ],
  ),

  // 5. 일반쓰레기
  RecycleGuide(
    id: 'trash',
    title: '일반쓰레기',
    subTitle: '재활용 안 되는 건 여기로!',
    themeColor: Colors.grey,
    // [변경] 쓰레기통 모양 아이콘
    icon: Symbols.delete_rounded,
    steps: ['종량제 봉투', '물기 제거', '날카로운 것 주의', '꽉 묶어서'],
    possibleItems: [
      RecycleItem(name: '휴지/물티슈', description: '재활용 절대 불가'),
      RecycleItem(name: '기저귀/생리대', description: '위생상 일반쓰레기'),
    ],
    impossibleItems: [
      RecycleItem(name: '건전지', description: '전용 수거함 배출'),
      RecycleItem(name: '형광등', description: '전용 수거함 배출'),
    ],
  ),
];