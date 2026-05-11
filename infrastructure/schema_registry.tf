resource "schemaregistry_schema" "crawl_log_key" {
  subject     = "${kafka_topic.crawl_error_log.name}-key"
  schema_type = "AVRO"

  schema = <<EOF
{
  "type": "record",
  "name": "CrawlErrorLogKey",
  "namespace": "com.finance_ai.market_data",
  "fields": [
    { "name": "partition_key", "type": "string" }
  ]
}
EOF
}

resource "schemaregistry_schema" "crawl_log_value" {
  subject     = "${kafka_topic.crawl_error_log.name}-value"
  schema_type = "AVRO"

  schema = <<EOF
{
  "type": "record",
  "name": "CrawlErrorLog",
  "namespace": "com.finance_ai.market_data",
  "fields": [
    { "name": "event_id", "type": "string" },
    { "name": "event_time", "type": { "type": "long", "logicalType": "timestamp-millis" } },
    { "name": "service", "type": "string" },
    { "name": "crawler_name", "type": "string" },
    { "name": "job_name", "type": "string" },
    { "name": "error_type", "type": "string" },
    { "name": "error_message", "type": "string" },
    { "name": "stage", "type": "string" },
    { "name": "partition_key", "type": "string" },
  ]
}
EOF
}