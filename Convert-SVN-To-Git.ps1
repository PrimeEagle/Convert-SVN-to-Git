Param(
    [Parameter(Mandatory=$true)]
    [string]$SvnUrl,

    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,

    [Parameter(Mandatory=$true, ParameterSetName="NonStandardLayout")]
    [string]$Trunk,

    [Parameter(Mandatory=$true, ParameterSetName="NonStandardLayout")]
    [string]$Branches,

    [Parameter(Mandatory=$true, ParameterSetName="NonStandardLayout")]
    [string]$Tags,

    [Parameter(Mandatory=$false)]
    [string]$GitUrl,

    [Parameter(Mandatory=$true)]
    [string]$UsersFile,

    [Parameter(Mandatory=$false, ParameterSetName="StandardLayout")]
    [switch]$IsStandardLayout,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeMetadata,

    [Parameter(Mandatory=$false)]
    [string]$MainBranchName = "main",
	
	[Parameter(Mandatory=$false)]
    [switch]$CreatePrivateRepository,

    [Parameter(Mandatory=$false)]
    [switch]$CreatePublicRepository,
	
	[Parameter(Mandatory=$false)]
    [string]$RepoName
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

if ($CreatePrivateRepository -and $CreatePublicRepository) {
    throw "Cannot use -CreatePrivateRepository and -CreatePublicRepository together."
}

if (($CreatePrivateRepository -or $CreatePublicRepository) -and -not $RepoName) {
    throw "The parameter -RepoName is required when creating a GitHub repository."
}

$TempTargetDirectory = "$TargetDirectory.tmp"

$arguments = @("svn", "clone", "--authors-file=$UsersFile", $SvnUrl, $TempTargetDirectory)

if ($IsStandardLayout) 
{ 
	$arguments += "--stdlayout" 
}
else
{
	$arguments += "--trunk=$Trunk"
	$arguments += "--branches=$Branches"
	$arguments += "--tags=$Tags"
}

if (-Not $IncludeMetadata) { $arguments += "--no-metadata" }

& git $arguments

ProcessSvnBranchesAndTags -tempDir $TempTargetDirectory -mainBranch $MainBranchName

git clone "$TempTargetDirectory" $TargetDirectory

ProcessGitBranches -tempDir $TempTargetDirectory -mainBranch $MainBranchName

git -C $TargetDirectory remote rm origin

if($CreatePrivateRepository -or $CreatePublicRepository)
{
	$repoVisibility = if ($CreatePrivateRepository) { "private" } else { "public" }

	gh repo create $RepoName --$repoVisibility --source="$TargetDirectory" --push
	
	git -C $TargetDirectory branch -M $MainBranchName
	git -C $TargetDirectory push --set-upstream origin $MainBranchName
}

if (Test-Path $TempTargetDirectory) {
    Remove-Item -Recurse -Force "$TempTargetDirectory"
}
