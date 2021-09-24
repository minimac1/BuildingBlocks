#!/usr/bin/env bash
source ./scripts/helper/service_helper.sh

fn_export_tf_vars
cd infra
terraform "${@}"