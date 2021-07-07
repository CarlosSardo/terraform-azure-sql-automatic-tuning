# Declare  the required variables
variable "administrator_login" {
  description = "MS SQL Server Administrator username"
  type        = string
  sensitive   = true
}

variable "administrator_login_password" {
  description = "MS SQL Server Administrator password"
  type        = string
  sensitive   = true
}

variable "ip_address" {
  description = "Your public IP Address (to add it in the SQL Database firewall rules)"
  type        = string
  sensitive   = true
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

# Create a SQL Server
resource "azurerm_mssql_server" "example" {
  name                         = "example-sqlserver-5d28ddb2229f"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
}

# Create a SQL Database 
resource "azurerm_mssql_database" "test" {
  name      = "acctest-db-d"
  server_id = azurerm_mssql_server.example.id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  sku_name  = "Basic"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  start_ip_address    = var.ip_address
  end_ip_address      = var.ip_address
}

resource "null_resource" "db_setup" {
  depends_on = [azurerm_mssql_database.test]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sqlcmd -S ${azurerm_mssql_server.example.name}.database.windows.net -d ${azurerm_mssql_database.test.name} -U ${var.administrator_login} -P ${var.administrator_login_password} -i ./auto-tuning.sql"
  }
}