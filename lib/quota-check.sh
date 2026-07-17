#!/usr/bin/env bash
# quota-check.sh — Cloud provider quota pre-flight
# Sourceable library for checking AWS, GCP, and Azure quotas before deploying.
#
# SAFETY: This script NEVER auto-increases quotas without explicit user action.
# - Default mode is read-only (safe for AI agents)
# - --increase flag required to request quota increases
# - Interactive mode prompts for confirmation before any increase
#
# shellcheck disable=SC2034

# ─── Constants ───────────────────────────────────────────────────────────────

declare -A QUOTA_AWS_CODES=(
    [elastic_ips]="L-0263D0A3"
    [vpcs]="L-F678F1CE"
    [nat_gateways]="L-FE5A380F"
    [alb]="L-53DA6B97"
)

declare -A QUOTA_AWS_DEFAULTS=(
    [elastic_ips]=5
    [vpcs]=5
    [nat_gateways]=5
    [alb]=20
    [vcpus]=64
)

# ─── Colors ──────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
    _QC_RED='\033[0;31m'; _QC_GREEN='\033[0;32m'; _QC_YELLOW='\033[1;33m'
    _QC_BLUE='\033[0;34m'; _QC_BOLD='\033[1m'; _QC_RESET='\033[0m'
else
    _QC_RED=''; _QC_GREEN=''; _QC_YELLOW=''; _QC_BLUE=''; _QC_BOLD=''; _QC_RESET=''
fi

# ─── Resource Calculation ────────────────────────────────────────────────────

quota_calculate() {
    local type="$1"
    local num_clusters="${2:-1}"

    declare -gA QUOTA_REQUIRED=()

    case "$type" in
        hub-student)
            local total=$((num_clusters + 1))
            QUOTA_REQUIRED[elastic_ips]=$total
            QUOTA_REQUIRED[vpcs]=$total
            QUOTA_REQUIRED[nat_gateways]=$total
            QUOTA_REQUIRED[alb]=$total
            QUOTA_REQUIRED[vcpus]=$(( 8 + (num_clusters * 16) ))  # hub=8, student=16 each
            ;;
        demo)
            QUOTA_REQUIRED[elastic_ips]=1
            QUOTA_REQUIRED[vpcs]=1
            QUOTA_REQUIRED[nat_gateways]=1
            QUOTA_REQUIRED[alb]=1
            QUOTA_REQUIRED[vcpus]=16
            ;;
        agnosticd-infra)
            QUOTA_REQUIRED[elastic_ips]=$num_clusters
            QUOTA_REQUIRED[vpcs]=$num_clusters
            QUOTA_REQUIRED[nat_gateways]=$num_clusters
            QUOTA_REQUIRED[alb]=$num_clusters
            QUOTA_REQUIRED[vcpus]=$((num_clusters * 16))
            ;;
    esac
}

# ─── AWS Quota Check ─────────────────────────────────────────────────────────

