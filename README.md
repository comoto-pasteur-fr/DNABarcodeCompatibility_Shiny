About
=================

Shiny front-end for the DNABarcodeCompatibility R-package.
Maintainer: Fabienne Wong Jun Tai

[Shiny Web App](https://dnabarcodecompatibility.pasteur.fr)


Local installation / Start up
================

#### Requirements

* Install [R](https://www.r-project.org/) if not yet installed (R >= 3.4 is required).
* Install the latest version of  [DNABarcodeCompatibility](https://github.com/comoto-pasteur-fr/DNABarcodeCompatibility#installation) R-package if not yet installed.
* Within a R console, type in the following commands:

```
# Install the shiny package and additional dependencies
install.packages(c('shiny', 'rmarkdown', 'shinydashboard', 'htmlTable', 'stringr', 'DT', 'shinyjs'), repos='https://cran.rstudio.com/')

```


#### Quick start using the R console

* Within a R console, type in the following commands:

```
library(shiny)    
runGitHub("comoto-pasteur-fr/DNABarcodeCompatibility_Shiny", subdir="R", launch.browser=TRUE)
```
* Close the R console to stop the application.


#### Advanced setup using docker

* First install [docker](https://docs.docker.com/install/) if not yet installed.
* Install and run the Shiny App

```
# In a shell console type in the following commands
docker pull etournay/dna_barcode_compatibility_shiny
docker run --name barcode_shiny -d -p 8080:3838 etournay/dna_barcode_compatibility_shiny
```

* Access the Shiny App from your web browser: [localhost:8080](http://localhost:8080)

* Start and stop the Shiny App on demand

```
# Start barcode_shiny
docker start barcode_shiny

# Stop barcode_shiny
docker stop barcode_shiny
```




Documentation
================

* Check the tutorial and help menus in the Shiny web app.


Support
=========

Please use the [github ticket system](https://github.com/comoto-pasteur-fr/DNABarcodeCompatibility_Shiny/issues) to report issues or suggestions. 
We also welcome pull requests.



Reference
==========

Trébeau, C., Boutet de Monvel, J., Wong Jun Tai, F., Petit, C., and Etournay, R. DNABarcodeCompatibility: an R-package for optimizing DNA-barcode combinations in multiplex sequencing experiments. Bioinformatics. [10.1093/bioinformatics/bty1030](10.1093/bioinformatics/bty1030)



