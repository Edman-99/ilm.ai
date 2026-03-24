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
    // Share
    required this.share,
    required this.copied,
    // Disclaimer
    required this.disclaimer,
    // Portfolio builder
    required this.buildPortfolio,
    required this.buildPortfolioSubtitle,
    required this.enterAmount,
    required this.amountHint,
    required this.chooseStrategy,
    required this.strategyConservative,
    required this.strategyConservativeDesc,
    required this.strategyModerate,
    required this.strategyModerateDesc,
    required this.strategyAggressive,
    required this.strategyAggressiveDesc,
    required this.buildingPortfolio,
    required this.yourPortfolio,
    required this.expectedReturn,
    required this.annualRisk,
    required this.sharpeRatio,
    required this.allocation,
    required this.ticker,
    required this.weight,
    required this.amount,
    required this.sector,
    required this.addToWatchlist,
    required this.maxDrawdown,
    required this.rebalancing,
    required this.rebalancingQuarterly,
    required this.rebalancingSemiAnnual,
    required this.shares,
    required this.priceLabel,
    required this.name,
    required this.assetClass,
    required this.portfolioAnalysis,
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

  String rebalancingLabel(String frequency) =>
      frequency == 'semi-annual' ? rebalancingSemiAnnual : rebalancingQuarterly;

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

  // Share
  final String share;
  final String copied;

  // Disclaimer
  final String disclaimer;

  // Portfolio builder
  final String buildPortfolio;
  final String buildPortfolioSubtitle;
  final String enterAmount;
  final String amountHint;
  final String chooseStrategy;
  final String strategyConservative;
  final String strategyConservativeDesc;
  final String strategyModerate;
  final String strategyModerateDesc;
  final String strategyAggressive;
  final String strategyAggressiveDesc;
  final String buildingPortfolio;
  final String yourPortfolio;
  final String expectedReturn;
  final String annualRisk;
  final String sharpeRatio;
  final String allocation;
  final String ticker;
  final String weight;
  final String amount;
  final String sector;
  final String addToWatchlist;
  final String maxDrawdown;
  final String rebalancing;
  final String rebalancingQuarterly;
  final String rebalancingSemiAnnual;
  final String shares;
  final String priceLabel;
  final String name;
  final String assetClass;
  final String portfolioAnalysis;

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
            'Полная картина за 1 минуту — все 8 анализов в одном отчёте, чтобы принять решение не открывая другие сайты',
      ),
      'technical': ModeInfo(
        label: 'Технический анализ',
        bank: 'Citadel',
        description:
            'Когда покупать и продавать — точки входа и выхода на основе технических сигналов и уровней',
      ),
      'screener': ModeInfo(
        label: 'Скрининг',
        bank: 'Goldman Sachs',
        description:
            'Стоит ли акция своих денег — быстрая проверка фундаментала и мультипликаторов за 30 секунд',
      ),
      'risk': ModeInfo(
        label: 'Оценка рисков',
        bank: 'Bridgewater',
        description:
            'Что может пойти не так — скрытые риски которые вы можете пропустить и как от них защититься',
      ),
      'dcf': ModeInfo(
        label: 'DCF оценка',
        bank: 'Morgan Stanley',
        description:
            'Реальная цена акции — переоценена или недооценена прямо сейчас на основе будущих денежных потоков',
      ),
      'earnings': ModeInfo(
        label: 'Отчётность',
        bank: 'JPMorgan',
        description:
            'Готовность к отчётности — стоит ли держать акцию перед earnings или лучше выйти заранее',
      ),
      'portfolio': ModeInfo(
        label: 'Портфель',
        bank: 'BlackRock',
        description:
            'Как собрать портфель — оптимальные доли, балансировка секторов и снижение общего риска',
      ),
      'dividends': ModeInfo(
        label: 'Дивиденды',
        bank: 'Harvard',
        description:
            'Сколько заработаете пассивно — прогноз дивидендного дохода и надёжность выплат',
      ),
      'competitors': ModeInfo(
        label: 'Конкуренты',
        bank: 'Bain',
        description:
            'Лучше ли конкурентов — кто выигрывает в секторе по марже, росту и доле рынка',
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
    share: 'Поделиться',
    copied: 'Скопировано!',
    disclaimer: 'Данный анализ носит информационный характер и не является инвестиционной рекомендацией. Перед принятием инвестиционных решений проконсультируйтесь с финансовым советником.',
    buildPortfolio: 'Собрать портфель',
    buildPortfolioSubtitle: 'AI подберёт оптимальный портфель под вашу сумму и стратегию',
    enterAmount: 'Сумма инвестиций',
    amountHint: 'Например, 10000',
    chooseStrategy: 'Выберите стратегию',
    strategyConservative: 'Консервативная',
    strategyConservativeDesc: 'Минимальный риск, стабильный доход. Облигации и защитные активы.',
    strategyModerate: 'Умеренная',
    strategyModerateDesc: 'Баланс роста и защиты. Акции + облигации + альтернативы.',
    strategyAggressive: 'Агрессивная',
    strategyAggressiveDesc: 'Максимальный рост. Технологии, крипто, развивающиеся рынки.',
    buildingPortfolio: 'Собираем портфель...',
    yourPortfolio: 'Ваш портфель',
    expectedReturn: 'Ожидаемая доходность',
    annualRisk: 'Годовой риск',
    sharpeRatio: 'Коэффициент Шарпа',
    allocation: 'Распределение',
    ticker: 'Тикер',
    weight: 'Доля',
    amount: 'Сумма',
    sector: 'Сектор',
    addToWatchlist: 'В Watchlist',
    maxDrawdown: 'Макс. просадка',
    rebalancing: 'Ребалансировка',
    rebalancingQuarterly: 'Ежеквартально',
    rebalancingSemiAnnual: 'Раз в полгода',
    shares: 'Кол-во',
    priceLabel: 'Цена',
    name: 'Название',
    assetClass: 'Класс актива',
    portfolioAnalysis: 'Анализ портфеля',
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
            'Full picture in 1 minute — all 8 analyses in one report so you can decide without opening other sites',
      ),
      'technical': ModeInfo(
        label: 'Technical Analysis',
        bank: 'Citadel',
        description:
            'When to buy and sell — entry and exit points based on technical signals and levels',
      ),
      'screener': ModeInfo(
        label: 'Screening',
        bank: 'Goldman Sachs',
        description:
            'Is the stock worth it — quick fundamental and multiples check in 30 seconds',
      ),
      'risk': ModeInfo(
        label: 'Risk Assessment',
        bank: 'Bridgewater',
        description:
            'What could go wrong — hidden risks you might miss and how to protect against them',
      ),
      'dcf': ModeInfo(
        label: 'DCF Valuation',
        bank: 'Morgan Stanley',
        description:
            'True stock price — overvalued or undervalued right now based on future cash flows',
      ),
      'earnings': ModeInfo(
        label: 'Earnings',
        bank: 'JPMorgan',
        description:
            'Earnings readiness — should you hold before earnings or exit in advance',
      ),
      'portfolio': ModeInfo(
        label: 'Portfolio',
        bank: 'BlackRock',
        description:
            'How to build a portfolio — optimal allocations, sector balance, and overall risk reduction',
      ),
      'dividends': ModeInfo(
        label: 'Dividends',
        bank: 'Harvard',
        description:
            'How much passive income — dividend income forecast and payout reliability',
      ),
      'competitors': ModeInfo(
        label: 'Competitors',
        bank: 'Bain',
        description:
            'Better than competitors — who is winning in the sector by margins, growth, and market share',
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
    share: 'Share',
    copied: 'Copied!',
    disclaimer: 'This analysis is for informational purposes only and does not constitute investment advice. Consult a financial advisor before making investment decisions.',
    buildPortfolio: 'Build Portfolio',
    buildPortfolioSubtitle: 'AI will build an optimal portfolio for your amount and strategy',
    enterAmount: 'Investment Amount',
    amountHint: 'e.g., 10000',
    chooseStrategy: 'Choose Strategy',
    strategyConservative: 'Conservative',
    strategyConservativeDesc: 'Low risk, stable income. Bonds and defensive assets.',
    strategyModerate: 'Moderate',
    strategyModerateDesc: 'Balanced growth and protection. Stocks + bonds + alternatives.',
    strategyAggressive: 'Aggressive',
    strategyAggressiveDesc: 'Maximum growth. Tech, crypto, emerging markets.',
    buildingPortfolio: 'Building portfolio...',
    yourPortfolio: 'Your Portfolio',
    expectedReturn: 'Expected Return',
    annualRisk: 'Annual Risk',
    sharpeRatio: 'Sharpe Ratio',
    allocation: 'Allocation',
    ticker: 'Ticker',
    weight: 'Weight',
    amount: 'Amount',
    sector: 'Sector',
    addToWatchlist: 'Add to Watchlist',
    maxDrawdown: 'Max Drawdown',
    rebalancing: 'Rebalancing',
    rebalancingQuarterly: 'Quarterly',
    rebalancingSemiAnnual: 'Semi-annual',
    shares: 'Shares',
    priceLabel: 'Price',
    name: 'Name',
    assetClass: 'Asset Class',
    portfolioAnalysis: 'Portfolio Analysis',
    errorModeUnavailable: 'This mode is not available on your plan.',
    errorLimitReached: 'Analysis limit reached. Upgrade your plan to continue.',
    errorServer: 'Server error',
    errorNoConnection: 'No server connection',
    errorGeneric: 'An error occurred',
  );
}
