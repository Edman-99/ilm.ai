import 'package:ai_stock_analyzer/data/user_plan.dart';

class ModeInfo {
  const ModeInfo({
    required this.label,
    required this.bank,
    required this.description,
  });

  final String label;
  final String bank;
  final String description;
}

class HeroRotatingItem {
  const HeroRotatingItem({required this.line1, required this.line2});
  final String line1;
  final String line2;
}

class HowItWorksStep {
  const HowItWorksStep({required this.title, required this.description});
  final String title;
  final String description;
}

class AppStrings {
  const AppStrings._({
    // Hero
    required this.heroTitle1,
    required this.heroTitle2,
    required this.heroSubtitle,
    required this.heroRotatingItems,
    // Modes
    required this.modes,
    // Home / Steps
    required this.enterTicker,
    required this.tickerHint,
    required this.next,
    required this.back,
    required this.startAnalysis,
    required this.analyze,
    required this.recentAnalyses,
    required this.error,
    required this.unlimited,
    // How it works
    required this.howItWorks,
    required this.howItWorksSubtitle,
    required this.howItWorksSteps,
    // Auth
    required this.login,
    required this.register,
    required this.emailHint,
    required this.passwordHint,
    required this.enterEmailAndPassword,
    required this.createAccount,
    required this.loginButton,
    required this.registerButton,
    required this.noAccount,
    required this.haveAccount,
    required this.accountNotFound,
    required this.wrongPassword,
    required this.emailTaken,
    // Pricing
    required this.choosePlan,
    required this.choosePlanSubtitle,
    required this.currentPlan,
    required this.select,
    required this.popular,
    required this.comingSoon,
    required this.perMonth,
    required this.analysesPerDay,
    required this.unlimitedLabel,
    // Plan features
    required this.freePlanFeatures,
    required this.proPlanFeatures,
    required this.premiumPlanFeatures,
    // Result page
    required this.overview,
    required this.quickVerdict,
    required this.indicators,
    required this.technicalAnalysis,
    required this.aiAnalysis,
    required this.fullAiReport,
    required this.fundamentalAnalysis,
    required this.riskAssessment,
    required this.recommendations,
    required this.swotAnalysis,
    required this.score,
    required this.trend,
    required this.price,
    required this.change,
    required this.summary,
    // SWOT
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
    required this.threats,
    required this.swotStrengthItems,
    required this.swotWeaknessItems,
    required this.swotOpportunityItems,
    required this.swotThreatItems,
    // Score
    required this.outOf100,
    required this.signalBuy,
    required this.signalHold,
    required this.signalSell,
    // Errors (cubit)
    required this.errorModeUnavailable,
    required this.errorLimitReached,
    required this.errorServer,
    required this.errorNoConnection,
    required this.errorGeneric,
  });

  // Hero
  final String heroTitle1;
  final String heroTitle2;
  final String heroSubtitle;
  final List<HeroRotatingItem> heroRotatingItems;

  // Modes
  final Map<String, ModeInfo> modes;

  // Home
  final String enterTicker;
  final String tickerHint;
  final String next;
  final String back;
  final String startAnalysis;
  final String analyze;
  final String recentAnalyses;
  final String error;
  final String unlimited;

  // How it works
  final String howItWorks;
  final String howItWorksSubtitle;
  final List<HowItWorksStep> howItWorksSteps;

  // Auth
  final String login;
  final String register;
  final String emailHint;
  final String passwordHint;
  final String enterEmailAndPassword;
  final String createAccount;
  final String loginButton;
  final String registerButton;
  final String noAccount;
  final String haveAccount;
  final String accountNotFound;
  final String wrongPassword;
  final String emailTaken;

  // Pricing
  final String choosePlan;
  final String choosePlanSubtitle;
  final String currentPlan;
  final String select;
  final String popular;
  final String comingSoon;
  final String perMonth;
  final String analysesPerDay;
  final String unlimitedLabel;

  // Plan features
  final List<PlanFeature> freePlanFeatures;
  final List<PlanFeature> proPlanFeatures;
  final List<PlanFeature> premiumPlanFeatures;

