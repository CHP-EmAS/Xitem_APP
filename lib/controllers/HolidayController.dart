import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/api/HolidayApi.dart';
import 'package:xitem/main.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/StateCodeConverter.dart';

class HolidayController extends ApiGateway {

  HolidayController(this._holidayApi);

  final HolidayApi _holidayApi;

  final List<PublicHoliday> _loadedHolidays = <PublicHoliday>[];
  final List<PublicHoliday> _upcomingHolidays = <PublicHoliday>[];

  bool _isInitialized = false;
  StateCode _currentLoadedState = StateCode.hh;

  Future<ResponseCode> initialize() async {
    StateCode savedStateCode = Xitem.settingController.getHolidayStateCode();

    ResponseCode loadStateHolidays = await loadHolidays(savedStateCode);
    if(loadStateHolidays != ResponseCode.success) {
      return loadStateHolidays;
    }

    _isInitialized = true;
    return ResponseCode.success;
  }

  Future<ResponseCode> loadHolidays(StateCode stateCode) async {
    DateTime now = DateTime.now();

    //load last year
    ApiResponse<List<PublicHoliday>> loadHolidayLastYear = await _holidayApi.loadHolidays(now.year - 1, stateCode);
    List<PublicHoliday>? holidaysLastYear = loadHolidayLastYear.value;
    if (loadHolidayLastYear.code != ResponseCode.success) {
      return loadHolidayLastYear.code;
    } else if (holidaysLastYear == null) {
      return ResponseCode.unknown;
    }

    //load current year
    ApiResponse<List<PublicHoliday>> loadHolidayCurrentYear = await _holidayApi.loadHolidays(now.year, stateCode);
    List<PublicHoliday>? holidaysCurrentYear = loadHolidayCurrentYear.value;
    if (loadHolidayCurrentYear.code != ResponseCode.success) {
      return loadHolidayCurrentYear.code;
    } else if (holidaysCurrentYear == null) {
      return ResponseCode.unknown;
    }

    //load next year
    ApiResponse<List<PublicHoliday>> loadHolidayNextYear = await _holidayApi.loadHolidays(now.year + 1, stateCode);
    List<PublicHoliday>? holidaysNextYear = loadHolidayNextYear.value;
    if (loadHolidayNextYear.code != ResponseCode.success) {
      return loadHolidayNextYear.code;
    } else if (holidaysNextYear == null) {
      return ResponseCode.unknown;
    }

    _loadedHolidays.clear();
    _loadedHolidays.addAll(holidaysLastYear);
    _loadedHolidays.addAll(holidaysCurrentYear);
    _loadedHolidays.addAll(holidaysNextYear);
    _loadedHolidays.sort(holidaySorter);

    _upcomingHolidays.clear();
    _currentLoadedState = stateCode;

    for (var thisYearHoliday in holidaysCurrentYear) {
      if (thisYearHoliday.date.isAfter(DateTime(now.year, now.month, now.day - 1))) {
        _upcomingHolidays.add(thisYearHoliday);
      }
    }

    for (var nextYearHoliday in holidaysNextYear) {
      if (nextYearHoliday.date.isBefore(DateTime(now.year + 1, now.month, now.day + 1))) {
        _upcomingHolidays.add(nextYearHoliday);
      }
    }

    _upcomingHolidays.sort(holidaySorter);

    return ResponseCode.success;
  }

  StateCode currentLoadedState() {
    if(!_isInitialized) {
      throw AssertionError("HolidayController must be initialized before it can be accessed!");
    }

    return _currentLoadedState;
  }

  List<PublicHoliday> holidays() {
    if(!_isInitialized) {
      throw AssertionError("HolidayController must be initialized before it can be accessed!");
    }

    return _loadedHolidays;
  }

  List<PublicHoliday> upcomingHolidays() {
    if(!_isInitialized) {
      throw AssertionError("HolidayController must be initialized before it can be accessed!");
    }

    return _upcomingHolidays;
  }

  int holidaySorter(PublicHoliday a, PublicHoliday b) {
      if (a.date == b.date) {
        return 0;
      } else if (a.date.isAfter(b.date)) {
        return 1;
      } else {
        return -1;
      }
  }
}
