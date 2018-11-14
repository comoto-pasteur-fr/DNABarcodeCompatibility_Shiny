library(shiny)
library(stringr)
library(DT)
library(shinyjs)
library(DNABarcodeCompatibility)
source("html_output.R")

platformsVec <-
  c(
    "Illumina iSeq100" = 1,
    "Illumina MiniSeq, NextSeq, NovaSeq" = 2,
    "Illumina MiSeq, HiSeq" = 4,
    "Other plaftorms" = 0
  )

distancesVec <-
  c(
    "Hamming" = "hamming",
    "Seqlev" = "seqlev",
    "Phaseshift" = "phaseshift",
    "No distance" = "none"
  )

update_valid_data <- function(df, gc_content_min, gc_content_max, remove_homopolymer) {
  valid = c()
  if (!is.null(df)){
    for (i in 1:nrow(df)) {
      if (df$GC_content[i] >= gc_content_min() &&
          df$GC_content[i] <= gc_content_max()){
        if ((!df$homopolymer[i] && remove_homopolymer()) || !remove_homopolymer()) {
          valid <- c(valid, "TRUE")
        }
        else{
          valid <- c(valid, "FALSE")
        }
      }
      else{
        valid <- c(valid, "FALSE")
      }
    }
    df <- cbind(df, valid)
    return(df)
  }
  else{
    return(NULL)
  }
}

define_distance_metric <- function(metric){
  if (metric == "none"){
    return(NULL)
  }
  else{
    return(metric)
  }
}

