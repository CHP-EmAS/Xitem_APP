import 'package:de/controllers/ApiController.dart';
import 'package:de/controllers/SettingController.dart';

class HolidayController {
  static List<PublicHoliday> loadedHolidays = new List<PublicHoliday>();
  static StateCode currentLoadedState = StateCode.BE;

  static Future<bool> loadPublicHolidays() async {
    StateCode stateCode = await SettingController.getHolidayStateCode();

    DateTime now = DateTime.now();

    final List<PublicHoliday> thisYearHolidays = await Api.loadHolidays(now.year, stateCode);
    final List<PublicHoliday> nextYearHolidays = await Api.loadHolidays(now.year + 1, stateCode);

    if (thisYearHolidays == null || nextYearHolidays == null) {
      print("Cannot load Holidays!");
      return false;
    }

    loadedHolidays.clear();
    currentLoadedState = stateCode;

    thisYearHolidays.forEach((thisYearHoliday) {
      if (thisYearHoliday.date.isAfter(DateTime(now.year, now.month, now.day - 1))) {
        loadedHolidays.add(thisYearHoliday);
      }
    });

    nextYearHolidays.forEach((nextYearHoliday) {
      if (nextYearHoliday.date.isBefore(DateTime(now.year + 1, now.month, now.day + 1))) {
        loadedHolidays.add(nextYearHoliday);
      }
    });

    loadedHolidays.sort((entryA, entryB) {
      if (entryA.date == entryB.date)
        return 0;
      else if (entryA.date.isAfter(entryB.date))
        return 1;
      else
        return -1;
    });

    return true;
  }

  static String getStateName(StateCode code) {
    switch (code) {
      case StateCode.BW:
        return "Baden-Württemberg";
        break;
      case StateCode.BY:
        return "Bayern";
        break;
      case StateCode.BE:
        return "Berlin";
        break;
      case StateCode.BB:
        return "Brandenburg";
        break;
      case StateCode.HB:
        return "Bremen";
        break;
      case StateCode.HH:
        return "Hamburg";
        break;
      case StateCode.HE:
        return "Hessen";
        break;
      case StateCode.MV:
        return "Mecklenburg-Vorpommern";
        break;
      case StateCode.NI:
        return "Niedersachsen";
        break;
      case StateCode.NW:
        return "Nordrhein-Westfalen";
        break;
      case StateCode.RP:
        return "Rheinland-Pfalz";
        break;
      case StateCode.SL:
        return "Saarland";
        break;
      case StateCode.SN:
        return "Sachsen";
        break;
      case StateCode.ST:
        return "Sachsen-Anhalt";
        break;
      case StateCode.SH:
        return "Schleswig-Holstein";
        break;
      case StateCode.TH:
        return "Thueringen";
        break;
      default:
        return "Unbekannt";
    }
  }

  static String getStateCode(StateCode code) {
    return code.toString().substring(code.toString().indexOf('.') + 1);
  }
}

enum StateCode { BW, BY, BE, BB, HB, HH, HE, MV, NI, NW, RP, SL, SN, ST, SH, TH }

class PublicHoliday {
  PublicHoliday(this.name, this.date);

  final String name;
  final DateTime date;
}
