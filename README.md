Module terraform de de transfert de données sur BigQuery

:warning: **Ce repo n'est plus mis à jour**: utiliser les repos spécifique en fonctione de la bdd  
[oracle](https://github.com/gouv-nc-data/gcp-spark-oracle-to-bigquery)  
[Postgres](https://github.com/gouv-nc-data/gcp-spark-postgresql-to-bigquery)

# Ressources créées
* TODO

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_scheduler_job.job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job) | resource |
| [google_monitoring_alert_policy.errors](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_project_iam_custom_role.dataproc-custom-role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.bigquery_editor_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.bigquery_user_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.cloud_scheduler_runner_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.dataflow_custom_worker_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.dataflow_developer_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.dataflow_worker_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.cloudschedulerapi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.dataprocrapi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.secretmanagerapi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.gce-default-account-iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_secret_manager_secret_version.jdbc-url-secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dataset_name"></a> [dataset\_name](#input\_dataset\_name) | nom du projet | `string` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | Google groupe associé au projet | `string` | n/a | yes |
| <a name="input_jdbc-url-secret-name"></a> [jdbc-url-secret-name](#input\_jdbc-url-secret-name) | nom du secret contenant l'url de connexion jdbc à la BDD | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | id du projet | `string` | n/a | yes |
| <a name="input_queries"></a> [queries](#input\_queries) | n/a | `map(map(string))` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"europe-west1"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | expression cron de schedule du job | `string` | n/a | yes |
| <a name="input_type_database"></a> [type\_database](#input\_type\_database) | type de base de données: oracle ou postgresql | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | n/a |
<!-- END_TF_DOCS -->
