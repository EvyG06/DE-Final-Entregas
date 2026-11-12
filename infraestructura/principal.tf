terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  ubicacion_datos      = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_datos}"
  ubicacion_resultados = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_resultados}"
}

# ---------------------------------------------------------------------------
# S3: bucket privado con prefijos entregas/ y resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket = var.nombre_bucket

  # Permite que terraform destroy elimine el bucket aunque tenga objetos.
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Glue Data Catalog: base de datos y tabla externa con partition projection
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Catalogo de intentos de entrega del examen final"
}

resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  description   = "Intentos de entrega en CSV particionados por fecha mediante partition projection"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones durante la consulta.
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio_proyeccion},${var.fecha_fin_proyeccion}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # Prefijo de cada partición. $${fecha} produce el literal ${fecha} para Athena.
    "storage.location.template" = "${local.ubicacion_datos}fecha=$${fecha}/"
  }

  partition_keys {
    name    = "fecha"
    type    = "string"
    comment = "Fecha del archivo, tomada de la carpeta fecha=yyyy-MM-dd"
  }

  storage_descriptor {
    location      = local.ubicacion_datos
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-coma"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name    = "id_envio"
      type    = "string"
      comment = "Identificador unico del envio"
    }

    columns {
      name    = "ciudad"
      type    = "string"
      comment = "Ciudad del intento de entrega"
    }

    columns {
      name    = "transportadora"
      type    = "string"
      comment = "Transportadora responsable del intento"
    }

    columns {
      name    = "estado"
      type    = "string"
      comment = "entregado, destinatario_ausente o direccion_incorrecta"
    }

    columns {
      name    = "duracion_minutos"
      type    = "int"
      comment = "Duracion positiva si estado es entregado y 0 si el intento fallo"
    }
  }
}

# ---------------------------------------------------------------------------
# Athena: workgroup con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  description   = "Workgroup del examen final de entregas"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = local.ubicacion_resultados

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
