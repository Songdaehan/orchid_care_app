import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 필요
import 'package:http/http.dart' as http; // HTTP 요청을 위해 필요
import 'dart:io'; // Platform.isAndroid 등을 위해 필요

// ApiService 클래스는 별도의 파일(lib/services/api_service.dart)에 있다고 가정하고 임포트합니다.
import 'package:orchid_care_app/services/api_service.dart'; // 프로젝트 이름에 맞춰 경로 확인 및 수정!

// ⭐ stomp_dart_client를 위한 import 문들 ⭐
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          SizedBox(height: 20),
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
                  lastScannedCode = code;
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

  Map<String, dynamic>? _sensorData;
  bool _isLoadingSensorData = true;
  String _lastUpdatedTime = '데이터 로딩 중...';

  final bool hasDisease = true;
  final String diseaseName = '탄저병';
  final String diseaseImageUrl = 'https://example.com/disease_spot.jpg';

  // stomp_dart_client 인스턴스
  late StompClient stompClient; // late 키워드 사용

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadSensorData(); // REST API를 통한 초기 데이터 로드 (WebSocket 연결 전 또는 실패 시 대비)
    _initStompClient(); // STOMP 클라이언트 초기화
  }

  @override
  void dispose() {
    stompClient.deactivate(); // 앱 종료 시 STOMP 연결 해제
    _cameraController?.dispose();
    super.dispose();
  }

  // 카메라 초기화 함수
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0], // 후면 카메라
        ResolutionPreset.medium, // 중간 해상도 설정
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // STOMP 클라이언트 초기화 함수
  void _initStompClient() {
    stompClient = StompClient(
      config: StompConfig.SockJS( // Spring Boot가 SockJS를 사용한다면 StompConfig.SockJS, 아니면 StompConfig.ws
        // 서버 IP와 WebSocket 엔드포인트를 정확히 입력하세요.
        // 상대방의 OCI 서버 IP: 134.185.115.80, 포트: 8080 가정
        // Spring Boot WebSocket 엔드포인트는 보통 '/ws-sensor'로 설정됩니다.
        url: 'http://134.185.115.80:8080/ws-sensor', // OCI 서버 IP, 포트, WebSocket 엔드포인트
        onConnect: (StompFrame frame) => _onStompConnect(frame), // 연결 성공 시 콜백
        onWebSocketError: (dynamic error) => print('WebSocket Error: $error'), // WebSocket 오류
        stompConnectHeaders: {'accept-version': '1.2'}, // STOMP CONNECT 헤더
      ),
    );
    stompClient.activate(); // STOMP 연결 활성화
  }

  // STOMP 연결 성공 시 호출될 콜백 함수
  void _onStompConnect(StompFrame frame) {
    print('STOMP Connected! Session: ${frame.headers['session']}');
    // 센서 데이터가 broadcast될 채널을 구독합니다.
    stompClient.subscribe(
      destination: '/topic/sensor', // Spring Boot에서 센서값을 broadcast할 채널
      callback: (StompFrame messageFrame) {
        if (messageFrame.body != null) {
          try {
            final data = jsonDecode(messageFrame.body!);
            print('Received STOMP message: $data');
            _updateSensorUI(data); // 화면에 실시간으로 센서값을 반영하는 함수 호출
          } catch (e) {
            print('STOMP message JSON parsing error: $e, Message: ${messageFrame.body}');
          }
        }
      },
    );
  }

  // UI에 센서값을 실시간 반영하는 함수
  void _updateSensorUI(Map<String, dynamic> data) {
    if (!mounted) return; // 위젯이 mounted 상태인지 확인
    setState(() {
      _sensorData = data;
      _isLoadingSensorData = false;

      if (_sensorData != null && _sensorData!['recordedAt'] != null) {
        try {
          final recordedTime = DateTime.parse(_sensorData!['recordedAt']);
          _lastUpdatedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(recordedTime);
        } catch (e) {
          _lastUpdatedTime = '시간 파싱 오류';
        }
      } else {
        _lastUpdatedTime = '데이터 없음';
      }
    });
  }

  Future<void> _loadSensorData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSensorData = true;
      _lastUpdatedTime = '로딩 중...';
    });

    final apiService = ApiService();
    final data = await apiService.getLatestSensorData();

    if (!mounted) return;
    setState(() {
      _sensorData = data;
      _isLoadingSensorData = false;
      if (_sensorData != null && _sensorData!['recordedAt'] != null) {
        try {
          final recordedTime = DateTime.parse(_sensorData!['recordedAt']);
          _lastUpdatedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(recordedTime);
        } catch (e) {
          _lastUpdatedTime = '시간 파싱 오류';
        }
      } else {
        _lastUpdatedTime = '데이터 없음';
      }
    });
  }

  void _sendSensorDataToBackend() async {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('센서 데이터 전송 중...'))
    );

    final apiService = ApiService();
    bool success = await apiService.sendSensorData(
      deviceId: 'TEST_ORCHID_001',
      temperature: 24.5,
      humidity: 60.2,
      soilMoisture: 35.8,
      npkN: 15.0,
      npkP: 10.0,
      npkK: 20.0,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('센서 데이터 백엔드 전송 성공!')),
      );
      // 데이터 전송 후 REST API로 즉시 업데이트 (WebSocket 문제 시 대비)
      _loadSensorData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('센서 데이터 백엔드 전송 실패! 네트워크 또는 서버 로그 확인!')),
      );
    }
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
            icon: Icon(Icons.cloud_upload_outlined, color: Colors.white),
            onPressed: _sendSensorDataToBackend,
            tooltip: '현재 센서 데이터 서버로 전송',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSensorData,
            tooltip: '센서 데이터 새로고침',
          ),
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
                      child: _isLoadingSensorData
                          ? CircularProgressIndicator(color: Colors.white)
                          : _sensorData == null
                          ? Text('센서 데이터 없음', style: TextStyle(color: Colors.white))
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sensorRow('🌡️ 온도', '${(_sensorData!['temperature'] as num?)?.toStringAsFixed(1) ?? '?'}°C', Colors.white),
                          sensorRow('💧 습도', '${(_sensorData!['humidity'] as num?)?.toStringAsFixed(1) ?? '?'}%', Colors.white),
                          sensorRow('🌱 토양 습도', '${(_sensorData!['soilMoisture'] as num?)?.toStringAsFixed(1) ?? '?'}%', Colors.white),
                          sensorRow('N', '${(_sensorData!['npkN'] as num?)?.toStringAsFixed(1) ?? '?'}', Colors.white),
                          sensorRow('P', '${(_sensorData!['npkP'] as num?)?.toStringAsFixed(1) ?? '?'}', Colors.white),
                          sensorRow('K', '${(_sensorData!['npkK'] as num?)?.toStringAsFixed(1) ?? '?'}', Colors.white),
                          SizedBox(height: 4),
                          Text('최신 업데이트: $_lastUpdatedTime', style: TextStyle(color: Colors.grey[300], fontSize: 10)),
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
                  context, '현재 상태', Icons.info_outline,
                  StatusScreen(
                    temperature: (_sensorData?['temperature'] as num?)?.toDouble() ?? 0.0,
                    humidity: (_sensorData?['humidity'] as num?)?.toDouble() ?? 0.0,
                    soilMoisture: (_sensorData?['soilMoisture'] as num?)?.toDouble() ?? 0.0,
                    lightLevel: '적당함', // 현재 백엔드 DTO에 lightLevel이 없다면 임시 고정값
                    // alertSoilDry와 alertLightLow 값을 전달합니다.
                    // _sensorData에 해당 필드가 있다면 그 값을 사용하고, 없다면 기본값(false)을 사용합니다.
                    alertSoilDry: _sensorData?['alertSoilDry'] ?? false,
                    alertLightLow: _sensorData?['alertLightLow'] ?? false,
                    // lastWatered와 lastLedOn도 백엔드에서 받아온 값을 전달합니다 (nullable 처리)
                    lastWatered: (_sensorData?['lastWatered'] != null) ? DateTime.parse(_sensorData!['lastWatered']) : null,
                    lastLedOn: (_sensorData?['lastLedOn'] != null) ? DateTime.parse(_sensorData!['lastLedOn']) : null,
                  )
              ),
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
  bool ledOn = false; // 현재 LED 상태

  // 물 공급 시작 버튼 액션
  void _startWatering() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('물 공급 명령 전송 중...')),
    );
    final apiService = ApiService();
    // 실제 deviceId를 사용해야 하지만, 현재는 테스트용으로 고정
    bool success = await apiService.controlWater(deviceId: 'ORCHID_CONTROL_001');

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('물 공급 명령 전송 완료.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('물 공급 명령 실패! 백엔드 로그 확인.')),
      );
    }
  }

  // LED 제어 버튼 액션
  void _toggleLed() async {
    // UI 상태는 명령 전송 성공 여부와 관계없이 즉시 토글하여 사용자에게 빠른 피드백 제공
    setState(() {
      ledOn = !ledOn;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('LED 명령 전송 중...')),
    );

    final apiService = ApiService();
    // 실제 deviceId를 사용해야 하지만, 현재는 테스트용으로 고정
    bool success = await apiService.controlLed(deviceId: 'ORCHID_CONTROL_001', state: ledOn);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ledOn ? 'LED 켜기 명령 성공!' : 'LED 끄기 명령 성공!')),
      );
    } else {
      // 명령 실패 시 UI 상태를 이전으로 되돌려 사용자에게 정확한 상태를 보여줌
      setState(() {
        ledOn = !ledOn; // UI 상태를 다시 되돌림
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('LED 명령 전송 실패! 백엔드 로그 확인.')),
      );
    }
  }

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
            // 수정된 부분: 단순 텍스트로 대체 (자동 스케줄 표시는 그대로 유지)
            Text(
              '현재 자동 스케줄',
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
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
              onPressed: _startWatering, // ✅ 함수 연결
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
              onPressed: _toggleLed, // ✅ 함수 연결
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
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final String lightLevel;
  // 새로 추가된 필드들: nullable로 받습니다.
  final DateTime? lastWatered;
  final DateTime? lastLedOn;
  final bool alertSoilDry;
  final bool alertLightLow;

  StatusScreen({
    Key? key,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    // 새로 추가된 필드들을 required가 아닌 named optional(선택적) 또는 nullable로 정의합니다.
    this.lastWatered,
    this.lastLedOn,
    required this.alertSoilDry,
    required this.alertLightLow,
  }) : super(key: key);

  // 이 필드들은 이제 생성자로 값을 받으므로, 여기서 초기화할 필요가 없습니다.
  // final DateTime lastWatered = DateTime.now().subtract(Duration(hours: 5));
  // final DateTime lastLedOn = DateTime.now().subtract(Duration(hours: 2));

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

            // 센서 데이터 카드 (기존 코드 유지)
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

                    // PlantDetailScreen에서 전달받은 값 사용
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

            // 경고 및 알림 카드 (데이터 연동)
            // alertSoilDry, alertLightLow 값을 전달받아 동적으로 표시
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

            // 최근 자동 관리 내역 카드 (데이터 연동)
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
                    // lastWatered 값을 전달받아 표시 (nullable 처리)
                    Text(
                      '💧 마지막 물 공급: ${(lastWatered != null) ? _formatDateTime(lastWatered!) : '기록 없음'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    // lastLedOn 값을 전달받아 표시 (nullable 처리)
                    Text(
                      '💡 마지막 LED 켜짐: ${(lastLedOn != null) ? _formatDateTime(lastLedOn!) : '기록 없음'}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 관리 팁 카드 (기존 코드 유지)
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

  // _sensorRow 함수는 이미 존재하므로 그대로 사용
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

  // _formatDateTime 함수는 이미 존재하므로 그대로 사용
  String _formatDateTime(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
// main.dart 파일 내 CalendarScreen 클래스
// main.dart 파일 내 CalendarScreen 클래스
class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, Map<String, dynamic>> records = {};

  @override
  void initState() {
    super.initState();
    _loadAllRecords(); // 캘린더 기록 로드 시작
  }

  Future<void> _loadAllRecords() async {
    final apiService = ApiService();
    final List<Map<String, dynamic>>? loadedList = await apiService.getAllPlantRecords();

    final Map<String, Map<String, dynamic>> newRecords = {};
    if (loadedList != null) {
      for (var record in loadedList) {
        // 백엔드 PlantRecordDto에서 'recordDate'가 LocalDate로 올 것
        final String? recordDateStr = record['recordDate']?.toString();
        if (recordDateStr != null && recordDateStr.length >= 10) {
          // 'YYYY-MM-DD' 형식 그대로 사용
          newRecords[recordDateStr] = record;
        }
      }
    }
    if (mounted) { // setState 호출 전 mounted 확인
      setState(() {
        records = newRecords;
      });
    }
  }

  // 특정 날짜의 기록을 백엔드에서 가져오는 함수 (getPlantRecordByDate 사용)
  Future<Map<String, dynamic>?> _loadRecord(DateTime date) async {
    final apiService = ApiService();
    final dateStr = _formatDate(date); // YYYY-MM-DD 형식
    final record = await apiService.getPlantRecordByDate(dateStr); // 특정 날짜 API 호출
    return record;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (mounted) { // setState 호출 전 mounted 확인
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }

    final record = await _loadRecord(selectedDay); // 선택된 날짜의 기록 로드

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${selectedDay.year}.${selectedDay.month}.${selectedDay.day} 기록'),
        content: Text(record != null && record!.isNotEmpty
            ? '상태: ${record!['status'] ?? '정보 없음'}\n메모: ${record!['notes'] ?? ''}\n${record!['diseaseName'] != null && record!['diseaseName'].isNotEmpty ? '병명: ${record!['diseaseName']}' : ''}'
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
                  builder: (_) => AddRecordScreen(date: selectedDay, initialRecord: record), // 기존 기록 전달
                ),
              ).then((_) => _loadAllRecords()); // 기록 추가/수정 후 캘린더 새로고침
            },
            child: Text('기록 추가 / 수정'),
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
    bool hasDiseaseInRecord = record['diseaseName'] != null && record['diseaseName'].toString().isNotEmpty;

    if (status == '정상' || status == 'normal') {
      return Icon(Icons.circle, color: Colors.green, size: 10);
    } else if (status == '문제 발생' || hasDiseaseInRecord) { // 문제 발생이거나 질병 정보가 있다면 빨간 마커
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
  final Map<String, dynamic>? initialRecord; // 기존 기록을 받을 필드 추가

  AddRecordScreen({required this.date, this.initialRecord}); // 생성자 수정

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _status;
  final List<String> _statusOptions = ['정상', '문제 발생'];
  final TextEditingController _diseaseNameController = TextEditingController(); // 질병명 입력 필드 추가
  final TextEditingController _diseaseImageUrlController = TextEditingController(); // 질병 이미지 URL 필드 추가


  @override
  void initState() {
    super.initState();
    // 기존 기록이 있다면 필드에 채워넣기
    if (widget.initialRecord != null && widget.initialRecord!.isNotEmpty) {
      _status = widget.initialRecord!['status'];
      _notesController.text = widget.initialRecord!['notes'] ?? '';
      _diseaseNameController.text = widget.initialRecord!['diseaseName'] ?? '';
      _diseaseImageUrlController.text = widget.initialRecord!['diseaseImageUrl'] ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _diseaseNameController.dispose();
    _diseaseImageUrlController.dispose();
    super.dispose();
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

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기록 저장 중...'))
    );

    final apiService = ApiService();
    bool success = await apiService.savePlantRecord(
      _formatDate(widget.date),
      _status!,
      _notesController.text,
      diseaseName: _diseaseNameController.text.isNotEmpty ? _diseaseNameController.text : null,
      diseaseImageUrl: _diseaseImageUrlController.text.isNotEmpty ? _diseaseImageUrlController.text : null,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 저장 성공!'))
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 저장 실패! 백엔드 API를 확인해주세요.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('기록 추가/수정')),
      body: SingleChildScrollView( // 스크롤 가능하도록 SingleChildScrollView 추가
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
            // 질병명 입력 필드 추가
            TextField(
              controller: _diseaseNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '질병명 (선택 사항)',
                hintText: '예: 탄저병',
              ),
            ),
            SizedBox(height: 20),
            // 질병 이미지 URL 입력 필드 추가
            TextField(
              controller: _diseaseImageUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '질병 이미지 URL (선택 사항)',
                hintText: '예: https://example.com/disease.jpg',
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