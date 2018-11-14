About
=================

Shiny front-end for the DNABarcodeCompatibility R-package.


Start up / installation 
================

#### Requirements

* Install [R](https://www.r-project.org/) if not yet installed (R >= 3.4 is required).
* Install the [DNABarcodeCompatibility](https://github.com/comoto-pasteur-fr/DNABarcodeCompatibility#installation) R-package if not yet installed.
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

* [Quick start tutorial](https://comoto-pasteur-fr.github.io/DNABarcodeCompatibility_Shiny/quickstart_tutorial/quickStartTutorial.pdf)


Support
=========

Please use the [github ticket system](https://github.com/comoto-pasteur-fr/DNABarcodeCompatibility_Shiny/issues) to report issues or suggestions. 
We also welcome pull requests.



Reference
==========

Céline Trébeau, Jacques Boutet de Monvel, Fabienne Wong Jun Tai, Raphaël Etournay. (2018, May 31). comoto-pasteur-fr/DNABarcodeCompatibility: First complete release (Version v0.0.0.9000). Zenodo. [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1256863.svg)](https://doi.org/10.5281/zenodo.1256863)


