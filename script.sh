#!/bin/bash

echo 

# Exit on any error
set -e

# Array of User-Agent strings
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 UBrowser/44.0.2400.0 Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (iPad; CPU OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
)

# Array of custom headers
CUSTOM_HEADERS=(
    "X-Custom-Header: you" 
    "X-Custom-Header: are"
    "X-Custom-Header: being"
    "X-Custom-Header: farmed"
    "X-Custom-Header: not"
    "X-Custom-Header: ddos-ed"
)

# Export arrays for access in subshells spawned by parallel
export -a USER_AGENTS
export -a CUSTOM_HEADERS

# Convert arrays to strings for exporting (parallel in subshell)
USER_AGENTS_STR="${USER_AGENTS[*]}"
CUSTOM_HEADERS_STR="${CUSTOM_HEADERS[*]}"
export USER_AGENTS_STR
export CUSTOM_HEADERS_STR

# GNU Parallel citation notice override
parallel --citation > /dev/null 2>&1 <<EOF
will cite
EOF

# Check for Internet by pinging Google's DNS
if ! ping -c 1 -W 2 -q 8.8.8.8 > /dev/null 2>&1; then
    printf "There appears to be no Internet connection. Exiting...\n" >&2
    exit 1
fi

# Verify curl is installed on system
if ! command -v curl &> /dev/null; then
    printf "'curl' must be installed on your system. Exiting...\n" >&2
    exit 1
fi

# Verify GNU Parallel is installed on system
if ! command -v parallel &> /dev/null; then
    echo "GNU Parallel is not installed. Please install it to proceed."
    exit 1
fi

# Verify bc is installed on the system
if ! command -v bc &> /dev/null; then
    echo "'bc' is not installed. Please install it to proceed."
    exit 1
fi

# URL validation via regex function
validate_url() {
    local url=$1
    local regex='^(https?://)?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z]{2,}(/.*)?$'
    [[ $url =~ $regex ]]
}

# Number of repetitions validation function
validate_repetitions() {
    local repetitions=$1
    if [[ $repetitions =~ ^[0-9]+$ ]] && [ $repetitions -le 100000 ]; then
        return 0
    else
        return 1
    fi
}

# Delay validation function
validate_delay() {
    local delay=$1
    if [[ $delay =~ ^[0-9]+$ ]] && [ $delay -ge 1 ]; then
        return 0
    else
        return 1
    fi
}

# Initialize silent mode
SILENT=false

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--silent) SILENT=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Prompt for website URL
read -p "Enter the website URL: " URL
if ! validate_url "$URL"; then
    echo "Invalid URL. Please enter a valid URL."
    exit 1
fi

# Prompt for number of repetitions
read -p "Enter the number of repetitions (up to 100000): " REPETITIONS
if ! validate_repetitions "$REPETITIONS"; then
    echo "Invalid number of repetitions. Please enter a number up to 100000."
    exit 1
fi

# Prompt for delay
read -p "Enter the delay between visits in seconds (minimum 1 second): " DELAY
if ! validate_delay "$DELAY"; then
    echo "Invalid delay. Please enter a number greater than or equal to 1."
    exit 1
fi

# Prompt for parallelism level
read -p "Enter the number of parallel visits (1-10, cautious use recommended): " PARALLELISM
if [[ ! $PARALLELISM =~ ^[1-9]$|^10$ ]]; then
    echo "Invalid parallelism level. Please enter a number between 1 and 10."
    exit 1
fi

# new line
echo 

# Calculate delay for parallel execution if needed
ADJUSTED_DELAY=$(echo "scale=2; $DELAY / $PARALLELISM" | bc)

# Export URL and DELAY for use in parallel subprocesses
export URL 
export DELAY

# Visit site function
visit_site() {
    IFS=" " read -r -a UA_ARRAY <<< "${USER_AGENTS_STR}"
    IFS=" " read -r -a HEADER_ARRAY <<< "${CUSTOM_HEADERS_STR}"
    UA_INDEX=$(($RANDOM % ${#UA_ARRAY[@]}))
    HEADER_INDEX=$(($RANDOM % ${#HEADER_ARRAY[@]}))
    USER_AGENT="${UA_ARRAY[$UA_INDEX]}"
    CUSTOM_HEADER="${HEADER_ARRAY[$HEADER_INDEX]}"
    
    curl -s "$URL" -A "$USER_AGENT" -H "$CUSTOM_HEADER" -o /dev/null
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        if [ "$SILENT" = false ]; then
            echo "$(date "+%H:%M:%S") | OK | Count: $1 "
        fi
    else
        if [ "$SILENT" = false ]; then
            echo "$(date "+%H:%M:%S") | --- Failed --- | Count: $1 "
        fi
    fi
}
export -f visit_site

# Loop with parallel, randomized User-Agent and custom header, and delayed visits
seq $REPETITIONS | parallel -j "$PARALLELISM" visit_site {}

# Success message
echo "Completed visiting $URL for $REPETITIONS times with a delay of $DELAY seconds, using $PARALLELISM parallel visits."
echo 
