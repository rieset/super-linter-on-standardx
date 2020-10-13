#!/usr/bin/env bash

################################################################################
################################################################################
########### Super-Linter (Lint all the code) @admiralawkbar ####################
################################################################################
################################################################################

##################################################################
# Debug Vars                                                     #
# Define these early, so we can use debug logging ASAP if needed #
##################################################################
RUN_LOCAL="${RUN_LOCAL}"                              # Boolean to see if we are running locally
ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-false}" # Boolean to see even more info (debug)

##################################################################
# Log Vars                                                       #
# Define these early, so we can use debug logging ASAP if needed #
##################################################################
LOG_FILE="${LOG_FILE:-super-linter.log}"                             # Default log file name (located in GITHUB_WORKSPACE folder)
LOG_LEVEL="${LOG_LEVEL:-VERBOSE}"                                    # Default log level (VERBOSE, DEBUG, TRACE)

if [[ ${ACTIONS_RUNNER_DEBUG} == true ]]; then LOG_LEVEL="DEBUG"; fi
# Boolean to see trace logs
LOG_TRACE=$(if [[ ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_TRACE
# Boolean to see debug logs
LOG_DEBUG=$(if [[ ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_DEBUG
# Boolean to see verbose logs (info function)
LOG_VERBOSE=$(if [[ ${LOG_LEVEL} == "VERBOSE" || ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_VERBOSE

#########################
# Source Function Files #
#########################
# shellcheck source=/dev/null
source /action/lib/log.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/buildFileList.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/validation.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/worker.sh # Source the function script(s)

###########
# GLOBALS #
###########
# Default Vars
DEFAULT_RULES_LOCATION='/action/lib/.automation' # Default rules files location
GITHUB_API_URL='https://api.github.com'          # GitHub API root url
# Ansible Vars
ANSIBLE_FILE_NAME='.ansible-lint.yml'                                 # Name of the file
ANSIBLE_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${ANSIBLE_FILE_NAME}" # Path to the Ansible lint rules
# Azure Resource Manager Vars
ARM_FILE_NAME='.arm-ttk.psd1'                                 # Name of the file
ARM_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${ARM_FILE_NAME}" # Path to the ARM lint rules
# Cloudformation Vars
CLOUDFORMATION_FILE_NAME='.cfnlintrc.yml'                                           # Name of the file
CLOUDFORMATION_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${CLOUDFORMATION_FILE_NAME}" # Path to the cloudformation lint rules
# Clojure Vars
CLOJURE_FILE_NAME='.clj-kondo/config.edn'                             # Name of the file
CLOJURE_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${CLOJURE_FILE_NAME}" # Path to the Clojure lint rules
# Coffee Vars
COFFEESCRIPT_FILE_NAME='.coffee-lint.json'                                      # Name of the file
COFFEESCRIPT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${COFFEESCRIPT_FILE_NAME}" # Path to the coffeescript lint rules
# CSS Vars
CSS_FILE_NAME="${CSS_FILE_NAME:-.stylelintrc.json}"           # Name of the file
CSS_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${CSS_FILE_NAME}" # Path to the CSS lint rules
# Dart Vars
DART_FILE_NAME='analysis_options.yml'                           # Name of the file
DART_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${DART_FILE_NAME}" # Path to the DART lint rules
# Dockerfile Vars
DOCKERFILE_FILE_NAME='.dockerfilelintrc'                                    # Name of the file
DOCKERFILE_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${DOCKERFILE_FILE_NAME}" # Path to the Docker lint rules
# Dockerfile Hadolint Vars
DOCKERFILE_HADOLINT_FILE_NAME="${DOCKERFILE_HADOLINT_FILE_NAME:-.hadolint.yml}"               # Name of the file
DOCKERFILE_HADOLINT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${DOCKERFILE_HADOLINT_FILE_NAME}" # Path to the Docker lint rules
# Editorconfig Vars
EDITORCONFIG_FILE_NAME="${EDITORCONFIG_FILE_NAME:-.ecrc}"                       # Name of the file
EDITORCONFIG_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${EDITORCONFIG_FILE_NAME}" # Path to the Editorconfig lint rules
# Golang Vars
GO_FILE_NAME='.golangci.yml'                                # Name of the file
GO_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${GO_FILE_NAME}" # Path to the Go lint rules
# Groovy Vars
GROOVY_FILE_NAME='.groovylintrc.json'                               # Name of the file
GROOVY_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${GROOVY_FILE_NAME}" # Path to the Groovy lint rules
# HTML Vars
HTML_FILE_NAME='.htmlhintrc'                                    # Name of the file
HTML_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${HTML_FILE_NAME}" # Path to the HTML lint rules
# Java Vars
JAVA_FILE_NAME="sun_checks.xml"                                 # Name of the Java config file
JAVA_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${JAVA_FILE_NAME}" # Path to the Java lint rules
# Javascript Vars
JAVASCRIPT_FILE_NAME="${JAVASCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"          # Name of the file
JAVASCRIPT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${JAVASCRIPT_FILE_NAME}" # Path to the Javascript lint rules
JAVASCRIPT_STANDARD_LINTER_RULES=''                                         # ENV string to pass when running js standard
# Default linter path
LINTER_RULES_PATH="${LINTER_RULES_PATH:-.github/linters}" # Linter Path Directory
# LaTeX Vars
LATEX_FILE_NAME='.chktexrc'                                       # Name of the file
LATEX_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${LATEX_FILE_NAME}" # Path to the Latex lint rules
# Lua Vars
LUA_FILE_NAME='.luacheckrc'                                   # Name of the file
LUA_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${LUA_FILE_NAME}" # Path to the Lua lint rules
# MD Vars
MARKDOWN_FILE_NAME="${MARKDOWN_CONFIG_FILE:-.markdown-lint.yml}"        # Name of the file
MARKDOWN_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${MARKDOWN_FILE_NAME}" # Path to the markdown lint rules
# OpenAPI Vars
OPENAPI_FILE_NAME='.openapirc.yml'                                    # Name of the file
OPENAPI_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${OPENAPI_FILE_NAME}" # Path to the OpenAPI lint rules
# PHPCS Vars
PHP_PHPCS_FILE_NAME='phpcs.xml'                                     # Name of the file
PHP_PHPCS_LINTER_RULES="${GITHUB_WORKSPACE}/${PHP_PHPCS_FILE_NAME}" # Path to the PHP CodeSniffer lint rules in the repository
if [ ! -f "$PHP_PHPCS_LINTER_RULES" ]; then
  PHP_PHPCS_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PHP_PHPCS_FILE_NAME}" # Path to the PHP CodeSniffer lint rules
fi
# PHPStan Vars
PHP_PHPSTAN_FILE_NAME='phpstan.neon'                                    # Name of the file
PHP_PHPSTAN_LINTER_RULES="${GITHUB_WORKSPACE}/${PHP_PHPSTAN_FILE_NAME}" # Path to the PHPStan lint rules in the repository
if [ ! -f "$PHP_PHPSTAN_LINTER_RULES" ]; then
  PHP_PHPSTAN_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PHP_PHPSTAN_FILE_NAME}" # Path to the PHPStan lint rules
fi
# Psalm Vars
PHP_PSALM_FILE_NAME='psalm.xml'                                     # Name of the file
PHP_PSALM_LINTER_RULES="${GITHUB_WORKSPACE}/${PHP_PSALM_FILE_NAME}" # Path to the Psalm lint rules in the repository
if [ ! -f "$PHP_PSALM_LINTER_RULES" ]; then
  PHP_PSALM_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PHP_PSALM_FILE_NAME}" # Path to the Psalm lint rules
fi
# Powershell Vars
POWERSHELL_FILE_NAME='.powershell-psscriptanalyzer.psd1'                    # Name of the file
POWERSHELL_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${POWERSHELL_FILE_NAME}" # Path to the Powershell lint rules
# Protocol Buffers Vars
PROTOBUF_FILE_NAME='.protolintrc.yml'                                   # Name of the file
PROTOBUF_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PROTOBUF_FILE_NAME}" # Path to the Protocol Buffers lint rules
# Python Vars
PYTHON_PYLINT_FILE_NAME="${PYTHON_PYLINT_CONFIG_FILE:-.python-lint}"              # Name of the file
PYTHON_PYLINT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PYTHON_PYLINT_FILE_NAME}" # Path to the python lint rules
PYTHON_FLAKE8_FILE_NAME="${PYTHON_FLAKE8_CONFIG_FILE:-.flake8}"                   # Name of the file
PYTHON_FLAKE8_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PYTHON_FLAKE8_FILE_NAME}" # Path to the python lint rules
PYTHON_BLACK_FILE_NAME="${PYTHON_BLACK_CONFIG_FILE:-.python-black}"               # Name of the file
PYTHON_BLACK_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${PYTHON_BLACK_FILE_NAME}"   # Path to the python lint rules
# R Vars
R_FILE_NAME='.lintr'                                      # Name of the file
R_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${R_FILE_NAME}" # Path to the R lint rules
# Ruby Vars
RUBY_FILE_NAME="${RUBY_CONFIG_FILE:-.ruby-lint.yml}"            # Name of the file
RUBY_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${RUBY_FILE_NAME}" # Path to the ruby lint rules
# Snakemake Vars
SNAKEMAKE_SNAKEFMT_FILE_NAME="${SNAKEMAKE_SNAKEFMT_CONFIG_FILE:-.snakefmt.toml}"                     # Name of the file
SNAKEMAKE_SNAKEFMT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${SNAKEMAKE_SNAKEFMT_FILE_NAME}" # Path to the snakemake lint rules
# SQL Vars
SQL_FILE_NAME=".sql-config.json"                              # Name of the file
SQL_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${SQL_FILE_NAME}" # Path to the SQL lint rules
# Terraform Vars
TERRAFORM_FILE_NAME='.tflint.hcl'                                         # Name of the file
TERRAFORM_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${TERRAFORM_FILE_NAME}" # Path to the Terraform lint rules
# Typescript Vars
TYPESCRIPT_FILE_NAME="${TYPESCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"          # Name of the file
TYPESCRIPT_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${TYPESCRIPT_FILE_NAME}" # Path to the Typescript lint rules
TYPESCRIPT_STANDARD_LINTER_RULES=''                                         # ENV string to pass when running js standard
# Version File info
VERSION_FILE='/action/lib/linter-versions.txt' # File to store linter versions
# YAML Vars
YAML_FILE_NAME="${YAML_CONFIG_FILE:-.yaml-lint.yml}"            # Name of the file
YAML_LINTER_RULES="${DEFAULT_RULES_LOCATION}/${YAML_FILE_NAME}" # Path to the yaml lint rules

##################
# Language array #
##################
LANGUAGE_ARRAY=('ANSIBLE' 'ARM' 'BASH' 'BASH_EXEC' 'CLOUDFORMATION' 'CLOJURE' 'COFFEESCRIPT' 'CSHARP' 'CSS'
  'DART' 'DOCKERFILE' 'DOCKERFILE_HADOLINT' 'EDITORCONFIG' 'ENV' 'GO' 'GROOVY' 'HTML'
  'JAVA' 'JAVASCRIPT_ES' 'JAVASCRIPT_STANDARD' 'JSON' 'JSX' 'KUBERNETES_KUBEVAL' 'KOTLIN' 'LATEX' 'LUA' 'MARKDOWN'
  'OPENAPI' 'PERL' 'PHP_BUILTIN' 'PHP_PHPCS' 'PHP_PHPSTAN' 'PHP_PSALM' 'POWERSHELL'
  'PROTOBUF' 'PYTHON_BLACK' 'PYTHON_PYLINT' 'PYTHON_FLAKE8' 'R' 'RAKU' 'RUBY' 'SHELL_SHFMT' 'SNAKEMAKE_LINT' 'SNAKEMAKE_SNAKEFMT' 'STATES' 'SQL' 'TERRAFORM'
  'TERRAFORM_TERRASCAN' 'TERRAGRUNT' 'TSX' 'TYPESCRIPT_ES' 'TYPESCRIPT_STANDARD' 'XML' 'YAML')

##############################
# Linter command names array #
##############################
declare -A LINTER_NAMES_ARRAY
LINTER_NAMES_ARRAY['ARM']="arm-ttk"
LINTER_NAMES_ARRAY['BASH']="shellcheck"
LINTER_NAMES_ARRAY['BASH_EXEC']="bash-exec"
LINTER_NAMES_ARRAY['CLOJURE']="clj-kondo"
LINTER_NAMES_ARRAY['CLOUDFORMATION']="cfn-lint"
LINTER_NAMES_ARRAY['COFFEESCRIPT']="coffeelint"
LINTER_NAMES_ARRAY['CSHARP']="dotnet-format"
LINTER_NAMES_ARRAY['CSS']="stylelint"
LINTER_NAMES_ARRAY['DART']="dart"
LINTER_NAMES_ARRAY['DOCKERFILE']="dockerfilelint"
LINTER_NAMES_ARRAY['DOCKERFILE_HADOLINT']="hadolint"
LINTER_NAMES_ARRAY['EDITORCONFIG']="editorconfig-checker"
LINTER_NAMES_ARRAY['ENV']="dotenv-linter"
LINTER_NAMES_ARRAY['GO']="golangci-lint"
LINTER_NAMES_ARRAY['GROOVY']="npm-groovy-lint"
LINTER_NAMES_ARRAY['HTML']="htmlhint"
LINTER_NAMES_ARRAY['JAVA']="checkstyle"
LINTER_NAMES_ARRAY['JAVASCRIPT_ES']="eslint"
LINTER_NAMES_ARRAY['JAVASCRIPT_STANDARD']="standard"
LINTER_NAMES_ARRAY['JSON']="jsonlint"
LINTER_NAMES_ARRAY['JSX']="eslint"
LINTER_NAMES_ARRAY['KOTLIN']="ktlint"
LINTER_NAMES_ARRAY['KUBERNETES_KUBEVAL']="kubeval"
LINTER_NAMES_ARRAY['LATEX']="chktex"
LINTER_NAMES_ARRAY['LUA']="lua"
LINTER_NAMES_ARRAY['MARKDOWN']="markdownlint"
LINTER_NAMES_ARRAY['OPENAPI']="spectral"
LINTER_NAMES_ARRAY['PERL']="perl"
LINTER_NAMES_ARRAY['PHP_BUILTIN']="php"
LINTER_NAMES_ARRAY['PHP_PHPCS']="phpcs"
LINTER_NAMES_ARRAY['PHP_PHPSTAN']="phpstan"
LINTER_NAMES_ARRAY['PHP_PSALM']="psalm"
LINTER_NAMES_ARRAY['POWERSHELL']="pwsh"
LINTER_NAMES_ARRAY['PROTOBUF']="protolint"
LINTER_NAMES_ARRAY['PYTHON_BLACK']="black"
LINTER_NAMES_ARRAY['PYTHON_PYLINT']="pylint"
LINTER_NAMES_ARRAY['PYTHON_FLAKE8']="flake8"
LINTER_NAMES_ARRAY['R']="lintr"
LINTER_NAMES_ARRAY['RAKU']="raku"
LINTER_NAMES_ARRAY['RUBY']="rubocop"
LINTER_NAMES_ARRAY['SHELL_SHFMT']="shfmt"
LINTER_NAMES_ARRAY['SNAKEMAKE_LINT']="snakemake"
LINTER_NAMES_ARRAY['SNAKEMAKE_SNAKEFMT']="snakefmt"
LINTER_NAMES_ARRAY['STATES']="asl-validator"
LINTER_NAMES_ARRAY['SQL']="sql-lint"
LINTER_NAMES_ARRAY['TERRAFORM']="tflint"
LINTER_NAMES_ARRAY['TERRAFORM_TERRASCAN']="terrascan"
LINTER_NAMES_ARRAY['TERRAGRUNT']="terragrunt"
LINTER_NAMES_ARRAY['TSX']="eslint"
LINTER_NAMES_ARRAY['TYPESCRIPT_ES']="eslint"
LINTER_NAMES_ARRAY['TYPESCRIPT_STANDARD']="standard"
LINTER_NAMES_ARRAY['XML']="xmllint"
LINTER_NAMES_ARRAY['YAML']="yamllint"

############################################
# Array for all languages that were linted #
############################################
LINTED_LANGUAGES_ARRAY=() # Will be filled at run time with all languages that were linted

###################
# GitHub ENV Vars #
###################
ANSIBLE_DIRECTORY="${ANSIBLE_DIRECTORY}"                             # Ansible Directory
DEFAULT_BRANCH="${DEFAULT_BRANCH:-master}"                           # Default Git Branch to use (master by default)
DISABLE_ERRORS="${DISABLE_ERRORS}"                                   # Boolean to enable warning-only output without throwing errors
FILTER_REGEX_INCLUDE="${FILTER_REGEX_INCLUDE}"                       # RegExp defining which files will be processed by linters (all by default)
FILTER_REGEX_EXCLUDE="${FILTER_REGEX_EXCLUDE}"                       # RegExp defining which files will be excluded from linting (none by default)
GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH}"                             # Github Event Path
GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"                             # GitHub Org/Repo passed from system
GITHUB_RUN_ID="${GITHUB_RUN_ID}"                                     # GitHub RUn ID to point to logs
GITHUB_SHA="${GITHUB_SHA}"                                           # GitHub sha from the commit
GITHUB_TOKEN="${GITHUB_TOKEN}"                                       # GitHub Token passed from environment
GITHUB_WORKSPACE="${GITHUB_WORKSPACE}"                               # Github Workspace
MULTI_STATUS="${MULTI_STATUS:-true}"                                 # Multiple status are created for each check ran
TEST_CASE_RUN="${TEST_CASE_RUN}"                                     # Boolean to validate only test cases
VALIDATE_ALL_CODEBASE="${VALIDATE_ALL_CODEBASE}"                     # Boolean to validate all files

################
# Default Vars #
################
DEFAULT_VALIDATE_ALL_CODEBASE='true'                # Default value for validate all files
DEFAULT_WORKSPACE="${DEFAULT_WORKSPACE:-/tmp/lint}" # Default workspace if running locally
DEFAULT_RUN_LOCAL='false'                           # Default value for debugging locally
DEFAULT_TEST_CASE_RUN='false'                       # Flag to tell code to run only test cases

###############################################################
# Default Vars that are called in Subs and need to be ignored #
###############################################################
DEFAULT_DISABLE_ERRORS='false'                          # Default to enabling errors
export DEFAULT_DISABLE_ERRORS                           # Workaround SC2034
ERROR_ON_MISSING_EXEC_BIT="${ERROR_ON_MISSING_EXEC_BIT:-false}" # Default to report a warning if a shell script doesn't have the executable bit set to 1
export ERROR_ON_MISSING_EXEC_BIT
RAW_FILE_ARRAY=()                                       # Array of all files that were changed
export RAW_FILE_ARRAY                                   # Workaround SC2034
TEST_CASE_FOLDER='.automation/test'                     # Folder for test cases we should always ignore
export TEST_CASE_FOLDER                                 # Workaround SC2034
WARNING_ARRAY_TEST=()                                   # Array of warning linters that did not have an expected test result.
export WARNING_ARRAY_TEST                               # Workaround SC2034

##############
# Format     #
##############
OUTPUT_FORMAT="${OUTPUT_FORMAT}"                            # Output format to be generated. Default none
OUTPUT_FOLDER="${OUTPUT_FOLDER:-super-linter.report}"       # Folder where the reports are generated. Default super-linter.report
OUTPUT_DETAILS="${OUTPUT_DETAILS:-simpler}"                 # What level of details. (simpler or detailed). Default simpler

##########################
# Array of changed files #
##########################
for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
  FILE_ARRAY_VARIABLE_NAME="FILE_ARRAY_${LANGUAGE}"
  debug "Setting ${FILE_ARRAY_VARIABLE_NAME} variable..."
  eval "${FILE_ARRAY_VARIABLE_NAME}=()"
done

################################################################################
########################## FUNCTIONS BELOW #####################################
################################################################################
################################################################################
#### Function Header ###########################################################
Header() {
  ###############################
  # Give them the possum action #
  ###############################
  /bin/bash /action/lib/possum.sh

  ##########
  # Prints #
  ##########
  info "---------------------------------------------"
  info "--- GitHub Actions Multi Language Linter ----"
  info " - Image Creation Date:[${BUILD_DATE}]"
  info " - Image Revision:[${BUILD_REVISION}]"
  info " - Image Version:[${BUILD_VERSION}]"
  info "---------------------------------------------"
  info "---------------------------------------------"
  info "The Super-Linter source code can be found at:"
  info " - https://github.com/github/super-linter"
  info "---------------------------------------------"
}
################################################################################
#### Function GetLinterVersions ################################################
GetLinterVersions() {
  #########################
  # Print version headers #
  #########################
  debug "---------------------------------------------"
  debug "Linter Version Info:"

  ################################
  # Cat the linter versions file #
  ################################
  CAT_CMD=$(cat "${VERSION_FILE}" 2>&1)

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ ${ERROR_CODE} -ne 0 ]; then
    # Failure
    warn "Failed to view version file:[${VERSION_FILE}]"
  else
    # Success
    debug "${CAT_CMD}"
  fi

  #########################
  # Print version footers #
  #########################
  debug "---------------------------------------------"
}
################################################################################
#### Function GetLinterRules ###################################################
GetLinterRules() {
  # Need to validate the rules files exist

  ################
  # Pull in vars #
  ################
  LANGUAGE_NAME="${1}" # Name of the language were looking for
  debug "Getting linter rules for ${LANGUAGE_NAME}..."

  #######################################################
  # Need to create the variables for the real variables #
  #######################################################
  LANGUAGE_FILE_NAME="${LANGUAGE_NAME}_FILE_NAME"
  LANGUAGE_LINTER_RULES="${LANGUAGE_NAME}_LINTER_RULES"
  debug "Variable names for language file name: ${LANGUAGE_FILE_NAME}, language linter rules: ${LANGUAGE_LINTER_RULES}"

  #####################################################
  # Check if the language rules variables are defined #
  #####################################################
  if [ -z "${!LANGUAGE_FILE_NAME+x}" ]; then
    debug "${LANGUAGE_FILE_NAME} is not set. Skipping loading rules for ${LANGUAGE_NAME}..."
    return
  fi

  ##########################
  # Get the file extension #
  ##########################
  FILE_EXTENSION=$(echo "${!LANGUAGE_FILE_NAME}" | rev | cut -d'.' -f1 | rev)
  FILE_NAME=$(basename "${!LANGUAGE_FILE_NAME}" ".${FILE_EXTENSION}")
  debug "${LANGUAGE_NAME} language rule file (${!LANGUAGE_FILE_NAME}) has ${FILE_NAME} name and ${FILE_EXTENSION} extension"

  ###############################
  # Set the secondary file name #
  ###############################
  SECONDARY_FILE_NAME=''

  #################################
  # Check for secondary file name #
  #################################
  if [[ $FILE_EXTENSION == 'yml' ]]; then
    # Need to see if yaml also exists
    SECONDARY_FILE_NAME="$FILE_NAME.yaml"
  elif [[ $FILE_EXTENSION == 'yaml' ]]; then
    # need to see if yml also exists
    SECONDARY_FILE_NAME="$FILE_NAME.yml"
  fi

  #####################################
  # Validate we have the linter rules #
  #####################################
  if [ -f "${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${!LANGUAGE_FILE_NAME}" ]; then
    info "----------------------------------------------"
    info "User provided file:[${!LANGUAGE_FILE_NAME}], setting rules file..."

    ########################################
    # Update the path to the file location #
    ########################################
    eval "${LANGUAGE_LINTER_RULES}=${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${!LANGUAGE_FILE_NAME}"
  else
    debug "  -> Codebase does NOT have file:[${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${!LANGUAGE_FILE_NAME}]"
    # Check if we have secondary name to check
    if [ -n "$SECONDARY_FILE_NAME" ]; then
      debug "${LANGUAGE_NAME} language rule file has a secondary rules file name to check: ${SECONDARY_FILE_NAME}"
      # We have a secondary name to validate
      if [ -f "${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${SECONDARY_FILE_NAME}" ]; then
        info "----------------------------------------------"
        info "User provided file:[${SECONDARY_FILE_NAME}], setting rules file..."

        ########################################
        # Update the path to the file location #
        ########################################
        eval "${LANGUAGE_LINTER_RULES}=${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${SECONDARY_FILE_NAME}"
      fi
    fi

    ########################################################
    # No user default provided, using the template default #
    ########################################################
    debug "  -> Codebase does NOT have file:[${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${!LANGUAGE_FILE_NAME}], nor file:[${GITHUB_WORKSPACE}/${LINTER_RULES_PATH}/${SECONDARY_FILE_NAME}], using Default rules at:[${!LANGUAGE_LINTER_RULES}]"
  fi
}
################################################################################
#### Function GetStandardRules #################################################
GetStandardRules() {
  ################
  # Pull In Vars #
  ################
  LINTER="${1}" # Type: javascript | typescript

  #########################################################################
  # Need to get the ENV vars from the linter rules to run in command line #
  #########################################################################
  # Copy orig IFS to var
  ORIG_IFS="${IFS}"
  # Set the IFS to newline
  IFS=$'\n'

  #########################################
  # Get list of all environment variables #
  #########################################
  # Only env vars that are marked as true
  GET_ENV_ARRAY=()
  if [[ ${LINTER} == "javascript" ]]; then
    mapfile -t GET_ENV_ARRAY < <(yq .env "${JAVASCRIPT_LINTER_RULES}" | grep true)
  elif [[ ${LINTER} == "typescript" ]]; then
    mapfile -t GET_ENV_ARRAY < <(yq .env "${TYPESCRIPT_LINTER_RULES}" | grep true)
  fi

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ ${ERROR_CODE} -ne 0 ]; then
    # ERROR
    error "Failed to gain list of ENV vars to load!"
    fatal "[${GET_ENV_ARRAY[*]}]"
  fi

  ##########################
  # Set IFS back to normal #
  ##########################
  # Set IFS back to Orig
  IFS="${ORIG_IFS}"

  ######################
  # Set the env string #
  ######################
  ENV_STRING=''

  #############################
  # Pull out the envs to load #
  #############################
  for ENV in "${GET_ENV_ARRAY[@]}"; do
    #############################
    # remove spaces from return #
    #############################
    ENV="$(echo -e "${ENV}" | tr -d '[:space:]')"
    ################################
    # Get the env to add to string #
    ################################
    ENV="$(echo "${ENV}" | cut -d'"' -f2)"
    debug "ENV:[${ENV}]"
    ENV_STRING+="--env ${ENV} "
  done

  #########################################
  # Remove trailing and ending whitespace #
  #########################################
  if [[ ${LINTER} == "javascript" ]]; then
    JAVASCRIPT_STANDARD_LINTER_RULES="$(echo -e "${ENV_STRING}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  elif [[ ${LINTER} == "typescript" ]]; then
    TYPESCRIPT_STANDARD_LINTER_RULES="$(echo -e "${ENV_STRING}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  fi
}
################################################################################
#### Function DetectOpenAPIFile ################################################
DetectOpenAPIFile() {
  ################
  # Pull in vars #
  ################
  FILE="${1}"

  ###############################
  # Check the file for keywords #
  ###############################
  grep -E '"openapi":|"swagger":|^openapi:|^swagger:' "${FILE}" >/dev/null

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ ${ERROR_CODE} -eq 0 ]; then
    ########################
    # Found string in file #
    ########################
    return 0
  else
    ###################
    # No string match #
    ###################
    return 1
  fi
}
################################################################################
#### Function DetectARMFile ####################################################
DetectARMFile() {
  ################
  # Pull in vars #
  ################
  FILE="${1}" # Name of the file/path we are validating

  ###############################
  # Check the file for keywords #
  ###############################
  grep -E 'schema.management.azure.com' "${FILE}" >/dev/null

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ ${ERROR_CODE} -eq 0 ]; then
    ########################
    # Found string in file #
    ########################
    return 0
  else
    ###################
    # No string match #
    ###################
    return 1
  fi
}
################################################################################
#### Function DetectCloudFormationFile #########################################
DetectCloudFormationFile() {
  ################
  # Pull in Vars #
  ################
  FILE="${1}" # File that we need to validate

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-formats.html
  # AWSTemplateFormatVersion is optional
  #######################################
  # Check if file has AWS Template info #
  #######################################
  if grep -q 'AWSTemplateFormatVersion' "${FILE}" >/dev/null; then
    # Found it
    return 0
  fi

  #####################################
  # See if it contains AWS References #
  #####################################
  if grep -q -E '(AWS|Alexa|Custom)::' "${FILE}" >/dev/null; then
    # Found it
    return 0
  fi

  #####################################################
  # No identifiers of a CLOUDFORMATION template found #
  #####################################################
  return 1
}
################################################################################
#### Function DetectKubernetesFile #########################################
DetectKubernetesFile() {
  ################
  # Pull in Vars #
  ################
  FILE="${1}" # File that we need to validate
  debug "Checking if ${FILE} is a Kubernetes descriptor..."

  if grep -v 'kustomize.config.k8s.io' "${FILE}" | grep -q -E '(apiVersion):'; then
    debug "${FILE} is a Kubernetes descriptor"
    return 0
  fi

  debug "${FILE} is NOT a Kubernetes descriptor"
  return 1

}
################################################################################
#### Function DetectAWSStatesFIle ##############################################
DetectAWSStatesFIle() {
  ################
  # Pull in Vars #
  ################
  FILE="${1}" # File that we need to validate

  # https://states-language.net/spec.html#example
  ###############################
  # check if file has resources #
  ###############################
  if grep -q '"Resource": *"arn"*' "${FILE}"; then
    # Found it
    return 0
  fi

  #################################################
  # No identifiers of a AWS States Language found #
  #################################################
  return 1
}
################################################################################
#### Function GetGitHubVars ####################################################
GetGitHubVars() {
  ##########
  # Prints #
  ##########
  info "--------------------------------------------"
  info "Gathering GitHub information..."

  ###############################
  # Get the Run test cases flag #
  ###############################
  if [ -z "${TEST_CASE_RUN}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    TEST_CASE_RUN="${DEFAULT_TEST_CASE_RUN}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  TEST_CASE_RUN="${TEST_CASE_RUN,,}"

  ##########################
  # Get the run local flag #
  ##########################
  if [ -z "${RUN_LOCAL}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    RUN_LOCAL="${DEFAULT_RUN_LOCAL}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  RUN_LOCAL="${RUN_LOCAL,,}"

  #################################
  # Check if were running locally #
  #################################
  if [[ ${RUN_LOCAL} != "false" ]]; then
    ##########################################
    # We are running locally for a debug run #
    ##########################################
    info "NOTE: ENV VAR [RUN_LOCAL] has been set to:[true]"
    info "bypassing GitHub Actions variables..."

    ############################
    # Set the GITHUB_WORKSPACE #
    ############################
    if [ -z "${GITHUB_WORKSPACE}" ]; then
      GITHUB_WORKSPACE="${DEFAULT_WORKSPACE}"
    fi

    if [ ! -d "${GITHUB_WORKSPACE}" ]; then
      fatal "Provided volume is not a directory!"
    fi

    ################################
    # Set the report output folder #
    ################################
    REPORT_OUTPUT_FOLDER="${DEFAULT_WORKSPACE}/${OUTPUT_FOLDER}"

    info "Linting all files in mapped directory:[${DEFAULT_WORKSPACE}]"

    # No need to touch or set the GITHUB_SHA
    # No need to touch or set the GITHUB_EVENT_PATH
    # No need to touch or set the GITHUB_ORG
    # No need to touch or set the GITHUB_REPO

    #################################
    # Set the VALIDATE_ALL_CODEBASE #
    #################################
    VALIDATE_ALL_CODEBASE="${DEFAULT_VALIDATE_ALL_CODEBASE}"
  else
    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_SHA}" ]; then
      error "Failed to get [GITHUB_SHA]!"
      fatal "[${GITHUB_SHA}]"
    else
      info "Successfully found:${F[W]}[GITHUB_SHA]${F[B]}, value:${F[W]}[${GITHUB_SHA}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_WORKSPACE}" ]; then
      error "Failed to get [GITHUB_WORKSPACE]!"
      fatal "[${GITHUB_WORKSPACE}]"
    else
      info "Successfully found:${F[W]}[GITHUB_WORKSPACE]${F[B]}, value:${F[W]}[${GITHUB_WORKSPACE}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_EVENT_PATH}" ]; then
      error "Failed to get [GITHUB_EVENT_PATH]!"
      fatal "[${GITHUB_EVENT_PATH}]"
    else
      info "Successfully found:${F[W]}[GITHUB_EVENT_PATH]${F[B]}, value:${F[W]}[${GITHUB_EVENT_PATH}]${F[B]}"
    fi

    ##################################################
    # Need to pull the GitHub Vars from the env file #
    ##################################################

    ######################
    # Get the GitHub Org #
    ######################
    GITHUB_ORG=$(jq -r '.repository.owner.login' <"${GITHUB_EVENT_PATH}")

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_ORG}" ]; then
      error "Failed to get [GITHUB_ORG]!"
      fatal "[${GITHUB_ORG}]"
    else
      info "Successfully found:${F[W]}[GITHUB_ORG]${F[B]}, value:${F[W]}[${GITHUB_ORG}]"
    fi

    #######################
    # Get the GitHub Repo #
    #######################
    GITHUB_REPO=$(jq -r '.repository.name' <"${GITHUB_EVENT_PATH}")

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_REPO}" ]; then
      error "Failed to get [GITHUB_REPO]!"
      fatal "[${GITHUB_REPO}]"
    else
      info "Successfully found:${F[W]}[GITHUB_REPO]${F[B]}, value:${F[W]}[${GITHUB_REPO}]"
    fi
  fi

  ############################
  # Validate we have a value #
  ############################
  if [ -z "${GITHUB_TOKEN}" ] && [[ ${RUN_LOCAL} == "false" ]]; then
    error "Failed to get [GITHUB_TOKEN]!"
    error "[${GITHUB_TOKEN}]"
    error "Please set a [GITHUB_TOKEN] from the main workflow environment to take advantage of multiple status reports!"

    ################################################################################
    # Need to set MULTI_STATUS to false as we cant hit API endpoints without token #
    ################################################################################
    MULTI_STATUS='false'
  else
    info "Successfully found:${F[W]}[GITHUB_TOKEN]"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  MULTI_STATUS="${MULTI_STATUS,,}"

  #######################################################################
  # Check to see if the multi status is set, and we have a token to use #
  #######################################################################
  if [ "${MULTI_STATUS}" == "true" ] && [ -n "${GITHUB_TOKEN}" ]; then
    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_REPOSITORY}" ]; then
      error "Failed to get [GITHUB_REPOSITORY]!"
      fatal "[${GITHUB_REPOSITORY}]"
    else
      info "Successfully found:${F[W]}[GITHUB_REPOSITORY]${F[B]}, value:${F[W]}[${GITHUB_REPOSITORY}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_RUN_ID}" ]; then
      error "Failed to get [GITHUB_RUN_ID]!"
      fatal "[${GITHUB_RUN_ID}]"
    else
      info "Successfully found:${F[W]}[GITHUB_RUN_ID]${F[B]}, value:${F[W]}[${GITHUB_RUN_ID}]"
    fi
  fi
}
################################################################################
#### Function CallStatusAPI ####################################################
CallStatusAPI() {
  ####################
  # Pull in the vars #
  ####################
  LANGUAGE="${1}" # langauge that was validated
  STATUS="${2}"   # success | error
  SUCCESS_MSG='No errors were found in the linting process'
  FAIL_MSG='Errors were detected, please view logs'
  MESSAGE='' # Message to send to status API

  ######################################
  # Check the status to create message #
  ######################################
  if [ "${STATUS}" == "success" ]; then
    # Success
    MESSAGE="${SUCCESS_MSG}"
  else
    # Failure
    MESSAGE="${FAIL_MSG}"
  fi

  ##########################################################
  # Check to see if were enabled for multi Status mesaages #
  ##########################################################
  if [ "${MULTI_STATUS}" == "true" ] && [ -n "${GITHUB_TOKEN}" ] && [ -n "${GITHUB_REPOSITORY}" ]; then

    # make sure we honor DISABLE_ERRORS
    if [ "${DISABLE_ERRORS}" == "true" ]; then
      STATUS="success"
    fi

    ##############################################
    # Call the status API to create status check #
    ##############################################
    SEND_STATUS_CMD=$(
      curl -f -s -X POST \
        --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}" \
        -H 'accept: application/vnd.github.v3+json' \
        -H "authorization: Bearer ${GITHUB_TOKEN}" \
        -H 'content-type: application/json' \
        -d "{ \"state\": \"${STATUS}\",
        \"target_url\": \"https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}\",
        \"description\": \"${MESSAGE}\", \"context\": \"--> Linted: ${LANGUAGE}\"
      }" 2>&1
    )

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    ##############################
    # Check the shell for errors #
    ##############################
    if [ "${ERROR_CODE}" -ne 0 ]; then
      # ERROR
      info "ERROR! Failed to call GitHub Status API!"
      info "ERROR:[${SEND_STATUS_CMD}]"
      # Not going to fail the script on this yet...
    fi
  fi
}
################################################################################
#### Function Reports ##########################################################
Reports() {
  info "----------------------------------------------"
  info "----------------------------------------------"
  info "Generated reports:"
  info "----------------------------------------------"
  info "----------------------------------------------"

  ###################################
  # Prints output report if enabled #
  ###################################
  if [ -z "${FORMAT_REPORT}" ]; then
    info "Reports generated in folder ${REPORT_OUTPUT_FOLDER}"
    #############################################
    # Print info on reports that were generated #
    #############################################
    if [ -d "${REPORT_OUTPUT_FOLDER}" ]; then
      info "Contents of report folder:"
      OUTPUT_CONTENTS_CMD=$(ls "${REPORT_OUTPUT_FOLDER}")
      info "$OUTPUT_CONTENTS_CMD"
    else
      warn "Report output folder (${REPORT_OUTPUT_FOLDER}) does NOT exist."
    fi
  fi

  ################################
  # Prints for warnings if found #
  ################################
  for TEST in "${WARNING_ARRAY_TEST[@]}"; do
    warn "Expected file to compare with was not found for ${TEST}"
  done
}
################################################################################
#### Function Footer ###########################################################
Footer() {
  info "----------------------------------------------"
  info "----------------------------------------------"
  info "The script has completed"
  info "----------------------------------------------"
  info "----------------------------------------------"

  ####################################################
  # Need to clean up the lanuage array of duplicates #
  ####################################################
  mapfile -t UNIQUE_LINTED_ARRAY < <(for LANG in "${LINTED_LANGUAGES_ARRAY[@]}"; do echo "${LANG}"; done | sort -u)

  ##############################
  # Prints for errors if found #
  ##############################
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    ###########################
    # Build the error counter #
    ###########################
    ERROR_COUNTER="ERRORS_FOUND_${LANGUAGE}"

    ##################
    # Print if not 0 #
    ##################
    if [[ ${!ERROR_COUNTER} -ne 0 ]]; then
      # We found errors in the language
      ###################
      # Print the goods #
      ###################
      error "ERRORS FOUND${NC} in ${LANGUAGE}:[${!ERROR_COUNTER}]"

      #########################################
      # Create status API for Failed language #
      #########################################
      CallStatusAPI "${LANGUAGE}" "error"
      ######################################
      # Check if we validated the langauge #
      ######################################
    elif [[ ${!ERROR_COUNTER} -eq 0 ]]; then
      if CheckInArray "${LANGUAGE}"; then
        # No errors found when linting the language
        CallStatusAPI "${LANGUAGE}" "success"
      fi
    fi
  done

  ##################################
  # Exit with 0 if errors disabled #
  ##################################
  if [ "${DISABLE_ERRORS}" == "true" ]; then
    warn "Exiting with exit code:[0] as:[DISABLE_ERRORS] was set to:[${DISABLE_ERRORS}]"
    exit 0
  fi

  ###############################
  # Exit with 1 if errors found #
  ###############################
  # Loop through all languages
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    # build the variable
    ERRORS_FOUND_LANGUAGE="ERRORS_FOUND_${LANGUAGE}"
    # Check if error was found
    if [[ ${!ERRORS_FOUND_LANGUAGE} -ne 0 ]]; then
      # Failed exit
      fatal "Exiting with errors found!"
    fi
  done

  ########################
  # Footer prints Exit 0 #
  ########################
  notice "All file(s) linted successfully with no errors detected"
  info "----------------------------------------------"
  # Successful exit
  exit 0
}
################################################################################
#### Function CheckInArray #####################################################
CheckInArray() {
  ###############
  # Pull in Var #
  ###############
  NEEDLE="$1" # Language we need to match

  ######################################
  # Check if Language was in the array #
  ######################################
  for LANG in "${UNIQUE_LINTED_ARRAY[@]}"; do
    if [[ "${LANG}" == "${NEEDLE}" ]]; then
      ############
      # Found it #
      ############
      return 0
    fi
  done

  ###################
  # Did not find it #
  ###################
  return 1
}
################################################################################
#### Function Cleanup ##########################################################
cleanup() {
  local -ri EXIT_CODE=$?

  sh -c "cat ${LOG_TEMP} >> ${GITHUB_WORKSPACE}/${LOG_FILE}" || true

  exit ${EXIT_CODE}
  trap - 0 1 2 3 6 14 15
}
trap 'cleanup' 0 1 2 3 6 14 15
################################################################################
############################### MAIN ###########################################
################################################################################

