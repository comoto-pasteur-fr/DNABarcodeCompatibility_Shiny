FROM openanalytics/r-base

MAINTAINER Raphael Etournay "raphael.etournay@pasteur.fr"

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0

# basic shiny functionality
RUN R -e "install.packages(c('shiny', 'rmarkdown', 'shinydashboard', 'htmlTable', 'stringr', 'DT', 'shinyjs'), repos='https://cran.rstudio.com/')"

# install dependencies of the DNABarcodeCompatibility app
RUN R -e "install.packages('devtools', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('DNABarcodes', repos='https://bioconductor.org/packages/3.7/bioc')"
RUN R -e "devtools::install_github('comoto-pasteur-fr/DNABarcodeCompatibility', ref='revision')"
#RUN R -e "devtools::install_github('comoto-pasteur-fr/DNABarcodeCompatibility', ref='bioconductor')"


# copy the app to the image
RUN mkdir /root/DNABarcodeCompatibility_ShinyApp
COPY R /root/DNABarcodeCompatibility_ShinyApp

COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/DNABarcodeCompatibility_ShinyApp')"]
