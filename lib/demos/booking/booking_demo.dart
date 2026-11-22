import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../rut.dart';
import 'boarding_pass.dart';
import 'booking_model.dart';
import 'seat_map.dart';

/// Demo de reserva de asientos: Mis viajes → ruta y horario → asiento → pasajero → pase de abordaje.
class BookingDemo extends StatefulWidget {
  const BookingDemo({super.key});

  @override
  State<BookingDemo> createState() => _BookingDemoState();
}

class _BookingDemoState extends State<BookingDemo> {
  final store = BookingStore.instance;

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final bookings = store.bookings;
          return Column(
            children: [
              Expanded(
                child: bookings.isEmpty
                    ? _EmptyTrips(text: s.noTrips)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => i == 0
                            ? Text(s.myTrips, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))
                            : _TripTile(booking: bookings[i - 1]),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _PrimaryButton(
                  label: s.newBooking,
                  icon: Icons.add_rounded,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _RouteStep())),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -12, end: 12),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, x, child) => Transform.translate(offset: Offset(x, 0), child: child),
            child: const Icon(Icons.directions_bus_filled_rounded, size: 72, color: accent),
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: muted)),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final route = booking.route;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TicketPage(booking: booking))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(
                tag: 'trip-${booking.code}',
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(booking.seat, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${route.from} → ${route.to}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text('${s.shortDate(booking.date)} · ${booking.time} · ${booking.code}', style: const TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_2_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Paso 1: ruta, fecha y horario ---------- */

class _RouteStep extends StatefulWidget {
  const _RouteStep();

  @override
  State<_RouteStep> createState() => _RouteStepState();
}

class _RouteStepState extends State<_RouteStep> {
  BusRoute route = routes.first;
  late DateTime date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
  String? time;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final today = DateUtils.dateOnly(DateTime.now());
    return _StepScaffold(
      step: 1,
      title: s.chooseRoute,
      bottom: _PrimaryButton(
        label: s.continueLabel,
        onPressed: time == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _SeatStep(route: route, date: date, time: time!))),
      ),
      children: [
        for (final r in routes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SelectableCard(
              selected: r == route,
              onTap: () => setState(() => route = r),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.from} → ${r.to}', style: TextStyle(color: r == route ? ink : Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(s.duration(r.minutes), style: TextStyle(color: r == route ? ink.withValues(alpha: 0.7) : muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(s.price(r.price), style: TextStyle(color: r == route ? ink : accent, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        _Label(s.chooseDate),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = today.add(Duration(days: i));
              final selected = DateUtils.isSameDay(d, date);
              return _SelectableCard(
                selected: selected,
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () => setState(() {
                  date = d;
                  time = null;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(i == 0 ? s.today : s.weekdays[d.weekday - 1], style: TextStyle(color: selected ? ink : muted, fontSize: 12)),
                    Text('${d.day}', style: TextStyle(color: selected ? ink : Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _Label(s.chooseTime),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in departures)
              Builder(builder: (context) {
                final free = seatRows * seatCols.length - occupiedSeats(route.id, date, t).length;
                final past = DateUtils.isSameDay(date, today) && t.compareTo(_nowHHmm()) <= 0;
                final selected = t == time;
                return _SelectableCard(
                  selected: selected,
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onTap: past ? null : () => setState(() => time = t),
                  child: Column(
                    children: [
                      Text(t, style: TextStyle(color: selected ? ink : (past ? muted : Colors.white), fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(past ? '—' : s.seatsLeft(free), style: TextStyle(color: selected ? ink : muted, fontSize: 11)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }

  String _nowHHmm() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

/* ---------- Paso 2: asiento ---------- */

class _SeatStep extends StatefulWidget {
  const _SeatStep({required this.route, required this.date, required this.time});
  final BusRoute route;
  final DateTime date;
  final String time;

  @override
  State<_SeatStep> createState() => _SeatStepState();
}

class _SeatStepState extends State<_SeatStep> {
  late final occupied = occupiedSeats(widget.route.id, widget.date, widget.time);
  String? seat;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return _StepScaffold(
      step: 2,
      title: s.chooseSeat,
      bottom: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                seat == null ? '${widget.route.from} → ${widget.route.to}' : '${s.seat} $seat · ${s.price(widget.route.price)}',
                key: ValueKey(seat),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: _PrimaryButton(
              label: s.continueLabel,
              onPressed: seat == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => _PassengerStep(route: widget.route, date: widget.date, time: widget.time, seat: seat!))),
            ),
          ),
        ],
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Legend(color: surface, border: const Color(0xFF3A4252), label: s.seatFree),
            _Legend(color: surfaceHigh, label: s.seatTaken),
            _Legend(color: accent, label: s.seatSelected),
          ],
        ),
        const SizedBox(height: 16),
        SeatMap(occupied: occupied, selected: seat, onSelect: (id) => setState(() => seat = id)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.border});
  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: border == null ? null : Border.all(color: border!)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

/* ---------- Paso 3: pasajero ---------- */

class _PassengerStep extends StatefulWidget {
  const _PassengerStep({required this.route, required this.date, required this.time, required this.seat});
  final BusRoute route;
  final DateTime date;
  final String time;
  final String seat;

  @override
  State<_PassengerStep> createState() => _PassengerStepState();
}

class _PassengerStepState extends State<_PassengerStep> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rut = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _rut.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    // Simula la llamada al servidor
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final booking = Booking(
      code: bookingCode(Random()),
      routeId: widget.route.id,
      date: widget.date,
      time: widget.time,
      seat: widget.seat,
      name: _name.text.trim(),
      rut: _rut.text,
    );
    await BookingStore.instance.add(booking);
    if (!mounted) return;
    final nav = Navigator.of(context);
    var popped = 0;
    nav.popUntil((_) => popped++ >= 3); // vuelve a "Mis viajes"
    nav.push(MaterialPageRoute<void>(builder: (_) => _TicketPage(booking: booking, fresh: true)));
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final r = widget.route;
    InputDecoration deco(String label, IconData icon, [String? helper]) => InputDecoration(
          labelText: label,
          helperText: helper,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        );
    return _StepScaffold(
      step: 3,
      title: s.passenger,
      bottom: _PrimaryButton(label: s.confirmBooking, loading: _saving, onPressed: _saving ? null : _confirm),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              _SummaryRow('${r.from} → ${r.to}', s.price(r.price), bold: true),
              const SizedBox(height: 6),
              _SummaryRow('${s.shortDate(widget.date)} · ${widget.time} – ${arrivalTime(widget.time, r.minutes)}', '${s.seat} ${widget.seat}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: deco(s.name, Icons.person_rounded),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.nameRequired : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rut,
                inputFormatters: [RutFormatter()],
                decoration: deco(s.rut, Icons.badge_rounded, s.rutHelp),
                validator: (v) => isValidRut(v ?? '') ? null : s.rutInvalid,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(s.demoNotice, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.left, this.right, {this.bold = false});
  final String left;
  final String right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: bold ? Colors.white : muted, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 15 : 13);
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style.copyWith(color: bold ? accent : Colors.white70)),
      ],
    );
  }
}

/* ---------- Pase de abordaje ---------- */

class _TicketPage extends StatelessWidget {
  const _TicketPage({required this.booking, this.fresh = false});
  final Booking booking;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.boardingPass),
        actions: [
          TextButton(
            onPressed: () async {
              await BookingStore.instance.remove(booking.code);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(s.cancelTrip, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (fresh)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Icon(isIOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle_rounded, color: accent, size: 54),
              ),
            if (fresh) const SizedBox(height: 12),
            Hero(tag: 'trip-${booking.code}', child: Material(type: MaterialType.transparency, child: BoardingPass(booking: booking))),
            const SizedBox(height: 14),
            Text(s.tapToFlip, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
            const SizedBox(height: 18),
            _PrimaryButton(label: s.done2, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

/* ---------- Piezas compartidas ---------- */

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.step, required this.title, required this.children, required this.bottom});
  final int step;
  final String title;
  final List<Widget> children;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: (step - 1) / 3, end: step / 3),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: surface, color: accent),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ListView(padding: const EdgeInsets.all(16), children: children)),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(color: ink, border: Border(top: BorderSide(color: surface))),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({required this.selected, required this.onTap, required this.child, this.width, this.padding});
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final double? width;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent : (onTap == null ? Colors.transparent : const Color(0xFF2A3140))),
        ),
        child: child,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.icon, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: ink,
        disabledBackgroundColor: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator.adaptive(strokeWidth: 2.5))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 6)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
    );
  }
}
