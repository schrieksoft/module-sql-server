// Generate a random server name
resource "random_string" "mssql_server_name" {
  length  = 24
  numeric = true
  lower   = true
  upper   = false
  special = false
}

// Server
resource "azurerm_mssql_server" "this" {
  name                = random_string.mssql_server_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
  version             = "12.0"
  minimum_tls_version = "1.2"

  tags = {
    name = var.name
  }

  dynamic "azuread_administrator" {
    for_each = {
      "administrators" : var.administrator_object_id,
    }

    content {
      azuread_authentication_only = true
      login_username              = azuread_administrator.key
      object_id                   = azuread_administrator.value
    }
  }
}

// Virtual Network Rule (Allow traffic from cluster)
resource "azurerm_mssql_virtual_network_rule" "apps" {
  name                                 = azurerm_mssql_server.this.name
  server_id                            = azurerm_mssql_server.this.id
  subnet_id                            = var.apps_subnet_id
  ignore_missing_vnet_service_endpoint = false
}

// Allow all traffic
resource "azurerm_mssql_firewall_rule" "all_ips" {
  count            = var.allow_all_ips ? 1 : 0
  name             = "${azurerm_mssql_server.this.name}-all"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
