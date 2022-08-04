# Add products to Order and Activate - Salesforce DX Project

## Testing Instructions

Please follow below instructions to deploy this to your dev org using VS Code.

### Deploy the `appCustom.css` file as a new Static Resource. ( Optional - Needed for data table padding while scrolling )
1. Create a new Static Resource named: `appCustom`. The file is present in `force-app\main\default\staticresources`
2. Upload the CSS file.

### Clone this project into you local devlopment environment.

`git clone https://github.com/m-debnath/OrderableProductsComponent.git`

or, if you have ssh setup for Github

`git clone git@github.com:m-debnath/OrderableProductsComponent.git`

### Open the git repo in VS Code.
It is expected that you have required Salesforce Extension, Salesforce CLI, nodejs, npm etc. already setup.
If not, follow instructions [here](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/set-up-visual-studio-code).

Authorize your dev org.

Locate the package.xml in `manifest/package.xml`
