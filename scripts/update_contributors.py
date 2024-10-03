import requests
from datetime import datetime

# Replace with your repository owner and name
REPO_OWNER = "Some-Apps"
REPO_NAME = "ShelterPartner"

# Option to ignore certain contributors
IGNORE_CONTRIBUTORS = ["dependabot[bot]", "allcontributors[bot]", "github-actions[bot]"]  # Add any bots or contributors you want to ignore

# Fetch contributors from the GitHub API
def fetch_contributors(repo_owner, repo_name):
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/contributors?per_page=100"
    response = requests.get(url)
    contributors = response.json()
    
    # Filter out ignored contributors
    return [contributor for contributor in contributors if contributor['login'] not in IGNORE_CONTRIBUTORS]

# Get pull requests for each contributor to calculate total contributions
def get_contributions(repo_owner, repo_name, contributor):
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/pulls?state=closed&per_page=100"
    response = requests.get(url)
    pulls = response.json()

    contributions = []
    for pull in pulls:
        if pull['user']['login'] == contributor['login'] and pull['merged_at'] is not None:
            contributions.append(pull)
    
    return contributions

# Update README with contributor data
def update_readme(contributors):
    # Sort by total contributions
    sorted_contributors = sorted(contributors, key=lambda c: c['contributions'], reverse=True)

    # Prepare the table content for the README
    table_content = """
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
"""

    for contributor in sorted_contributors:
        contributions = get_contributions(REPO_OWNER, REPO_NAME, contributor)
        total_contributions = len(contributions)

        # Define tier based on contribution count
        if total_contributions >= 50:
            tier = "ChatGPT"
        elif total_contributions >= 5:
            tier = "GitHub Copilot"
        elif total_contributions >= 1:
            tier = "Gather Account"
        else:
            tier = "Inactive"

        # Add each contributor's info as a table cell
        table_content += f"""
      <td align="center" valign="top" width="14.28%">
        <a href="{contributor['html_url']}">
          <img src="{contributor['avatar_url']}?s=100" width="100px;" alt="{contributor['login']}'s avatar"/><br />
          <sub><b>{contributor['login']}</b></sub>
        </a><br />
        <em>{tier}</em><br />
        <span>Total Contributions: {total_contributions}</span>
      </td>
"""

    # Close the table row and body
    table_content += """
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
"""

    # Read the current README content
    with open("README.md", "r") as file:
        readme = file.read()

    # Identify the start and end of the "Contributors Grid" section
    start_marker = "<!-- CONTRIBUTORS-START -->"
    end_marker = "<!-- CONTRIBUTORS-END -->"

    start_index = readme.find(start_marker)
    end_index = readme.find(end_marker)

    if start_index == -1 or end_index == -1:
        print("Contributors section not found in README.md")
        return

    # Replace the content between the markers
    updated_readme = (
        readme[:start_index + len(start_marker)] +
        "\n" + table_content + readme[end_index:]
    )

    # Write the updated content back to the README file
    with open("README.md", "w") as file:
        file.write(updated_readme)

def main():
    contributors = fetch_contributors(REPO_OWNER, REPO_NAME)
    
    # Update the README with contributor grid
    update_readme(contributors)

if __name__ == "__main__":
    main()



