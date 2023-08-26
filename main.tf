
resource "google_service_account" "sa" {
  project                   = "ag-workload-identity-github"
  account_id = "test-storage-sa"
}


resource "google_service_account" "private" {
  project                   = "ag-workload-identity-github"
  account_id = "private-sa"
}


resource "google_project_iam_member" "sa" {
  project = "ag-workload-identity-github"
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "project" {
  project = "ag-workload-identity-github"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.private.email}"
}

resource "google_iam_workload_identity_pool" "main" {
  provider                  = google-beta
  project                   = "ag-workload-identity-github"
  workload_identity_pool_id = "github-general"
  display_name              = "github-general"
  description               = "General workload identity pool for github actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "main" {
  project                   = "ag-workload-identity-github"
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-general-provider"
  display_name                       = "github-general-provider"
  description                        = "General Github actions provider"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
    "attribute.environment" = "assertion.environment"
    "attribute.repository" = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.runner_environment" = "assertion.runner_environment"
    "attribute.ref" = "assertion.ref"
    "attribute.job_workflow_ref" = "assertion.job_workflow_ref"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  }

resource "google_service_account_iam_member" "storage" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/GoldbergAlexander/gcp-oidc"
}

resource "google_service_account_iam_member" "private" {
  service_account_id = google_service_account.private.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.job_workflow_ref/GoldbergAlexander/gcp-oidc/.github/workflows/reusable_workflow.yaml@refs/heads/main"
}

