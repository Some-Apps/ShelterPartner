import requests
from datetime import datetime, timedelta

# Replace with your repository owner and name
REPO_OWNER = "Some-Apps"
REPO_NAME = "ShelterPartner"
OWNER = "JaredDanielJones"  # Set the owner's GitHub username

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

# Calculate contributions within specific time periods
def count_contributions_in_timeframe(contributions, days):
    now = datetime.utcnow()
    timeframe_start = now - timedelta(days=days)
    
    return sum(1 for contribution in contributions 
               if datetime.strptime(contribution['merged_at'], '%Y-%m-%dT%H:%M:%SZ') > timeframe_start)

# Get the list of perks based on contributions in time periods
def get_perks(contributor_login, contributions):
    # If the contributor is the owner, return "NA"
    if contributor_login == OWNER:
        return "NA"
    
    perks = []
    
    # Contributions in the last 30 days
    contributions_last_30_days = count_contributions_in_timeframe(contributions, 30)
    if contributions_last_30_days >= 1:
        perks.append("Gather Account")
    if contributions_last_30_days >= 5:
        perks.append("GitHub Copilot")

    # Contributions in the last 365 days (1 year)
    contributions_last_year = count_contributions_in_timeframe(contributions, 365)
    if contributions_last_year >= 50:
        perks.append("ChatGPT Subscription")

    return ", ".join(perks) if perks else "None"

# Update README with contributor data
def update_readme(contributors):
    # Sort by total contributions (all-time contributions)
    sorted_contributors = sorted(contributors, key=lambda c: c['contributions'], reverse=True)

    # Prepare the HTML table content for the README
    html_content = """
## Contributors
Updated daily

<table>
  <thead>
    <tr>
      <th>Photo</th>
      <th>User</th>
      <th>Contributions</th>
      <th>Perks</th>
    </tr>
  </thead>
  <tbody>
"""

    for contributor in sorted_contributors:
        contributions = get_contributions(REPO_OWNER, REPO_NAME, contributor)
        
        # Get the list of perks for the contributor (set to "NA" for the owner)
        perks_list = get_perks(contributor['login'], contributions)

        # Add each contributor's info in a row
        html_content += f"""
    <tr>
      <td>
        <a href="{contributor['html_url']}">
          <img src="{contributor['avatar_url']}?s=100" width="100" height="100" alt="{contributor['login']}'s avatar"/>
        </a>
      </td>
      <td><a href="{contributor['html_url']}"><strong>{contributor['login']}</strong></a></td>
      <td><strong>{len(contributions)} contributions</strong></td>
      <td>{perks_list}</td>
    </tr>
"""

    html_content += """
  </tbody>
</table>

"""

    # Read the current README content
    with open("README.md", "r") as file:
        readme = file.read()

    # Identify the start and end of the "Contributors" section
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
        "\n" + html_content.strip() + "\n" + readme[end_index:]
    )

    # Write the updated content back to the README file
    with open("README.md", "w") as file:
        file.write(updated_readme)

def main():
    contributors = fetch_contributors(REPO_OWNER, REPO_NAME)
    
    # Update the README with contributor list table
    update_readme(contributors)

if __name__ == "__main__":
    main()

