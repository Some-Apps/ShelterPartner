import requests
from datetime import datetime

# Replace with your repository owner and name
REPO_OWNER = "Some-Apps"
REPO_NAME = "ShelterPartner"

# Option to ignore certain contributors
IGNORE_CONTRIBUTORS = ["dependabot[bot]"]  # Add any bots or contributors you want to ignore

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

# Count contributions for the current month or last month
def count_contributions_last_month(contributions):
    now = datetime.now()
    last_month = now.month - 1 if now.month > 1 else 12

    return sum(1 for contribution in contributions 
               if datetime.strptime(contribution['merged_at'], '%Y-%m-%dT%H:%M:%SZ').month == last_month)

# Update README with contributor data
def update_readme(contributors):
    # Sort by total contributions
    sorted_contributors = sorted(contributors, key=lambda c: c['contributions'], reverse=True)

    # Prepare the grid for the README
    readme_content = """
## Contributors Grid

| Contributor       | Tier                | Total Contributions | Profile Photo |
|-------------------|---------------------|----------------------|---------------|
"""

    for contributor in sorted_contributors:
        contributions = get_contributions(REPO_OWNER, REPO_NAME, contributor)
        total_contributions = len(contributions)
        
        # Define tier based on contribution count (can adjust these rules)
        if total_contributions >= 50:
            tier = "ChatGPT"
        elif total_contributions >= 5:
            tier = "GitHub Copilot"
        elif total_contributions >= 1:
            tier = "Gather Account"
        else:
            tier = "Inactive"

        # Add contributor details to the grid
        readme_content += f"| [{contributor['login']}]({contributor['html_url']}) | {tier} | {contributor['contributions']} | ![Avatar]({contributor['avatar_url']}) |\n"

    # Write the updated content back to the README file
    with open("README.md", "w") as file:
        file.write(readme_content)

def main():
    contributors = fetch_contributors(REPO_OWNER, REPO_NAME)
    
    # Update the README with contributor grid
    update_readme(contributors)

if __name__ == "__main__":
    main()

