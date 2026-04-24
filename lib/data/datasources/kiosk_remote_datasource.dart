import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/api_client.dart';

/// Result returned by a successful PIN validation.
class KioskPinValidationResult {
  const KioskPinValidationResult({
    required this.employeeId,
    required this.employeeName,
  });

  final int employeeId;
  final String employeeName;

  factory KioskPinValidationResult.fromJson(Map<String, dynamic> json) =>
      KioskPinValidationResult(
        employeeId: json['employee_id'] as int? ?? 0,
        employeeName: (json['employee_name'] ?? json['full_name'] ?? '') as String,
      );
}

class KioskRemoteDatasource {
  const KioskRemoteDatasource(this._client);

  final ApiClient _client;

  /// Validates a kiosk PIN against the backend.
  ///
  /// TODO: Backend endpoint required — POST [ApiConstants.kioskValidatePin]
  ///   Request:  {"pin": "1234", "business_id": "<id>"}
  ///   Response: {"valid": true, "employee_id": 42, "employee_name": "Ana García"}
  ///             {"valid": false}  → throws [ValidationException]
  ///
  /// Throws [ValidationException] if the PIN is incorrect.
  /// Throws [NotFoundException] if the endpoint is not yet deployed.
  /// Throws [NetworkException] on connectivity issues.
  Future<KioskPinValidationResult> validatePin({
    required String pin,
    required String businessId,
  }) async {
    final data = await _client.post(
      ApiConstants.kioskValidatePin,
      body: {'pin': pin, 'business_id': businessId},
    ) as Map<String, dynamic>;

    final valid = data['valid'] as bool? ?? false;
    if (!valid) {
      throw const ValidationException('PIN incorrecto.');
    }
    return KioskPinValidationResult.fromJson(data);
  }
}
