resource "kafka_topic" "crawl_log" {
  name               = "test-kafka-topic"
  replication_factor = 1
  partitions         = 1

  config = {
    "cleanup.policy"      = "compact"
    # "min.insync.replicas" = "1"
    "retention.ms"        = "604800000" # 7 days
    "delete.retention.ms" = "86400000"  # 1 day for delete retention
  }

  # Optional: Add tags for better management
  # tags = {
  #   Environment = "development"
  #   Project     = "orchestration-setup"
  # }
}