"""
Create an example Tilt workspace for temporal.
"""

load("ext://uibutton", "cmd_button")

docker_prune_settings(max_age_mins = 360, num_builds = 0, interval_hrs = 1, keep_recent = 2)

docker_compose("./docker-compose.yml")

docker_build("temporalio/temporalite", "./temporalite")

cmd_button(
    "client:submit",
    argv = ["docker-compose", "exec", "client", "node", "--enable-source-maps", "./client/index.js"],
    resource = "client",
    icon_name = "cloud_download",
    text = "Submit Job",
)
