"""
01_discover_journals.py

Consulta a API ArticleMeta do SciELO para:
1. Listar todos os periódicos da coleção Brasil (scl)
2. Filtrar por subject areas relevantes para CP/RI
3. Estimar volume de artigos por periódico no período 2005-2025
4. Salvar lista em CSV para validação manual

Auditabilidade:
- Todas as respostas brutas da API são salvas em data/raw/api_responses/
- Log completo da execução salvo em data/raw/logs/
- Periódicos rejeitados salvos para auditoria
- Metadados da execução (parâmetros, filtros, timestamp) salvos em JSON

Requer Python >= 3.10 (usa list[dict], dict | None, set[str]).

API docs: https://articlemeta.scielo.org
"""

import csv
import json
import logging
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
COLLECTION = "scl"  # Brasil
PERIOD_FROM = "2005-01-01"
PERIOD_UNTIL = "2025-12-31"
MAX_PAGINATION_PAGES = 50  # limite de segurança contra paginação infinita

# Subject areas relevantes — match parcial case-insensitive.
# "social sciences" excluído por ser amplo demais; periódicos de ciências
# sociais genéricas serão capturados via seed list ou validação manual.
RELEVANT_SUBJECTS = [
    "political science",
    "public administration",
    "international relations",
    "ciência política",
    "ciencias politicas",
    "administração pública",
    "relações internacionais",
    "public policy",
    "políticas públicas",
]

# ISSNs conhecidos de periódicos relevantes (seed list para validação)
KNOWN_RELEVANT_ISSNS = {
    "0011-5258",  # Dados
    "0102-6909",  # RBCS - Revista Brasileira de Ciências Sociais
    "1981-3821",  # BPSR - Brazilian Political Science Review
    "0104-6276",  # Opinião Pública
    "0034-7329",  # RBPI - Revista Brasileira de Política Internacional
    "0102-6445",  # Lua Nova
    "0101-3300",  # Novos Estudos CEBRAP
    "1678-9873",  # Revista de Sociologia e Política
}

# Diretórios
PROJECT_DIR = Path(__file__).parent.parent
DATA_DIR = PROJECT_DIR / "data" / "raw"
API_CACHE_DIR = DATA_DIR / "api_responses" / "journals"
LOG_DIR = DATA_DIR / "logs"


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
    log_file = LOG_DIR / f"01_discover_journals_{run_timestamp}.log"

    logger = logging.getLogger("discover_journals")
    logger.setLevel(logging.DEBUG)

    # Evitar acumular handlers se chamado mais de uma vez
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
    """Cria sessão HTTP com retry automático e backoff exponencial.

    Returns:
        Sessão requests configurada com retry para status 429/5xx.
    """
    session = requests.Session()
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

def get_all_journals(
    session: requests.Session,
    log: logging.Logger,
) -> list[dict]:
    """Lista todos os periódicos da coleção Brasil.

    Args:
        session: Sessão HTTP com retry configurado.
        log: Logger para registrar progresso e erros.

    Returns:
        Lista de dicts com identificadores de periódicos.

    Raises:
        RuntimeError: Se a paginação for interrompida por erro de rede
            ou resposta inválida, indicando lista possivelmente incompleta.
    """
    journals: list[dict] = []
    offset = 0
    limit = 100

    for _page in range(MAX_PAGINATION_PAGES):
        url = f"{BASE_URL}/journal/identifiers/"
        params = {"collection": COLLECTION, "limit": limit, "offset": offset}

        try:
            resp = session.get(url, params=params, timeout=30)
            resp.raise_for_status()
        except requests.RequestException as e:
            log.error("Erro ao buscar journals (offset=%d): %s", offset, e)
            raise RuntimeError(
                f"Paginação interrompida em offset={offset}. "
                f"{len(journals)} periódicos coletados podem estar incompletos."
            ) from e

        try:
            data = resp.json()
        except ValueError as e:
            log.error("Resposta não-JSON ao buscar journals (offset=%d)", offset)
            raise RuntimeError(
                f"API retornou resposta inválida em offset={offset}."
            ) from e

        objects = data.get("objects", [])
        if not objects:
            log.debug("Paginação encerrada: sem objetos em offset=%d", offset)
            break

        journals.extend(objects)
        log.info("Coletados %d identificadores de periódicos...", len(journals))

        offset += limit
        time.sleep(0.5)
    else:
        log.warning(
            "Limite de paginação atingido (%d páginas). "
            "Lista pode estar incompleta.", MAX_PAGINATION_PAGES
        )

    return journals


