import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../providers/booking_providers.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/error_dialog.dart';

/// Admin view for a single booking with status management actions.
///
/// Displays full booking details including customer info, package,
/// date, guests, custom fees, and total price.
///
/// Admin actions (only for upcoming bookings):
/// - Cancel booking → sets status to 'cancelled'
/// - Mark as completed → sets status to 'past'
///
/// Uses [BookingRepository.updateStatus] for direct status changes
/// and [BookingRepository.cancelBooking] for cancellations.
class AdminBookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const AdminBookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState
    extends ConsumerState<AdminBookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final booking = await repo.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorDialog(context, e);
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Booking',
      message:
          'Are you sure you want to cancel this booking for ${_booking!.userName}? This cannot be undone.',
      confirmLabel: 'Cancel Booking',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.cancelBooking(widget.bookingId);
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markAsCompleted() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark as Completed',
      message: 'Mark this booking for ${_booking!.userName} as completed/past?',
      confirmLabel: 'Mark Completed',
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.updateStatus(widget.bookingId, AppConstants.statusPast);
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
      );
    }

    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final isUpcoming =
        booking.status == AppConstants.statusUpcoming &&
        booking.eventDate.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: booking.status == 'upcoming'
                      ? AppColors.info.withValues(alpha: 0.1)
                      : booking.status == 'cancelled'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status[0].toUpperCase() + booking.status.substring(1),
                  style: TextStyle(
                    color: booking.status == 'upcoming'
                        ? AppColors.info
                        : booking.status == 'cancelled'
                        ? AppColors.error
                        : AppColors.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Package name
            Text(
              booking.packageName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Customer info card
            Card(
              color: AppColors.goldMuted,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.navy,
                      radius: 20,
                      child: Icon(
                        Icons.person,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.userName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customer',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Booking details
            _detailRow(
              Icons.calendar_today,
              'Event Date',
              DateFormat(
                AppConstants.dateFormatDisplay,
              ).format(booking.eventDate),
            ),
            _detailRow(Icons.people, 'Guests', '${booking.numGuests}'),
            _detailRow(
              Icons.receipt,
              'Total Price',
              '${AppConstants.currencySymbol} ${booking.totalPrice.toStringAsFixed(2)}',
            ),
            _detailRow(
              Icons.access_time,
              'Booked On',
              DateFormat(
                AppConstants.dateTimeFormatDisplay,
              ).format(booking.createdAt),
            ),
            _detailRow(Icons.confirmation_number, 'Booking ID', booking.id),
            const SizedBox(height: 24),

            // Custom fees
            if (booking.customFees.isNotEmpty) ...[
              Text(
                'Custom Fees',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...booking.customFees.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f.name),
                      Text(
                        '${AppConstants.currencySymbol} ${f.amount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Admin actions (only for upcoming bookings)
            if (isUpcoming) ...[
              Text('Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Mark as completed
              AppButton.primary(
                label: 'Mark as Completed',
                onPressed: _isUpdating ? null : _markAsCompleted,
                loading: _isUpdating,
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 12),

              // Cancel booking
              AppButton.outlined(
                label: 'Cancel Booking',
                onPressed: _isUpdating ? null : _cancelBooking,
                loading: _isUpdating,
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey500),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColors.grey600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
