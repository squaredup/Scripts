# Scripts

## Overview

Contains various scripts related to Microsoft System Center Operations Manager (SCOM) and/or Squared Up.

## Help and Assistance

All scripts in this repo are community efforts originally developed by Squared Up (<http://www.squaredup.com>).

For help and advice, post questions on <http://community.squaredup.com/answers>.

If you have found a specific bug or issue with the scripts in this repo, please raise an [issue](https://github.com/squaredup/Scripts/issues) on GitHub.

## Contributions

If you want to suggest some fixes or improvements to the scripts, raise an issue on [the GitHub Issues page](https://github.com/squaredup/Scripts/issues) or better, submit the suggested change as a [Pull Request](https://github.com/squaredup/Scripts/pulls).

If you have an awesome command/script that you would like to share but lack the time or skill to polish it, feel free to raise an issue and include the content you want in the script.

### Guidelines

* Please target pull requests at the **Develop** branch.
* Target the minimum version of dependencies that you can, and avoid versions that were introduced in particular minor updates.
* For PowerShell scripts, ensure that there are no outstanding [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer) issues reported by your change.
* Please use appropriate types for your configuration elements (i.e do not use **string** for values that clearly are boolean).
