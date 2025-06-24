// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  final String baseUrl;

  ApiService() : baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    // 상대방의 OCI 서버 공인 IP 주소입니다.
    const String OCI_SERVER_IP = '134.185.115.80';
    const String SERVER_PORT = '8080'; // Spring Boot의 기본 포트

    // 모든 플랫폼에서 OCI 서버의 공인 IP로 직접 접근하도록 설정합니다.
    return 'http://$OCI_SERVER_IP:$SERVER_PORT';
  }

  // --- 1. 최신 센서 데이터 조회 API 호출 (GET) ---
  // Spring Boot의 SensorDataController @GetMapping("/api/sensor/latest")와 연결
  Future<Map<String, dynamic>?> getLatestSensorData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sensor/latest'));
      if (response.statusCode == 200) {
        // 백엔드에서 받은 데이터에 recordedAt, lastWatered, lastLedOn, alertSoilDry, alertLightLow 등이 포함됨
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else if (response.statusCode == 204) {
        print('최신 센서 데이터 없음 (HTTP 204).');
        return null;
      } else {
        print('센서 데이터 조회 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('네트워크 요청 중 오류 발생: $e');
      return null;
    }
  }

  // --- 2. 센서 데이터 저장 API 호출 (POST) ---
  // Spring Boot의 SensorDataController @PostMapping("/api/sensor")와 연결
  Future<bool> sendSensorData({
    required String deviceId,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    double? npkN,
    double? npkP,
    double? npkK,
    // SensorDataDto에 추가된 필드들도 여기서 전달할 수 있습니다 (필요시)
    // DateTime? lastWatered, DateTime? lastLedOn, bool? alertSoilDry, bool? alertLightLow,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'deviceId': deviceId,
          'temperature': temperature,
          'humidity': humidity,
          'soilMoisture': soilMoisture,
          'npkN': npkN,
          'npkP': npkP,
          'npkK': npkK,
          // 'lastWatered': lastWatered?.toIso8601String(), // DateTime을 ISO 8601 문자열로
          // 'lastLedOn': lastLedOn?.toIso8601String(),
          // 'alertSoilDry': alertSoilDry,
          // 'alertLightLow': alertLightLow,
        }),
      );
      if (response.statusCode == 200) {
        print('센서 데이터 저장 성공! 서버 응답: ${response.body}');
        return true;
      } else {
        print('센서 데이터 저장 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('네트워크 요청 중 오류 발생: $e');
      return false;
    }
  }

  // --- 3. 모든 센서 기록 (캘린더 기록 포함) 가져오기 API 호출 (GET) ---
  // Spring Boot의 SensorDataController @GetMapping("/api/sensor/all")과 연결
  Future<List<Map<String, dynamic>>?> getAllPlantRecords() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sensor/all'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        print('캘린더 기록 조회 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('캘린더 기록 네트워크 오류 발생: $e');
      return null;
    }
  }

  // --- 4. 특정 날짜 센서 기록 (캘린더 기록 포함) 조회 API 호출 (GET) ---
  // Spring Boot의 SensorDataController @GetMapping("/api/sensor/{date}")와 연결
  Future<Map<String, dynamic>?> getPlantRecordByDate(String dateStr) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sensor/$dateStr'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else if (response.statusCode == 404) { // 데이터 없음
        print('특정 날짜 캘린더 기록 없음 (HTTP 404).');
        return null;
      } else {
        print('특정 날짜 캘린더 기록 조회 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('특정 날짜 캘린더 기록 네트워크 오류 발생: $e');
      return null;
    }
  }

  // --- 5. 식물 기록 추가/수정 API 호출 (POST) ---
  // Spring Boot의 SensorDataController @PostMapping("/api/sensor/record")와 연결
  Future<bool> savePlantRecord(String dateStr, String status, String notes, {String? diseaseName, String? diseaseImageUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor/record'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'recordedAt': dateStr + 'T00:00:00', // LocalDate를 LocalDateTime으로 변환하여 전송 (시간은 00:00:00)
          'status': status,
          'notes': notes,
          'diseaseName': diseaseName,
          'diseaseImageUrl': diseaseImageUrl,
          // deviceId, temperature 등 센서 필드는 이 API에서는 전송하지 않을 수 있습니다.
          // 백엔드에서 null 허용 또는 기본값 설정 필요.
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // 200 OK 또는 201 Created
        print('캘린더 기록 저장 성공! 서버 응답: ${response.body}');
        return true;
      } else {
        print('캘린더 기록 저장 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('캘린더 기록 네트워크 오류 발생: $e');
      return false;
    }
  }

  // --- 6. 수동 물 공급 명령 API 호출 (POST) ---
  // Spring Boot의 SensorDataController @PostMapping("/api/sensor/control/water")와 연결
  Future<bool> controlWater({required String deviceId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor/control/water?deviceId=$deviceId'), // 쿼리 파라미터로 deviceId 전달
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8', // JSON 형태는 아니지만, 편의상 추가
        },
        // body: json.encode({ 'deviceId': deviceId }), // @RequestParam 이므로 body 필요 없음
      );

      if (response.statusCode == 200) {
        print('물 공급 명령 성공! 서버 응답: ${response.body}');
        return true;
      } else {
        print('물 공급 명령 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('물 공급 명령 네트워크 오류 발생: $e');
      return false;
    }
  }

  // --- 7. 수동 LED 제어 명령 API 호출 (POST) ---
  // Spring Boot의 SensorDataController @PostMapping("/api/sensor/control/led")와 연결
  Future<bool> controlLed({required String deviceId, required bool state}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor/control/led?deviceId=$deviceId&state=$state'), // 쿼리 파라미터로 deviceId와 state 전달
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('LED 제어 명령 성공! 서버 응답: ${response.body}');
        return true;
      } else {
        print('LED 제어 명령 실패! 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('LED 제어 명령 네트워크 오류 발생: $e');
      return false;
    }
  }
}