quota_check_aws() {
    local region="$1"

    if ! command -v aws &>/dev/null; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} AWS CLI not found. Install: sudo dnf install -y awscli2"
        return 1
    fi

    if ! aws sts get-caller-identity &>/dev/null 2>&1; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} AWS credentials not configured. Run: aws configure"
        return 1
    fi

    declare -gA QUOTA_CURRENT=()
    declare -gA QUOTA_USED=()

    # Elastic IPs
    QUOTA_CURRENT[elastic_ips]=$(aws service-quotas get-service-quota \
        --service-code ec2 --quota-code "${QUOTA_AWS_CODES[elastic_ips]}" \
        --region "$region" --query 'Quota.Value' --output text 2>/dev/null) || \
        QUOTA_CURRENT[elastic_ips]="${QUOTA_AWS_DEFAULTS[elastic_ips]}"
    QUOTA_USED[elastic_ips]=$(aws ec2 describe-addresses --region "$region" \
        --query 'Addresses | length(@)' --output text 2>/dev/null) || \
        QUOTA_USED[elastic_ips]=0

    # VPCs
    QUOTA_CURRENT[vpcs]=$(aws service-quotas get-service-quota \
        --service-code vpc --quota-code "${QUOTA_AWS_CODES[vpcs]}" \
        --region "$region" --query 'Quota.Value' --output text 2>/dev/null) || \
        QUOTA_CURRENT[vpcs]="${QUOTA_AWS_DEFAULTS[vpcs]}"
    QUOTA_USED[vpcs]=$(aws ec2 describe-vpcs --region "$region" \
        --query 'Vpcs | length(@)' --output text 2>/dev/null) || \
        QUOTA_USED[vpcs]=0

    # NAT Gateways
    QUOTA_CURRENT[nat_gateways]=$(aws service-quotas get-service-quota \
        --service-code vpc --quota-code "${QUOTA_AWS_CODES[nat_gateways]}" \
        --region "$region" --query 'Quota.Value' --output text 2>/dev/null) || \
        QUOTA_CURRENT[nat_gateways]="${QUOTA_AWS_DEFAULTS[nat_gateways]}"
    QUOTA_USED[nat_gateways]=$(aws ec2 describe-nat-gateways --region "$region" \
        --filter "Name=state,Values=available" \
        --query 'NatGateways | length(@)' --output text 2>/dev/null) || \
        QUOTA_USED[nat_gateways]=0

    # vCPUs (approximate - uses running instances)
    QUOTA_CURRENT[vcpus]="${QUOTA_AWS_DEFAULTS[vcpus]}"
    QUOTA_USED[vcpus]=$(aws ec2 describe-instances --region "$region" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].CpuOptions.CoreCount' --output text 2>/dev/null | \
        awk '{s+=$1}END{print s+0}') || \
        QUOTA_USED[vcpus]=0
}

# ─── GCP Quota Check ─────────────────────────────────────────────────────────

quota_check_gcp() {
    local region="$1"

    if ! command -v gcloud &>/dev/null; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} gcloud CLI not found. Install: https://cloud.google.com/sdk/docs/install"
        return 1
    fi

    declare -gA QUOTA_CURRENT=()
    declare -gA QUOTA_USED=()

    local quota_json
    quota_json="$(gcloud compute regions describe "$region" --format=json 2>/dev/null)" || {
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} Cannot query GCP quotas for region: $region"
        return 1
    }

    QUOTA_CURRENT[elastic_ips]=$(echo "$quota_json" | jq -r '.quotas[] | select(.metric == "STATIC_ADDRESSES") | .limit' 2>/dev/null) || QUOTA_CURRENT[elastic_ips]=8
    QUOTA_USED[elastic_ips]=$(echo "$quota_json" | jq -r '.quotas[] | select(.metric == "STATIC_ADDRESSES") | .usage' 2>/dev/null) || QUOTA_USED[elastic_ips]=0

    QUOTA_CURRENT[vcpus]=$(echo "$quota_json" | jq -r '.quotas[] | select(.metric == "CPUS") | .limit' 2>/dev/null) || QUOTA_CURRENT[vcpus]=24
    QUOTA_USED[vcpus]=$(echo "$quota_json" | jq -r '.quotas[] | select(.metric == "CPUS") | .usage' 2>/dev/null) || QUOTA_USED[vcpus]=0

    QUOTA_CURRENT[vpcs]=15
    QUOTA_USED[vpcs]=0
    QUOTA_CURRENT[nat_gateways]=10
    QUOTA_USED[nat_gateways]=0
    QUOTA_CURRENT[alb]=50
    QUOTA_USED[alb]=0
}

# ─── Azure Quota Check ───────────────────────────────────────────────────────