def get_journal_metadata(
    issn: str,
    session: requests.Session,
    log: logging.Logger,
) -> dict | None:
    """Obtém metadados completos de um periódico e salva resposta bruta.

    Args:
        issn: ISSN do periódico.
        session: Sessão HTTP.
        log: Logger.

    Returns:
        Dict com metadados do periódico, ou None em caso de erro.
    """
    url = f"{BASE_URL}/journal/"
    params = {"issn": issn, "collection": COLLECTION}

    try:
        resp = session.get(url, params=params, timeout=30)
        resp.raise_for_status()
    except requests.RequestException as e:
        log.warning("Erro ao buscar metadados do periódico %s: %s",
                     issn, e, exc_info=True)
        return None

    try:
        data = resp.json()
    except ValueError:
        log.warning("Resposta não-JSON para periódico %s (status=%d)",
                     issn, resp.status_code)
        return None

    # A API pode retornar uma lista (com um único elemento) em vez de dict
    if isinstance(data, list):
        if data:
            data = data[0]
            log.debug("API retornou lista para %s, usando primeiro elemento", issn)
        else:
            log.warning("API retornou lista vazia para %s", issn)
            return None

    if not isinstance(data, dict):
        log.warning("API retornou tipo inesperado para %s: %s",
                     issn, type(data).__name__)
        return None

    # Salvar resposta bruta para auditoria
    cache_file = API_CACHE_DIR / f"{issn}.json"
    try:
        _atomic_json_write(cache_file, data)
    except OSError:
        log.warning("Não foi possível salvar cache para %s", issn, exc_info=True)

    return data


