"""
02_collect_articles.py

Coleta metadados e texto completo de artigos dos periódicos validados
via API ArticleMeta do SciELO.

Fluxo:
1. Lê lista de periódicos validados (data/raw/journals_list.csv)
2. Para cada periódico, lista PIDs de artigos no período
3. Para cada artigo, coleta metadados (JSON) e texto completo (XML JATS)
4. Salva metadados consolidados em CSV e textos em arquivos individuais

Auditabilidade:
- Respostas brutas da API salvas em data/raw/api_responses/articles/
- Log completo em data/raw/logs/
- Checkpoint incremental para retomada
- PIDs com falha registrados separadamente para retentativa

Uso:
    python scripts/02_collect_articles.py              # período padrão (2020)
    YEAR_FROM=2005 YEAR_UNTIL=2025 python scripts/02_collect_articles.py

Requer Python >= 3.10.

API docs: https://articlemeta.scielo.org
"""

import csv
import json
import logging
import os
import tempfile
import time
from collections.abc import Callable
from datetime import datetime, timezone
from io import TextIOWrapper
from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# --- Configuração ---

BASE_URL = "https://articlemeta.scielo.org/api/v1"
COLLECTION = "scl"
MAX_PAGINATION_PAGES = 200

# Período de PUBLICAÇÃO para filtro final no CSV (não usado na API)
PUB_YEAR_FROM = int(os.environ.get("PUB_YEAR_FROM", "2005"))
PUB_YEAR_UNTIL = int(os.environ.get("PUB_YEAR_UNTIL", "2025"))

# Diretórios
PROJECT_DIR = Path(__file__).parent.parent
DATA_DIR = PROJECT_DIR / "data" / "raw"
JOURNALS_FILE = DATA_DIR / "journals_list.csv"
API_CACHE_DIR = DATA_DIR / "api_responses" / "articles"
FULLTEXT_DIR = DATA_DIR / "articles_fulltext"
LOG_DIR = DATA_DIR / "logs"

# Tipos de documento a excluir (resenhas, editoriais, etc.)
EXCLUDED_DOC_TYPES = {
    "review", "book-review", "editorial", "letter",
    "correction", "erratum", "retraction", "news",
    "obituary", "reply", "comment",
}

# Colunas obrigatórias no CSV de entrada
REQUIRED_JOURNAL_COLUMNS = {"issn", "title"}


# --- Utilitários ---

def _atomic_write(path: Path, write_fn: Callable[[TextIOWrapper], None]) -> None:
    """Escreve arquivo atomicamente (via temporário + rename).

    Args:
        path: Caminho do arquivo de destino.
        write_fn: Callable que recebe o file handle e escreve o conteúdo.

    Raises:
        OSError: Se a escrita ou o rename falharem.
    """
    tmp_fd, tmp_path = tempfile.mkstemp(
        dir=path.parent, suffix=".tmp", prefix=path.stem
    )
    try:
        with open(tmp_fd, "w", encoding="utf-8", newline="") as f:
            write_fn(f)
        Path(tmp_path).replace(path)
    except BaseException:
        # Limpa temp file em qualquer falha, incluindo Ctrl+C
        Path(tmp_path).unlink(missing_ok=True)
        raise


def _atomic_json_write(path: Path, data: object) -> None:
    """Escreve JSON atomicamente.

    Args:
        path: Caminho do arquivo de destino.
        data: Objeto serializável para JSON.

    Raises:
        OSError: Se a escrita ou o rename falharem.
    """
    _atomic_write(path, lambda f: json.dump(data, f, ensure_ascii=False, indent=2))


# --- Logging ---

