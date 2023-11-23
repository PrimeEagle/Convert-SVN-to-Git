param (
    [string]$ProjectName
)

if (-not $ProjectName) {
    Write-Error "-ProjectName is required."
    exit 1
}

$GitProjectName = $ProjectName.Replace(" ", "-")

& Convert-SVN-To-Git -UsersFile "D:\My Code\users.txt" -IncludeMetadata -Trunk "/$ProjectName" -Branches "/$ProjectName/branches" -Tags "/$ProjectName/tags" -SvnUrl "https://matrix.tplinkdns.com:8443/svn/MyCode" -TargetDirectory "D:\My Code\$ProjectName.git" -GitUrl https://github.com/PrimeEagle/$GitProjectName  -CreatePrivateRepository -RepoName $GitProjectName

try {
    Set-Location "D:\My Code\$ProjectName.git"
    git add .
    git commit -m "initial commit"
    git push
} catch {
    Write-Error "Git commit/push failed: $_"
}