##########
# Header #
##########
Header

##############################################################
# check flag for validating the report folder does not exist #
##############################################################
if [ -n "${OUTPUT_FORMAT}" ]; then
  if [ -d "${REPORT_OUTPUT_FOLDER}" ]; then
    error "ERROR! Found ${REPORT_OUTPUT_FOLDER}"
    fatal "Please remove the folder and try again."
  fi
fi

#######################
# Get GitHub Env Vars #
#######################
# Need to pull in all the GitHub variables
# needed to connect back and update checks
GetGitHubVars

########################################################
# Initialize variables that depend on GitHub variables #
########################################################
DEFAULT_ANSIBLE_DIRECTORY="${GITHUB_WORKSPACE}/ansible"          # Default Ansible Directory
export DEFAULT_ANSIBLE_DIRECTORY                                 # Workaround SC2034
REPORT_OUTPUT_FOLDER="${GITHUB_WORKSPACE}/${OUTPUT_FOLDER}"      # Location for the report folder

############################
# Validate the environment #
############################
GetValidationInfo
ValidatePowershellModules

########################
# Get the linter rules #
########################
for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
  debug "Loading rules for ${LANGUAGE}..."
  eval "GetLinterRules ${LANGUAGE}"
done

# Load rules for a couple of special cases
GetStandardRules "javascript"
GetStandardRules "typescript"

