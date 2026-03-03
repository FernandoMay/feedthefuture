import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feed_the_future/donation.dart';
import 'package:feed_the_future/donation_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  return DonationRepositoryImpl(firestore: FirebaseFirestore.instance);
});

// Stream: all available donations
final availableDonationsProvider = StreamProvider<List<Donation>>((ref) {
  return ref.watch(donationRepositoryProvider).watchAvailableDonations();
});

// Stream: my donations (as donor)
final myDonationsProvider =
    StreamProvider.family<List<Donation>, String>((ref, donorId) {
  return ref.watch(donationRepositoryProvider).watchDonationsByDonor(donorId);
});

// Stream: donations for NGO
final ngoDonationsProvider =
    StreamProvider.family<List<Donation>, String>((ref, ngoId) {
  return ref.watch(donationRepositoryProvider).watchDonationsByNgo(ngoId);
});

// Filter state
class DonationFilter {
  final String? category;
  final String? status;
  final String? riskScore;
  final bool urgentOnly;

  const DonationFilter({
    this.category,
    this.status,
    this.riskScore,
    this.urgentOnly = false,
  });

  DonationFilter copyWith({
    String? category,
    String? status,
    String? riskScore,
    bool? urgentOnly,
  }) {
    return DonationFilter(
      category: category ?? this.category,
      status: status ?? this.status,
      riskScore: riskScore ?? this.riskScore,
      urgentOnly: urgentOnly ?? this.urgentOnly,
    );
  }
}

final donationFilterProvider =
    StateProvider<DonationFilter>((_) => const DonationFilter());

// Filtered donations
final filteredDonationsProvider = Provider<AsyncValue<List<Donation>>>((ref) {
  final filter = ref.watch(donationFilterProvider);
  final donations = ref.watch(availableDonationsProvider);

  return donations.whenData((list) {
    var result = list;
    if (filter.category != null) {
      result = result.where((d) => d.category == filter.category).toList();
    }
    if (filter.riskScore != null) {
      result = result.where((d) => d.riskScore == filter.riskScore).toList();
    }
    if (filter.urgentOnly) {
      result = result.where((d) => d.isUrgent).toList();
    }
    return result;
  });
});

// Donation creation notifier
class DonationCreateNotifier extends StateNotifier<AsyncValue<void>> {
  final DonationRepository _repository;
  DonationCreateNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> create(Donation donation) async {
    state = const AsyncValue.loading();
    final result = await _repository.createDonation(donation);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}

final donationCreateProvider =
    StateNotifierProvider<DonationCreateNotifier, AsyncValue<void>>((ref) {
  return DonationCreateNotifier(ref.watch(donationRepositoryProvider));
});
