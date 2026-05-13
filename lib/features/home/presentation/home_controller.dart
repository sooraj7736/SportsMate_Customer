import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../AddFeed/domain/AddFeed_entity.dart';
import '../data/feedrepository.dart';
import '../domain/ad_entity.dart';

final feedListStreamProvider = StreamProvider<List<FeedEntity>>((ref) {
  return ref.watch(feedRepositoryProvider).watchFeeds();
});

final adListStreamProvider = StreamProvider<List<AdEntity>>((ref) {
  return ref.watch(feedRepositoryProvider).watchAds();
});
