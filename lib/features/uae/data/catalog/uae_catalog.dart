import 'dart:math';

import 'package:rihla/features/uae/domain/entities/uae_driving_rule.dart';
import 'package:rihla/features/uae/domain/entities/uae_holiday_traffic.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/uae/domain/entities/uae_speed_camera.dart';
import 'package:rihla/features/uae/domain/entities/uae_toll_gate.dart';

/// Static UAE intelligence catalog (Salik, cameras, services, emergency).
abstract final class UaeCatalog {
  static const salikGates = [
    UaeTollGate(
      id: 'salik_al_garhoud',
      name: 'Al Garhoud Bridge',
      latitude: 25.2401,
      longitude: 55.3522,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_al_maktoum',
      name: 'Al Maktoum Bridge',
      latitude: 25.2633,
      longitude: 55.3208,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_al_safa',
      name: 'Al Safa',
      latitude: 25.1965,
      longitude: 55.2601,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_al_barsha',
      name: 'Al Barsha',
      latitude: 25.1102,
      longitude: 55.2003,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_airport_tunnel',
      name: 'Airport Tunnel',
      latitude: 25.2528,
      longitude: 55.3654,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_mamzar',
      name: 'Al Mamzar South',
      latitude: 25.2831,
      longitude: 55.3542,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_mamzar_north',
      name: 'Al Mamzar North',
      latitude: 25.2918,
      longitude: 55.3528,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_jebel_ali',
      name: 'Jebel Ali',
      latitude: 24.9854,
      longitude: 55.0915,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_al_safa_north',
      name: 'Al Safa North',
      latitude: 25.1784,
      longitude: 55.2468,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_business_bay_crossing',
      name: 'Business Bay Crossing',
      latitude: 25.2304,
      longitude: 55.3336,
      region: UaeRegion.dubai,
    ),
    UaeTollGate(
      id: 'salik_al_yalayis',
      name: 'Al Yalayis',
      latitude: 24.9306,
      longitude: 55.1710,
      region: UaeRegion.dubai,
    ),
  ];

  static const speedCameras = [
    UaeSpeedCamera(
      id: 'cam_sheikh_zayed_fixed',
      name: 'Sheikh Zayed Road',
      latitude: 25.2048,
      longitude: 55.2708,
      type: UaeCameraType.fixed,
      speedLimitKmh: 100,
    ),
    UaeSpeedCamera(
      id: 'cam_e311_average',
      name: 'E311 Average Speed Zone',
      latitude: 25.1120,
      longitude: 55.1980,
      type: UaeCameraType.averageSpeed,
      speedLimitKmh: 120,
      zoneLengthKm: 8.0,
    ),
    UaeSpeedCamera(
      id: 'cam_jumeirah_redlight',
      name: 'Jumeirah Beach Road',
      latitude: 25.1972,
      longitude: 55.2394,
      type: UaeCameraType.redLight,
      speedLimitKmh: 60,
    ),
    UaeSpeedCamera(
      id: 'cam_school_al_quoz',
      name: 'Al Quoz School Zone',
      latitude: 25.1420,
      longitude: 55.2310,
      type: UaeCameraType.schoolZone,
      speedLimitKmh: 40,
    ),
    UaeSpeedCamera(
      id: 'cam_abu_dhabi_fixed',
      name: 'Sheikh Khalifa Highway',
      latitude: 24.4539,
      longitude: 54.3773,
      type: UaeCameraType.fixed,
      speedLimitKmh: 120,
    ),
  ];

  static const drivingRules = [
    UaeDrivingRule(
      id: 'rule_seatbelt',
      title: 'Seat belt required',
      description:
          'All passengers must wear seat belts. Front and rear seat belt use is mandatory in the UAE.',
      category: 'safety',
    ),
    UaeDrivingRule(
      id: 'rule_phone',
      title: 'No handheld phone use',
      description:
          'Using a mobile phone while driving is prohibited unless using hands-free. Fines apply.',
      category: 'distraction',
    ),
    UaeDrivingRule(
      id: 'rule_school_zone',
      title: 'School zone speed limits',
      description:
          'Reduce speed to 40 km/h in school zones during active hours. Watch for children.',
      category: 'school',
      conditions: ['school_zone'],
    ),
    UaeDrivingRule(
      id: 'rule_emergency_yield',
      title: 'Yield to emergency vehicles',
      description:
          'Move to the right and slow down when emergency vehicles approach with lights/sirens.',
      category: 'emergency',
    ),
    UaeDrivingRule(
      id: 'rule_fog',
      title: 'Fog driving guidance',
      description:
          'Use low beams, reduce speed significantly, increase following distance. Do not use hazard lights while moving unless stopped.',
      category: 'weather',
      conditions: ['fog'],
    ),
    UaeDrivingRule(
      id: 'rule_rain',
      title: 'Rain driving guidance',
      description:
          'Roads become slippery after first rain. Reduce speed, avoid sudden braking, and increase following distance.',
      category: 'weather',
      conditions: ['rain'],
    ),
    UaeDrivingRule(
      id: 'rule_desert',
      title: 'Desert driving guidance',
      description:
          'Check tire pressure, carry water, inform someone of your route. Avoid driving on sand without a 4x4.',
      category: 'desert',
      conditions: ['desert_road'],
    ),
  ];