##########################
# Define linter commands #
##########################
declare -A LINTER_COMMANDS_ARRAY
LINTER_COMMANDS_ARRAY['ARM']="Import-Module ${ARM_TTK_PSD1} ; \${config} = \$(Import-PowerShellDataFile -Path ${ARM_LINTER_RULES}) ; Test-AzTemplate @config -TemplatePath"
LINTER_COMMANDS_ARRAY['BASH']="shellcheck --color --external-sources"
LINTER_COMMANDS_ARRAY['BASH_EXEC']="bash-exec"
LINTER_COMMANDS_ARRAY['CLOJURE']="clj-kondo --config ${CLOJURE_LINTER_RULES} --lint"
LINTER_COMMANDS_ARRAY['CLOUDFORMATION']="cfn-lint --config-file ${CLOUDFORMATION_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['COFFEESCRIPT']="coffeelint -f ${COFFEESCRIPT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['CSHARP']="dotnet-format --folder --check --exclude / --include"
LINTER_COMMANDS_ARRAY['CSS']="stylelint --config ${CSS_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['DART']="dartanalyzer --fatal-infos --fatal-warnings --options ${DART_LINTER_RULES}"
# NOTE: dockerfilelint's "-c" option expects the folder *containing* the DOCKER_LINTER_RULES file
LINTER_COMMANDS_ARRAY['DOCKERFILE']="dockerfilelint -c $(dirname ${DOCKERFILE_LINTER_RULES})"
LINTER_COMMANDS_ARRAY['DOCKERFILE_HADOLINT']="hadolint -c ${DOCKERFILE_HADOLINT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['EDITORCONFIG']="editorconfig-checker -config ${EDITORCONFIG_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['ENV']="dotenv-linter"
LINTER_COMMANDS_ARRAY['GO']="golangci-lint run -c ${GO_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['GROOVY']="npm-groovy-lint -c $GROOVY_LINTER_RULES --failon warning"
LINTER_COMMANDS_ARRAY['HTML']="htmlhint --config ${HTML_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JAVA']="java -jar /usr/bin/checkstyle -c ${JAVA_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JAVASCRIPT_ES']="eslint --no-eslintrc -c ${JAVASCRIPT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JAVASCRIPT_STANDARD']="standard ${JAVASCRIPT_STANDARD_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JSON']="jsonlint"
LINTER_COMMANDS_ARRAY['JSX']="eslint --no-eslintrc -c ${JAVASCRIPT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['KOTLIN']="ktlint"
LINTER_COMMANDS_ARRAY['KUBERNETES_KUBEVAL']="kubeval --strict"
LINTER_COMMANDS_ARRAY['LATEX']="chktex -q -l ${LATEX_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['LUA']="luacheck --config ${LUA_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['MARKDOWN']="markdownlint -c ${MARKDOWN_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['OPENAPI']="spectral lint -r ${OPENAPI_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['PERL']="perlcritic"
LINTER_COMMANDS_ARRAY['PHP_BUILTIN']="php -l"
LINTER_COMMANDS_ARRAY['PHP_PHPCS']="phpcs --standard=${PHP_PHPCS_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['PHP_PHPSTAN']="phpstan analyse --no-progress --no-ansi -c ${PHP_PHPSTAN_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['PHP_PSALM']="psalm --config=${PHP_PSALM_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['POWERSHELL']="Invoke-ScriptAnalyzer -EnableExit -Settings ${POWERSHELL_LINTER_RULES} -Path"
LINTER_COMMANDS_ARRAY['PROTOBUF']="protolint lint --config_path ${PROTOBUF_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['PYTHON_BLACK']="black --config ${PYTHON_BLACK_LINTER_RULES} --diff --check"
LINTER_COMMANDS_ARRAY['PYTHON_PYLINT']="pylint --rcfile ${PYTHON_PYLINT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['PYTHON_FLAKE8']="flake8 --config=${PYTHON_FLAKE8_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['R']="lintr"
LINTER_COMMANDS_ARRAY['RAKU']="raku"
LINTER_COMMANDS_ARRAY['RUBY']="rubocop -c ${RUBY_LINTER_RULES} --force-exclusion"
LINTER_COMMANDS_ARRAY['SHELL_SHFMT']="shfmt -d"
LINTER_COMMANDS_ARRAY['SNAKEMAKE_LINT']="snakemake --lint -s"
LINTER_COMMANDS_ARRAY['SNAKEMAKE_SNAKEFMT']="snakefmt --config ${SNAKEMAKE_SNAKEFMT_LINTER_RULES} --check --compact-diff"
LINTER_COMMANDS_ARRAY['STATES']="asl-validator --json-path"
LINTER_COMMANDS_ARRAY['SQL']="sql-lint --config ${SQL_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TERRAFORM']="tflint -c ${TERRAFORM_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TERRAFORM_TERRASCAN']="terrascan scan -p /root/.terrascan/pkg/policies/opa/rego/ -t aws -f "
LINTER_COMMANDS_ARRAY['TERRAGRUNT']="terragrunt hclfmt --terragrunt-check --terragrunt-hclfmt-file "
LINTER_COMMANDS_ARRAY['TSX']="eslint --no-eslintrc -c ${TYPESCRIPT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TYPESCRIPT_ES']="eslint --no-eslintrc -c ${TYPESCRIPT_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TYPESCRIPT_STANDARD']="standardx --parser @typescript-eslint/parser --plugin @typescript-eslint/eslint-plugin ${TYPESCRIPT_STANDARD_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['XML']="xmllint"
LINTER_COMMANDS_ARRAY['YAML']="yamllint -c ${YAML_LINTER_RULES}"


##################################
# Get and print all version info #
##################################
GetLinterVersions

###########################################
# Check to see if this is a test case run #
###########################################
if [[ ${TEST_CASE_RUN} != "false" ]]; then

  #############################################
  # Set the multi status to off for test runs #
  #############################################
  MULTI_STATUS='false'

  ###########################
  # Run only the test cases #
  ###########################
  # Code will exit from inside this loop
  RunTestCases
fi

###########################################
# Build the list of files for each linter #
###########################################
BuildFileList "${VALIDATE_ALL_CODEBASE}"

###############
# Run linters #
###############
EDITORCONFIG_FILE_PATH="${GITHUB_WORKSPACE}"/.editorconfig

for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
  debug "Running linter for the ${LANGUAGE} language..."
  VALIDATE_LANGUAGE_VARIABLE_NAME="VALIDATE_${LANGUAGE}"
  debug "Setting VALIDATE_LANGUAGE_VARIABLE_NAME to ${VALIDATE_LANGUAGE_VARIABLE_NAME}..."
  VALIDATE_LANGUAGE_VARIABLE_VALUE="${!VALIDATE_LANGUAGE_VARIABLE_NAME}"
  debug "Setting VALIDATE_LANGUAGE_VARIABLE_VALUE to ${VALIDATE_LANGUAGE_VARIABLE_VALUE}..."

  if [ "${VALIDATE_LANGUAGE_VARIABLE_VALUE}" = "true" ]; then
    # Check if we need an .editorconfig file
    # shellcheck disable=SC2153
    if [ "${LANGUAGE}" = "EDITORCONFIG" ] || [ "${LANGUAGE}" = "SHELL_SHFMT" ]; then
      if [ -e "${EDITORCONFIG_FILE_PATH}" ]; then
        debug "Found an EditorConfig file at ${EDITORCONFIG_FILE_PATH}"
      else
        debug "No .editorconfig found at: $EDITORCONFIG_FILE_PATH. Skipping ${LANGUAGE} linting..."
        continue
      fi
    elif [ "${LANGUAGE}" = "R" ] && [ ! -f "${GITHUB_WORKSPACE}/.lintr" ] && ((${#FILE_ARRAY_R[@]})); then
        info "No .lintr configuration file found, using defaults."
        cp $R_LINTER_RULES "$GITHUB_WORKSPACE"
    # Check if there's local configuration for the Raku linter
    elif [ "${LANGUAGE}" = "RAKU" ] && [ -e "${GITHUB_WORKSPACE}/META6.json" ]; then
      cd "${GITHUB_WORKSPACE}" && zef install --deps-only --/test .
    fi

    if [ "${LANGUAGE}" = "ANSIBLE" ]; then
      # Due to the nature of how we want to validate Ansible, we cannot use the
      # standard loop, since it looks for an ansible folder, excludes certain
      # files, and looks for additional changes, it should be an outlier
      LintAnsibleFiles "${ANSIBLE_LINTER_RULES}" # Passing rules but not needed, dont want to exclude unused var
    else
      LINTER_NAME="${LINTER_NAMES_ARRAY["${LANGUAGE}"]}"
      if [ -z "${LINTER_NAME}" ];then
        fatal "Cannot find the linter name for ${LANGUAGE} language."
      else
        debug "Setting LINTER_NAME to ${LINTER_NAME}..."
      fi

      LINTER_COMMAND="${LINTER_COMMANDS_ARRAY["${LANGUAGE}"]}"
      if [ -z "${LINTER_COMMAND}" ];then
        fatal "Cannot find the linter command for ${LANGUAGE} language."
      else
        debug "Setting LINTER_COMMAND to ${LINTER_COMMAND}..."
      fi

      FILE_ARRAY_VARIABLE_NAME="FILE_ARRAY_${LANGUAGE}"
      debug "Setting FILE_ARRAY_VARIABLE_NAME to ${FILE_ARRAY_VARIABLE_NAME}..."

      # shellcheck disable=SC2125
      LANGUAGE_FILE_ARRAY="${FILE_ARRAY_VARIABLE_NAME}"[@]
      debug "${FILE_ARRAY_VARIABLE_NAME} file array contents: ${!LANGUAGE_FILE_ARRAY}"

      debug "Invoking ${LINTER_NAME} linter..."
      LintCodebase "${LANGUAGE}" "${LINTER_NAME}" "${LINTER_COMMAND}" "${FILTER_REGEX_INCLUDE}" "${FILTER_REGEX_EXCLUDE}" "${!LANGUAGE_FILE_ARRAY}"
    fi
  fi
done

###########
# Reports #
###########
Reports

##########
# Footer #
##########
Footer
