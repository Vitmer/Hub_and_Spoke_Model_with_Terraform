##############################
# AZURE AD MFA POLICY (DEFAULT: ALL USERS)
##############################

# Retrieve information about the current Entra ID (Azure AD) client
data "azuread_client_config" "current" {}

# MAIN CONFIGURATION: MFA FOR ALL USERS (default setting)
resource "azuread_conditional_access_policy" "require_mfa" {
  display_name = "Require MFA for All Users"
  state        = "enabled"
  conditions {
    users {
      included_users = ["All"]  # Require MFA for ALL users
    }

    applications {
      included_applications = ["All"]  # MFA applies to all cloud applications
    }

    client_app_types = ["all"] # Required argument (Defines supported app types)
  }

  grant_controls {
    built_in_controls = ["mfa"]
    operator         = "OR"
  }

}

#########################################
# 💡 ADDITIONAL CONFIGURATION OPTIONS
#########################################

# OPTION 1: MFA ONLY FOR A SPECIFIC USER GROUP
# --------------------------------------------------------------
# If you want to enable MFA only for a specific group of users,
# uncomment this code and add the required users to the "Require MFA Group".

/*
resource "azuread_group" "mfa_group" {
  display_name     = "Require MFA Group"
  security_enabled = true
}

resource "azuread_conditional_access_policy" "require_mfa_group" {
  display_name = "Require MFA for Group"
  state        = "enabled"

  conditions {
    users {
      include_groups = [azuread_group.mfa_group.id]  #  Applies MFA only to this group!
    }

    applications {
      include_applications = ["all"]
    }
  }

  grant_controls {
    built_in_controls = ["mfa"]
    operator         = "OR"
  }

  session_controls {
    sign_in_frequency {
      value  = 1
      unit   = "days"
    }
  }
}
*/

#  OPTION 2: MFA ONLY FOR ADMINISTRATORS
# --------------------------------------------------------------
# If you want to enable MFA only for users with the Global Administrator role,
# uncomment this code. The Global Administrator role ID is "62e90394-69f5-4237-9190-012177145e10".

/*
resource "azuread_conditional_access_policy" "require_mfa_admins" {
  display_name = "Require MFA for Admins"
  state        = "enabled"

  conditions {
    users {
      include_roles = ["62e90394-69f5-4237-9190-012177145e10"]  # Applies MFA only to admins!
    }

    applications {
      include_applications = ["all"]
    }
  }

  grant_controls {
    built_in_controls = ["mfa"]
    operator         = "OR"
  }

  session_controls {
    sign_in_frequency {
      value  = 1
      unit   = "days"
    }
  }
}
*/