  static const regionalServices = [
    UaeRegionalService(
      id: 'adnoc_dubai_marina',
      name: 'ADNOC Dubai Marina',
      category: 'fuel_adnoc',
      latitude: 25.0805,
      longitude: 55.1403,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'enoc_business_bay',
      name: 'ENOC Business Bay',
      category: 'fuel_enoc',
      latitude: 25.1850,
      longitude: 55.2650,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'emarat_jlt',
      name: 'Emarat JLT',
      category: 'fuel_emarat',
      latitude: 25.0697,
      longitude: 55.1420,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'ev_dewa_green',
      name: 'DEWA EV Green Charger',
      category: 'ev_charging',
      latitude: 25.2048,
      longitude: 55.2708,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'hospital_rashid',
      name: 'Rashid Hospital',
      category: 'hospital_government',
      latitude: 25.2580,
      longitude: 55.3160,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'police_dubai_hq',
      name: 'Dubai Police HQ',
      category: 'police',
      latitude: 25.2740,
      longitude: 55.3100,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'civil_defence_dubai',
      name: 'Dubai Civil Defence',
      category: 'civil_defence',
      latitude: 25.2285,
      longitude: 55.3270,
      distanceKm: 0,
    ),
    UaeRegionalService(
      id: 'parking_dubai_mall',
      name: 'Dubai Mall Parking',
      category: 'public_parking',
      latitude: 25.1972,
      longitude: 55.2790,
      distanceKm: 0,
    ),
  ];

  static List<UaeEmergencyContact> emergencyDirectory(UaeRegion region) => [
    const UaeEmergencyContact(
      id: 'em_police',
      name: 'Police',
      number: '999',
      category: 'police',
    ),
    const UaeEmergencyContact(
      id: 'em_ambulance',
      name: 'Ambulance',
      number: '998',
      category: 'ambulance',
    ),
    const UaeEmergencyContact(
      id: 'em_fire',
      name: 'Fire / Civil Defence',
      number: '997',
      category: 'fire',
    ),
    UaeEmergencyContact(
      id: 'em_roadside',
      name: 'Roadside Assistance',
      number: '800 4357',
      category: 'roadside',
      region: region,
    ),
    const UaeEmergencyContact(
      id: 'em_poison',
      name: 'Poison Information',
      number: '800 424',
      category: 'poison',
    ),
    const UaeEmergencyContact(
      id: 'em_coast_guard',
      name: 'Coast Guard',
      number: '996',
      category: 'coast_guard',
    ),
    UaeEmergencyContact(
      id: 'em_rta',
      name: 'Road Authority (RTA)',
      number: '800 9090',
      category: 'road_authority',
      region: UaeRegion.dubai,
    ),
    UaeEmergencyContact(
      id: 'em_ad_police',
      name: 'Abu Dhabi Police',
      number: '999',
      category: 'police',
      region: UaeRegion.abuDhabi,
    ),
  ];

  static List<UaeHolidayTraffic> activeHolidayTraffic(DateTime now) {
    final month = now.month;
    final results = <UaeHolidayTraffic>[];

    if (month == 12) {
      results.add(
        const UaeHolidayTraffic(
          type: UaeHolidayType.nationalDay,
          title: 'UAE National Day',
          description:
              'Expect heavier traffic near celebration venues and major roads on 2–3 December.',
          trafficMultiplier: 1.4,
        ),
      );
    }

    results.add(
      const UaeHolidayTraffic(
        type: UaeHolidayType.airport,
        title: 'DXB Airport peak hours',
        description:
            'Airport approach roads (D89, E11) typically congested 6–9 AM and 4–8 PM.',
        trafficMultiplier: 1.3,
      ),
    );

    return results;
  }

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
