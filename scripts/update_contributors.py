import os
import requests
import time
from datetime import datetime, timedelta, timezone

# Replace with your repository owner and name
REPO_OWNER = "Some-Apps"
REPO_NAME = "ShelterPartner"
OWNER = "JaredDanielJones"  # Set the owner's GitHub username

# Option to ignore certain contributors
IGNORE_CONTRIBUTORS = ["dependabot[bot]", "allcontributors[bot]", "github-actions[bot]"]  # Add any bots or contributors you want to ignore

# Read GitHub token from environment variable for authenticated requests
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')  # Ensure you set this in your environment

def fetch_all_pages(url):
    items = []
    headers = {}
    if GITHUB_TOKEN:
        headers['Authorization'] = f'token {GITHUB_TOKEN}'
    while url:
        response = requests.get(url, headers=headers)
        if response.status_code == 403 and 'X-RateLimit-Remaining' in response.headers and response.headers['X-RateLimit-Remaining'] == '0':
            # Rate limit exceeded, wait until reset time
            reset_time = int(response.headers['X-RateLimit-Reset'])
            sleep_time = reset_time - int(time.time()) + 5  # Add 5 seconds buffer
            if sleep_time > 0:
                print(f"Rate limit exceeded. Sleeping for {sleep_time} seconds.")
                time.sleep(sleep_time)
                continue  # Retry the request after sleeping
        response.raise_for_status()
        items.extend(response.json())

        # Parse the 'Link' header to get the URL of the next page
        links = response.headers.get('Link', '')
        next_url = None
        for link in links.split(','):
            if 'rel="next"' in link:
                next_url = link[link.find('<')+1:link.find('>')]
                break
        url = next_url
    return items

# Fetch contributors from the GitHub API
def fetch_contributors(repo_owner, repo_name):
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/contributors?per_page=100"
    contributors = fetch_all_pages(url)
    
    # Filter out ignored contributors
    return [contributor for contributor in contributors if contributor['login'] not in IGNORE_CONTRIBUTORS]

def fetch_all_closed_pulls(repo_owner, repo_name):
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/pulls?state=closed&per_page=100"
    pulls = fetch_all_pages(url)
    return pulls

# Calculate contributions within specific time periods
def count_contributions_in_timeframe(contributions, days):
    now = datetime.now(timezone.utc)  # Use timezone-aware UTC datetime
    timeframe_start = now - timedelta(days=days)
    
    return sum(1 for contribution in contributions 
               if datetime.strptime(contribution['merged_at'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc) > timeframe_start)

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
def update_readme(contributors, contributions_by_user):
    # Sort by total contributions (all-time contributions)
    sorted_contributors = sorted(contributors, key=lambda c: c['contributions'], reverse=True)

    # Prepare the HTML table content for the README
    html_content = """
## Contributors

<table>
  <thead>
    <tr>
      <th>Photo</th>
      <th>User</th>
      <th>Contributions</th>
      <th>Perks</th>
    </tr>
  </thead>
  <tbody>"""

    for contributor in sorted_contributors:
        login = contributor['login']
        contributions = contributions_by_user.get(login, [])

        # Get the list of perks for the contributor (set to "NA" for the owner)
        perks_list = get_perks(login, contributions)

        # Set contributions to "NA" if the contributor is the owner
        contributions_count = "NA" if login == OWNER else f"{len(contributions)} contributions"

        # Add each contributor's info in a row
        html_content += f"""
        <tr>
      <td>
        <a href="{contributor['html_url']}">
          <img src="{contributor['avatar_url']}?s=100" width="100" height="100" alt="{login}'s avatar"/>
        </a>
      </td>
      <td><a href="{contributor['html_url']}"><strong>{login}</strong></a></td>
      <td><strong>{contributions_count}</strong></td>
      <td>{perks_list}</td>
    </tr>"""

    html_content += """
  </tbody>
</table>"""

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
    # Fetch all contributors
    print("Fetching contributors...")
    contributors = fetch_contributors(REPO_OWNER, REPO_NAME)

    # Fetch all closed pull requests
    print("Fetching all closed pull requests...")
    all_pulls = fetch_all_closed_pulls(REPO_OWNER, REPO_NAME)

    # Build a mapping from contributor login to their contributions
    contributions_by_user = {}
    for pull in all_pulls:
        if pull['merged_at'] is not None:
            login = pull['user']['login']
            if login not in contributions_by_user:
                contributions_by_user[login] = []
            contributions_by_user[login].append(pull)

    # Update the README with contributor list table
    update_readme(contributors, contributions_by_user)

if __name__ == "__main__":
    main()

