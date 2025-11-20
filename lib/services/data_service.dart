import 'package:nairaflow/models/data_plan.dart';
import 'package:nairaflow/models/transaction.dart';
import 'package:nairaflow/services/api_service.dart';

class DataService {
  /// Fetch available data plans for a specific network
  /// This calls your backend which calls VTpass service-variations API
  static Future<List<DataPlan>> fetchDataPlans(NetworkProvider network) async {
    try {
      final networkName = network.name.toLowerCase();
      
      // Call your backend endpoint
      // Backend should call: GET https://vtpass.com/api/service-variations?serviceID=mtn-data
      final response = await ApiService.get('/data/plans?network=$networkName');
      
      print('📦 Data plans response: ${response.data}'); // Debug log
      
      if (response.data['success'] == true) {
        final plansData = response.data['plans'] as List<dynamic>? ?? 
                          response.data['variations'] as List<dynamic>? ?? 
                          response.data['data'] as List<dynamic>? ??
                          [];
        
        print('📋 Found ${plansData.length} plans'); // Debug log
        
        final plans = plansData
            .map((json) {
              print('💰 Plan data: $json'); // Debug log
              return DataPlan.fromJson(json as Map<String, dynamic>);
            })
            .toList();
            
        print('✅ Parsed ${plans.length} plans successfully'); // Debug log
        return plans;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch data plans');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e'); // Debug log
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      
      // If already formatted error, rethrow
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      
      throw Exception('Failed to load data plans: ${e.toString()}');
    }
  }
}
