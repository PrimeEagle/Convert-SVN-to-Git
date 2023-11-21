Param(
    [Parameter(Mandatory=$true)]
    [string]$SvnUrl,
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,
    [Parameter(Mandatory=$true)]
    [string]$GitUrl,
    [Parameter(Mandatory=$true)]
    [string]$UsersFile,
    [Parameter(Mandatory=$false)]
    [switch]$NotStandardLayout,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeMetadata,
    [Parameter(Mandatory=$false)]
    [switch]$GitRepositoryExists,
    [Parameter(Mandatory=$false)]
    [string]$MainBranchName = "main"
)

function ProcessSvnBranchesAndTags {
    param (
        [string]$tempDir,
        [string]$mainBranch
    )

    $remoteBranches = git -C $tempDir branch -r
    foreach ($remoteBranch in $remoteBranches) {
        $remoteBranch = $remoteBranch.Trim()

        if ($remoteBranch.StartsWith("tags/")) {
            $tagName = $remoteBranch.Substring(5)
            git -C $tempDir checkout -b "tag-$tagName" $remoteBranch
            git -C $tempDir checkout $mainBranch
            git -C $tempDir tag $tagName "tag-$tagName"
            git -C $tempDir branch -D "tag-$tagName"
        } elseif (-Not $remoteBranch.Contains("trunk")) {
            git -C $tempDir checkout -b $remoteBranch $remoteBranch
        }
    }
}

function ProcessGitBranches {
    param (
        [string]$tempDir,
        [string]$mainBranch
    )

    $remoteBranches = git -C $tempDir branch -r
    foreach ($remoteBranch in $remoteBranches) {
        $remoteBranch = $remoteBranch.Trim()

        if ($remoteBranch -notcontains "HEAD" -and $remoteBranch -notcontains $mainBranch) {
            $branchName = $remoteBranch.Substring(7)
            if (!(git -C $tempDir branch --list $branchName)) {
                git -C $tempDir checkout -b $branchName $remoteBranch
            }
        }
    }

    if (git -C $tempDir branch --list $mainBranch) {
        git -C $tempDir checkout $mainBranch
    } else {
        Write-Warning "Main branch '$mainBranch' does not exist."
    }
}

$TempTargetDirectory = "$TargetDirectory.tmp"

$arguments = @("svn", "clone", "--authors-file=$UsersFile", $SvnUrl, $TempTargetDirectory)
if (-Not $NotStandardLayout) { $arguments += "--stdlayout" }
if (-Not $IncludeMetadata) { $arguments += "--no-metadata" }

& git $arguments

ProcessSvnBranchesAndTags -tempDir $TempTargetDirectory -mainBranch $MainBranchName

if ($GitRepositoryExists) {
    if (-Not (Test-Path $TargetDirectory)) {
        git clone $GitUrl $TargetDirectory
    }

    if (!(git -C $TargetDirectory rev-parse --git-dir 2> $null)) {
        Write-Error "The target directory does not appear to be a Git repository."
        return
    }

    git -C $TargetDirectory fetch origin
    git -C $TargetDirectory remote add svn-migration "$TempTargetDirectory"
    git -C $TargetDirectory pull svn-migration $MainBranchName --allow-unrelated-histories
} else {
    git clone "$TempTargetDirectory" $TargetDirectory

    ProcessGitBranches -tempDir $TempTargetDirectory -mainBranch $MainBranchName

    git -C $TargetDirectory remote rm origin
    git -C $TargetDirectory remote add origin $GitUrl
}

if (Test-Path $TempTargetDirectory) {
    Remove-Item -Recurse -Force "$TempTargetDirectory"
}