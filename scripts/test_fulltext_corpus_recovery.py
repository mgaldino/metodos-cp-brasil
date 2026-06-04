import importlib.util
from pathlib import Path


def load_module():
    path = Path(__file__).with_name("16_recover_fulltext_corpus.py")
    spec = importlib.util.spec_from_file_location("fulltext_corpus_recovery", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_reference_heading_rule_avoids_body_sentence_false_positive():
    module = load_module()
    assert not module.corpus_is_reference_heading(
        "Referências ao voto feminino aparecem aqui e ali nos anos finais do Império."
    )
    assert not module.corpus_is_reference_heading(
        "REFERENCIAS CONCEPTUALES: LAS RELACIONES DE GÉNERO Y EL ANÁLISIS GENERACIONAL"
    )
    assert module.corpus_is_reference_heading("Referências")
    assert module.corpus_is_reference_heading("Bibliographic references")


def test_doi_candidate_url_normalizes_plain_and_prefixed_dois():
    module = load_module()
    assert module.doi_candidate_url({"doi": "10.1590/DADOS.2025.68.4.392"}) == (
        "https://doi.org/10.1590/DADOS.2025.68.4.392"
    )
    assert module.doi_candidate_url({"doi": "doi:10.1590/test"}) == (
        "https://doi.org/10.1590/test"
    )
    assert module.doi_candidate_url({"doi": "https://doi.org/10.1590/test"}) == (
        "https://doi.org/10.1590/test"
    )
    assert module.doi_candidate_url({"doi": ""}) == ""


def test_substantive_last_attempt_ignores_offline_cache_misses():
    module = load_module()
    attempts = [
        {
            "source_method": "articlemeta_fulltexts_html",
            "status": "invalid",
            "reason": "too_short_for_body",
        },
        {
            "source_method": "pdf_text_extraction",
            "status": "skipped",
            "reason": "offline_no_cache",
        },
    ]
    last = module.substantive_last_attempt(attempts)
    assert last["source_method"] == "articlemeta_fulltexts_html"
    assert last["reason"] == "too_short_for_body"


def test_duplicate_processed_rows_are_moved_to_failures():
    module = load_module()
    processed = {
        "pid_a": {
            "pid": "pid_a",
            "body_text": "same body",
            "input_hash": "a" * 64,
            "source_method": "articlemeta_fulltexts_html",
            "source_url": "https://example.org/a",
            "input_path": "data/raw/fulltext_corpus/html/pid_a.html",
        },
        "pid_b": {
            "pid": "pid_b",
            "body_text": "same body",
            "input_hash": "a" * 64,
            "source_method": "articlemeta_fulltexts_html",
            "source_url": "https://example.org/b",
            "input_path": "data/raw/fulltext_corpus/html/pid_b.html",
        },
    }
    failures = {}
    metadata = {
        "pid_a": {"pid": "pid_a", "title": "A"},
        "pid_b": {"pid": "pid_b", "title": "B"},
    }
    module.move_duplicate_processed_rows_to_failures(
        processed,
        failures,
        metadata,
        "run",
    )
    assert processed == {}
    assert set(failures) == {"pid_a", "pid_b"}
    assert failures["pid_a"]["last_reason"] == "duplicate_input_hash_or_body_hash_across_pids"
