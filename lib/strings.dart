/// Textos en español e inglés.
class S {
  const S(this.lang);
  final String lang;
  bool get _es => lang == 'es';

  /// Texto rápido en ambos idiomas para los demos.
  String t(String es, String en) => _es ? es : en;

  String get title => 'Flutter Lab';
  String get subtitle => _es
      ? 'Demos de mis proyectos reales, hechas en Flutter y compiladas a WebAssembly: corren en tu navegador.'
      : 'Demos of my real projects, built in Flutter and compiled to WebAssembly: they run in your browser.';
  String get platformHint => _es
      ? 'Cambia iOS / Android abajo del teléfono: la app se adapta en vivo, con el mismo código.'
      : 'Switch iOS / Android below the phone: the app adapts live, from the same code.';
  String basedOn(String project) => _es ? 'Inspirada en $project' : 'Based on $project';
  String get viewCode => _es ? 'Ver código' : 'View code';



  String get name => _es ? 'Nombre' : 'Name';
  String get rut => 'RUT';
  String get rutHelp => _es ? 'Prueba con 12.345.678-5' : 'Try 12.345.678-5';
  String get nameRequired => _es ? 'Ingresa tu nombre' : 'Enter your name';
  String get rutInvalid => _es ? 'RUT inválido' : 'Invalid RUT';

  // Reserva de asientos
  String get bookingTitle => _es ? 'Reserva de asientos' : 'Seat booking';
  String get bookingDesc => _es ? 'Ruta, asiento, pasajero y pase de abordaje con QR.' : 'Route, seat, passenger and a QR boarding pass.';
  String get myTrips => _es ? 'Mis viajes' : 'My trips';
  String get noTrips => _es ? 'Aún no tienes viajes reservados.' : "You don't have any trips yet.";
  String get newBooking => _es ? 'Reservar viaje' : 'Book a trip';
  String get chooseRoute => _es ? 'Elige tu ruta' : 'Choose your route';
  String get chooseDate => _es ? 'Fecha' : 'Date';
  String get chooseTime => _es ? 'Horario' : 'Departure';
  String get chooseSeat => _es ? 'Elige tu asiento' : 'Choose your seat';
  String get seatFree => _es ? 'Libre' : 'Free';
  String seatsLeft(int n) => _es ? (n == 1 ? '1 libre' : '$n libres') : '$n left';
  String get seatTaken => _es ? 'Ocupado' : 'Taken';
  String get seatSelected => _es ? 'Tu asiento' : 'Your seat';
  String get driver => _es ? 'Conductor' : 'Driver';
  String get passenger => _es ? 'Pasajero' : 'Passenger';
  String get continueLabel => _es ? 'Continuar' : 'Continue';
  String get confirmBooking => _es ? 'Confirmar reserva' : 'Confirm booking';
  String get boardingPass => _es ? 'Pase de abordaje' : 'Boarding pass';
  String get tapToFlip => _es ? 'Toca el pase para darlo vuelta' : 'Tap the pass to flip it';
  String get seat => _es ? 'Asiento' : 'Seat';
  String get departure => _es ? 'Salida' : 'Departs';
  String get arrival => _es ? 'Llegada' : 'Arrives';
  String get code => _es ? 'Código' : 'Code';
  String get total => 'Total';
  String get showAtBoarding => _es ? 'Muestra este código al subir al bus.' : 'Show this code when boarding.';
  String get demoNotice => _es ? 'Demo con datos ficticios: no se realiza ningún cobro.' : 'Demo with fictitious data: no payment is made.';
  String get done2 => _es ? 'Listo' : 'Done';
  String get cancelTrip => _es ? 'Anular' : 'Cancel';
  String duration(int minutes) => '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
  String get today => _es ? 'Hoy' : 'Today';
  List<String> get weekdays => _es ? const ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'] : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> get months => _es
      ? const ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
      : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String shortDate(DateTime d) => '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  String price(int clp) {
    final digits = clp.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '\$$buffer';
  }

  // Mapa de flota
  String get fleetTitle => _es ? 'Flota en vivo' : 'Live fleet';
  String get fleetDesc => _es ? 'Buses simulados moviéndose por Santiago sobre un mapa real.' : 'Simulated buses moving across Santiago on a real map.';
  String get fleetLive => _es ? 'En vivo' : 'Live';
  String fleetSummary(int total, int moving) => _es ? '$moving de $total en movimiento' : '$moving of $total moving';
  String get fleetHint => _es ? 'Toca un bus para ver su detalle' : 'Tap a bus to see its details';
  String get fleetSpeed => _es ? 'Velocidad' : 'Speed';
  String get fleetNextStop => _es ? 'Próxima parada' : 'Next stop';
  String get fleetOccupancy => _es ? 'Ocupación' : 'Occupancy';
  String get fleetDriver => _es ? 'Conductor' : 'Driver';
  String get fleetFollow => _es ? 'Seguir' : 'Follow';
  String get fleetFollowing => _es ? 'Siguiendo' : 'Following';
}
