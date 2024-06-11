# git-shortcuts
# various git shortcuts / macros

function check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo "Error: You have uncommitted changes. Please commit or stash them."
        return 1
    fi
}

function git-switch-branch() {
    # saves local changes and switches to branch
    local branch_name="$1"
    git add -A
    git commit -m "WIP" --no-verify
    git pull origin "$branch_name"
    git checkout "$branch_name"
}

function git-rebase-to-master() {
    set -e

    # Check for uncommitted changes
    check_uncommitted_changes

    # Fetch the latest changes from the remote repository
    echo "Fetching latest updates from origin..."
    git fetch origin master
    
    # Rebase the current branch on top of the fetched master branch
    echo "Rebasing current branch onto master..."
    git rebase origin/master
    
    echo "Rebase successful!"
}

function git-push-new-branch() {
    set -e

    # Get the current branch name
    local branch_name="$(git branch --show-current)"

    # Check for uncommitted changes
    check_uncommitted_changes

    # Push the current branch to the remote and set upstream tracking
    echo "Pushing new branch '$branch_name' to remote..."
    git push -u origin "$branch_name"

    echo "Push successful and upstream tracking set!"
}