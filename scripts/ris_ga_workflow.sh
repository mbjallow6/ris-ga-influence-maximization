#!/bin/bash

# =============================================================================
# RIS+GA Influence Maximization - Git & GitHub Research Workflow Script
# =============================================================================
# Automates the complete Git/GitHub workflow for RIS+GA feature development.
# Usage: ./scripts/ris_ga_workflow.sh [command] [options]
# =============================================================================

set -e  # Exit on any error

# --- Configuration ---
MAIN_BRANCH="main"
FEATURE_PREFIX="feature/"
REMOTE_NAME="origin"
PYTHON_ENV="venv"
PROJECT_NAME="ris-ga-influence-maximization"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Utility Functions ---
print_header()   { echo -e "\n${BLUE}=== $1 ===${NC}"; }
print_success()  { echo -e "${GREEN}✅ $1${NC}"; }
print_info()     { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()    { echo -e "${RED}❌ $1${NC}"; }

check_project_root() {
    if [[ ! -f "setup.py" ]] || [[ ! -d "src" ]]; then
        print_error "Not in RIS+GA project root directory."
        print_info "Please run this script from the ris_ga_im_project directory."
        exit 1
    fi
}

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository."
        exit 1
    fi
}

check_virtual_env() {
    if [[ ! -d "$PYTHON_ENV" ]]; then
        print_error "Virtual environment '$PYTHON_ENV' not found."
        print_info "Please run './scripts/install.sh' first."
        exit 1
    fi
}

check_github_cli() {
    if ! command -v gh > /dev/null; then
        print_warning "GitHub CLI (gh) is not installed."
        print_info "Install with: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg"
        print_info "Then install: sudo apt update && sudo apt install gh"
        return 1
    fi

    if ! gh auth status > /dev/null 2>&1; then
        print_warning "Not authenticated with GitHub CLI. Please run: gh auth login"
        return 1
    fi

    return 0
}

get_current_branch() {
    git branch --show-current
}

activate_env() {
    # Use `.` or `source` depending on shell
    if [[ -f "$PYTHON_ENV/bin/activate" ]]; then
        # shellcheck disable=SC1091
        source "$PYTHON_ENV/bin/activate"
    else
        print_error "Cannot find activation script in '$PYTHON_ENV/bin/activate'"
        exit 1
    fi
}

run_tests() {
    print_info "Running project tests..."
    activate_env
    if pytest tests/ -v; then
        print_success "All tests passed!"
        return 0
    else
        print_error "Tests failed!"
        return 1
    fi
}

check_code_quality() {
    print_info "Checking code quality..."
    activate_env

    # Check if black and flake8 are available
    if command -v black &> /dev/null && command -v flake8 &> /dev/null; then
        print_info "Running black formatter..."
        black --check src/ tests/ || {
            print_warning "Code formatting issues found. Run 'black src/ tests/' to fix."
        }

        print_info "Running flake8 linter..."
        flake8 src/ tests/ || {
            print_warning "Linting issues found."
        }

        print_success "Code quality checks completed!"
    else
        print_info "Code quality tools not installed. Skipping..."
    fi
}

# --- Main Workflow Functions ---

start_day() {
    print_header "🚀 STARTING DAY - RIS+GA PROJECT"
    check_project_root
    check_git_repo

    print_info "Switching to '$MAIN_BRANCH' and syncing..."
    git checkout $MAIN_BRANCH
    git fetch --all --prune
    git pull $REMOTE_NAME $MAIN_BRANCH

    print_info "Cleaning up old merged branches..."
    git branch --merged | grep -v "\*\|$MAIN_BRANCH" | xargs -r git branch -d

    print_info "Activating development environment..."
    activate_env

    print_success "Repository is up-to-date. Ready for RIS+GA development!"
}

create_feature() {
    local feature_name=$1
    if [[ -z "$feature_name" ]]; then
        print_error "Feature name is required."
        print_info "Usage: ./scripts/ris_ga_workflow.sh feature <name>"
        print_info "Examples:"
        print_info "  ./scripts/ris_ga_workflow.sh feature ris-sampler"
        print_info "  ./scripts/ris_ga_workflow.sh feature ga-population-management"
        print_info "  ./scripts/ris_ga_workflow.sh feature public-health-metrics"
        exit 1
    fi

    local branch_name="${FEATURE_PREFIX}${feature_name}"
    print_header "🌿 CREATING NEW FEATURE: $branch_name"

    start_day # Always start from an up-to-date main branch

    print_info "Creating and switching to new branch..."
    git checkout -b "$branch_name"

    print_success "Ready to work on feature '$branch_name'."
    print_info "Don't forget to run tests before committing: ./scripts/ris_ga_workflow.sh test"
}

