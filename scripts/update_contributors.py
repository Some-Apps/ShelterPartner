import requests
from datetime import datetime

# Replace with your repository owner and name
REPO_OWNER = "Some-Apps"
REPO_NAME = "ShelterPartner"
CONTRIBUTORS = ["JaredDanielJones", "rhjones777", "kateoconn1", "jacobthejones"]  # Add more as needed

def get_contributions(repo_owner, repo_name, contributor):
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/pulls?state=closed&per_page=100"
    response = requests.get(url)
    pulls = response.json()

    contributions = []
    for pull in pulls:
        if pull['user']['login'] == contributor and pull['merged_at'] is not None:
            contributions.append(pull)
    
    return contributions

def count_contributions_last_month(contributions):
    now = datetime.now()
    last_month = now.month - 1 if now.month > 1 else 12
    
    return sum(1 for contribution in contributions 
               if datetime.strptime(contribution['merged_at'], '%Y-%m-%dT%H:%M:%SZ').month == last_month)

def update_readme(contributor, tier):
    with open("README.md", "r") as file:
        readme = file.readlines()

    # Update contributor's tier in README
    for i, line in enumerate(readme):
        if f"{contributor}" in line:
            readme[i] = f"{contributor} - {tier} Tier\n"

    with open("README.md", "w") as file:
        file.writelines(readme)

def main():
    for contributor in CONTRIBUTORS:
        contributions = get_contributions(REPO_OWNER, REPO_NAME, contributor)
        last_month_contributions = count_contributions_last_month(contributions)
        
        # Update tier based on contribution counts
        if last_month_contributions >= 5:
            tier = "GitHub Copilot"
        elif last_month_contributions >= 1:
            tier = "Gather Account"
        else:
            tier = "Inactive"
        
        update_readme(contributor, tier)

if __name__ == "__main__":
    main()