def get_article_count(
    issn: str,
    session: requests.Session,
    log: logging.Logger,
    from_date: str = PERIOD_FROM,
    until_date: str = PERIOD_UNTIL,
) -> int | None:
    """Conta artigos de um periódico em um período.

    Args:
        issn: ISSN do periódico.
        session: Sessão HTTP.
        log: Logger.
        from_date: Data inicial (YYYY-MM-DD).
        until_date: Data final (YYYY-MM-DD).

    Returns:
        Número de artigos, ou None em caso de erro na consulta.
    """
    url = f"{BASE_URL}/article/identifiers/"
    params = {
        "collection": COLLECTION,
        "issn": issn,
        "from": from_date,
        "until": until_date,
        "limit": 1,  # só queremos o total
    }

    try:
        resp = session.get(url, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        total = data.get("meta", {}).get("total")
        if total is None:
            log.warning("Campo 'meta.total' ausente na resposta para %s", issn)
            return None
        return total
    except requests.RequestException as e:
        log.warning("Erro ao contar artigos de %s: %s", issn, e, exc_info=True)
        return None
    except ValueError:
        log.warning("Resposta não-JSON ao contar artigos de %s", issn)
        return None


# --- Extração de metadados ---

def extract_subject_areas(journal_meta: dict) -> set[str]:
    """Extrai subject areas dos metadados do periódico.

    A API ArticleMeta retorna subject areas em campos variados dependendo
    do periódico. Campos consultados:
    - v350: subject areas do periódico (formato ISIS)
    - v854: WoS subject areas
    - v441: áreas temáticas CNPq
    - subject_areas: campo de nível superior (formato REST)
    - study_areas, subject_descriptors: campos alternativos

    Args:
        journal_meta: Dict com metadados brutos do periódico.

    Returns:
        Conjunto de strings com as subject areas encontradas.
    """
    areas: set[str] = set()

    for field_key in ["v350", "v854", "v441"]:
        field = journal_meta.get(field_key, [])
        if isinstance(field, list):
            for item in field:
                if isinstance(item, dict):
                    for val in item.values():
                        if isinstance(val, str):
                            areas.add(val.strip())
                elif isinstance(item, str):
                    areas.add(item.strip())
        elif isinstance(field, str):
            areas.add(field.strip())

    if "subject_areas" in journal_meta:
        sa = journal_meta["subject_areas"]
        if isinstance(sa, list):
            areas.update(sa)

    for key in ["study_areas", "subject_descriptors"]:
        if key in journal_meta:
            val = journal_meta[key]
            if isinstance(val, list):
                for item in val:
                    if isinstance(item, str):
                        areas.add(item.strip())
                    elif isinstance(item, dict):
                        for v in item.values():
                            if isinstance(v, str):
                                areas.add(v.strip())

    return areas


def extract_title(journal_meta: dict) -> str:
    """Extrai título do periódico dos metadados.

    Args:
        journal_meta: Dict com metadados brutos do periódico.

    Returns:
        Título do periódico, ou string vazia se não encontrado.
    """
    for key in ["v100", "v150"]:
        field = journal_meta.get(key, [])
        if isinstance(field, list) and field:
            item = field[0]
            if isinstance(item, dict):
                title = item.get("_", "")
            elif isinstance(item, str):
                title = item
            else:
                title = ""
            if title:
                return title

    title = journal_meta.get("title", "") or journal_meta.get("v100", "")
    if isinstance(title, list) and title:
        return str(title[0])
    if isinstance(title, str):
        return title
    return ""


def is_relevant(subject_areas: set[str]) -> bool:
    """Verifica se as subject areas indicam relevância para CP/RI.

    Usa match parcial case-insensitive: cada subject area do periódico é
    verificada contra cada termo em RELEVANT_SUBJECTS.

    Args:
        subject_areas: Conjunto de subject areas do periódico.

    Returns:
        True se pelo menos uma subject area casar com um termo relevante.
    """
    for area in subject_areas:
        area_lower = area.lower()
        for relevant in RELEVANT_SUBJECTS:
            if relevant in area_lower:
                return True
    return False


# --- Checkpoint ---

def save_checkpoint(
    path: Path,
    relevant: list[dict],
    rejected: list[dict],
    processed_issns: set[str],
    all_subject_areas: set[str],
) -> None:
    """Salva checkpoint incremental atomicamente.

    Args:
        path: Caminho do arquivo de checkpoint.
        relevant: Lista de periódicos relevantes encontrados.
        rejected: Lista de periódicos rejeitados.
        processed_issns: ISSNs já processados.
        all_subject_areas: Todas as subject areas encontradas.
    """
    _atomic_json_write(path, {
        "relevant": relevant,
        "rejected": rejected,
        "processed_issns": sorted(processed_issns),
        "all_subject_areas": sorted(all_subject_areas),
    })


def load_checkpoint(
    path: Path,
    log: logging.Logger,
) -> tuple[list[dict], list[dict], set[str], set[str]]:
    """Carrega checkpoint anterior se existir.

    Args:
        path: Caminho do arquivo de checkpoint.
        log: Logger.

    Returns:
        Tupla (relevant, rejected, processed_issns, all_subject_areas).
    """
    if not path.exists():
        return [], [], set(), set()

    try:
        with open(path, encoding="utf-8") as f:
            checkpoint = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        log.warning("Checkpoint corrompido (%s), reiniciando do zero: %s",
                     path, e)
        return [], [], set(), set()

    relevant = checkpoint.get("relevant", [])
    rejected = checkpoint.get("rejected", [])
    processed_issns = set(checkpoint.get("processed_issns", []))
    all_subject_areas = set(checkpoint.get("all_subject_areas", []))
    log.info("Checkpoint carregado: %d processados anteriormente",
             len(processed_issns))
    return relevant, rejected, processed_issns, all_subject_areas


# --- Pipeline principal ---

def main() -> None:
    """Pipeline de descoberta de periódicos SciELO Brasil.

    Executa 4 passos sequenciais:
    1. Lista todos os periódicos da coleção Brasil via API
    2. Filtra por subject area relevante (CP/RI/áreas afins)
    3. Estima volume de artigos por periódico no período configurado
    4. Salva resultados (CSV, JSON de metadados, logs)

    Suporta retomada via checkpoint em caso de interrupção.
    """
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    # Setup
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    API_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    log = setup_logging(run_timestamp)
    session = create_session()

    log.info("=" * 60)
    log.info("ETAPA 1: Descoberta de periódicos SciELO Brasil")
    log.info("Execução: %s", run_timestamp)
    log.info("Período: %s a %s", PERIOD_FROM, PERIOD_UNTIL)
    log.info("=" * 60)

    # --- Passo 1: Listar todos os periódicos ---
    log.info("1. Listando todos os periódicos da coleção Brasil...")
    journal_ids = get_all_journals(session, log)
    log.info("Total de periódicos encontrados: %d", len(journal_ids))

    # Salvar lista bruta de IDs para auditoria
    ids_file = DATA_DIR / "journal_ids_raw.json"
    try:
        _atomic_json_write(ids_file, journal_ids)
    except OSError:
        log.error("Falha ao salvar lista bruta de IDs", exc_info=True)
        raise

    # --- Passo 2: Obter metadados e filtrar por subject area ---
    log.info("2. Obtendo metadados e filtrando por subject area...")
    checkpoint_file = DATA_DIR / "discovery_checkpoint.json"

    relevant_journals, rejected_journals, processed_issns, all_subject_areas = \
        load_checkpoint(checkpoint_file, log)

    newly_processed = 0
    for j in journal_ids:
        issn = j.get("code", "")
        if not issn or issn in processed_issns:
            continue

        meta = get_journal_metadata(issn, session, log)
        if not meta:
            processed_issns.add(issn)
            continue

        subject_areas = extract_subject_areas(meta)
        all_subject_areas.update(subject_areas)
        title = extract_title(meta)

        is_known = issn in KNOWN_RELEVANT_ISSNS
        matched_subject = is_relevant(subject_areas)
        is_rel = matched_subject or is_known

        record = {
            "issn": issn,
            "title": title,
            "subject_areas": "; ".join(sorted(subject_areas)),
            "is_known_seed": is_known,
            "matched_by": ("seed_list" if is_known and not matched_subject
                           else "subject_area" if is_rel else "rejected"),
        }

        if is_rel:
            relevant_journals.append(record)
        else:
            rejected_journals.append(record)

        processed_issns.add(issn)
        newly_processed += 1

        if newly_processed % 20 == 0:
            log.info("Processados %d/%d periódicos, %d relevantes",
                     len(processed_issns), len(journal_ids),
                     len(relevant_journals))
            save_checkpoint(checkpoint_file, relevant_journals,
                            rejected_journals, processed_issns,
                            all_subject_areas)

        time.sleep(0.3)

    log.info("Total de periódicos relevantes: %d", len(relevant_journals))
    log.info("Total de periódicos rejeitados: %d", len(rejected_journals))

    # Checkpoint final do passo 2 (garante que últimos items sejam salvos)
    save_checkpoint(checkpoint_file, relevant_journals,
                    rejected_journals, processed_issns, all_subject_areas)

    # Salvar todas as subject areas encontradas
    areas_file = DATA_DIR / "all_subject_areas.json"
    try:
        _atomic_json_write(areas_file, sorted(all_subject_areas))
    except OSError:
        log.error("Falha ao salvar subject areas", exc_info=True)

    # Salvar periódicos rejeitados para auditoria
    rejected_file = DATA_DIR / "journals_rejected.csv"
    rejected_fields = ["issn", "title", "subject_areas"]
    try:
        def _write_rejected(f: TextIOWrapper) -> None:
            writer = csv.DictWriter(f, fieldnames=rejected_fields, restval="")
            writer.writeheader()
            for j in sorted(rejected_journals, key=lambda x: x.get("title", "")):
                writer.writerow({k: j[k] for k in rejected_fields})

        _atomic_write(rejected_file, _write_rejected)
        log.info("Periódicos rejeitados salvos em: %s", rejected_file)
    except OSError:
        log.error("Falha ao salvar periódicos rejeitados", exc_info=True)

    # --- Passo 3: Contar artigos por periódico ---
    log.info("3. Estimando volume de artigos por periódico (%s a %s)...",
             PERIOD_FROM, PERIOD_UNTIL)
    newly_counted = 0
    for j in relevant_journals:
        if "article_count" in j and j["article_count"] is not None:
            continue  # já contado em checkpoint anterior
        count = get_article_count(j["issn"], session, log)
        j["article_count"] = count
        newly_counted += 1
        count_str = str(count) if count is not None else "ERRO"
        log.info("%-50s | ISSN: %s | Artigos: %s",
                 j["title"][:50], j["issn"], count_str)

        # Checkpoint durante contagem (a cada 10 periódicos contados)
        if newly_counted % 10 == 0:
            save_checkpoint(checkpoint_file, relevant_journals,
                            rejected_journals, processed_issns,
                            all_subject_areas)

        time.sleep(0.3)

    # Checkpoint final antes de salvar resultados
    save_checkpoint(checkpoint_file, relevant_journals,
                    rejected_journals, processed_issns, all_subject_areas)

    # --- Passo 4: Salvar resultado final ---
    output_file = DATA_DIR / "journals_list.csv"
    fieldnames = [
        "issn", "title", "subject_areas", "is_known_seed",
        "matched_by", "article_count",
    ]

    try:
        sorted_journals = sorted(
            relevant_journals,
            key=lambda x: x.get("article_count") or 0,
            reverse=True,
        )

        def _write_results(f: TextIOWrapper) -> None:
            writer = csv.DictWriter(
                f, fieldnames=fieldnames,
                extrasaction="ignore", restval="",
            )
            writer.writeheader()
            for j in sorted_journals:
                writer.writerow(j)

        _atomic_write(output_file, _write_results)
        log.info("Lista salva em: %s", output_file)
    except OSError:
        log.error("FALHA CRÍTICA ao salvar resultado final", exc_info=True)
        log.error("Dados preservados no checkpoint: %s", checkpoint_file)
        raise

    # Salvar metadados da execução
    total_articles = sum(
        j["article_count"]
        for j in relevant_journals
        if isinstance(j.get("article_count"), int) and j["article_count"] > 0
    )
    errors_count = sum(
        1 for j in relevant_journals if j.get("article_count") is None
    )

    run_meta = {
        "timestamp": run_timestamp,
        "base_url": BASE_URL,
        "collection": COLLECTION,
        "period_from": PERIOD_FROM,
        "period_until": PERIOD_UNTIL,
        "relevant_subjects_filter": RELEVANT_SUBJECTS,
        "known_issns": sorted(KNOWN_RELEVANT_ISSNS),
        "total_journals_scanned": len(journal_ids),
        "total_relevant": len(relevant_journals),
        "total_rejected": len(rejected_journals),
        "total_articles_estimated": total_articles,
        "count_errors": errors_count,
    }
    meta_file = DATA_DIR / f"run_metadata_{run_timestamp}.json"
    try:
        _atomic_json_write(meta_file, run_meta)
    except OSError:
        log.error("Falha ao salvar metadados da execução", exc_info=True)

    # --- Resumo ---
    seed_found = sum(1 for j in relevant_journals if j["is_known_seed"])

    log.info("=" * 60)
    log.info("RESUMO")
    log.info("=" * 60)
    log.info("Periódicos relevantes: %d", len(relevant_journals))
    log.info("Artigos estimados (%s-%s): %d",
             PERIOD_FROM[:4], PERIOD_UNTIL[:4], total_articles)
    if errors_count:
        log.warning("Periódicos com erro na contagem: %d", errors_count)
    log.info("Periódicos da seed list encontrados: %d/%d",
             seed_found, len(KNOWN_RELEVANT_ISSNS))

    found_issns = {j["issn"] for j in relevant_journals}
    missing_seeds = KNOWN_RELEVANT_ISSNS - found_issns
    if missing_seeds:
        log.warning("Seed list ISSNs NÃO encontrados: %s",
                     ", ".join(sorted(missing_seeds)))
    else:
        log.info("Todos os ISSNs da seed list foram encontrados.")

    log.info("Metadados da execução: %s", meta_file)
    log.info("Próximo passo: revisar %s e validar a lista.", output_file)

    # Limpar checkpoint somente após todas as escritas terem sucesso
    if checkpoint_file.exists():
        checkpoint_file.unlink()
        log.info("Checkpoint removido (execução completa).")


if __name__ == "__main__":
    main()
