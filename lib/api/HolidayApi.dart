import 'dart:convert';

import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/StateCodeConverter.dart';

class HolidayApi extends ApiGateway {
  Future<ApiResponse<List<PublicHoliday>>> loadHolidays(int year, StateCode stateCode) async {
    Response response = await sendRequest("/holidays/$year/${StateCodeConverter.getStateCodeString(stateCode)}", RequestType.get);

    if (response.statusCode != 200) {
      return ApiResponse(extractResponseCode(response));
    }

    Map<String, dynamic> data = jsonDecode(response.body);

    if (data.containsKey("Holidays")) {
      List<PublicHoliday> publicHolidays = <PublicHoliday>[];

      for (final publicHoliday in data["Holidays"]) {
        final String name = publicHoliday["name"].toString();
        final DateTime date = DateTime.parse(publicHoliday["date"]);

        PublicHoliday newPublicHoliday = PublicHoliday(name, date);
        publicHolidays.add(newPublicHoliday);
      }

      return ApiResponse(ResponseCode.success, publicHolidays);
    }

    return ApiResponse(ResponseCode.unknown);
  }
}