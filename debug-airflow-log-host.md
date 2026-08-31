# Debug Session: airflow-log-host
- **Status**: [OPEN]
- **Issue**: Airflow UI builds served-log URL as `http://:8793/...` so task logs cannot be read and the UI shows `No host supplied`.
- **Debug Server**: Pending start
- **Log File**: .dbg/trae-debug-log-airflow-log-host.ndjson

## Reproduction Steps
1. Open Airflow task log for a failed or running task.
2. Observe served-log request URL in the UI error details.
3. Confirm the host portion is empty before port `8793`.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Airflow worker/scheduler persists an empty hostname into metadata DB when creating job/task records. | High | Medium | Partially confirmed: `task_instance.hostname` for `market_data_stock_index.job.delete_before_load` on `scheduled__2026-08-31T00:00:00+00:00` is empty. |
| B | Current containers are still running with old config, so recent compose/config edits were not actually applied. | High | Low | Rejected: `get_hostname()` returns `airflow-worker` / `airflow-scheduler` in running containers. |
| C | `hostname_callable` resolves differently inside one or more Airflow services, so only some components write an empty host. | Medium | Medium | Rejected: both worker and scheduler resolve correctly with `socket.gethostname`. |
| D | The failing task belongs to an older DagRun/TaskInstance created before the hostname fix, so the stale DB row still contains empty host even if new runs are healthy. | Medium | Low | Inconclusive: row is recent, but stale state alone does not explain Redis enqueue failure. |
| E | A non-worker component (scheduler/dag-processor/triggerer) is the actor writing the empty hostname used for log serving. | Medium | Medium | Confirmed as symptom chain: scheduler fails to enqueue Celery task before worker can ever claim it. |

## Log Evidence
- Running containers use updated config: worker `get_hostname() -> airflow-worker`, scheduler `get_hostname() -> airflow-scheduler`.
- `task_instance` row for `market_data_stock_index.job.delete_before_load` / `scheduled__2026-08-31T00:00:00+00:00` has `hostname=''`.
- Scheduler resolves host `redis` to `172.19.0.3` on external `finance_network`, not local Redis `172.20.0.2`.
- Python Redis client from scheduler:
  - `redis://redis:6379/0` -> `AuthenticationError`
  - direct `172.20.0.2` -> `True`
- Scheduler/worker logs show `Error sending Celery task: Authentication required.` before worker execution.

## Verification Conclusion
Root cause identified: Airflow broker hostname `redis` collides with another Redis service on `finance_network` (container `redis_server`) that requires authentication. Celery connects to the wrong Redis, task dispatch fails before worker execution, and affected task instances retain an empty `hostname`, which later causes served-log URLs like `http://:8793/...`.
