# S3
resource "aws_s3_bucket" "quest013_bucket" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "quest013_bucket" {
  bucket = aws_s3_bucket.quest013_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "quest013_bucket" {
  bucket = aws_s3_bucket.quest013_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "quest013_database" {
  name = local.glue_database_name
}

# Glue Catalog Table
resource "aws_glue_catalog_table" "quest013_table" {
  database_name = aws_glue_catalog_database.quest013_database.name
  name          = local.glue_table_name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location = "s3://${aws_s3_bucket.quest013_bucket.bucket}/data/"

    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = local.glue_table_serde_name
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = ","
      }
    }

    columns {
      name = "adventurer_id"
      type = "string"
    }

    columns {
      name = "recorded_at"
      type = "string"
    }

    columns {
      name = "action"
      type = "string"
    }

    columns {
      name = "exp"
      type = "int"
    }
  }

  parameters = {
    "classification"         = "csv"
    "skip.header.line.count" = "1"
  }
}