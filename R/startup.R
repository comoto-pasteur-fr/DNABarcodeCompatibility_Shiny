#' @title 
#' Start up the DNABarcodeCompatibilityShiny interface
#'
#' @description 
#' Start up the DNABarcodeCompatibilityShiny interface
#'
#' @usage 
#' startup()
#'
#' @return 
#' Launches the web interface
#'
#' @examples
#' # Just run startup()
#' ls()
#' 
#' @export
#' 

startup <- function(){
    shiny::runApp('R')
}
