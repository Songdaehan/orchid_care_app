import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화 보장
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(OrchidCareApp());
}

class OrchidCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orchid Care',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green[50],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
        home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 난초 관리 앱',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 4,
      ),
      body: Column(
        children: [
          // 카메라 영역 (크기 줄임)
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[100]!, Colors.green[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: Center(
                child: Icon(Icons.camera_alt_outlined, size: 100, color: Colors.green[800]),
              ),
            ),
          ),
          // 버튼 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlantDetailScreen()),
                    ),
                    icon: Icon(Icons.local_florist_outlined, color: Colors.white),
                    label: Text('내 식물 보기', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QrScanScreen()),
                    ),
                    icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: Text('QR 코드 등록', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20), // 너무 아래 붙는 것 방지
        ],
      ),
    );
  }
}


class QrScanScreen extends StatefulWidget {
  @override
  _QrScanScreenState createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  // 스캔한 코드를 저장해 중복 처리
  String? lastScannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR 코드 스캔')),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (barcodeCapture) {
              final barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null && code != lastScannedCode) {
                  lastScannedCode = code;  // 중복 방지 위해 마지막 코드 저장
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('QR 스캔 결과: $code')),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'QR 코드를 화면 중앙에 맞춰 주세요',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class PlantDetailScreen extends StatefulWidget {
  @override
  _PlantDetailScreenState createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  final String lastUpdated = DateFormat('HH:mm:ss').format(DateTime.now());
  final bool hasDisease = true;
  final String diseaseName = '탄저병';
  final String diseaseImageUrl = 'https://example.com/disease_spot.jpg';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0], // 후면 카메라
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 식물 정보',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(
              hasDisease ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: hasDisease ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('질병 상태'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hasDisease
                          ? '❗ 식물이 질병에 걸렸습니다.\n병명: $diseaseName'
                          : '✔ 현재 질병이 없습니다. 건강합니다!'),
                      SizedBox(height: 12),
                      if (hasDisease)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            diseaseImageUrl,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Text('사진을 불러올 수 없습니다.'),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('닫기'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
            tooltip: hasDisease ? '질병 정보 보기' : '건강 상태 보기',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 카메라 실시간 영상 영역 + 센서값 표시 (왼쪽 상단)
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : Center(child: CircularProgressIndicator()),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sensorRow('🌡️ 온도', '23°C', Colors.white),
                          sensorRow('💧 습도', '55%', Colors.white),
                          sensorRow('🌱 토양 습도', '28%', Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                    children: [
                      customButton(
                          context, '자동 관리 일정', Icons.schedule, AutoControlScreen()),
                      customButton(
                          context, '수동 제어', Icons.settings_remote, ManualControlScreen()),
                      customButton(
                          context, '현재 상태', Icons.info_outline, StatusScreen()),
                      customButton(
                          context, '캘린더', Icons.calendar_today, CalendarScreen()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sensorRow(String label, String value, Color textColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        Text(value, style: TextStyle(color: textColor)),
      ],
    ),
  );

  Widget customButton(BuildContext context, String label, IconData icon, Widget screen) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
class AutoControlScreen extends StatelessWidget {
  final DateTime nextWaterTime = DateTime.now().add(Duration(hours: 2));
  final int soilHumidity = 25; // 실제론 센서 데이터 연동
  final int lightLevel = 500;  // lux 단위 예시

  String getTimeLeft(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return '지금 관리 필요!';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours 시간 $minutes 분 남음';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('자동 관리 일정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '다음 물 공급까지: ${getTimeLeft(nextWaterTime)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green[900]),
            ),
            SizedBox(height: 20),

            _buildScheduleCard(
              icon: Icons.water_drop,
              iconColor: Colors.blueAccent,
              text: '💧 물 공급 예정: 6시 (토양 습도 30% 이하)',
            ),
            SizedBox(height: 10),
            Text('현재 토양 습도: $soilHumidity% ${soilHumidity < 30 ? '(관리 필요)' : '(적정)'}',
                style: TextStyle(fontSize: 16, color: soilHumidity < 30 ? Colors.red : Colors.green)),
            SizedBox(height: 20),

            _buildScheduleCard(
              icon: Icons.light_mode,
              iconColor: Colors.orangeAccent,
              text: '💡 LED 작동 예정: 9시 ~ 21시',
            ),
            SizedBox(height: 10),
            Text('빛 밝기 : 적당함',
                style: TextStyle(fontSize: 16, color: Colors.orange[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard({required IconData icon, required Color iconColor, required String text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ManualControlScreen extends StatefulWidget {
  @override
  _ManualControlScreenState createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  bool ledOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '수동 제어',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade900.withOpacity(0.4),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '현재 자동 스케줄',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '⏰ 6시 물 공급,  💡 LED 9시 ~ 21시',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green[900],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 90),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('물 공급 시작!')),
                );
              },
              icon: Icon(Icons.water_drop, color: Colors.white),
              label: Text(
                '물 공급 시작',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(220, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  ledOn = !ledOn;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ledOn ? 'LED 켜짐' : 'LED 꺼짐')),
                );
              },
              icon: Icon(
                ledOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: ledOn ? Colors.amber : Colors.grey[300],
              ),
              label: Text(
                ledOn ? 'LED 끄기' : 'LED 켜기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ledOn ? Colors.amber[700] : Colors.grey[200],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ledOn ? Colors.grey[850] : Colors.grey[700],
                minimumSize: Size(220, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusScreen extends StatelessWidget {
  // 예시 센서 데이터 - 실제 하드웨어 연동 시 데이터 바인딩 필요
  final double temperature = 24.5;  // 섭씨
  final double humidity = 60;       // %
  final double soilMoisture = 35;   // %
  final String lightLevel = "적당함"; // 빛 밝기 쉬운말 표현

  final DateTime lastWatered = DateTime.now().subtract(Duration(hours: 5));
  final DateTime lastLedOn = DateTime.now().subtract(Duration(hours: 2));

  final bool alertSoilDry = false;
  final bool alertLightLow = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현재 상태'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 요약 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '🌿 식물 상태',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '현재 완벽한 환경에서 생장 중!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 센서 데이터 카드
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '센서 데이터',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 20),

                    _sensorRow(Icons.thermostat, '온도', '${temperature.toStringAsFixed(1)}°C'),
                    Divider(),
                    _sensorRow(Icons.opacity, '습도', '${humidity.toStringAsFixed(0)}%'),
                    Divider(),
                    _sensorRow(Icons.grass, '토양 수분', '${soilMoisture.toStringAsFixed(0)}%'),
                    Divider(),
                    _sensorRow(Icons.wb_sunny, '빛 밝기', lightLevel),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 경고 및 알림 카드
            if (alertSoilDry || alertLightLow) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ 경고 알림',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      if (alertSoilDry)
                        Text('토양이 너무 건조합니다. 물을 주세요.',
                            style: TextStyle(fontSize: 16)),
                      if (alertLightLow)
                        Text('빛이 부족합니다. LED를 켜주세요.',
                            style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],

            // 최근 자동 관리 내역 카드
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 자동 관리 내역',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '💧 마지막 물 공급: ${_formatDateTime(lastWatered)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '💡 마지막 LED 켜짐: ${_formatDateTime(lastLedOn)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 관리 팁 카드
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.green[100],
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌱 오늘의 관리 팁',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '토양 수분이 30% 이하일 때 물을 주세요.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '빛 밝기가 적당하면 LED를 켜지 않아도 괜찮아요.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sensorRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700], size: 28),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(fontSize: 18, color: Colors.green[900]),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[900]),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // 예: 06월 10일 15:30
    return '${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // key를 DateTime이 아닌 yyyy-MM-dd 문자열로 관리
  Map<String, Map<String, dynamic>> records = {};

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('plant_records').get();

    final Map<String, Map<String, dynamic>> loaded = {};

    for (var doc in snapshot.docs) {
      final dateStr = doc.id; // Firestore 문서 ID가 yyyy-MM-dd 형식 가정
      loaded[dateStr] = doc.data();
    }

    setState(() {
      records = loaded;
    });
  }

  Future<Map<String, dynamic>?> _loadRecord(DateTime date) async {
    final doc = await FirebaseFirestore.instance
        .collection('plant_records')
        .doc(_formatDate(date))
        .get();

    if (doc.exists) return doc.data();
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final record = await _loadRecord(selectedDay);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${selectedDay.year}.${selectedDay.month}.${selectedDay.day} 기록'),
        content: Text(record != null
            ? '상태: ${record['status'] ?? '정보 없음'}\n메모: ${record['notes'] ?? ''}'
            : '기록이 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecordScreen(date: selectedDay),
                ),
              ).then((_) => _loadAllRecords());
            },
            child: Text('새로운 기록 추가 / 수정'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(DateTime date) {
    final dateStr = _formatDate(date);
    final record = records[dateStr];
    if (record == null) return SizedBox.shrink();

    String? status = record['status']?.toString().toLowerCase();

    if (status == '정상' || status == 'normal') {
      return Icon(Icons.circle, color: Colors.green, size: 10);
    } else if (status == '문제 발생' ||
        status == 'problem' ||
        status == '질병 있음' ||
        status == 'disease') {
      return Icon(Icons.circle, color: Colors.red, size: 10);
    }

    if (record['disease'] != null && record['disease'].toString().isNotEmpty) {
      return Icon(Icons.circle, color: Colors.red, size: 10);
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('캘린더 기록')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, _) {
                return _buildMarker(date);
              },
            ),
          ),
          SizedBox(height: 20),
          Text('🟢 정상    🔴 문제 발생 / 질병 있음'),
        ],
      ),
    );
  }
}

// 기록 추가/수정 스크린
class AddRecordScreen extends StatefulWidget {
  final DateTime date;
  AddRecordScreen({required this.date});

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _status;
  final List<String> _statusOptions = ['정상', '문제 발생'];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final doc = await FirebaseFirestore.instance
        .collection('plant_records')
        .doc(_formatDate(widget.date))
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _status = data['status'];
        _notesController.text = data['notes'] ?? '';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRecord() async {
    if (_status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태를 선택해주세요!')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('plant_records')
        .doc(_formatDate(widget.date))
        .set({
      'status': _status,
      'notes': _notesController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('기록 추가/수정')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('날짜: ${widget.date.year}.${widget.date.month}.${widget.date.day}'),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '상태'),
              value: _status,
              items: _statusOptions
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _status = value;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '메모',
                hintText: '예: 물을 주었음, LED 작동 등',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRecord,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}