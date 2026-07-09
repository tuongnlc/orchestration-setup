[OPEN] Debug session: airflow-src-import

Issue:
- Airflow raises `ModuleNotFoundError: No module named 'src.shared'` while parsing DAGs that import from `finance-data-crawler`.

Scope:
- No business logic changes before runtime evidence is collected.
- First phase focuses on environment, mount, and import-path verification inside Airflow containers.

Hypotheses:
- H1: The running `airflow-scheduler` or `airflow-dag-processor` container does not have the expected `PYTHONPATH`.
- H2: The `finance-data-crawler` volume is not mounted as expected inside the Airflow container.
- H3: Airflow is running an older image/container state and has not picked up local file changes such as added `__init__.py`.
- H4: Python resolves a different top-level `src` package before the mounted repo path, so `src.shared` is not found.
- H5: The failing process is not the same service that was restarted, and another Airflow component still parses DAGs with stale environment.

Plan:
1. Inspect compose services and container status.
2. Read effective environment and filesystem inside relevant Airflow containers.
3. Reproduce the import manually with `python -c`.
4. Confirm or reject hypotheses based on output.
5. Only then propose the minimal fix.

Evidence:
- `docker compose ps` shows both `airflow-scheduler` and `airflow-dag-processor` are running with both mounts: `/opt/airflow/finance_data_crawler` and `/opt/airflow/finance_ai_engineer`.
- In `airflow-dag-processor`, `PYTHONPATH` is `/opt/airflow/finance_data_crawler:/opt/airflow/etl_pipeline:/opt/airflow/finance_ai_engineer`.
- In `airflow-dag-processor`, `importlib.util.find_spec("src")` resolves to `/opt/airflow/finance_ai_engineer/src/__init__.py`.
- In the same container, `find_spec("src.shared")` returns `None`.
- `/opt/airflow/finance_data_crawler/src` exists and contains `shared`, but does not contain `__init__.py`.

Hypothesis Status:
- H1 rejected: `PYTHONPATH` is present in the failing container.
- H2 rejected: the crawler repo is mounted and visible in the failing container.
- H3 partially rejected: container sees recent files, but the top-level package file is still missing from `finance-data-crawler/src`.
- H4 confirmed: `src` resolves to `finance_ai_engineer/src`, which shadows the crawler's namespace package.
- H5 less likely: one failing process is enough to explain DAG import failure, and the evidence already pinpoints the collision.

Current Conclusion:
- Root cause is package shadowing on the top-level module name `src`.
- `finance-ai-engineer` provides a regular package at `src/__init__.py`.
- `finance-data-crawler` provides only a namespace-style `src` directory, so Python selects the regular package from `finance-ai-engineer`, making `src.shared` unavailable.

Additional Evidence:
- `etl-pipeline` has its own regular package at `etl-pipeline/src/__init__.py`.
- `etl-pipeline` imports `from src.utils.config_loader import load_and_parse_config` in `src/orchestration/dag_builder/task_factories/trigger_dag_factory.py`.
- After the crawler package was fixed, `airflow-dag-processor` now resolves `src` to `/opt/airflow/finance_data_crawler/src/__init__.py`.
- In that same process, `find_spec("src.utils")` is `None` while `find_spec("src.shared")` resolves under `finance_data_crawler`.

Updated Conclusion:
- The system has multiple independent projects exposing the same top-level package name `src`.
- Only one regular package named `src` can win in a given Python process, based on import order and `sys.path`.
- Fixing one project by making its `src` explicit causes another project's `src.*` imports to fail.
