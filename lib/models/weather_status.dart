enum WeatherState {
  loading,
  ready,
  noInternet,
  locationDenied,
  locationServiceDisabled,
  unavailable,
}

class WeatherStatus {
  const WeatherStatus({
    required this.state,
    this.temperatureC,
    this.weatherCode,
    this.cityLabel,
  });

  final WeatherState state;
  final double? temperatureC;
  final int? weatherCode;
  final String? cityLabel;
}

/// Maps Open-Meteo WMO weather codes to a short label.
/// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
String weatherCodeLabel(int? code, bool arabic) {
  if (code == null) return arabic ? 'غير معروف' : 'Unknown';
  if (code == 0) return arabic ? 'صافٍ' : 'Clear sky';
  if (code <= 2) return arabic ? 'غائم جزئياً' : 'Partly cloudy';
  if (code == 3) return arabic ? 'غائم' : 'Cloudy';
  if (code == 45 || code == 48) return arabic ? 'ضباب' : 'Fog';
  if (code >= 51 && code <= 57) return arabic ? 'رذاذ' : 'Drizzle';
  if (code >= 61 && code <= 67) return arabic ? 'أمطار' : 'Rain';
  if (code >= 71 && code <= 77) return arabic ? 'ثلوج' : 'Snow';
  if (code >= 80 && code <= 82) return arabic ? 'زخات مطر' : 'Rain showers';
  if (code >= 95) return arabic ? 'عاصفة رعدية' : 'Thunderstorm';
  return arabic ? 'غير معروف' : 'Unknown';
}
