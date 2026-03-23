enum UserPlan { free, pro, premium }

class PlanInfo {
  const PlanInfo({
    required this.name,
    required this.price,
    required this.dailyLimit,
    this.isPopular = false,
  });

  final String name;
  final String price;
  final int dailyLimit; // -1 = unlimited
  final bool isPopular;
}

class PlanFeature {
  const PlanFeature({required this.label, required this.included});

  final String label;
  final bool included;
}

const freeModes = <String>{'technical'};

const plans = <UserPlan, PlanInfo>{
  UserPlan.free: PlanInfo(
    name: 'Free',
    price: '\$0',
    dailyLimit: 3,
  ),
  UserPlan.pro: PlanInfo(
    name: 'Pro',
    price: '\$9',
    dailyLimit: 30,
    isPopular: true,
  ),
  UserPlan.premium: PlanInfo(
    name: 'Premium',
    price: '\$29',
    dailyLimit: -1,
  ),
};