server <- function(input, output, session) {
  
  notif_running <- NULL
  final_result <- NULL
  run_time <- NULL
  log <- NULL
  
  #########################
  #### SINGLE INDEXING ####
  #########################
  
  single_sample_number <- reactive(input$single_sample_number)
  single_mplex_level <- reactive(as.numeric(input$single_multiplex_level))
  single_platform <- reactive(input$single_platform)
  single_gc_content_min <- reactive(input$single_gc_content[1])
  single_gc_content_max <- reactive(input$single_gc_content[2])
  single_remove_homopolymer <- reactive(input$single_homopolymer)
  single_metric <- reactive(define_distance_metric(input$single_distance_metric))
  single_distance <- reactive(input$single_distance)
  single_index_df <- reactive(update_valid_data(DNABarcodeCompatibility:::file_loading_and_checking(input$single_file$datapath), single_gc_content_min, single_gc_content_max, single_remove_homopolymer))
  
  ### Update single multiplexing level when sample number changes ###
  observe({
    single_nb_sample <- as.numeric(single_sample_number())
    if (!DNABarcodeCompatibility:::sample_number_check(single_nb_sample)){
      output$single_sample_number_error_message <- renderText(error_message)
    }
    else{
      output$single_sample_number_error_message <- renderText("")
      updateSelectInput(
        session,
        "single_multiplex_level",
        choices = DNABarcodeCompatibility:::multiplexing_level_set(single_sample_number())
      )
    }
  })
  
  ### Handle when wrong input for distance parameter ###
  observe({
    distance <- as.numeric(single_distance())
    if (distance < 0 || is.na(distance)){
      output$single_distance_error_message <- renderText("Please enter a correct positive value")
    }
    else{
      output$single_distance_error_message <- renderText("")
    }
  })
  
  ### Disable distance numeric input when "no distance" is chosen from distance metric ###
  observeEvent(input$single_distance_metric, {
    if (is.null(single_metric())) {
      disable("single_distance")
      updateNumericInput(session, "single_distance", value = 0)
    }
    else{
      enable("single_distance")
      updateNumericInput(session, "single_distance", value = 3)
    }
  })
  
  ### Load input data when single file is uploaded ###
  observeEvent(input$single_file, {
    if (is.null(single_index_df())) {
      output$single_input_error_message <- renderText(paste("Error loading file : ", error_message))
      output$single_loaded_data <- renderDataTable( NULL )
    }
    else{
      output$single_input_error_message <- renderText("")
      output$single_loaded_data <-
        renderDataTable(
          datatable(single_index_df(), options = list(pageLength = 25)) %>% formatStyle(
            'valid',
            target = "row",
            backgroundColor = styleEqual(c(TRUE, FALSE), c('#DEFFD4', '#FFADAD'))
        )
      )
    }
  })
  
  ### When clicking on search button ###
  observeEvent(
    input$single_search, {
      
      #Reset outputs
      output$single_table_result <- renderDataTable({ NULL })
      hide("single_download_results")
      output$single_visual_result <- renderText( NULL )
      output$single_log <- renderText( NULL )
      hide("single_download_log")
      
      single_nb_sample <- as.numeric(single_sample_number())
      single_dist <- as.numeric(single_distance())
      if (is.null(input$single_file)){
        output$single_table_result_error_message <- renderText("Please upload a file first")
        output$single_visual_result_error_message <- renderText("Please upload a file first")
        output$single_log_error_message <- renderText("Please upload a file first")
      }
      else if (is.null(single_index_df())){
        output$single_table_result_error_message <- renderText("Please upload a valid file")
        output$single_visual_result_error_message <- renderText("Please upload a valid file")
        output$single_log_error_message <- renderText("Please upload a valid file")
      }
      else if (!DNABarcodeCompatibility:::sample_number_check(single_nb_sample)){
        output$single_table_result_error_message <- renderText("Please enter a valid sample number")
        output$single_visual_result_error_message <- renderText("Please enter a valid sample number")
        output$single_log_error_message <- renderText("Please enter a valid sample number")
      }
      else if (single_dist < 0 || is.na(single_dist)){
        output$single_table_result_error_message <- renderText("Please enter a valid distance")
        output$single_visual_result_error_message <- renderText("Please enter a valid distance")
        output$single_log_error_message <- renderText("Please enter a valid distance")
      }
      else{
        #Show running notification
        if (is.null(notif_running)){
          notif_running <<- showNotification(type = "message", "Process running... ")
        }
        
        run_time <<- format(Sys.time())
        output$single_table_result_error_message <- renderText("")
        output$single_visual_result_error_message <- renderText("")
        output$single_log_error_message <- renderText("")
        final_result <<- DNABarcodeCompatibility:::final_result(
          isolate(single_index_df()[which(single_index_df()$valid==TRUE),]),
          isolate(single_sample_number()),
          isolate(single_mplex_level()),
          isolate(single_platform()),
          isolate(single_metric()),
          isolate(single_distance())
        )
        
        if (!is.null(final_result)){
          output$single_table_result <- renderDataTable({
             final_result
          })
          show("single_download_results")
          
          updateTabsetPanel(session, "single_tabset", selected = "single_visual_result")
          output$single_visual_result <- renderText(build_table_style(final_result, isolate(single_platform())))
          log_text = ""
          log_text = paste(log_text, run_time, "\n", sep="")
          log_text = paste(log_text, "File: ", input$single_file$name, "\n", sep="")
          log_text = paste(log_text, "Platform: ", names(platformsVec)[platformsVec == input$single_platform], "\n", sep="")
          log_text = paste(log_text, "Sample number: ", input$single_sample_number, "\n", sep="")
          log_text = paste(log_text, "Multiplexing level: ", input$single_multiplex_level, "\n", sep="")
          log_text = paste(log_text, "GC content range (%): ", input$single_gc_content[1],"-", input$single_gc_content[2], "\n", sep="")
          log_text = paste(log_text, "Remove homopolymer: ", input$single_homopolymer, "\n", sep="")
          log_text = paste(log_text, "Distance metric: ", names(distancesVec)[distancesVec == input$single_distance_metric], "\n", sep="")
          log_text = paste(log_text, "Distance: ", input$single_distance, "\n", sep="")
          log_text = paste(log_text, "--------------- Index ---------------", "\n", sep="")
          log_text = paste(log_text, "Id\tSequence\tGC_content\tHomopolymer\tvalid", "\n", sep="")
          ind <- mutate(single_index_df(), out = paste(Id, sequence, GC_content, homopolymer, valid, sep = '\t'))
          log <<- paste(log_text, paste(ind$out, collapse = "\n"), "\n", sep="")
          output$single_log <- renderText(log)
          show("single_download_log")
        }
        else{
          output$single_table_result_error_message <- renderText(error_message)
          output$single_visual_result_error_message <- renderText(error_message)
          output$single_log_error_message <- renderText(error_message)
        }
        
        #Remove running notification
        if (!is.null(notif_running)){
          removeNotification(notif_running)
          notif_running <<- NULL
        }
      }
    })
    
    ### When clicking on download results button ###
    output$single_download_results <- downloadHandler(
      filename = function() {
        paste("DNABarcodeCompatibility_result_", run_time, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(final_result, file)
      }
    )
    
    ### When clicking on download log button ###
    output$single_download_log <- downloadHandler(
      filename = function() {
        paste("DNABarcodeCompatibility_log_", run_time, ".txt", sep = "")
      },
      content = function(file) {
        write(log, file)
      }
    )
  
  #######################
  #### DUAL INDEXING ####
  #######################
  
  dual_sample_number <- reactive(input$dual_sample_number)
  dual_mplex_level <- reactive(as.numeric(input$dual_multiplex_level))
  dual_platform <- reactive(input$dual_platform)
  dual_gc_content_min <- reactive(input$dual_gc_content[1])
  dual_gc_content_max <- reactive(input$dual_gc_content[2])
  dual_remove_homopolymer <- reactive(input$dual_homopolymer)
  dual_metric <- reactive(define_distance_metric(input$dual_distance_metric))
  dual_distance <- reactive(input$dual_distance)
  dual_index_df1 <- reactive(update_valid_data(DNABarcodeCompatibility:::file_loading_and_checking(input$dual_file1$datapath), dual_gc_content_min, dual_gc_content_max, dual_remove_homopolymer))
  dual_index_df2 <- reactive(update_valid_data(DNABarcodeCompatibility:::file_loading_and_checking(input$dual_file2$datapath), dual_gc_content_min, dual_gc_content_max, dual_remove_homopolymer))
  
  ### Update dual multiplexing level when sample number changes ###
  observe({
    dual_nb_sample <- as.numeric(dual_sample_number())
    if (!DNABarcodeCompatibility:::sample_number_check(dual_nb_sample)){
      output$dual_sample_number_error_message <- renderText(error_message)
    }
    else{
      output$dual_sample_number_error_message <- renderText("")
      updateSelectInput(
        session,
        "dual_multiplex_level",
        choices = DNABarcodeCompatibility:::multiplexing_level_set(dual_sample_number())
      )
    }
  })
  
  ### Handle when wrong input for distance parameter ###
  observe({
    distance <- as.numeric(dual_distance())
    if (distance < 0 || is.na(distance)){
      output$dual_distance_error_message <- renderText("Please enter a correct positive value")
    }
    else{
      output$dual_distance_error_message <- renderText("")
    }
  })
  
  ### Disable distance numeric input when "no distance" is chosen from distance metric ###
  observeEvent(input$dual_distance_metric, {
    if (is.null(dual_metric())) {
      disable("dual_distance")
      updateNumericInput(session, "dual_distance", value = 0)
    }
    else{
      enable("dual_distance")
      updateNumericInput(session, "dual_distance", value = 3)
    }
  })
  
  ### Load input data when dual file 1 is uploaded ###
  observeEvent(input$dual_file1, {
    if (is.null(dual_index_df1())) {
      output$dual_input_error_message1 <- renderText(paste("Error loading file : ", error_message))
      output$dual_loaded_data1 <- renderDataTable( NULL )
    }
    else{
      output$dual_input_error_message1 <- renderText("")
      output$dual_loaded_data1 <-
        renderDataTable(
          datatable(dual_index_df1(), options = list(pageLength = 25)) %>% formatStyle(
            'valid',
            target = "row",
            backgroundColor = styleEqual(c(TRUE, FALSE), c('#DEFFD4', '#FFADAD'))
        )
      )
    }
    updateTabsetPanel(session, "dual_input_tab", selected = "file1")
  })
  
  ### Load input data when dual file 2 is uploaded ###
  observeEvent(input$dual_file2, {
    if (is.null(dual_index_df2())) {
      output$dual_input_error_message2 <- renderText(paste("Error loading file : ", error_message))
      output$dual_loaded_data2 <- renderDataTable( NULL )
    }
    else{
      output$dual_input_error_message2 <- renderText("")
      output$dual_loaded_data2 <-
        renderDataTable(
          datatable(dual_index_df2(), options = list(pageLength = 25)) %>% formatStyle(
            'valid',
            target = "row",
            backgroundColor = styleEqual(c(TRUE, FALSE), c('#DEFFD4', '#FFADAD'))
          )
        )
    }
    updateTabsetPanel(session, "dual_input_tab", selected = "file2")
  })
  
  ### When clicking on search button ###
  observeEvent(
    input$dual_search, {
      
      #Reset outputs
      output$dual_table_result <- renderDataTable({ NULL })
      hide("dual_download_results")
      output$dual_visual_result <- renderText( NULL )
      output$dual_log <- renderText( NULL )
      hide("dual_download_log")
      
      dual_nb_sample <- as.numeric(dual_sample_number())
      dual_dist <- as.numeric(dual_distance())
      if (is.null(input$dual_file1) || is.null(input$dual_file2)){
        output$dual_table_result_error_message <- renderText("Please upload the files first")
        output$dual_visual_result_error_message <- renderText("Please upload the files first")
        output$dual_log_error_message <- renderText("Please upload the files first")
      }
      else if (is.null(dual_index_df1()) || is.null(dual_index_df2())){
        output$dual_table_result_error_message <- renderText("Please upload valid files")
        output$dual_visual_result_error_message <- renderText("Please upload valid files")
        output$dual_log_error_message <- renderText("Please upload valid files")
      }
      else if (!DNABarcodeCompatibility:::sample_number_check(dual_nb_sample)){
        output$dual_table_result_error_message <- renderText("Please enter a valid sample number")
        output$dual_visual_result_error_message <- renderText("Please enter a valid sample number")
        output$dual_log_error_message <- renderText("Please enter a valid sample number")
      }
      else if (dual_dist < 0 || is.na(dual_dist)){
        output$dual_table_result_error_message <- renderText("Please enter a valid distance")
        output$dual_visual_result_error_message <- renderText("Please enter a valid distance")
        output$dual_log_error_message <- renderText("Please enter a valid distance")
      }
      else{
        #Show running notification
        if (is.null(notif_running)){
          notif_running <<- showNotification(type = "message", "Process running... ")
        }
        run_time <<- format(Sys.time())
        output$dual_table_result_error_message <- renderText("")
        output$dual_visual_result_error_message <- renderText("")
        output$dual_log_error_message <- renderText("")
        final_result <<- DNABarcodeCompatibility:::final_result_dual(
          isolate(dual_index_df1()[which(dual_index_df1()$valid==TRUE),]),
          isolate(dual_index_df2()[which(dual_index_df2()$valid==TRUE),]),
          isolate(dual_sample_number()),
          isolate(dual_mplex_level()),
          isolate(dual_platform()),
          isolate(dual_metric()),
          isolate(dual_distance())
        )
        
        if (!is.null(final_result)){
          output$dual_table_result <- renderDataTable({
            final_result
          })
          show("dual_download_results")
          
          updateTabsetPanel(session, "dual_tabset", selected = "dual_visual_result")
          output$dual_visual_result <- renderText(build_table_style_dual(final_result, isolate(dual_platform())))
          log_text = ""
          log_text = paste(log_text, format(Sys.time()), "\n", sep="")
          log_text = paste(log_text, "File 1: ", input$dual_file1$name, "\n", sep="")
          log_text = paste(log_text, "File 2: ", input$dual_file2$name, "\n", sep="")
          log_text = paste(log_text, "Platform: ", names(platformsVec)[platformsVec == input$dual_platform], "\n", sep="")
          log_text = paste(log_text, "Sample number: ", input$dual_sample_number, "\n", sep="")
          log_text = paste(log_text, "Multiplexing level: ", input$dual_multiplex_level, "\n", sep="")
          log_text = paste(log_text, "GC content range (%): ", input$dual_gc_content[1],"-", input$dual_gc_content[2], "\n", sep="")
          log_text = paste(log_text, "Remove homopolymer: ", input$dual_homopolymer, "\n", sep="")
          log_text = paste(log_text, "Distance metric: ", names(distancesVec)[distancesVec == input$dual_distance_metric], "\n", sep="")
          log_text = paste(log_text, "Distance: ", input$dual_distance, "\n", sep="")
          log_text = paste(log_text, "--------------- Index 1 ---------------", "\n", sep="")
          log_text = paste(log_text, "Id\tSequence\tGC_content\tHomopolymer\tvalid", "\n", sep="")
          ind1 <- mutate(dual_index_df1(), out = paste(Id, sequence, GC_content, homopolymer, valid, sep = '\t'))
          log_text = paste(log_text, paste(ind1$out, collapse = "\n"), "\n", sep="")
          log_text = paste(log_text, "--------------- Index 2 ---------------", "\n", sep="")
          log_text = paste(log_text, "Id\tSequence\tGC_content\tHomopolymer\tvalid", "\n", sep="")
          ind2 <- mutate(dual_index_df2(), out = paste(Id, sequence, GC_content, homopolymer, valid, sep = '\t'))
          log <<- paste(log_text, paste(ind2$out, collapse = "\n"), "\n", sep="")
          output$dual_log <- renderText(log)
          show("dual_download_log")
        }
        else{
          output$dual_table_result_error_message <- renderText(error_message)
          output$dual_visual_result_error_message <- renderText(error_message)
          output$dual_log_error_message <- renderText(error_message)
        }
        
        #Remove running notification
        if (!is.null(notif_running)){
          removeNotification(notif_running)
          notif_running <<- NULL
        }
        
        ### When clicking on download results button ###
        output$dual_download_results <- downloadHandler(
          filename = function() {
            paste("DNABarcodeCompatibility_result_", run_time, ".csv", sep = "")
          },
          content = function(file) {
            write.csv(final_result, file)
          }
        )
        
        ### When clicking on download log button ###
        output$dual_download_log <- downloadHandler(
          filename = function() {
            paste("DNABarcodeCompatibility_log_", run_time, ".txt", sep = "")
          },
          content = function(file) {
            write(log, file)
          }
        )
      }
    }
  )

}