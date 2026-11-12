variable "region" {
  description = "Región de AWS donde se despliegan todos los recursos del ejercicio."
  type        = string
  default     = "us-east-1"
}

variable "nombre_bucket" {
  description = "Nombre global y único del bucket S3 privado del ejercicio."
  type        = string
  default     = "de-final-entregas-evyg06"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.nombre_bucket))
    error_message = "El nombre del bucket debe tener entre 3 y 63 caracteres en minúscula, números, puntos o guiones."
  }
}

variable "prefijo_datos" {
  description = "Prefijo del bucket donde se cargan los CSV de entregas."
  type        = string
  default     = "entregas/"

  validation {
    condition     = endswith(var.prefijo_datos, "/")
    error_message = "El prefijo de datos debe terminar en /."
  }
}

variable "prefijo_resultados" {
  description = "Prefijo del bucket donde Athena escribe los resultados de las consultas."
  type        = string
  default     = "resultados-athena/"

  validation {
    condition     = endswith(var.prefijo_resultados, "/")
    error_message = "El prefijo de resultados debe terminar en /."
  }
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos en Glue Data Catalog."
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de intentos de entrega."
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena del ejercicio."
  type        = string
  default     = "entregas-wg"
}

variable "fecha_inicio_proyeccion" {
  description = "Primera fecha proyectada (incluida), en formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin_proyeccion" {
  description = "Última fecha proyectada (incluida), en formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-03"
}
