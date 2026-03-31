variable "aws_region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "function_name" {
  description = "Lambda 関数名"
  type        = string
  default     = "aurora-express-drizzle-sample"
}

variable "db_host" {
  description = "Aurora PostgreSQL クラスターエンドポイント"
  type        = string
}

variable "db_user" {
  description = "データベース IAM 認証ユーザー名"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "postgres"
}

variable "log_level" {
  description = "ログレベル（debug / info / warn / error）"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "log_level は debug, info, warn, error のいずれかを指定してください。"
  }
}

variable "tz" {
  description = "タイムゾーン（IANA 形式: Asia/Tokyo, UTC など）"
  type        = string
  default     = "Asia/Tokyo"
}

variable "tags" {
  description = "リソースに付与する追加タグ（Project / ManagedBy はデフォルトで設定される）"
  type        = map(string)
  default     = {}
}
