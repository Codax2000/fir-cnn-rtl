# GitHub Commands and Code Management

Here are two tutorials from UW CSE and YouTube on the basics of GitHub.
[GitHub Setup](https://courses.cs.washington.edu/courses/cse154/22au/resources/assets/vscode-git-tutorial/windows/index.html)
[GitHub Crash Course](https://youtu.be/RGOj5yH7evk)

## Useful GitHub Commands

### Cloning the GitHub Repo  
1. Make sure your SSH key is set up properly.
2. Navigate to the GitHub repository and click the green button at the top-right of the repository that says 'clone.'
3. Under the drop-down menu, select 'Clone with SSH'
4. Copy the command and navigate in your local terminal to the folder into which you would like to clone the repo.
5. Type `git clone git@github.com:Codax2000/fir-cnn-rtl.git` and hit 'enter'

### Pushing to the Repo
1. In the local repository, type the following commands:
```
git add .
git commit -m "UPDATE MESSAGE HERE"
git push
```

TODO: Update this section for different branches