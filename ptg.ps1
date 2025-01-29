# Load environment variables from .env file
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            Set-Item -Path "env:$($matches[1])" -Value $matches[2]
        }
    }
} else {
    Write-Host "Error: .env file not found!" -ForegroundColor Red
    exit 1
}

# Set Git user details
git config --global user.name $env:USERN
git config --global user.email "$env:USERN@users.noreply.github.com"

# Set the current directory as a safe Git directory
git config --global --add safe.directory (Get-Location)

# Check if inside a Git repository
if (-Not (Test-Path .git)) {
    Write-Host "Not a git repository. Initializing..."
    git init
    $repo_url = Read-Host "Enter the full GitHub repository URL (e.g., https://github.com/org/repo.git)"
    git remote add origin $repo_url
}

# Prompt for branch name (default: main)
$branch = Read-Host "Enter the branch to push to (default: main)"
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }

# Ensure the branch name is correctly set
git branch -M $branch

# Add all changes
git add .

# Prompt for commit message
$commit_message = Read-Host "Enter commit message"
git commit -m $commit_message

# Authenticate using Personal Access Token by creating a .netrc file
$netrcPath = "$HOME\_netrc"
@"
machine github.com
login $env:USERN
password $env:PASS
"@ | Out-File -Encoding ASCII -FilePath $netrcPath

# Secure the .netrc file
icacls $netrcPath /inheritance:r /grant:r "$($env:USERNAME):R" > $null

# Push changes
git push -u origin $branch

# Cleanup after pushing
Remove-Item -Force $netrcPath

Write-Host "Changes pushed successfully!" -ForegroundColor Green
