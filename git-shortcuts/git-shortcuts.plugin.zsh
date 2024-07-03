# git-shortcuts
# various git shortcuts / macros

function check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo "Error: You have uncommitted changes. Please commit or stash them."
        return 1
    fi
    return 0
}

function git-switch-branch() {
    # saves local changes and switches to branch
    local branch_name="$1"
    git add -A
    git commit -m "WIP" --no-verify
    if ! git pull origin "$branch_name"; then
        echo "Error: Failed to pull from origin/$branch_name"
        return 1
    fi
    if ! git checkout "$branch_name"; then
        echo "Error: Failed to checkout $branch_name"
        return 1
    fi
    echo "Successfully switched to branch $branch_name"
}

function git-rebase-to-master() {
    # Check for uncommitted changes
    if ! check_uncommitted_changes; then
        return 1
    fi

    # Fetch the latest changes from the remote repository
    echo "Fetching latest updates from origin..."
    if ! git fetch origin master; then
        echo "Error: Failed to fetch from origin/master"
        return 1
    fi
    
    # Rebase the current branch on top of the fetched master branch
    echo "Rebasing current branch onto master..."
    if ! git rebase origin/master; then
        echo "Error: Rebase failed. Please resolve conflicts and run 'git rebase --continue'"
        return 1
    fi
    
    echo "Rebase successful!"
}

function git-push-new-branch() {
    # Get the current branch name
    local branch_name="$(git branch --show-current)"

    # Check for uncommitted changes
    if ! check_uncommitted_changes; then
        return 1
    fi

    # Push the current branch to the remote and set upstream tracking
    echo "Pushing new branch '$branch_name' to remote..."
    if ! git push -u origin "$branch_name"; then
        echo "Error: Failed to push branch $branch_name to origin"
        return 1
    fi

    echo "Push successful and upstream tracking set!"
}

function git-checkout-upstream() {
    if [ $# -eq 0 ]; then
        echo "Usage: git-checkout-upstream <branch_name>"
        return 1
    fi

    local branch_name="$1"
    local remote_name="origin"

    # Check for uncommitted changes
    if ! check_uncommitted_changes; then
        return 1
    fi

    # Fetch only the specified branch from the remote
    echo "Fetching branch '$branch_name' from $remote_name..."
    if ! git fetch "$remote_name" "$branch_name"; then
        echo "Error: Failed to fetch branch $branch_name from $remote_name"
        return 1
    fi

    # Check if the branch exists on the remote
    if git ls-remote --exit-code --heads "$remote_name" "$branch_name" >/dev/null 2>&1; then
        # Create a new local branch tracking the remote branch
        echo "Checking out branch '$branch_name'..."
        if ! git checkout -b "$branch_name" "$remote_name/$branch_name"; then
            echo "Error: Failed to checkout branch $branch_name"
            return 1
        fi
        echo "Branch '$branch_name' checked out successfully!"
    else
        echo "Error: Branch '$branch_name' does not exist on remote '$remote_name'"
        return 1
    fi
}