  List<PlanFeature> featuresFor(UserPlan plan) {
    switch (plan) {
      case UserPlan.free:
        return freePlanFeatures;
      case UserPlan.pro:
        return proPlanFeatures;
      case UserPlan.premium:
        return premiumPlanFeatures;
    }
  }

  String dailyLimitLabel(int limit) =>
      limit < 0 ? unlimitedLabel : '$limit $analysesPerDay';

  // Result page
  final String overview;
  final String quickVerdict;
  final String indicators;
  final String technicalAnalysis;
  final String aiAnalysis;
  final String fullAiReport;
  final String fundamentalAnalysis;
  final String riskAssessment;
  final String recommendations;
  final String swotAnalysis;
  final String score;
  final String trend;
  final String price;
  final String change;
  final String summary;

  // SWOT
  final String strengths;
  final String weaknesses;
  final String opportunities;
  final String threats;
  final List<String> swotStrengthItems;
  final List<String> swotWeaknessItems;
  final List<String> swotOpportunityItems;
  final List<String> swotThreatItems;

  // Score
  final String outOf100;
  final String signalBuy;
  final String signalHold;
  final String signalSell;

  String signal(int score) {
    if (score >= 65) return signalBuy;
    if (score >= 45) return signalHold;
    return signalSell;
  }

  // Errors
  final String errorModeUnavailable;
  final String errorLimitReached;
  final String errorServer;
  final String errorNoConnection;
  final String errorGeneric;

  String errorServerWithCode(int code) =>
      '$errorServer ($code)';

