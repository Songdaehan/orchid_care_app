import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
        title: Text('내 난초 관리 앱', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 3,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: Center(
                child: Icon(Icons.camera_alt_outlined, size: 120, color: Colors.green[700]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlantDetailScreen()),
                    ),
                    icon: Icon(Icons.local_florist_outlined),
                    label: Text('내 식물 보기'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QrScanScreen()),
                    ),
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('QR 코드 등록'),
                  ),
                ),
              ],
            ),
          ),
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
class PlantDetailScreen extends StatelessWidget {
  final String lastUpdated = DateFormat('HH:mm:ss').format(DateTime.now());

  // 예시로 질병 여부, 병명, 병변 사진 URL 변수 추가
  final bool hasDisease = true;  // 임시: 질병 있음 여부
  final String diseaseName = '탄저병';
  final String diseaseImageUrl = 'https://example.com/disease_spot.jpg'; // 실제 사진 URL이나 AssetImage 써도 됨

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 식물 정보'),
        actions: [
          IconButton(
            icon: Icon(
              hasDisease ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: hasDisease ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              // 클릭 시 다이얼로그 띄우기
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
              color: Colors.green[100],
              child: Center(child: Icon(Icons.videocam, size: 100)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  sensorRow('온도', '23°C'),
                  sensorRow('습도', '55%'),
                  sensorRow('토양 습도', '28%'),
                  Text('업데이트: $lastUpdated'),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AutoControlScreen()),
                        ),
                        child: Text('자동 관리 일정'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManualControlScreen()),
                        ),
                        child: Text('수동 제어'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StatusScreen()),
                        ),
                        child: Text('현재 상태'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CalendarScreen()),
                        ),
                        child: Text('캘린더'),
                      ),
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

  Widget sensorRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );
}

class AutoControlScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('자동 관리 일정')),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blueAccent),
                SizedBox(width: 10),
                Expanded(child: Text('💧 물 공급 예정: 6시 (토양 습도 30% 이하)', style: TextStyle(fontSize: 18))),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.light_mode, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Expanded(child: Text('💡 LED 작동 예정: 9시 ~ 21시', style: TextStyle(fontSize: 18))),
              ],
            ),
          ],
        ),
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
      appBar: AppBar(title: Text('수동 제어')),
      body: Padding(
        padding: EdgeInsets.all(26.0),
        child: Column(
          children: [
            Text(
              '현재 자동 스케줄: 6시 물공급, LED 9~21시',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('물 공급 시작!')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(140, 48), // 버튼 크기 고정
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row가 자식 크기만큼만 차지하도록
                mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                children: [
                  Icon(Icons.water_drop),
                  SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                  Text(
                    '물 공급 시작',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ledOn = !ledOn;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ledOn ? 'LED 켜짐' : 'LED 꺼짐')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(140, 48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ledOn ? Icons.lightbulb : Icons.lightbulb_outline),
                  SizedBox(width: 8),
                  Text(
                    ledOn ? 'LED 끄기' : 'LED 켜기',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class StatusScreen extends StatelessWidget {
  final String statusMessage = '현재 완벽한 환경에서 생장 중!';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('현재 상태')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            statusMessage,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.green[700]),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
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