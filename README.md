# Welcome To [Shelter Partner](https://shelterpartner.org)!

The plan is to switch everything to Flutter by the end of the year and scrap the swift and kotlin versions as soon as that's done.

## How To Contribute On GitHub
1. Create an issue in the Some-Apps/ShelterPartner repository or select an existing issue. Issues that I've labeled as "up next" are higher priority but you're welcome to work on anything even if it isn't marked as "up next".
2. Comment on the issue that you would like to work on it
3. Once you have been assigned the issue, fork to the repository into a branch containing the issue number
4. When you are ready, submit a pull request from this branch
5. Your code will be reviewed and then either be approved or have changes requested
6. Once the pull request has been approved, you can safely delete your branch and start on a new issue.

Feel free to use your issue thread to communicate. Contributors will only be assigned one issue at a time.

### File Organization
Follow MVVM repository architecture. For example:

```plaintext
lib/
  models/
    animal.dart
  views/
    pages/
      animals_page.dart
    components/
      animal_card_view.dart
  view_models/
    animals_view_model.dart
  repositories/
    animal_repository.dart
```