  // ── RU ──
  static const ru = AppStrings._(
    heroTitle1: 'Анализ акций',
    heroTitle2: 'с помощью ИИ',
    heroSubtitle: 'Выберите методологию для начала',
    heroRotatingItems: [
      HeroRotatingItem(line1: 'Анализ акций', line2: 'от ILM'),
      HeroRotatingItem(line1: 'Технический анализ', line2: 'от Citadel'),
      HeroRotatingItem(line1: 'Оценка рисков', line2: 'от Bridgewater'),
      HeroRotatingItem(line1: 'DCF оценка', line2: 'от Morgan Stanley'),
      HeroRotatingItem(line1: 'Портфель', line2: 'от BlackRock'),
    ],
    modes: {
      'full': ModeInfo(
        label: 'Полный отчёт',
        bank: 'Все методологии',
        description:
            'Комплексный анализ акции по всем 9 методологиям ведущих инвестиционных банков мира в одном отчёте',
      ),
      'technical': ModeInfo(
        label: 'Технический анализ',
        bank: 'Citadel',
        description:
            'RSI, MACD, Bollinger Bands, скользящие средние, уровни поддержки и сопротивления',
      ),
      'screener': ModeInfo(
        label: 'Скрининг',
        bank: 'Goldman Sachs',
        description:
            'Фундаментальный скрининг акции — финансовые мультипликаторы, рентабельность, рост выручки',
      ),
      'risk': ModeInfo(
        label: 'Оценка рисков',
        bank: 'Bridgewater',
        description:
            'Анализ рыночных, секторальных и специфических рисков компании с рекомендациями по хеджированию',
      ),
      'dcf': ModeInfo(
        label: 'DCF оценка',
        bank: 'Morgan Stanley',
        description:
            'Оценка справедливой стоимости методом дисконтированных денежных потоков с прогнозом на 5 лет',
      ),
      'earnings': ModeInfo(
        label: 'Отчётность',
        bank: 'JPMorgan',
        description:
            'Анализ перед квартальной отчётностью — ожидания рынка, исторические сюрпризы, прогноз реакции',
      ),
      'portfolio': ModeInfo(
        label: 'Портфель',
        bank: 'BlackRock',
        description:
            'Построение оптимального портфеля — диверсификация, корреляции, распределение по секторам',
      ),
      'dividends': ModeInfo(
        label: 'Дивиденды',
        bank: 'Harvard',
        description:
            'Дивидендная доходность, история выплат, коэффициент покрытия, прогноз будущих дивидендов',
      ),
      'competitors': ModeInfo(
        label: 'Конкуренты',
        bank: 'Bain',
        description:
            'Сравнительный анализ с конкурентами — рыночная доля, маржинальность, темпы роста',
      ),
    },
    enterTicker: 'Напишите тикер компании',
    tickerHint: 'Тикер вводится на английском — например AAPL, TSLA, GOOGL',
    next: 'Далее',
    back: 'Назад',
    startAnalysis: 'Запустить анализ?',
    analyze: 'Анализировать',
    recentAnalyses: 'Недавние анализы',
    error: 'Ошибка',
    unlimited: 'Безлимит',
    howItWorks: 'Как это работает',
    howItWorksSubtitle: 'Три простых шага до профессионального анализа',
    howItWorksSteps: [
      HowItWorksStep(
        title: 'Введите тикер',
        description:
            'Укажите тикер акции и выберите один из 9 режимов анализа',
      ),
      HowItWorksStep(
        title: 'AI анализирует',
        description:
            'Нейросеть применяет методологии ведущих инвестиционных банков',
      ),
      HowItWorksStep(
        title: 'Получите отчёт',
        description:
            'Детальный анализ со скором, индикаторами и рекомендациями',
      ),
    ],
    login: 'Войти',
    register: 'Регистрация',
    emailHint: 'Email',
    passwordHint: 'Пароль',
    enterEmailAndPassword: 'Введите email и пароль',
    createAccount: 'Создайте аккаунт',
    loginButton: 'Войти',
    registerButton: 'Зарегистрироваться',
    noAccount: 'Нет аккаунта?',
    haveAccount: 'Уже есть аккаунт?',
    accountNotFound: 'Аккаунт не найден',
    wrongPassword: 'Неверный пароль',
    emailTaken: 'Email уже зарегистрирован',
    choosePlan: 'Выберите тариф',
    choosePlanSubtitle: 'Начните бесплатно, обновите когда будете готовы',
    currentPlan: 'Текущий план',
    select: 'Выбрать',
    popular: 'Популярный',
    comingSoon: 'Coming soon',
    perMonth: '/мес',
    analysesPerDay: 'анализов/день',
    unlimitedLabel: 'Безлимит',
    freePlanFeatures: [
      PlanFeature(label: '3 анализа в день', included: true),
      PlanFeature(label: '1 режим (Технический анализ)', included: true),
      PlanFeature(label: 'История за 1 день', included: true),
      PlanFeature(label: 'Экспорт PDF', included: false),
      PlanFeature(label: 'Портфельный анализ', included: false),
      PlanFeature(label: 'Приоритет ответа', included: false),
    ],
    proPlanFeatures: [
      PlanFeature(label: '30 анализов в день', included: true),
      PlanFeature(label: 'Все 9 режимов', included: true),
      PlanFeature(label: 'История за 30 дней', included: true),
      PlanFeature(label: 'Экспорт PDF', included: true),
      PlanFeature(label: 'Портфельный анализ', included: false),
      PlanFeature(label: 'Приоритет ответа', included: false),
    ],
    premiumPlanFeatures: [
      PlanFeature(label: 'Безлимит анализов', included: true),
      PlanFeature(label: 'Все 9 режимов', included: true),
      PlanFeature(label: 'Вся история', included: true),
      PlanFeature(label: 'Экспорт PDF', included: true),
      PlanFeature(label: 'Портфельный анализ', included: true),
      PlanFeature(label: 'Приоритет ответа', included: true),
    ],
    overview: 'Обзор',
    quickVerdict: 'Быстрый вердикт',
    indicators: 'Индикаторы',
    technicalAnalysis: 'Технический анализ',
    aiAnalysis: 'AI Анализ',
    fullAiReport: 'Полный AI отчёт',
    fundamentalAnalysis: 'Фундаментальный анализ',
    riskAssessment: 'Оценка рисков',
    recommendations: 'Рекомендации',
    swotAnalysis: 'SWOT анализ',
    score: 'Скор',
    trend: 'Тренд',
    price: 'Цена',
    change: 'Изменение',
    summary: 'Сводка',
    strengths: 'Сильные стороны',
    weaknesses: 'Слабые стороны',
    opportunities: 'Возможности',
    threats: 'Угрозы',
    swotStrengthItems: ['Стабильный рост выручки', 'Сильный бренд'],
    swotWeaknessItems: ['Высокий P/E', 'Зависимость от рынка'],
    swotOpportunityItems: ['AI сегмент', 'Новые рынки'],
    swotThreatItems: ['Конкуренция', 'Регуляторные риски'],
    outOf100: 'из 100',
    signalBuy: 'ПОКУПКА',
    signalHold: 'ЖДАТЬ',
    signalSell: 'ПРОДАЖА',
    errorModeUnavailable: 'Этот режим недоступен на вашем тарифе.',
    errorLimitReached: 'Лимит анализов исчерпан. Обновите тариф для продолжения.',
    errorServer: 'Ошибка сервера',
    errorNoConnection: 'Нет подключения к серверу',
    errorGeneric: 'Произошла ошибка',
  );