def setup_logging(run_timestamp: str) -> logging.Logger:
    """Configura logging para console e arquivo.

    Args:
        run_timestamp: Timestamp da execução para nomear o arquivo de log.

    Returns:
        Logger configurado com handlers para arquivo (DEBUG) e console (INFO).
    """
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / f"02_collect_articles_{run_timestamp}.log"

    logger = logging.getLogger("collect_articles")
    logger.setLevel(logging.DEBUG)
    if logger.handlers:
        logger.handlers.clear()

    fmt = logging.Formatter(
        "%(asctime)s | %(levelname)-7s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    logger.info("Log salvo em: %s", log_file)
    return logger


# --- HTTP ---

def create_session() -> requests.Session:
    """Cria sessão HTTP com retry e backoff exponencial.

    Returns:
        Sessão requests configurada com retry para status 429/5xx.
    """
    session = requests.Session()
    session.headers["User-Agent"] = "metodos_CP_collector/0.1 (academic research)"
    retries = Retry(
        total=3,
        backoff_factor=1.0,
        status_forcelist=[429, 500, 502, 503, 504],
    )
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


# --- Funções de coleta ---

def load_journals(path: Path, log: logging.Logger) -> list[dict]:
    """Carrega e valida lista de periódicos do CSV.

    Args:
        path: Caminho do CSV com periódicos.
        log: Logger.

    Returns:
        Lista de dicts com campos do CSV.

    Raises:
        ValueError: Se o CSV não contiver as colunas obrigatórias.
    """
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError(f"CSV vazio ou sem header: {path}")
        missing = REQUIRED_JOURNAL_COLUMNS - set(reader.fieldnames)
        if missing:
            raise ValueError(
                f"Colunas obrigatórias faltando em {path}: {missing}"
            )
        journals = list(reader)

    if not journals:
        raise ValueError(f"Nenhum periódico encontrado em {path}")

    log.info("CSV validado: %d periódicos, colunas: %s",
             len(journals), ", ".join(reader.fieldnames))
    return journals


def list_article_pids(
    issn: str,
    session: requests.Session,
    log: logging.Logger,
) -> tuple[list[dict], bool]:
    """Lista TODOS os PIDs de artigos de um periódico (sem filtro de data).

    A API filtra por processing_date, não publication_year. Para garantir
    cobertura completa, coletamos todos os artigos e filtramos por
    publication_year posteriormente.

    Args:
        issn: ISSN do periódico.
        session: Sessão HTTP.
        log: Logger.

    Returns:
        Tupla (lista de PIDs, is_complete). is_complete=False indica
        que a listagem pode estar incompleta por erro de rede.
    """
    articles: list[dict] = []
    offset = 0
    limit = 100
    is_complete = True

    for _page in range(MAX_PAGINATION_PAGES):
        url = f"{BASE_URL}/article/identifiers/"
        params = {
            "collection": COLLECTION,
            "issn": issn,
            "limit": limit,
            "offset": offset,
        }

        try:
            resp = session.get(url, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()
        except (requests.RequestException, ValueError) as e:
            log.warning("Erro ao listar artigos de %s (offset=%d): %s",
                         issn, offset, e, exc_info=True)
            is_complete = False
            break

        objects = data.get("objects", [])
        if not objects:
            break

        articles.extend(objects)
        total = data.get("meta", {}).get("total", "?")
        log.debug("ISSN %s: %d/%s PIDs coletados", issn, len(articles), total)

        offset += limit
        time.sleep(0.3)
    else:
        log.warning("Limite de paginação atingido para ISSN %s", issn)
        is_complete = False

    return articles, is_complete


def get_article_metadata(
    pid: str,
    session: requests.Session,
    log: logging.Logger,
) -> dict | None:
    """Obtém metadados completos de um artigo.

    Args:
        pid: PID (código SciELO) do artigo.
        session: Sessão HTTP.
        log: Logger.

    Returns:
        Dict com metadados, ou None em caso de erro.
    """
    url = f"{BASE_URL}/article/"
    params = {"code": pid, "collection": COLLECTION}

    try:
        resp = session.get(url, params=params, timeout=60)
        resp.raise_for_status()
        data = resp.json()
    except (requests.RequestException, ValueError) as e:
        log.warning("Erro ao obter metadados de %s: %s", pid, e, exc_info=True)
        return None

    if isinstance(data, list):
        data = data[0] if data else None
    if not isinstance(data, dict):
        log.warning("Resposta inesperada para %s: tipo %s",
                     pid, type(data).__name__)
        return None

    return data


def get_article_fulltext_xml(
    pid: str,
    session: requests.Session,
    log: logging.Logger,
) -> str | None:
    """Obtém texto completo em XML JATS de um artigo.

    Args:
        pid: PID do artigo.
        session: Sessão HTTP.
        log: Logger.

    Returns:
        String com XML, ou None em caso de erro ou indisponibilidade.
    """
    url = f"{BASE_URL}/article/"
    params = {"code": pid, "collection": COLLECTION, "format": "xmlrsps"}

    try:
        resp = session.get(url, params=params, timeout=60)
        resp.raise_for_status()
        content = resp.text
        if not content or content.strip().startswith("{"):
            log.debug("Sem XML para %s (resposta JSON ou vazia)", pid)
            return None
        return content
    except requests.RequestException as e:
        log.warning("Erro ao obter XML de %s: %s", pid, e, exc_info=True)
        return None


# --- Extração de campos ---

def _isis_field_text(field: list | None, lang: str = "") -> str:
    """Extrai texto de um campo ISIS (lista de dicts com chave '_').

    Args:
        field: Lista de dicts no formato ISIS [{\"_\": \"valor\", \"l\": \"pt\"}, ...].
        lang: Se especificado, filtra por idioma (chave 'l' ou 'a').

    Returns:
        Texto do primeiro item que casa, ou string vazia.
    """
    if not isinstance(field, list):
        return ""
    for item in field:
        if not isinstance(item, dict):
            continue
        if lang:
            item_lang = item.get("l", "")
            if item_lang == lang:
                return item.get("a", "") or item.get("_", "")
        else:
            return item.get("_", "")
    # Se buscou por lang e não encontrou, retorna primeiro disponível
    if lang and field:
        item = field[0]
        if isinstance(item, dict):
            return item.get("a", "") or item.get("_", "")
    return ""


def extract_article_record(pid: str, meta: dict) -> dict:
    """Extrai campos relevantes dos metadados de um artigo.

    A API ArticleMeta retorna metadados em dois níveis:
    - Nível superior: campos como code, doi, document_type, publication_date
    - meta[\"article\"]: campos ISIS (v10=autores, v12=título, v83=abstract, etc.)
    - meta[\"title\"]: metadados do PERIÓDICO (não do artigo!)

    Args:
        pid: PID do artigo.
        meta: Dict com metadados brutos da API.

    Returns:
        Dict com campos normalizados para o CSV.
    """
    art = meta.get("article", {}) or {}

    # Título (v12: lista de dicts com 'l'=idioma, '_'=texto)
    v12 = art.get("v12", [])
    title_pt = _isis_field_text(v12, "pt")
    title_en = _isis_field_text(v12, "en")
    title = title_pt or title_en or _isis_field_text(v12)

    # Autores (v10: lista de dicts com 'n'=given_names, 's'=surname, 'k'=ORCID)
    v10 = art.get("v10", []) or []
    authors = []
    for a in v10:
        if isinstance(a, dict):
            given = a.get("n", "")
            surname = a.get("s", "")
            name = f"{given} {surname}".strip()
            if name:
                authors.append(name)

    # Afiliações (v70: lista de dicts com '_'=instituição, 'p'=país, '1'=depto)
    v70 = art.get("v70", []) or []
    affiliations = []
    for aff in v70:
        if isinstance(aff, dict):
            inst = aff.get("_", "")
            dept = aff.get("1", "")
            country = aff.get("p", "")
            parts = [p for p in [dept, inst, country] if p]
            if parts:
                affiliations.append(", ".join(parts))

    # Abstract (v83: lista de dicts com 'a'=texto, 'l'=idioma)
    v83 = art.get("v83", [])
    abstract_pt = _isis_field_text(v83, "pt")
    abstract_en = _isis_field_text(v83, "en")

    # Ano (nível superior)
    pub_date = meta.get("publication_date", "") or ""
    year = pub_date[:4] if len(pub_date) >= 4 else ""

    # Tipo de documento (nível superior)
    doc_type = meta.get("document_type", "") or ""
    if isinstance(doc_type, list):
        doc_type = doc_type[0] if doc_type else ""

    # DOI (nível superior)
    doi = meta.get("doi", "") or ""

    # ISSN do periódico (de code_title ou title.v400)
    issn = ""
    code_title = meta.get("code_title")
    if isinstance(code_title, list) and code_title:
        issn = code_title[0]
    if not issn:
        title_meta = meta.get("title", {})
        if isinstance(title_meta, dict):
            v400 = title_meta.get("v400", [])
            if isinstance(v400, list) and v400:
                item = v400[0]
                issn = item.get("_", "") if isinstance(item, dict) else ""

    # Título do periódico (de title.v100)
    journal_title = ""
    title_meta = meta.get("title", {})
    if isinstance(title_meta, dict):
        v100 = title_meta.get("v100", [])
        if isinstance(v100, list) and v100:
            item = v100[0]
            journal_title = item.get("_", "") if isinstance(item, dict) else ""

    # Idioma (v40 no article, ou languages no nível superior)
    v40 = art.get("v40", [])
    language = _isis_field_text(v40)
    if not language:
        languages = meta.get("languages", []) or []
        language = languages[0] if languages else ""

    return {
        "pid": pid,
        "title": title,
        "title_en": title_en,
        "authors": "; ".join(authors),
        "affiliations": "; ".join(sorted(set(affiliations))),
        "year": year,
        "issn": issn,
        "journal_title": journal_title,
        "abstract_pt": abstract_pt,
        "abstract_en": abstract_en,
        "doi": doi,
        "document_type": doc_type,
        "language": language,
        "has_fulltext_xml": 0,
    }


def is_excluded_doc_type(doc_type: str) -> bool:
    """Verifica se o tipo de documento deve ser excluído.

    Args:
        doc_type: Tipo de documento retornado pela API.

    Returns:
        True se deve ser excluído (resenha, editorial, etc.).
    """
    if not doc_type:
        return False
    return doc_type.lower().strip() in EXCLUDED_DOC_TYPES


# --- Checkpoint ---

def save_checkpoint(
    path: Path,
    collected_pids: set[str],
    failed_pids: set[str],
    incomplete_issns: list[str],
) -> None:
    """Salva checkpoint atomicamente.

    O checkpoint salva apenas PIDs (não os artigos completos) para manter
    o arquivo leve mesmo com milhares de artigos. Os dados dos artigos
    são reconstruídos a partir dos JSONs individuais em api_responses/.

    Args:
        path: Caminho do checkpoint.
        collected_pids: PIDs já coletados com sucesso.
        failed_pids: PIDs que falharam (para retentativa futura).
        incomplete_issns: ISSNs com listagem possivelmente incompleta.
    """
    _atomic_json_write(path, {
        "collected_pids": sorted(collected_pids),
        "failed_pids": sorted(failed_pids),
        "incomplete_issns": incomplete_issns,
    })


def load_checkpoint(
    path: Path,
    log: logging.Logger,
) -> dict:
    """Carrega checkpoint, retornando dict vazio se não existe ou corrompido.

    Args:
        path: Caminho do checkpoint.
        log: Logger.

    Returns:
        Dict com dados do checkpoint.
    """
    if not path.exists():
        return {}
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        log.warning("Checkpoint corrompido (%s), reiniciando: %s", path, e)
        return {}


# --- Pipeline principal ---

def main() -> None:
    """Pipeline de coleta de artigos SciELO.

    Coleta metadados e texto completo de TODOS os artigos dos periódicos
    validados (sem filtro de data na API). O filtro por publication_year
    é aplicado apenas na geração do CSV final.

    Configurável via PUB_YEAR_FROM e PUB_YEAR_UNTIL (default: 2005-2025).
    """
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    # Setup
    API_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    FULLTEXT_DIR.mkdir(parents=True, exist_ok=True)
    log = setup_logging(run_timestamp)
    session = create_session()

    log.info("=" * 60)
    log.info("ETAPA 2: Coleta de artigos SciELO Brasil")
    log.info("Execução: %s", run_timestamp)
    log.info("Coleta: TODOS os artigos (sem filtro de data na API)")
    log.info("Filtro final no CSV: publication_year %d-%d",
             PUB_YEAR_FROM, PUB_YEAR_UNTIL)
    log.info("=" * 60)

    # Carregar periódicos validados
    if not JOURNALS_FILE.exists():
        log.error("Arquivo de periódicos não encontrado: %s", JOURNALS_FILE)
        raise FileNotFoundError(JOURNALS_FILE)

    journals = load_journals(JOURNALS_FILE, log)

    # Checkpoint
    checkpoint_file = DATA_DIR / "collection_checkpoint.json"
    checkpoint = load_checkpoint(checkpoint_file, log)
    collected_pids: set[str] = set(checkpoint.get("collected_pids", []))
    failed_pids: set[str] = set(checkpoint.get("failed_pids", []))
    incomplete_issns: list[str] = checkpoint.get("incomplete_issns", [])
    log.info("Checkpoint: %d coletados, %d falhados anteriormente",
             len(collected_pids), len(failed_pids))

    # --- Coleta ---
    total_pids_found = 0
    total_collected = len(collected_pids)
    total_excluded = 0
    total_xml = 0
    newly_collected = 0
    articles_data: list[dict] = []
    per_journal_counts: dict[str, int] = {}

    for journal in journals:
        issn = journal["issn"]
        title = journal["title"]
        log.info("--- %s (ISSN: %s) ---", title, issn)

        # Listar PIDs de artigos (todos, sem filtro de data)
        pid_list, is_complete = list_article_pids(issn, session, log)
        if not is_complete:
            log.warning("  LISTAGEM POSSIVELMENTE INCOMPLETA para %s", issn)
            if issn not in incomplete_issns:
                incomplete_issns.append(issn)

        log.info("  PIDs encontrados: %d", len(pid_list))
        total_pids_found += len(pid_list)
        journal_count = 0

        for pid_obj in pid_list:
            pid = pid_obj.get("code", "")
            if not pid or pid in collected_pids:
                continue

            # Obter metadados
            meta = get_article_metadata(pid, session, log)
            if not meta:
                failed_pids.add(pid)
                continue

            time.sleep(0.2)  # rate limiting entre metadata e XML

            # Salvar resposta bruta
            cache_file = API_CACHE_DIR / f"{pid}.json"
            try:
                _atomic_json_write(cache_file, meta)
            except OSError:
                log.warning("Falha ao salvar cache de %s", pid, exc_info=True)

            # Extrair record
            record = extract_article_record(pid, meta)

            # Filtrar tipos de documento excluídos
            if is_excluded_doc_type(record["document_type"]):
                log.debug("Excluído (tipo=%s): %s", record["document_type"], pid)
                total_excluded += 1
                collected_pids.add(pid)
                continue

            # Obter texto completo XML
            xml_content = get_article_fulltext_xml(pid, session, log)
            if xml_content:
                xml_file = FULLTEXT_DIR / f"{pid}.xml"
                try:
                    _atomic_write(xml_file, lambda f, c=xml_content: f.write(c))
                    record["has_fulltext_xml"] = 1
                    total_xml += 1
                except OSError:
                    log.warning("Falha ao salvar XML de %s", pid, exc_info=True)

            articles_data.append(record)
            collected_pids.add(pid)
            total_collected += 1
            newly_collected += 1
            journal_count += 1

            # Checkpoint a cada 20 artigos coletados
            if newly_collected % 20 == 0:
                save_checkpoint(checkpoint_file, collected_pids, failed_pids,
                                incomplete_issns)
                log.info("  Checkpoint: %d artigos coletados nesta execução",
                         newly_collected)

            time.sleep(0.3)

        per_journal_counts[f"{title} ({issn})"] = journal_count

    # Checkpoint final
    save_checkpoint(checkpoint_file, collected_pids, failed_pids,
                    incomplete_issns)

    # --- Reconstruir dataset completo a partir dos JSONs individuais ---
    # Garante que o CSV inclua TODOS os artigos (incluindo de execuções anteriores)
    log.info("Reconstruindo dataset a partir dos JSONs em cache...")
    all_articles: list[dict] = []
    filtered_articles: list[dict] = []
    for pid in sorted(collected_pids):
        cache_file = API_CACHE_DIR / f"{pid}.json"
        if not cache_file.exists():
            continue
        try:
            with open(cache_file, encoding="utf-8") as f:
                meta = json.load(f)
            record = extract_article_record(pid, meta)
            if is_excluded_doc_type(record["document_type"]):
                continue
            # Verificar se XML existe
            if (FULLTEXT_DIR / f"{pid}.xml").exists():
                record["has_fulltext_xml"] = 1
            all_articles.append(record)
            # Filtrar por publication_year
            try:
                pub_year = int(record["year"])
                if PUB_YEAR_FROM <= pub_year <= PUB_YEAR_UNTIL:
                    filtered_articles.append(record)
            except (ValueError, TypeError):
                log.debug("Ano inválido para %s: '%s'", pid, record["year"])
        except (json.JSONDecodeError, OSError, KeyError) as e:
            log.warning("Erro ao reconstruir record de %s: %s", pid, e)

    log.info("Dataset total: %d artigos", len(all_articles))
    log.info("Dataset filtrado (%d-%d): %d artigos",
             PUB_YEAR_FROM, PUB_YEAR_UNTIL, len(filtered_articles))

    # --- Salvar CSV (apenas artigos no período) ---
    output_file = DATA_DIR / f"articles_{PUB_YEAR_FROM}_{PUB_YEAR_UNTIL}.csv"
    fieldnames = [
        "pid", "title", "title_en", "authors", "affiliations", "year",
        "issn", "journal_title", "abstract_pt", "abstract_en",
        "doi", "document_type", "language", "has_fulltext_xml",
    ]

    try:
        def _write_csv(f: TextIOWrapper) -> None:
            writer = csv.DictWriter(
                f, fieldnames=fieldnames,
                extrasaction="ignore", restval="",
            )
            writer.writeheader()
            for article in sorted(filtered_articles, key=lambda x: x.get("pid", "")):
                writer.writerow(article)

        _atomic_write(output_file, _write_csv)
        log.info("Artigos salvos em: %s", output_file)
    except OSError:
        log.error("FALHA ao salvar CSV de artigos", exc_info=True)
        log.error("Dados preservados no checkpoint: %s", checkpoint_file)
        raise

    # --- Metadados da execução ---
    run_meta = {
        "timestamp": run_timestamp,
        "pub_year_from": PUB_YEAR_FROM,
        "pub_year_until": PUB_YEAR_UNTIL,
        "journals_count": len(journals),
        "pids_found": total_pids_found,
        "articles_total": len(all_articles),
        "articles_in_csv": len(filtered_articles),
        "articles_collected_this_run": newly_collected,
        "articles_excluded": total_excluded,
        "articles_with_xml": sum(1 for a in filtered_articles if a.get("has_fulltext_xml")),
        "articles_failed": len(failed_pids),
        "incomplete_issns": incomplete_issns,
        "xml_coverage_pct": round(
            sum(1 for a in filtered_articles if a.get("has_fulltext_xml"))
            / len(filtered_articles) * 100, 1
        ) if filtered_articles else 0,
        "per_journal": per_journal_counts,
    }
    meta_file = DATA_DIR / f"run_metadata_collect_{run_timestamp}.json"
    try:
        _atomic_json_write(meta_file, run_meta)
    except OSError:
        log.error("Falha ao salvar metadados", exc_info=True)

    # --- Resumo ---
    log.info("=" * 60)
    log.info("RESUMO")
    log.info("=" * 60)
    log.info("PIDs encontrados: %d", total_pids_found)
    log.info("Artigos coletados nesta execução: %d", newly_collected)
    log.info("Artigos excluídos (resenha/editorial/etc.): %d", total_excluded)
    log.info("Dataset total (todas as execuções): %d", len(all_articles))
    log.info("Dataset filtrado (%d-%d): %d",
             PUB_YEAR_FROM, PUB_YEAR_UNTIL, len(filtered_articles))
    if failed_pids:
        log.warning("PIDs com falha (não coletados): %d", len(failed_pids))
    if incomplete_issns:
        log.warning("ISSNs com listagem possivelmente incompleta: %s",
                     ", ".join(incomplete_issns))
    log.info("Artigos por periódico:")
    for jname, count in sorted(per_journal_counts.items(),
                                key=lambda x: x[1], reverse=True):
        log.info("  %-55s %d", jname, count)
    log.info("Metadados da execução: %s", meta_file)
    log.info("CSV: %s", output_file)

    # Limpar checkpoint
    if checkpoint_file.exists():
        checkpoint_file.unlink()
        log.info("Checkpoint removido (execução completa).")


if __name__ == "__main__":
    main()
