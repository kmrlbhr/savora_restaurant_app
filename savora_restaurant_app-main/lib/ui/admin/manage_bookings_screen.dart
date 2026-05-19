import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_providers.dart';

/// Admin screen to view and manage all customer bookings.
///
/// Displays bookings in three tabs (Upcoming, Past, Cancelled)
/// matching the customer-side pattern. Each booking card shows
/// the customer name, package, date, guests, and total price.
///
/// Tapping a card navigates to the admin booking detail screen
/// where the admin can update status or cancel bookings.
class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AdminBookingList(
                  filter: _BookingFilter.upcoming,
                  emptyLabel: 'No upcoming bookings',
                ),
                _AdminBookingList(
                  filter: _BookingFilter.past,
                  emptyLabel: 'No past bookings',
                ),
                _AdminBookingList(
                  filter: _BookingFilter.cancelled,
                  emptyLabel: 'No cancelled bookings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BookingFilter { upcoming, past, cancelled }

class _AdminBookingList extends ConsumerWidget {
  final _BookingFilter filter;
  final String emptyLabel;

  const _AdminBookingList({required this.filter, required this.emptyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBookingsAsync = ref.watch(allBookingsProvider);

    return allBookingsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load bookings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(allBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        final now = DateTime.now();
        final filtered = bookings.where((b) {
          switch (filter) {
            case _BookingFilter.upcoming:
              return b.status == AppConstants.statusUpcoming &&
                  b.eventDate.isAfter(now);
            case _BookingFilter.past:
              return b.status == AppConstants.statusPast ||
                  (b.status == AppConstants.statusUpcoming &&
                      b.eventDate.isBefore(now));
            case _BookingFilter.cancelled:
              return b.status == AppConstants.statusCancelled;
          }
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _AdminBookingCard(booking: filtered[index]),
        );
      },
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;

  const _AdminBookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'upcoming':
        return AppColors.info;
      case 'past':
        return AppColors.grey500;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Package name + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.packageName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.status[0].toUpperCase() +
                          booking.status.substring(1),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Customer name
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text(
                    booking.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 3: Date + Guests
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      AppConstants.dateFormatDisplay,
                    ).format(booking.eventDate),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text('${booking.numGuests} guests'),
                ],
              ),
              const SizedBox(height: 8),

              // Row 4: Total price
              Text(
                '${AppConstants.currencySymbol} ${booking.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