  // ── EN ──
  static const en = AppStrings._(
    heroTitle1: 'Stock Analysis',
    heroTitle2: 'powered by AI',
    heroSubtitle: 'Choose a methodology to get started',
    heroRotatingItems: [
      HeroRotatingItem(line1: 'Stock Analysis', line2: 'by ILM'),
      HeroRotatingItem(line1: 'Technical Analysis', line2: 'by Citadel'),
      HeroRotatingItem(line1: 'Risk Assessment', line2: 'by Bridgewater'),
      HeroRotatingItem(line1: 'DCF Valuation', line2: 'by Morgan Stanley'),
      HeroRotatingItem(line1: 'Portfolio', line2: 'by BlackRock'),
    ],
    modes: {
      'full': ModeInfo(
        label: 'Full Report',
        bank: 'All Methodologies',
        description:
            'Comprehensive stock analysis using all 9 methodologies from the world\'s leading investment banks in one report',
      ),
      'technical': ModeInfo(
        label: 'Technical Analysis',
        bank: 'Citadel',
        description:
            'RSI, MACD, Bollinger Bands, moving averages, support and resistance levels',
      ),
      'screener': ModeInfo(
        label: 'Screening',
        bank: 'Goldman Sachs',
        description:
            'Fundamental stock screening — financial multiples, profitability, revenue growth',
      ),
      'risk': ModeInfo(
        label: 'Risk Assessment',
        bank: 'Bridgewater',
        description:
            'Analysis of market, sectoral, and company-specific risks with hedging recommendations',
      ),
      'dcf': ModeInfo(
        label: 'DCF Valuation',
        bank: 'Morgan Stanley',
        description:
            'Fair value estimation using discounted cash flow method with a 5-year forecast',
      ),
      'earnings': ModeInfo(
        label: 'Earnings',
        bank: 'JPMorgan',
        description:
            'Pre-earnings analysis — market expectations, historical surprises, reaction forecast',
      ),
      'portfolio': ModeInfo(
        label: 'Portfolio',
        bank: 'BlackRock',
        description:
            'Optimal portfolio construction — diversification, correlations, sector allocation',
      ),
      'dividends': ModeInfo(
        label: 'Dividends',
        bank: 'Harvard',
        description:
            'Dividend yield, payout history, coverage ratio, future dividend forecast',
      ),
      'competitors': ModeInfo(
        label: 'Competitors',
        bank: 'Bain',
        description:
            'Competitive analysis — market share, margins, growth rates',
      ),
    },
    enterTicker: 'Enter company ticker',
    tickerHint: 'Enter ticker in English — e.g. AAPL, TSLA, GOOGL',
    next: 'Next',
    back: 'Back',
    startAnalysis: 'Start analysis?',
    analyze: 'Analyze',
    recentAnalyses: 'Recent analyses',
    error: 'Error',
    unlimited: 'Unlimited',
    howItWorks: 'How it works',
    howItWorksSubtitle: 'Three simple steps to professional analysis',
    howItWorksSteps: [
      HowItWorksStep(
        title: 'Enter ticker',
        description:
            'Enter a stock ticker and choose one of 9 analysis modes',
      ),
      HowItWorksStep(
        title: 'AI analyzes',
        description:
            'Neural network applies methodologies of leading investment banks',
      ),
      HowItWorksStep(
        title: 'Get report',
        description:
            'Detailed analysis with score, indicators, and recommendations',
      ),
    ],
    login: 'Sign In',
    register: 'Sign Up',
    emailHint: 'Email',
    passwordHint: 'Password',
    enterEmailAndPassword: 'Enter your email and password',
    createAccount: 'Create an account',
    loginButton: 'Sign In',
    registerButton: 'Sign Up',
    noAccount: 'Don\'t have an account?',
    haveAccount: 'Already have an account?',
    accountNotFound: 'Account not found',
    wrongPassword: 'Wrong password',
    emailTaken: 'Email already registered',
    choosePlan: 'Choose a plan',
    choosePlanSubtitle: 'Start for free, upgrade when you\'re ready',
    currentPlan: 'Current plan',
    select: 'Select',
    popular: 'Popular',
    comingSoon: 'Coming soon',
    perMonth: '/mo',
    analysesPerDay: 'analyses/day',
    unlimitedLabel: 'Unlimited',
    freePlanFeatures: [
      PlanFeature(label: '3 analyses per day', included: true),
      PlanFeature(label: '1 mode (Technical Analysis)', included: true),
      PlanFeature(label: '1 day history', included: true),
      PlanFeature(label: 'PDF export', included: false),
      PlanFeature(label: 'Portfolio analysis', included: false),
      PlanFeature(label: 'Priority response', included: false),
    ],
    proPlanFeatures: [
      PlanFeature(label: '30 analyses per day', included: true),
      PlanFeature(label: 'All 9 modes', included: true),
      PlanFeature(label: '30 days history', included: true),
      PlanFeature(label: 'PDF export', included: true),
      PlanFeature(label: 'Portfolio analysis', included: false),
      PlanFeature(label: 'Priority response', included: false),
    ],
    premiumPlanFeatures: [
      PlanFeature(label: 'Unlimited analyses', included: true),
      PlanFeature(label: 'All 9 modes', included: true),
      PlanFeature(label: 'Full history', included: true),
      PlanFeature(label: 'PDF export', included: true),
      PlanFeature(label: 'Portfolio analysis', included: true),
      PlanFeature(label: 'Priority response', included: true),
    ],
    overview: 'Overview',
    quickVerdict: 'Quick verdict',
    indicators: 'Indicators',
    technicalAnalysis: 'Technical Analysis',
    aiAnalysis: 'AI Analysis',
    fullAiReport: 'Full AI report',
    fundamentalAnalysis: 'Fundamental analysis',
    riskAssessment: 'Risk assessment',
    recommendations: 'Recommendations',
    swotAnalysis: 'SWOT analysis',
    score: 'Score',
    trend: 'Trend',
    price: 'Price',
    change: 'Change',
    summary: 'Summary',
    strengths: 'Strengths',
    weaknesses: 'Weaknesses',
    opportunities: 'Opportunities',
    threats: 'Threats',
    swotStrengthItems: ['Stable revenue growth', 'Strong brand'],
    swotWeaknessItems: ['High P/E', 'Market dependency'],
    swotOpportunityItems: ['AI segment', 'New markets'],
    swotThreatItems: ['Competition', 'Regulatory risks'],
    outOf100: 'out of 100',
    signalBuy: 'BUY',
    signalHold: 'HOLD',
    signalSell: 'SELL',
    errorModeUnavailable: 'This mode is not available on your plan.',
    errorLimitReached: 'Analysis limit reached. Upgrade your plan to continue.',
    errorServer: 'Server error',
    errorNoConnection: 'No server connection',
    errorGeneric: 'An error occurred',
  );
}
