import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

/// 전역 포인트 예시
int points = 120;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRecycle',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// ===============================
/// 1) 홈 화면
/// ===============================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoRecycle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          EcoParticipationSection(),
        ],
      ),
    );
  }
}

/// ===============================
/// 2) 홈 화면 파란 카드 UI
/// ===============================
class EcoParticipationSection extends StatelessWidget {
  const EcoParticipationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapView()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.blue, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "근처 친환경 활동 장소 확인하기",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "지도로 확인하기",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// 3) 지도 페이지(MapView)
/// ===============================
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  bool _showShopList = false;
  _Shop? _selectedShop;

  final List<_Shop> _shops = [
    _Shop(
      name: "보탬상점",
      address: "서울 중랑구 봉화산로22길 2 (중화동)",
      position: const LatLng(37.600, 127.095),
      description:
      "기후위기 시대에 발맞춰 동네 가까운 곳에서 제로웨이스트와 환경교육을 만날 수 있는 커뮤니티 플랫폼입니다.\n\n"
          "🌿 플라스틱으로 만든 제품은 거의 없으며, 천연수세미, 비건 주방비누, 대나무 칫솔, 다회용 화장솜 등 모두 친환경 물품입니다.\n"
          "📦 포장도 간소화되어 있으며, 집에서 가져온 용기에 원하는 만큼 담을 수 있는 리필세제도 판매합니다.\n"
          "🧴 주방세제, 섬유유연제, 세탁세제 3종류가 있으며, 미처 용기를 준비하지 못했다면 가게에서 구매 가능.",
      eventInfo:
      "🗓 매월 다양한 주제로 환경교육 진행: '면월경대 만들기', '쓰레기 줄이기 꿀팁 나누기', '양말목 변신' 등\n"
          "⏰ 운영시간: 월~토 12:00~20:00, 일요일·공휴일 휴무\n"
          "💬 류경기 중랑구청장: '지구와 마을과 살림에 보탬이 되는 보탬상점에 많이 방문해주시길 바랍니다. 환경보호와 제로웨이스트 문화를 확산시키겠습니다.'",
    ),

    _Shop(
      name: "보탬상점",
      address: "서울 중랑구 봉화산로22길 2 (중화동)",
      position: const LatLng(37.600, 127.095),
      description:
      "💚 제로웨이스트 & 친환경 커뮤니티 플랫폼\n"
          "🌿 플라스틱 없는 생활용품: 천연수세미, 비건 주방비누, 대나무 칫솔 등\n"
          "🧴 리필세제 판매: 주방세제, 섬유유연제, 세탁세제\n"
          "📦 포장 최소화, 용기 지참 가능",
      eventInfo:
      "🗓 환경교육 프로그램 진행\n"
          "예: 면월경대 만들기, 쓰레기 줄이기 꿀팁 나누기, 양말목 재활용\n"
          "⏰ 운영시간: 월~토 12:00~20:00, 일요일·공휴일 휴무",
    ),

    _Shop(
      name: "면목 에코센터",
      address: "서울 중랑구 면목동 200-1",
      position: const LatLng(37.5920, 127.0900),
      description:
      "재활용 교육 및 체험 공간.\n♻️ 재활용 분리, 업사이클링 체험 가능.\n🌱 지역 주민 환경 참여 독려.",
      eventInfo: "🗓 주말 친환경 캠페인 / 재활용 체험 활동",
    ),
    _Shop(
      name: "면목 그린스토어",
      address: "서울 중랑구 면목로 50",
      position: const LatLng(37.5950, 127.0950),
      description:
      "친환경 제품 판매 및 환경 교육 제공.\n🛒 제로웨이스트 제품, 친환경 생활용품 구비.\n🌿 환경 보호 교육 진행.",
      eventInfo: "🗓 친환경 DIY 워크숍 / 제품 체험 이벤트",
    ),
    _Shop(
      name: "면목 재활용카페",
      address: "서울 중랑구 면목길 77",
      position: const LatLng(37.5900, 127.0850),
      description:
      "커피와 함께하는 재활용 체험 공간.\n☕ 업사이클링 공예 체험 가능.\n♻️ 환경 보호 교육과 이벤트 운영.",
      eventInfo: "🗓 재활용 예술 체험 행사 / 친환경 카페 체험",
    ),
    _Shop(
      name: "굿윌스토어 강동첨단점",
      address: "서울 강동구 상일동 522",
      position: const LatLng(37.5550, 127.1700),
      description:
      "지역 주민 참여형 재활용 공간.\n📦 중고 물품 기부 및 판매.\n♻️ 재활용 및 나눔 실천.",
      eventInfo: "🗓 중고 물품 기부 캠페인 / 재활용 DIY 클래스",
    ),
  ];

  final CameraPosition _initialPosition =
  const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 12);

  /// 현재 위치 가져오기
  Future<void> _determinePosition() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      setState(() {
        _currentPosition = LatLng(p.latitude, p.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14),
      );
    } catch (_) {}
  }

  Set<Marker> _createMarkers() {
    return _shops.map((s) {
      final selected = _selectedShop?.name == s.name;

      return Marker(
        markerId: MarkerId(s.name),
        position: s.position,
        infoWindow: InfoWindow(title: s.name, snippet: s.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  void _onSelect(_Shop s) {
    setState(() => _selectedShop = s);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(s.position, 15),
    );

    // 모달로 상세 정보 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.38,
        minChildSize: 0.2,
        maxChildSize: 0.85,
        builder: (_, controller) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.description,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.eventInfo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("친환경 참여 공간"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          /// 지도 영역
          SizedBox(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _createMarkers(),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          const SizedBox(height: 10),

          /// 메뉴 버튼 2개
          Row(
            children: [
              Expanded(
                child: _menuButton(
                  icon: Icons.my_location,
                  text: "현재 위치",
                  onTap: _determinePosition,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _menuButton(
                  icon: Icons.store,
                  text: "주변 친환경 가게",
                  onTap: () =>
                      setState(() => _showShopList = !_showShopList),
                ),
              ),
            ],
          ),

          /// 주변 가게 목록 (가로 스크롤)
          if (_showShopList)
            SizedBox(
              height: 150,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                scrollDirection: Axis.horizontal,
                itemCount: _shops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final shop = _shops[i];
                  return GestureDetector(
                    onTap: () => _onSelect(shop),
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedShop?.name == shop.name
                            ? Colors.green.shade600
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 3,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _selectedShop?.name == shop.name
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop.address,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedShop?.name == shop.name
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 20),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// 4) Shop 데이터 모델
/// ===============================
class _Shop {
  final String name;
  final String address;
  final String description;
  final String eventInfo;
  final LatLng position;

  _Shop({
    required this.name,
    required this.address,
    required this.description,
    required this.eventInfo,
    required this.position,
  });
}
