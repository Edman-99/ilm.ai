from __future__ import annotations

import glob
import os

from app.config import settings

CATEGORY_MAP = {
    "01_screener": "screener",
    "02_dcf": "dcf",
    "03_risk": "risk",
    "04_earnings": "earnings",
    "05_portfolio": "portfolio",
    "06_technical": "technical",
    "07_dividends": "dividends",
    "08_competitors": "competitors",
    "09_full_report": "master",
    "10_portfolio_user": "user_portfolio",
    "11_portfolio_blackrock": "blackrock_portfolio",
}


class VectorStore:
    """Простое keyword-based хранилище без внешних зависимостей."""

    def __init__(self) -> None:
        self._chunks: list[dict] = []
        self._loaded = False

    def load_knowledge(self) -> None:
        if self._loaded:
            return

        md_files = sorted(glob.glob(os.path.join(settings.documents_dir, "*.md")))
        if not md_files:
            print(f"[WARN] Нет .md файлов в {settings.documents_dir}")
            return

        for filepath in md_files:
            filename = os.path.basename(filepath)
            category = self._detect_category(filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            for chunk in self._split_by_sections(content):
                self._chunks.append({
                    "text": chunk["text"],
                    "source": filename,
                    "section": chunk.get("section", ""),
                    "category": category,
                })

        self._loaded = True
        print(f"[OK] Загружено {len(self._chunks)} чанков из {len(md_files)} файлов")

    def count(self) -> int:
        return len(self._chunks)

    def search(self, query: str, n_results: int = 5, category: str | None = None) -> list[dict]:
        if not self._loaded:
            self.load_knowledge()

        pool = [c for c in self._chunks if category is None or c["category"] == category]
        query_words = set(query.lower().split())

        def _score(chunk: dict) -> int:
            text = chunk["text"].lower()
            return sum(1 for w in query_words if w in text)

        ranked = sorted(pool, key=_score, reverse=True)
        return ranked[:n_results]

    def search_multi(self, query: str, categories: list[str] | None = None, n_per_cat: int = 2) -> list[dict]:
        if not categories:
            return self.search(query, n_results=8)
        results = []
        for cat in categories:
            results.extend(self.search(query, n_results=n_per_cat, category=cat))
        return results

    def _split_by_sections(self, text: str) -> list[dict]:
        chunks: list[dict] = []
        current_section = ""
        current_text: list[str] = []

        def _flush() -> None:
            combined = "\n".join(current_text).strip()
            if len(combined) > 50:
                chunks.append({"section": current_section, "text": combined})

        for line in text.split("\n"):
            if line.startswith("## "):
                _flush()
                current_section = line[3:].strip()
                current_text = [line]
            elif line.startswith("# ") and not line.startswith("##"):
                _flush()
                current_section = line[2:].strip()
                current_text = [line]
            else:
                current_text.append(line)

        _flush()
        if not chunks:
            chunks.append({"section": "full", "text": text.strip()})
        return chunks

    def _detect_category(self, filename: str) -> str:
        for key, cat in CATEGORY_MAP.items():
            if key in filename:
                return cat
        return "general"


rag_store = VectorStore()
