import 'package:xitem/models/SpecialEvent.dart';

enum StateCode { bw, by, be, bb, hb, hh, he, mv, ni, nw, rp, sl, sn, st, sh, th }


class StateCodeConverter {
  static String getStateName(StateCode code) {
    switch (code) {
      case StateCode.bw:
        return "Baden-Württemberg";
      case StateCode.by:
        return "Bayern";
      case StateCode.be:
        return "Berlin";
      case StateCode.bb:
        return "Brandenburg";
      case StateCode.hb:
        return "Bremen";
      case StateCode.hh:
        return "Hamburg";
      case StateCode.he:
        return "Hessen";
      case StateCode.mv:
        return "Mecklenburg-Vorpommern";
      case StateCode.ni:
        return "Niedersachsen";
      case StateCode.nw:
        return "Nordrhein-Westfalen";
      case StateCode.rp:
        return "Rheinland-Pfalz";
      case StateCode.sl:
        return "Saarland";
      case StateCode.sn:
        return "Sachsen";
      case StateCode.st:
        return "Sachsen-Anhalt";
      case StateCode.sh:
        return "Schleswig-Holstein";
      case StateCode.th:
        return "Thüringen";
      default:
        return "Unbekannt";
    }
  }

  static String getStateCodeString(StateCode code) {
    return code.toString().substring(code.toString().indexOf('.') + 1).toUpperCase();
  }

  static StateCode getStateCode(String shortStateCode) {
    switch (shortStateCode) {
      case "BW":
        return StateCode.bw;
      case "BY":
        return StateCode.by;
      case "BE":
        return StateCode.be;
      case "BB":
        return StateCode.bb;
      case "HB":
        return StateCode.hb;
      case "HH":
        return StateCode.hh;
      case "HE":
        return StateCode.he;
      case "MV":
        return StateCode.mv;
      case "NI":
        return StateCode.ni;
      case "NW":
        return StateCode.nw;
      case "RP":
        return StateCode.rp;
      case "SL":
        return StateCode.sl;
      case "SN":
        return StateCode.sn;
      case "ST":
        return StateCode.st;
      case "SH":
        return StateCode.sh;
      case "TH":
        return StateCode.th;
      default:
        return StateCode.hh;
    }
  }
}
