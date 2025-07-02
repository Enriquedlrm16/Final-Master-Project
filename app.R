library(shiny)
library(shinydashboard)
library(keras)
library(DT)  # For displaying a data table
library(magrittr) 
library(Matrix) 
library(shinyhelper) 
library(data.table)
library(tensorflow)
library(reticulate)
library(hdf5r) 
library(ggdendro) 
library(gridExtra) 
library(shinythemes)
library(ggplot2)
library(ggrepel)
library(bslib)
library(shinyjs)
library(rmarkdown)
library(shinyalert)
library(stringr)
library(isoband)
library(shinyBS)
library(caret)

reticulate::py_config()

# light <- bs_theme(bootswatch = "cerulean")
# dark <- bs_theme(bootswatch = "cyborg")

light <- bs_theme(bootswatch = "litera", base_font = font_google("Roboto"), 
                  bg = "#f7f9fc", fg = "#2e3b4e", primary = "#007bff")
dark <- bs_theme(bootswatch = "cyborg", base_font = font_google("Roboto"), 
                 bg = "#2e3b4e", fg = "#f7f9fc", primary = "#ff4081")
    
#####

# Load or define your neural network model here
model_NN <- keras::load_model_hdf5("neural_network_model_TFM_2.h5")

# Define the UI
ui <- navbarPage(theme = light, checkboxInput("dark_mode", "Dark mode"), collapsible = FALSE, title = "Cálculo de Riesgo Crediticio", position = "static-top",
                 tags$head(
                   tags$style(HTML("
      /* Estilos generales */
                                   body {
                                   font-family: 'Roboto', sans-serif;
                                   background-color: #f7f9fc;
                                   color: #2e3b4e;
                                   }
                                   
                                   /* Navbar */
                                   .navbar {
                                   background-color: #007bff !important;
                                   color: white !important;
                                   margin-bottom: 20px;
                                   }
                                   
                                   /* Panel principal */
                                   .main-panel {
                                   padding: 25px;
                                   background-color: white;
                                   box-shadow: 0px 3px 6px rgba(0,0,0,0.1);
                                   border-radius: 8px;
                                   margin-bottom: 30px;
                                   }
                                   
                                   /* Botones */
                                   .btn {
                                   background-color: #007bff;
                                   color: white;
                                   border: none;
                                   border-radius: 4px;
                                   padding: 10px 15px;
                                   font-size: 16px;
                                   transition: background-color 0.3s ease;
                                   }
                                   
                                   .btn:hover {
                                   background-color: #0056b3;
                                   }
                                   
                                   /* Tooltips personalizados */
                                   .tooltip-custom {
                                   position: relative;
                                   display: inline-block;
                                   cursor: pointer;
                                   padding: 5px;
                                   margin-top: 10px;
                                   }
                                   
                                   .tooltip-custom .tooltiptext {
                                   visibility: hidden;
                                   width: 250px;
                                   background-color: #333;
                                   color: #fff;
                                   text-align: center;
                                   border-radius: 6px;
                                   padding: 10px;
                                   position: absolute;
                                   z-index: 1;
                                   top: 120%;
                                   left: 50%;
                                   margin-left: -125px;
                                   opacity: 0;
                                   transition: opacity 0.3s ease;
                                   }
                                   
                                   .tooltip-custom:hover .tooltiptext {
                                   visibility: visible;
                                   opacity: 1;
                                   }
                                   
                                   /* Tablas */
                                   .dataTables_wrapper {
                                   margin-top: 20px;
                                   }
                                   
                                   /* Footer */
                                   .footer {
                                   background-color: #007bff;
                                   color: white;
                                   text-align: center;
                                   padding: 10px;
                                   position: fixed;
                                   width: 100%;
                                   bottom: 0;
                                   }
                                   /* Modo oscuro */
                                   body.dark-mode {
                                   background-color: #2e3b4e;
                                   color: #f7f9fc;
                                   }
                                   
                                   .dark-mode .navbar {
                                   background-color: #333;
                                   }
                                   
                                   .dark-mode .main-panel {
                                   background-color: #444;
                                   color: white;
                                   }
                                   
                                   .dark-mode .footer {
                                   background-color: #333;
                                   }
                                   
                                   .dark-mode .btn {
                                   background-color: #444;
                                   color: white;
                                   }
                                   /*MOD*/
                                   .container-fluid{width:auto !important; padding-right:0px !important;padding-left:0px !important;} /*Centrar cabecera*/
                                   #shiny-disconnected-overlay {display: none !important;  /* Ocultar el overlay gris */
                                   .main-panel {}
                                   
                                   ")),
                   tags$script(HTML("
                                    $(document).on('click', '.tooltip-custom', function() {
                                    $(this).toggleClass('active');
                                    });
                                    "))
                   ),
                 tabsetPanel(
                   tabPanel(HTML("Información del Modelo"),
                            mainPanel(uiOutput("pdfview"))
                   ), # end tabpanel 2
                   tabPanel(HTML("Predicción con Red Neuronal"),
                            style = "margin-bottom: 4.5rem; width: 100%;",
                            # Main panel for displaying outputs ----
                            sidebarLayout(
                              sidebarPanel(
                                useShinyjs(),
                                style = "width: 125%;",
                                tabsetPanel(
                                  tabPanel("Subir Datos para Predicción",
                                           tags$img(
                                             src = "RNA_seq_protocol.png",
                                             height = "auto",
                                             width = "100%",
                                             alt = "Algo fue mal",
                                             style = "margin-top: 20px; margin-bottom: 20px;"
                                           ),
                                           fileInput("credit_risk", label = "Subir Matriz de Datos Crudos (CSV)",
                                                     accept = c('text/csv', 'text/comma-separated-values', 'text/plain', '.csv')
                                           ),
                                           actionButton("showData_raw", "Mostrar Datos Procesados"),
                                           actionButton("removeRawTable", "Eliminar Datos"),
                                           downloadButton("downloadData", "Descargar Datos Procesados"),
                                           br(), br(), br()
                                  ),
                                  tabPanel("Subir Datos Procesados para Red Neuronal",
                                           fileInput("patient_data_expression", label = "Subir Datos para la predicción con Red Neuronal",
                                                     accept = c('text/csv', 'text/comma-separated-values', 'text/plain', '.csv')),
                                           
                                           # Custom tooltip with click functionality
                                           div(class = "tooltip-custom",
                                               actionButton("runNetwork", "Ejecutar Red Neuronal"),
                                               icon("info-circle"),  # Interrogation icon
                                               span(class = "tooltiptext", "Esta red neuronal predice el riesgo crediticio basado en diferentes datos del cliente.")
                                           ),
                                           
                                           actionButton("showData", "Mostrar Datos Subidos"),
                                           actionButton("removeTable", "Eliminar Tabla"),
                                           tags$img(
                                             src = "Screenshot_neural.png",
                                             height = "auto",
                                             width = "100%",
                                             alt = "Something went wrong",
                                             style = "margin-top: 20px;"
                                           )
                                  )
                                )
                              ),
                              mainPanel(
                                # Custom tooltip with click functionality
                                div(class = "tooltip-custom",
                                    verbatimTextOutput(outputId = "prediction"),
                                    icon("info-circle"),  # Ícono de interrogación
                                    span(class = "tooltiptext", HTML("La red neuronal clasifica el riesgo crediticio en cinco niveles:<br><br>
                                                                     Nivel 0: Pago completo – riesgo bajo.<br>
                                                                     Nivel 1: En período de gracia – riesgo bajo-moderado.<br>
                                                                     Nivel 2: Retraso leve (16-30 días) – riesgo moderado.<br>
                                                                     Nivel 3: Retraso grave (31-120 días) – riesgo alto.<br>
                                                                     Nivel 4: Incobrable o en default – riesgo muy alto.<br><br>
                                                                     Cualquier otro valor indica un estado de préstamo no clasificado (% de confianza inferior a 70)."))
                                    ),
                                div(
                                  id = "rawTableContainer",
                                  DTOutput('table_raw', width = "100%"),
                                  style = "margin-top: 40px;"
                                ),
                                div(
                                  id = "tableContainer",
                                  DTOutput('table', width = "100%"),
                                  style = "margin-top: 40px;"
                                ),
                                style = "margin-top: 20px; margin-left: 160px; max-width: 50%;"
                              )
                            )
                   )
                 ),
                 tags$div(
                   style = "background-color: #f5f5f5; padding: 10px; text-align: center; position: fixed; bottom: 0; left: 0; right: 0; min-height: 2.5rem; width: 100%;",
                   HTML(paste("<strong>Enrique de la Rosa</strong>"))
                   )
                 )

#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################

# Define server  ----
#####
server <- function(input, output, session) {
#####    
    shinyjs::useShinyjs()
    
    options(shiny.maxRequestSize = 3000 * 1024^2)
    
    observe(session$setCurrentTheme(
        if (isTRUE(input$dark_mode)) dark else light
    ))
    
    output$pdfview <- renderUI({
        tags$iframe(style="height:1200px; width:150%; border:none; margin-bottom: 60px;", src="markdown_credit_risk.html")
    })
    
#####
    ######
    # Function to reset the file input buttons
    resetFileInputs <- function() {
        shinyjs::reset("credit_risk")
        shinyjs::reset("patient_data_expression")
    }
    
    # Initial visibility of tables
    showRawTable <- FALSE
    showRawTable_sc <- FALSE
    showTable <- FALSE
    
    # Logic to control datatable visibility
    observeEvent(input$removeRawTable, {
        showRawTable <<- FALSE
        shinyjs::hide("rawTableContainer")
        resetFileInputs()
      #  session$reload()  # Reload the session
    })
    
    observeEvent(input$removeTable, {
        showTable <<- FALSE
        shinyjs::hide("tableContainer")
        resetFileInputs()
        #session$reload()  # Reload the session
    })
    
    observeEvent(input$credit_risk, {
        showRawTable <<- TRUE
        shinyjs::show("rawTableContainer")
    })
    
    observeEvent(input$patient_data_expression, {
        showTable <<- TRUE
        shinyjs::show("tableContainer")
    })
    
    observeEvent(input$showData_raw, {
        # Show a modal when the button is pressed
        shinyalert("Espera, por favor!", "Procesamiento en progreso...")
    })
    
    UploadandprocessData <- function(inputfile, model_NN) {
      # Step 1: Load the uploaded CSV
      data_raw <- read.csv(inputfile$datapath)
      data_raw <- data_raw[,-1]  # Remove the first column (assumes it contains IDs or unnecessary info)
      
      # Step 2: Select columns for normalization
      selected_vars <- colnames(data_raw)
      
      # Step 3: Normalize the selected numeric variables
      preprocess_params <- preProcess(data_raw[, selected_vars], method = c("center", "scale"))
      data_final <- predict(preprocess_params, data_raw[, selected_vars])
      
      # Step 4: Convert to numeric matrix
      data_final <- as.matrix(as.data.frame(lapply(data_final, as.numeric)))
      
      # Step 5: Handle NA values
      nan_columns <- which(apply(data_final, 2, function(col) any(is.na(col))))
      
      if (!is.null(nan_columns) && length(nan_columns) > 0) {
        # Replace NAs with column means
        for (col in nan_columns) {
          col_mean <- mean(data_final[, col], na.rm = TRUE)  # Compute the mean for the column
          data_final[is.na(data_final[, col]), col] <- col_mean  # Replace NAs with the mean
        }
      }
      
      # Return processed data and predictions
      return(data_final = data_final)
    }
    
    data_matrix_raw <- reactive({
        req(input$credit_risk)
        data_raw <- UploadandprocessData(input$credit_risk, model_NN)
    })
    
    output$table_raw <- renderDT({
      req(input$credit_risk, input$showData_raw > 0)
      
      # Assume `data_matrix_raw` returns a matrix
      data_raw <- data_matrix_raw()
      
      # Check the number of columns and select appropriately
      if (nrow(data_raw[, 1:nrow(data_raw)]) < 4) {
        head(as.matrix(data_raw[, 1:nrow(data_raw)]))  # Fewer than 4 columns
      } else {
        head(as.matrix(data_raw[, 1:4]))  # At least 3 columns
      }
    })

    data_matrix <- reactive({
        req(input$patient_data_expression)
        data <- read.csv(input$patient_data_expression$datapath)
        rownames(data) <- data[,1]
        data <- data[,-1]
    })

    output$table <- renderDT({
        req(input$patient_data_expression)
        data <- read.csv(input$patient_data_expression$datapath)
        rownames(data) <- data[,1]
        data <- data[,-1]
        data <- as.matrix(data)

        if (req(input$showData > 0)) {
            if (nrow(data) < 4) {
                data[nrow(data),1:4]
            }
            else{
                data[1:3,1:4]
            }
        } else {
            NULL
        }
    })
    #####

    #####
    output$prediction <- renderText({
      # Step 1: Validate input
      if (is.null(data_matrix())) {
        return("Por favor, sube una matriz válida.")
      }
      
      mtx <- as.matrix(data_matrix())
      # Check if the "Run Neural Network" button is clicked
      run_clicked <- input$runNetwork
      
      # Step 2: Check if "Run Neural Network" button is clicked
      if (run_clicked == 0) {
        return("Click 'Ejecutar Red Neuronal' para hacer predicciones.")
      } else {
        # Run predictions with the model
        predictions <- model_NN$predict(mtx)
        
        # Step 4: Map loan status and interpret results
        loan_status_map <- c(
          "Fully Paid" = 0,
          "In Grace Period" = 1,
          "Late (16-30 days)" = 2,
          "Late (31-120 days)" = 3,
          "Charged Off/Default" = 4
        )
        
        prediction_result <- vector("character", nrow(predictions))
        
        for (i in seq_len(nrow(predictions))) {
          max_prob <- max(predictions[i,])
          max_index <- which.max(predictions[i,])
          
          # Map prediction class to loan status
          loan_status <- names(loan_status_map)[which(loan_status_map == (max_index - 1))]
          
          # Determine confidence level and interpret result
          confidence <- round(max_prob * 100, 2)
          if (max_prob < 0.7) {
            prediction_text <- paste0("undetermined (", confidence, "% confidence)")
          } else {
            prediction_text <- paste0(loan_status, " (", confidence, "% confidence)")
          }
          
          prediction_result[i] <- prediction_text
        }
        
        # Step 5: Return prediction results as a concatenated string
        paste(prediction_result, collapse = "\n")
            }
      })

    # Downloadable csv of selected dataset ----
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("preprocessed_dataset_for_neural_network.csv", sep = "")
      },
      content = function(file) {
        # Assume `data_matrix_raw()` returns a normal matrix
        data_raw <- data_matrix_raw()
        
        # Write the entire matrix to a CSV file
        write.csv(data_raw, file, row.names = TRUE)
      }
    )
    
}
#####

#####

shinyApp(ui, server)


