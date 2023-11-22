# Convert-SVN-to-Git

<img src="https://github.com/PrimeEagle/Convert-SVN-to-Git/blob/main/convert.png?raw=true" width="250" />

PowerShell script to migrate a Subversion repository to a Git repository.

Parameters:
```
SvnUrl - (required) URL of the the Subversion repository
TargetDirectory - (required) the directoryfor the Git repository
Trunk - (required, unless -IsStandardLayout is specified) path to the trunk in Subversion
Branches - (required, unless -IsStandardLayout is specified) path to the branches in Subversion
Tags - (required, unless -IsStandardLayout is specified) path to the tags in Subversion
GitUrl - (optional) the URL to the Git to create
UsersFile - (required) an SVN-to-Git user mapping file (see below)
IsStandardLayout - (required, unless Trunk, Branches, and Tags are specified) uses the standard Subversion structure
IncludeMetadata - (optional) whether to include Subversion metadata in the conversion
MainBranchName - (optional), defaults to "main" if not specified
CreatePrivateRepository - (optional) whether to create a private repository on Git
CreatePublicRepository - (optional) whether to create a public repository on Git
RepoName - (optional) the name of the repository to create, if CreatePrivateRepository or CreatePublicRepository is specified
```

The users file format is as follows:
```
SVNUser1 = GitUsername <GitEmailAddress>
(no author) = GitUsername <GitEmailAddress>
```
