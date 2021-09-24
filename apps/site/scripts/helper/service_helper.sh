#!/usr/bin/env bash
fn_export_tf_vars() {
    set -a
    TF_VAR_aws_access_key=${AWS_ACCESS_KEY}
    TF_VAR_aws_secret_key=${AWS_SECRET_ACCESS_KEY}
    TF_VAR_aws_region=${AWS_REGION}
    TF_VAR_current_date="$(date)"
    TF_VAR_instance_name="${SITE_NAME}"
    set +a
}