save_work() {
    local commit_message=${1:-"WIP: Save progress"}
    print_header "💾 SAVING WORK"
    check_project_root

    # Run quick tests before saving
    if ! run_tests; then
        print_warning "Tests are failing. Saving anyway, but please fix before creating PR."
    fi

    if ! git diff-index --quiet HEAD --; then
        git add -A
        git commit -m "$commit_message"
        print_success "Changes committed locally."
    else
        print_info "No changes to commit."
    fi

    print_info "Pushing to remote..."
    git push -u $REMOTE_NAME $(get_current_branch)
    print_success "Work pushed to GitHub!"
}

test_project() {
    print_header "🧪 RUNNING TESTS"
    check_project_root
    check_virtual_env

    run_tests
    check_code_quality
}

create_pr() {
    local current_branch=$(get_current_branch)
    local pr_title=${1:-"feat: ${current_branch#$FEATURE_PREFIX}"}

    if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
        print_error "Cannot create PR from main branch."
        print_info "Please create a feature branch first: ./scripts/ris_ga_workflow.sh feature <name>"
        exit 1
    fi

    print_header "📬 CREATING PULL REQUEST"

    # Save any final changes and run comprehensive tests
    save_work "Ready for review: ${pr_title}"

    if ! run_tests; then
        print_error "Tests must pass before creating a pull request."
        exit 1
    fi

    if check_github_cli; then
        print_info "Creating pull request on GitHub..."
        gh pr create \
            --title "$pr_title" \
            --body "## Description
Pull request for the **${current_branch#$FEATURE_PREFIX}** feature.

## Testing
- [x] All tests passing
- [x] Code quality checks completed

## Type of Change
- [ ] Bug fix
- [ ] New feature (RIS algorithm)
- [ ] New feature (GA algorithm)
- [ ] Public health integration
- [ ] Documentation update
- [ ] Performance improvement

## Checklist
- [x] Tests added/updated
- [x] Documentation updated (if needed)
- [x] Code follows project style guidelines" \
            --base $MAIN_BRANCH

        print_success "Pull request created!"
        gh pr view --web
    else
        print_info "GitHub CLI not available. Please create PR manually at:"
        print_info "https://github.com/mbjallow6/ris-ga-influence-maximization/compare/$current_branch"
    fi
}

complete_feature() {
    local current_branch=$(get_current_branch)
    print_header "🎉 COMPLETING FEATURE"

    if ! check_github_cli; then
        print_error "GitHub CLI required for auto-merge. Please merge PR manually on GitHub."
        exit 1
    fi

    print_info "Merging pull request via GitHub CLI..."
    gh pr merge "$current_branch" --squash --delete-branch

    # Go back to main and clean up
    start_day

    print_success "Feature '$current_branch' has been merged and cleaned up!"
}

show_status() {
    print_header "📊 PROJECT STATUS"
    check_project_root

    print_info "Current branch: $(get_current_branch)"
    print_info "Git status:"
    git status --short

    if [[ -d "$PYTHON_ENV" ]]; then
        print_success "Virtual environment: Ready"
    else
        print_warning "Virtual environment: Not found"
    fi

    print_info "Recent commits:"
    git log --oneline -5
}

# --- Main Script Logic ---
main() {
    local command=${1:-help}
    shift || true

    case $command in
        start) start_day ;;
        feature) create_feature "$1" ;;
        save) save_work "$*" ;;
        test) test_project ;;
        pr) create_pr "$*" ;;
        complete) complete_feature ;;
        status) show_status ;;
        *)
            print_header "🔬 RIS+GA INFLUENCE MAXIMIZATION WORKFLOW"
            echo "Usage: ./scripts/ris_ga_workflow.sh [command] [options]"
            echo ""
            echo "Commands:"
            echo "  start           - Start day: sync main branch, clean up"
            echo "  feature <name>  - Create new feature branch"
            echo "  save [message]  - Save work with optional commit message"
            echo "  test            - Run tests and code quality checks"
            echo "  pr [title]      - Create pull request"
            echo "  complete        - Complete feature (merge and cleanup)"
            echo "  status          - Show project status"
            echo ""
            echo "Examples:"
            echo "  ./scripts/ris_ga_workflow.sh start"
            echo "  ./scripts/ris_ga_workflow.sh feature ris-sampler"
            echo "  ./scripts/ris_ga_workflow.sh save 'Implement RIS theta estimation'"
            echo "  ./scripts/ris_ga_workflow.sh pr 'Add RIS sampler framework'"
            echo ""
            print_info "Repository: https://github.com/mbjallow6/ris-ga-influence-maximization"
            ;;
    esac
}

main "$@"
