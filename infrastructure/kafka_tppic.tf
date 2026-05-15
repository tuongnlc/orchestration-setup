resource "kafka_topic" "crawl_error_log" {
  name               = "crawl-error-log"
  replication_factor = 2
  partitions         = 2

  config = {
    "cleanup.policy"      = "compact"
    # "min.insync.replicas" = "1"
    "retention.ms"        = "604800000" # 7 days
    "delete.retention.ms" = "86400000"  # 1 day for delete retention
  }
}