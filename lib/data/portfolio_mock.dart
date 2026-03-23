// Mock data for AI Portfolio builder.

class PortfolioPosition {
  const PortfolioPosition({
    required this.ticker,
    required this.name,
    required this.sector,
    required this.weight,
    required this.color,
  });

  final String ticker;
  final String name;
  final String sector;
  final double weight; // 0..1
  final int color; // hex color for pie chart

  double amount(double total) => total * weight;
}

class PortfolioResult {
  const PortfolioResult({
    required this.positions,
    required this.expectedReturn,
    required this.risk,
    required this.sharpe,
    required this.analysis,
  });

  final List<PortfolioPosition> positions;
  final double expectedReturn; // annual %
  final double risk; // annual volatility %
  final double sharpe;
  final String analysis; // markdown

  Map<String, double> get sectorWeights {
    final map = <String, double>{};
    for (final p in positions) {
      map[p.sector] = (map[p.sector] ?? 0) + p.weight;
    }
    return map;
  }
}

enum PortfolioStrategy { conservative, moderate, aggressive }

const mockPortfolios = <PortfolioStrategy, PortfolioResult>{
  // ── Conservative ──
  PortfolioStrategy.conservative: PortfolioResult(
    expectedReturn: 7.2,
    risk: 8.5,
    sharpe: 0.85,
    positions: [
      PortfolioPosition(
        ticker: 'BND',
        name: 'Vanguard Total Bond',
        sector: 'Bonds',
        weight: 0.30,
        color: 0xFF3B82F6,
      ),
      PortfolioPosition(
        ticker: 'VTI',
        name: 'Vanguard Total Stock',
        sector: 'US Equity',
        weight: 0.20,
        color: 0xFF22C55E,
      ),
      PortfolioPosition(
        ticker: 'VXUS',
        name: 'Vanguard Intl Stock',
        sector: 'Intl Equity',
        weight: 0.15,
        color: 0xFF8B5CF6,
      ),
      PortfolioPosition(
        ticker: 'VNQ',
        name: 'Vanguard Real Estate',
        sector: 'Real Estate',
        weight: 0.10,
        color: 0xFFF59E0B,
      ),
      PortfolioPosition(
        ticker: 'GLD',
        name: 'SPDR Gold',
        sector: 'Commodities',
        weight: 0.10,
        color: 0xFFEAB308,
      ),
      PortfolioPosition(
        ticker: 'TIP',
        name: 'iShares TIPS Bond',
        sector: 'Bonds',
        weight: 0.15,
        color: 0xFF60A5FA,
      ),
    ],
    analysis: '''## Консервативный портфель

Портфель ориентирован на **сохранение капитала** с умеренным ростом. Основа — облигации (45%), которые обеспечивают стабильный доход и защиту от волатильности.

### Ключевые характеристики
- **Низкая волатильность** — просадки не превышают 10-12% даже в кризисные периоды
- **Стабильный доход** — дивиденды и купоны ~3-4% годовых
- **Защита от инфляции** — TIPS и золото хеджируют инфляционные риски

### Рекомендации
- Подходит для горизонта **3-5 лет**
- Ребалансировка раз в квартал
- При снижении ставок ФРС можно увеличить долю акций до 40%''',
  ),

  // ── Moderate ──
  PortfolioStrategy.moderate: PortfolioResult(
    expectedReturn: 10.5,
    risk: 14.2,
    sharpe: 0.74,
    positions: [
      PortfolioPosition(
        ticker: 'VOO',
        name: 'Vanguard S&P 500',
        sector: 'US Equity',
        weight: 0.30,
        color: 0xFF22C55E,
      ),
      PortfolioPosition(
        ticker: 'QQQ',
        name: 'Invesco Nasdaq 100',
        sector: 'Tech',
        weight: 0.15,
        color: 0xFF6366F1,
      ),
      PortfolioPosition(
        ticker: 'VXUS',
        name: 'Vanguard Intl Stock',
        sector: 'Intl Equity',
        weight: 0.15,
        color: 0xFF8B5CF6,
      ),
      PortfolioPosition(
        ticker: 'BND',
        name: 'Vanguard Total Bond',
        sector: 'Bonds',
        weight: 0.15,
        color: 0xFF3B82F6,
      ),
      PortfolioPosition(
        ticker: 'VNQ',
        name: 'Vanguard Real Estate',
        sector: 'Real Estate',
        weight: 0.10,
        color: 0xFFF59E0B,
      ),
      PortfolioPosition(
        ticker: 'SCHD',
        name: 'Schwab US Dividend',
        sector: 'Dividends',
        weight: 0.10,
        color: 0xFF14B8A6,
      ),
      PortfolioPosition(
        ticker: 'GLD',
        name: 'SPDR Gold',
        sector: 'Commodities',
        weight: 0.05,
        color: 0xFFEAB308,
      ),
    ],
    analysis: '''## Умеренный портфель

Сбалансированный подход — **60% акции, 25% облигации и защитные активы, 15% альтернативы**. Оптимален для большинства инвесторов.

### Ключевые характеристики
- **Сбалансированный рост** — исторически ~10% годовых
- **Диверсификация** — 7 ETF покрывают все основные классы активов
- **Дивидендный поток** — SCHD + VNQ дают ~2.5% дивидендной доходности

### Рекомендации
- Подходит для горизонта **5-10 лет**
- Ребалансировка раз в полгода
- QQQ даёт экспозицию на AI и tech-рост без чрезмерной концентрации''',
  ),

  // ── Aggressive ──
  PortfolioStrategy.aggressive: PortfolioResult(
    expectedReturn: 14.8,
    risk: 22.5,
    sharpe: 0.66,
    positions: [
      PortfolioPosition(
        ticker: 'QQQ',
        name: 'Invesco Nasdaq 100',
        sector: 'Tech',
        weight: 0.25,
        color: 0xFF6366F1,
      ),
      PortfolioPosition(
        ticker: 'SOXX',
        name: 'iShares Semiconductor',
        sector: 'Semiconductors',
        weight: 0.15,
        color: 0xFFEC4899,
      ),
      PortfolioPosition(
        ticker: 'VOO',
        name: 'Vanguard S&P 500',
        sector: 'US Equity',
        weight: 0.20,
        color: 0xFF22C55E,
      ),
      PortfolioPosition(
        ticker: 'VWO',
        name: 'Vanguard Emerging Markets',
        sector: 'Emerging Markets',
        weight: 0.15,
        color: 0xFFF97316,
      ),
      PortfolioPosition(
        ticker: 'ARKK',
        name: 'ARK Innovation',
        sector: 'Innovation',
        weight: 0.10,
        color: 0xFFE11D48,
      ),
      PortfolioPosition(
        ticker: 'BTC-USD',
        name: 'Bitcoin',
        sector: 'Crypto',
        weight: 0.10,
        color: 0xFFF59E0B,
      ),
      PortfolioPosition(
        ticker: 'GLD',
        name: 'SPDR Gold',
        sector: 'Commodities',
        weight: 0.05,
        color: 0xFFEAB308,
      ),
    ],
    analysis: '''## Агрессивный портфель

Портфель нацелен на **максимальный рост капитала**. Высокая доля технологий, emerging markets и криптовалюты. Готовьтесь к просадкам 25-35%.

### Ключевые характеристики
- **Высокий потенциал роста** — исторически 15%+ годовых в хорошие годы
- **Tech-heavy** — 40% в технологиях и полупроводниках (AI, облачные вычисления)
- **Crypto экспозиция** — 10% в Bitcoin как ставка на цифровые активы

### Рекомендации
- Подходит для горизонта **10+ лет**
- Ребалансировка при отклонении долей >5%
- Не паникуйте при просадках — это нормально для данного профиля риска
- Рассмотрите DCA (регулярные покупки) вместо единовременного входа''',
  ),
};
