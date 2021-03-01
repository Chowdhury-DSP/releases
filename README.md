# ChowDSP Releases Pipeline

GitHub Actions pipeline for releasing ChowDSP plugins.

## Nightly Pipeline

The nightly pipeline runs once per night, and performs the following tasks:
- Check every plugin in the `plugins` directory to see if the main plugin
  repository has been updated.
- The script will then push to GitHub to kick off a build for all of the plugins
  that have been updated.
- The builds will run via GitHub Actions, and upload the resulting artifacts to a server.
- The nightly script will wait 1 hour, then check the server for new builds.
- If new builds are available, the script will download them to a `nightly_plugins`
  directory that can be accessed by the ChowDSP web page.

TODO: make a releases script.