quota_check_azure() {
    local region="$1"

    if ! command -v az &>/dev/null; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} Azure CLI not found. Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi

    declare -gA QUOTA_CURRENT=()
    declare -gA QUOTA_USED=()

    local pip_json
    pip_json="$(az network list-usages --location "$region" -o json 2>/dev/null)" || {
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} Cannot query Azure quotas for region: $region"
        return 1
    }

    QUOTA_CURRENT[elastic_ips]=$(echo "$pip_json" | jq -r '.[] | select(.name.value == "PublicIPAddresses") | .limit' 2>/dev/null) || QUOTA_CURRENT[elastic_ips]=10
    QUOTA_USED[elastic_ips]=$(echo "$pip_json" | jq -r '.[] | select(.name.value == "PublicIPAddresses") | .currentValue' 2>/dev/null) || QUOTA_USED[elastic_ips]=0

    local vm_json
    vm_json="$(az vm list-usage --location "$region" -o json 2>/dev/null)" || vm_json="[]"

    QUOTA_CURRENT[vcpus]=$(echo "$vm_json" | jq -r '.[] | select(.name.value == "cores") | .limit' 2>/dev/null) || QUOTA_CURRENT[vcpus]=20
    QUOTA_USED[vcpus]=$(echo "$vm_json" | jq -r '.[] | select(.name.value == "cores") | .currentValue' 2>/dev/null) || QUOTA_USED[vcpus]=0

    QUOTA_CURRENT[vpcs]=50
    QUOTA_USED[vpcs]=0
    QUOTA_CURRENT[nat_gateways]=10
    QUOTA_USED[nat_gateways]=0
    QUOTA_CURRENT[alb]=100
    QUOTA_USED[alb]=0
}

# ─── Report Generation ───────────────────────────────────────────────────────

quota_report() {
    local provider="$1"
    local region="$2"
    local type="$3"
    local num="$4"

    local failures=0
    local increase_cmds=()

    echo ""
    echo -e "${_QC_BOLD}Cloud Quota Pre-flight — $provider, $region${_QC_RESET}"
    echo "Type: $type ($num clusters)"
    echo "════════════════════════════════════════════════════════════════"
    printf " %-20s %-8s %-8s %-10s %-10s %s\n" "Resource" "Limit" "Used" "Required" "Available" "Status"

    for resource in elastic_ips vpcs nat_gateways alb vcpus; do
        local limit="${QUOTA_CURRENT[$resource]:-0}"
        local used="${QUOTA_USED[$resource]:-0}"
        local required="${QUOTA_REQUIRED[$resource]:-0}"
        local available=$(( ${limit%.*} - ${used%.*} ))
        local status

        # Convert float to int for comparison
        local limit_int="${limit%.*}"
        local used_int="${used%.*}"

        if (( available >= required )); then
            status="${_QC_GREEN}PASS${_QC_RESET}"
        else
            status="${_QC_RED}FAIL${_QC_RESET}"
            ((failures++))

            local needed=$((required - available + limit_int))
            case "$provider" in
                aws)
                    local code="${QUOTA_AWS_CODES[$resource]:-}"
                    if [[ -n "$code" ]]; then
                        local svc="ec2"
                        [[ "$resource" == "vpcs" || "$resource" == "nat_gateways" ]] && svc="vpc"
                        increase_cmds+=("$resource: request increase to ${needed}+ (currently $limit_int)")
                        increase_cmds+=("  → aws service-quotas request-service-quota-increase --service-code $svc --quota-code $code --desired-value $needed --region $region")
                    fi
                    ;;
                gcp)
                    increase_cmds+=("$resource: request increase via GCP Console → IAM & Admin → Quotas")
                    ;;
                azure)
                    increase_cmds+=("$resource: request increase via Azure Portal → Subscriptions → Usage + quotas")
                    ;;
            esac
        fi

        local label="${resource//_/ }"
        label="${label^}"
        printf " %-20s %-8s %-8s %-10s %-10s " "$label" "$limit_int" "$used_int" "$required" "$available"
        echo -e "$status"
    done

    echo "════════════════════════════════════════════════════════════════"

    if (( failures == 0 )); then
        echo -e " Result: ${_QC_GREEN}PASS${_QC_RESET} (all quotas sufficient)"
        echo ""
        return 0
    else
        echo -e " Result: ${_QC_RED}BLOCKED${_QC_RESET} ($failures quota increase(s) needed)"
        echo ""
        echo " Action required:"
        local i=1
        for cmd in "${increase_cmds[@]}"; do
            if [[ "$cmd" == "  →"* ]]; then
                echo "      $cmd"
            else
                echo "   $i. $cmd"
                ((i++))
            fi
        done
        echo ""
        echo " Re-run after increases are approved: make check-quota"
        echo ""
        return 1
    fi
}

# ─── Quota Increase Request ──────────────────────────────────────────────────

