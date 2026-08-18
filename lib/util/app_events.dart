import 'package:event_bus_plus/event_bus_plus.dart';
import '../models/social_account_model.dart';

// Global EventBus instance
final EventBus eventBus = EventBus();

// Social Account Event
class OnSocialAccountUpdated extends AppEvent {
  final String platform; // 'facebook' or 'instagram'
  final bool isConnected;
  final SocialAccountModel? account;

  const OnSocialAccountUpdated({
    required this.platform,
    required this.isConnected,
    this.account,
  });

  @override
  List<Object?> get props => [platform, isConnected, account];
}
