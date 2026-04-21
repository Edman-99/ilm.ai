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
    required this.analyze,
    required this.recentAnalyses,
    required this.emptyHistory,
    required this.error,
    // Tabs
    required this.tabAiAnalysis,
    required this.tabTradingAnalytics,
    // How it works
    required this.howItWorks,
    required this.howItWorksSubtitle,
    required this.howItWorksSteps,
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
    // Trading CTA
    required this.tradingDemoButton,
    required this.tradingOrDivider,
    required this.tradingAlreadyClient,
    required this.tradingSignIn,
    required this.tradingNoAccount,
    required this.tradingOpenAccount,
    required this.tradingCtaTitle,
    required this.tradingCtaSubtitle,
    required this.tradingCtaButton,
    required this.tradingDemoLabel,
    required this.tradingPassword,
    required this.investlinkUrl,
    // Lead form
    required this.leadTitle,
    required this.leadSubtitle,
    required this.leadFirstName,
    required this.leadLastName,
    required this.leadEmail,
    required this.leadWhatsapp,
    required this.leadSubmit,
    required this.leadPrivacy,
    required this.leadFirstNameRequired,
    required this.leadEmailRequired,
    required this.leadEmailInvalid,
    // Errors
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
  final String analyze;
  final String recentAnalyses;
  final String emptyHistory;
  final String error;

  // Tabs
  final String tabAiAnalysis;
  final String tabTradingAnalytics;

  // How it works
  final String howItWorks;
  final String howItWorksSubtitle;
  final List<HowItWorksStep> howItWorksSteps;

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

  // Trading CTA
  final String tradingDemoButton;
  final String tradingOrDivider;
  final String tradingAlreadyClient;
  final String tradingSignIn;
  final String tradingNoAccount;
  final String tradingOpenAccount;
  final String tradingCtaTitle;
  final String tradingCtaSubtitle;
  final String tradingCtaButton;
  final String tradingDemoLabel;
  final String tradingPassword;
  final String investlinkUrl;

  // Lead form
  final String leadTitle;
  final String leadSubtitle;
  final String leadFirstName;
  final String leadLastName;
  final String leadEmail;
  final String leadWhatsapp;
  final String leadSubmit;
  final String leadPrivacy;
  final String leadFirstNameRequired;
  final String leadEmailRequired;
  final String leadEmailInvalid;

  // Errors
  final String errorServer;
  final String errorNoConnection;
  final String errorGeneric;

  String errorServerWithCode(int code) => '$errorServer ($code)';

  // ── RU ──
  static const ru = AppStrings._(
    heroTitle1: 'Анализ акций',
    heroTitle2: 'по методологиям топ-фондов',
    heroSubtitle: 'Введите тикер и выберите методологию',
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
    tickerHint: 'Например AAPL, TSLA, GOOGL',
    analyze: 'Анализировать',
    recentAnalyses: 'Недавние анализы',
    emptyHistory: 'Ваш первый анализ появится здесь',
    error: 'Ошибка',
    tabAiAnalysis: 'Анализ акций',
    tabTradingAnalytics: 'Trading Analytics',
    howItWorks: 'Как это работает',
    howItWorksSubtitle: 'Три простых шага до профессионального анализа',
    howItWorksSteps: [
      HowItWorksStep(
        title: 'Введите тикер',
        description:
            'Укажите тикер акции и выберите один из 9 режимов анализа',
      ),
      HowItWorksStep(
        title: 'Анализ по методологии',
        description:
            'Применяются методологии ведущих инвестиционных банков и фондов',
      ),
      HowItWorksStep(
        title: 'Получите отчёт',
        description:
            'Детальный анализ со скором, индикаторами и рекомендациями',
      ),
    ],
    overview: 'Обзор',
    quickVerdict: 'Быстрый вердикт',
    indicators: 'Индикаторы',
    technicalAnalysis: 'Технический анализ',
    aiAnalysis: 'Анализ',
    fullAiReport: 'Полный отчёт',
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
    swotOpportunityItems: ['Новые рынки', 'Расширение бизнеса'],
    swotThreatItems: ['Конкуренция', 'Регуляторные риски'],
    outOf100: 'из 100',
    signalBuy: 'ПОКУПКА',
    signalHold: 'ЖДАТЬ',
    signalSell: 'ПРОДАЖА',
    share: 'Поделиться',
    copied: 'Скопировано!',
    disclaimer:
        'Данный анализ носит информационный характер и не является инвестиционной рекомендацией. Перед принятием инвестиционных решений проконсультируйтесь с финансовым советником.',
    tradingDemoButton: 'Попробовать с демо-данными',
    tradingOrDivider: 'или',
    tradingAlreadyClient: 'Уже клиент Investlink?',
    tradingSignIn: 'Войти',
    tradingNoAccount: 'Нет аккаунта?',
    tradingOpenAccount: 'Открыть счёт в Investlink',
    tradingCtaTitle: 'Торгуйте акциями США с Investlink',
    tradingCtaSubtitle: 'Комиссия от \$0 · Доступ к 5000+ акций · Аналитика по методологиям',
    tradingCtaButton: 'Открыть счёт бесплатно',
    tradingDemoLabel: 'DEMO',
    tradingPassword: 'Пароль',
    investlinkUrl: 'https://investlink.kz/',
    leadTitle: 'Получите профессиональный анализ',
    leadSubtitle: 'Заполните форму и получите профессиональный отчёт за 30 секунд',
    leadFirstName: 'Имя',
    leadLastName: 'Фамилия',
    leadEmail: 'Email',
    leadWhatsapp: 'WhatsApp',
    leadSubmit: 'Получить анализ',
    leadPrivacy: 'Ваши данные защищены и не передаются третьим лицам',
    leadFirstNameRequired: 'Введите имя',
    leadEmailRequired: 'Введите email',
    leadEmailInvalid: 'Некорректный email',
    errorServer: 'Ошибка сервера',
    errorNoConnection: 'Нет подключения к серверу',
    errorGeneric: 'Произошла ошибка',
  );

  // ── EN ──
  static const en = AppStrings._(
    heroTitle1: 'Stock Analysis',
    heroTitle2: 'by top fund methodologies',
    heroSubtitle: 'Enter a ticker and choose a methodology',
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
    tickerHint: 'e.g. AAPL, TSLA, GOOGL',
    analyze: 'Analyze',
    recentAnalyses: 'Recent analyses',
    emptyHistory: 'Your first analysis will appear here',
    error: 'Error',
    tabAiAnalysis: 'Stock Analysis',
    tabTradingAnalytics: 'Trading Analytics',
    howItWorks: 'How it works',
    howItWorksSubtitle: 'Three simple steps to professional analysis',
    howItWorksSteps: [
      HowItWorksStep(
        title: 'Enter ticker',
        description:
            'Enter a stock ticker and choose one of 9 analysis modes',
      ),
      HowItWorksStep(
        title: 'Analysis by methodology',
        description:
            'Methodologies of leading investment banks and funds are applied',
      ),
      HowItWorksStep(
        title: 'Get report',
        description:
            'Detailed analysis with score, indicators, and recommendations',
      ),
    ],
    overview: 'Overview',
    quickVerdict: 'Quick verdict',
    indicators: 'Indicators',
    technicalAnalysis: 'Technical Analysis',
    aiAnalysis: 'Analysis',
    fullAiReport: 'Full report',
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
    swotOpportunityItems: ['New markets', 'Business expansion'],
    swotThreatItems: ['Competition', 'Regulatory risks'],
    outOf100: 'out of 100',
    signalBuy: 'BUY',
    signalHold: 'HOLD',
    signalSell: 'SELL',
    share: 'Share',
    copied: 'Copied!',
    disclaimer:
        'This analysis is for informational purposes only and does not constitute investment advice. Consult a financial advisor before making investment decisions.',
    tradingDemoButton: 'Try with demo data',
    tradingOrDivider: 'or',
    tradingAlreadyClient: 'Already an Investlink client?',
    tradingSignIn: 'Sign In',
    tradingNoAccount: 'No account yet?',
    tradingOpenAccount: 'Open Investlink Account',
    tradingCtaTitle: 'Trade US stocks with Investlink',
    tradingCtaSubtitle: 'Commission from \$0 · Access to 5000+ stocks · Methodology-based analytics',
    tradingCtaButton: 'Open Account for Free',
    tradingDemoLabel: 'DEMO',
    tradingPassword: 'Password',
    investlinkUrl: 'https://investlink.io/',
    leadTitle: 'Get Professional Analysis',
    leadSubtitle: 'Fill in the form and get a professional report in 30 seconds',
    leadFirstName: 'First name',
    leadLastName: 'Last name',
    leadEmail: 'Email',
    leadWhatsapp: 'WhatsApp',
    leadSubmit: 'Get Analysis',
    leadPrivacy: 'Your data is secure and never shared with third parties',
    leadFirstNameRequired: 'Enter your name',
    leadEmailRequired: 'Enter your email',
    leadEmailInvalid: 'Invalid email',
    errorServer: 'Server error',
    errorNoConnection: 'No server connection',
    errorGeneric: 'An error occurred',
  );
}
