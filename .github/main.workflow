workflow "Create docker container" {
  on = "push"
  resolves = ["GitHub Action for Docker-1"]
}

action "Docker Registry" {
  uses = "actions/docker/login@86ab5e854a74b50b7ed798a94d9b8ce175d8ba19"
  secrets = ["DOCKER_USERNAME", "DOCKER_PASSWORD"]
}

action "GitHub Action for Docker" {
  uses = "actions/docker/cli@86ab5e854a74b50b7ed798a94d9b8ce175d8ba19"
  needs = ["Docker Registry"]
  args = "build -t tonobo/sma_exporter ."
}

action "GitHub Action for Docker-1" {
  uses = "actions/docker/cli@86ab5e854a74b50b7ed798a94d9b8ce175d8ba19"
  needs = ["GitHub Action for Docker"]
  args = "push tonobo/sma_exporter"
}