quota_request_increase() {
    local provider="$1"
    local region="$2"

    echo ""
    echo -e "${_QC_YELLOW}[WARN]${_QC_RESET} Quota increase requested."
    echo ""
    echo "  This will submit quota increase requests to your cloud provider."
    echo "  Increases may take minutes to hours to be approved."
    echo ""

    if [[ ! -t 0 ]]; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} Cannot request increases in non-interactive mode."
        echo "  Run the displayed commands manually, or use: scripts/check-quota.sh --increase"
        return 1
    fi

    local response
    read -rp "  Would you like to request these quota increases? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "  Quota increase cancelled."
        return 1
    fi

    echo ""
    echo "  Submitting quota increase requests..."

    for resource in elastic_ips vpcs nat_gateways; do
        local available=$(( ${QUOTA_CURRENT[$resource]%.*} - ${QUOTA_USED[$resource]%.*} ))
        local required="${QUOTA_REQUIRED[$resource]:-0}"

        if (( available < required )); then
            local needed=$((required - available + ${QUOTA_CURRENT[$resource]%.*}))
            local code="${QUOTA_AWS_CODES[$resource]:-}"

            case "$provider" in
                aws)
                    if [[ -n "$code" ]]; then
                        local svc="ec2"
                        [[ "$resource" == "vpcs" || "$resource" == "nat_gateways" ]] && svc="vpc"
                        echo "  Requesting $resource increase to $needed..."
                        aws service-quotas request-service-quota-increase \
                            --service-code "$svc" \
                            --quota-code "$code" \
                            --desired-value "$needed" \
                            --region "$region" 2>&1 || echo "  (request may already be pending)"
                    fi
                    ;;
                gcp|azure)
                    echo "  $provider quota increases must be requested via console."
                    echo "  See the commands above for instructions."
                    ;;
            esac
        fi
    done

    echo ""
    echo "  Quota increase requests submitted. Re-run check after approval."
}

# ─── Main Entry Point ────────────────────────────────────────────────────────

quota_check() {
    local type=""
    local provider=""
    local region=""
    local num_students=""
    local num_configs=""
    local do_increase=false
    local status_only=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)         type="${2:-}"; shift 2 ;;
            --provider)     provider="${2:-}"; shift 2 ;;
            --region)       region="${2:-}"; shift 2 ;;
            --num-students) num_students="${2:-}"; shift 2 ;;
            --num-configs)  num_configs="${2:-}"; shift 2 ;;
            --increase)     do_increase=true; shift ;;
            --status)       status_only=true; shift ;;
            *) shift ;;
        esac
    done

    if [[ -z "$provider" || -z "$region" ]]; then
        echo -e "${_QC_RED}[ERROR]${_QC_RESET} Provider and region are required."
        echo "  Ensure deploy/config.yml exists with cloud_provider and cloud_region."
        return 1
    fi

    # Calculate required resources
    local num_clusters=1
    case "$type" in
        hub-student)   num_clusters="${num_students:-2}" ;;
        agnosticd-infra) num_clusters="${num_configs:-1}" ;;
    esac

    quota_calculate "$type" "$num_clusters"

    # Query provider
    case "$provider" in
        aws)   quota_check_aws "$region" || return $? ;;
        gcp)   quota_check_gcp "$region" || return $? ;;
        azure) quota_check_azure "$region" || return $? ;;
        *)
            echo -e "${_QC_RED}[ERROR]${_QC_RESET} Unsupported provider: $provider"
            echo "  Supported: aws, gcp, azure"
            return 1
            ;;
    esac

    if [[ "$status_only" == "true" ]]; then
        quota_report "$provider" "$region" "$type" "$num_clusters"
        return 0
    fi

    # Generate report
    quota_report "$provider" "$region" "$type" "$num_clusters"
    local result=$?

    # Handle increase request if quota check failed and --increase was specified
    if (( result != 0 )) && [[ "$do_increase" == "true" ]]; then
        quota_request_increase "$provider" "$region"
    elif (( result != 0 )); then
        echo "  To request increases: make check-quota INCREASE=yes"
        echo "  Or manually run the commands above."
    fi

    return $result
}
