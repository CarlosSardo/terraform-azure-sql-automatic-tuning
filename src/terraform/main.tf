# Declare  the required variables
variable "ip_address" {
  description = "Your current public IP Address (to be added in the SQL Database firewall rules)"
  type        = string
  sensitive   = true
}

# need random suffix for log analytics workspace, to avoid soft deletion conflicts
resource "random_string" "resources_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "mssql_server_administrator_login" {
  length  = 12
  special = false
}

resource "random_password" "mssql_server_administrator_login_password" {
  length  = 24
  special = false
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "example-resources-${random_string.resources_suffix.result}"
  location = "West Europe"
}

# Create a SQL Server
resource "azurerm_mssql_server" "example" {
  name                         = "example-sqlserver-${random_string.resources_suffix.result}"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = random_string.mssql_server_administrator_login.result
  administrator_login_password = random_password.mssql_server_administrator_login_password.result
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
    command = "sqlcmd -S ${azurerm_mssql_server.example.name}.database.windows.net -d ${azurerm_mssql_database.test.name} -U ${random_string.mssql_server_administrator_login.result} -P ${random_password.mssql_server_administrator_login_password.result} -i ./auto-tuning.sql"
  }
}