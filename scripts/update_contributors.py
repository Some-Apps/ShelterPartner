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

# Update README with contributor data
def update_readme(contributors):
    # Sort by total contributions
    sorted_contributors = sorted(contributors, key=lambda c: c['contributions'], reverse=True)

    # Prepare the grid content for the README
    grid_content = """
## Contributors Grid

| Contributor       | Tier                | Total Contributions | Profile Photo |
|-------------------|---------------------|----------------------|---------------|
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

        # Add contributor details to the grid
        grid_content += f"| [{contributor['login']}]({contributor['html_url']}) | {tier} | {contributor['contributions']} | ![Avatar]({contributor['avatar_url']}) |\n"

    grid_content += "\n"

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
        "\n" + grid_content + readme[end_index:]
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


