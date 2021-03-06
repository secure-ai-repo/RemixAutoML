#' AutoH2oDRFMultiClass is an automated H2O modeling framework with grid-tuning and model evaluation
#'
#' AutoH2oDRFMultiClass is an automated H2O modeling framework with grid-tuning and model evaluation that runs a variety of steps. First, a stratified sampling (by the target variable) is done to create train and validation sets. Then, the function will run a random grid tune over N number of models and find which model is the best (a default model is always included in that set). Once the model is identified and built, several other outputs are generated: validation data with predictions, evaluation metrics, confusion matrix, and variable importance.
#' @author Adrian Antico
#' @family Automated MultiClass Classification
#' @param data This is your data set for training and testing your model
#' @param TrainOnFull Set to TRUE to train on full data
#' @param ValidationData This is your holdout data set used in modeling either refine your hyperparameters.
#' @param TestData This is your holdout data set. Catboost using both training and validation data in the training process so you should evaluate out of sample performance with this data set.
#' @param TargetColumnName Either supply the target column name OR the column number where the target is located (but not mixed types).
#' @param FeatureColNames Either supply the feature column names OR the column number where the target is located (but not mixed types)
#' @param eval_metric This is the metric used to identify best grid tuned model. Choose from "logloss", "r2", "RMSE", "MSE"
#' @param Trees The maximum number of trees you want in your models
#' @param GridTune Set to TRUE to run a grid tuning procedure. Set a number in MaxModelsInGrid to tell the procedure how many models you want to test.
#' @param MaxMem Set the maximum amount of memory you'd like to dedicate to the model run. E.g. "32G"
#' @param NThreads Set the number of threads you want to dedicate to the model building
#' @param MaxModelsInGrid Number of models to test from grid options (1080 total possible options)
#' @param model_path A character string of your path file to where you want your output saved
#' @param metadata_path A character string of your path file to where you want your model evaluation output saved. If left NULL, all output will be saved to model_path.
#' @param ModelID A character string to name your model and output
#' @param ReturnModelObjects Set to TRUE to output all modeling objects (E.g. plots and evaluation metrics)
#' @param SaveModelObjects Set to TRUE to return all modeling objects to your environment
#' @param IfSaveModel Set to "mojo" to save a mojo file, otherwise "standard" to save a regular H2O model object
#' @param H2OShutdown Set to TRUE to have H2O shutdown after running this function
#' @examples
#' \donttest{
#' Correl <- 0.85
#' N <- 1000
#' data <- data.table::data.table(Target = runif(N))
#' data[, x1 := qnorm(Target)]
#' data[, x2 := runif(N)]
#' data[, Independent_Variable1 := log(pnorm(Correl * x1 +
#'                                             sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable2 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable3 := exp(pnorm(Correl * x1 +
#'                                             sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable4 := exp(exp(pnorm(Correl * x1 +
#'                                                 sqrt(1-Correl^2) * qnorm(x2))))]
#' data[, Independent_Variable5 := sqrt(pnorm(Correl * x1 +
#'                                              sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable6 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.10]
#' data[, Independent_Variable7 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.25]
#' data[, Independent_Variable8 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.75]
#' data[, Independent_Variable9 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^2]
#' data[, Independent_Variable10 := (pnorm(Correl * x1 +
#'                                           sqrt(1-Correl^2) * qnorm(x2)))^4]
#' data[, Independent_Variable11 := as.factor(
#'   ifelse(Independent_Variable2 < 0.20, "A",
#'          ifelse(Independent_Variable2 < 0.40, "B",
#'                 ifelse(Independent_Variable2 < 0.6,  "C",
#'                        ifelse(Independent_Variable2 < 0.8,  "D", "E")))))]
#' data[, Target :=
#' ifelse(Independent_Variable2 < 0.25, "A",
#'        ifelse(Independent_Variable2 < 0.45, "B",
#'               ifelse(Independent_Variable2 < 0.65, "C",
#'                      ifelse(Independent_Variable2 < 0.85,  "D", "E"))))]
#' data[, ':=' (x1 = NULL, x2 = NULL)]
#' TestModel <- AutoH2oDRFMultiClass(data,
#'                                   TrainOnFull = FALSE,
#'                                   ValidationData = NULL,
#'                                   TestData = NULL,
#'                                   TargetColumnName = "Target",
#'                                   FeatureColNames = 2:ncol(data),
#'                                   eval_metric = "logloss",
#'                                   Trees = 50,
#'                                   GridTune = FALSE,
#'                                   MaxMem = "32G",
#'                                   NThreads = max(1, parallel::detectCores()-2),
#'                                   MaxModelsInGrid = 10,
#'                                   model_path = NULL,
#'                                   metadata_path = NULL,
#'                                   ModelID = "FirstModel",
#'                                   ReturnModelObjects = TRUE,
#'                                   SaveModelObjects = FALSE,
#'                                   IfSaveModel = "mojo",
#'                                   H2OShutdown = FALSE)
#' }
#' @return Saves to file and returned in list: VariableImportance.csv, Model, ValidationData.csv, EvaluationMetrics.csv, GridCollect, and GridList
#' @export
AutoH2oDRFMultiClass <- function(data,
                                 TrainOnFull = FALSE,
                                 ValidationData = NULL,
                                 TestData = NULL,
                                 TargetColumnName = NULL,
                                 FeatureColNames = NULL,
                                 eval_metric = "logloss",
                                 Trees = 50,
                                 GridTune = FALSE,
                                 MaxMem = "32G",
                                 NThreads = max(1, parallel::detectCores()-2),
                                 MaxModelsInGrid = 2,
                                 model_path = NULL,
                                 metadata_path = NULL,
                                 ModelID = "FirstModel",
                                 ReturnModelObjects = TRUE,
                                 SaveModelObjects = FALSE,
                                 IfSaveModel = "mojo",
                                 H2OShutdown = FALSE) {
  # MultiClass Check Arguments----
  if (!(tolower(eval_metric) %chin% c("auc", "logloss"))) {
    stop("eval_metric not in AUC, logloss")
  }
  if (Trees < 1) stop("Trees must be greater than 1")
  if (!GridTune %in% c(TRUE, FALSE)) stop("GridTune needs to be TRUE or FALSE")
  if (MaxModelsInGrid < 1 & GridTune == TRUE) {
    warning("MaxModelsInGrid needs to be at least 1")
  }
  if (!is.null(model_path)) {
    if (!is.character(model_path)) stop("model_path needs to be a character type")
  }
  if (!is.null(metadata_path)) {
    if (!is.character(metadata_path)) stop("metadata_path needs to be a character type")
  }
  if (!is.character(ModelID) & !is.null(ModelID)) stop("ModelID needs to be a character type")
  if (!(ReturnModelObjects %in% c(TRUE, FALSE))) stop("ReturnModelObjects needs to be TRUE or FALSE")
  if (!(SaveModelObjects %in% c(TRUE, FALSE))) stop("SaveModelObjects needs to be TRUE or FALSE")
  if (!(tolower(eval_metric) == "auc")) {
    eval_metric <- tolower(eval_metric)
  } else {
    eval_metric <- toupper(eval_metric)
  }
  if (tolower(eval_metric) %chin% c("auc")) {
    Decreasing <- TRUE
  } else {
    Decreasing <- FALSE
  }
  
  # MultiClass Target Name Storage----
  if (is.character(TargetColumnName)) {
    Target <- TargetColumnName
  } else {
    Target <- names(data)[TargetColumnName]
  }
  
  # MultiClass Ensure data is a data.table----
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }
  
  # MultiClass Ensure data is a data.table----
  if (!is.null(ValidationData)) {
    if (!data.table::is.data.table(ValidationData)) {
      ValidationData <- data.table::as.data.table(ValidationData)
    }
  }
  
  # MultiClass Ensure data is a data.table----
  if (!is.null(TestData)) {
    if (!data.table::is.data.table(TestData)) {
      TestData <- data.table::as.data.table(TestData)
    }
  }
  
  # MultiClass Data Partition----
  if (is.null(ValidationData) & is.null(TestData) & TrainOnFull == FALSE) {
    dataSets <- AutoDataPartition(
      data,
      NumDataSets = 3,
      Ratios = c(0.70, 0.20, 0.10),
      PartitionType = "random",
      StratifyColumnNames = Target,
      TimeColumnName = NULL
    )
    data <- dataSets$TrainData
    ValidationData <- dataSets$ValidationData
    TestData <- dataSets$TestData
  }
  
  # MultiClass ModelDataPrep----
  dataTrain <- ModelDataPrep(data = data, Impute = FALSE, CharToFactor = TRUE)
  
  # MultiClass ModelDataPrep----
  if(!TrainOnFull) {
    dataTest <- ModelDataPrep(data = ValidationData, Impute = FALSE, CharToFactor = TRUE)  
  }
  
  # MultiClass ModelDataPrep----
  if (!is.null(TestData)) {
    TestData <- ModelDataPrep(data = TestData, Impute = FALSE, CharToFactor = TRUE)
  }
  
  # MultiClass Ensure Target Is a Factor Type----
  if (!is.factor(dataTrain[[eval(Target)]])) {
    dataTrain[, eval(Target) := as.factor(get(Target))]
  }
  
  # MultiClass Ensure Target Is a Factor Type----
  if(!TrainOnFull) {
    if (!is.factor(dataTest[[eval(Target)]])) {
      dataTest[, eval(Target) := as.factor(get(Target))]
    }  
  }
  
  # MultiClass Ensure Target Is a Factor Type----
  if (!is.null(TestData)) {
    if (!is.factor(TestData[[eval(Target)]])) {
      TestData[, eval(Target) := as.factor(get(Target))]
    }
  }
  
  # MultiClass Save Names of data----
  if(is.numeric(FeatureColNames)) {
    Names <- data.table::as.data.table(names(data)[FeatureColNames])
    data.table::setnames(Names, "V1", "ColNames")
  } else {
    Names <- data.table::as.data.table(FeatureColNames)
    if(!"V1" %chin% names(Names)) {
      data.table::setnames(Names, "FeatureColNames", "ColNames")
    } else {
      data.table::setnames(Names, "V1", "ColNames")
    }
  }
  if (SaveModelObjects) {
    data.table::fwrite(Names, paste0(model_path, "/", ModelID, "_ColNames.csv"))
  }
  
  # MultiClass Grid Tune Check----
  if(GridTune == TRUE & TrainOnFull == FALSE) {
    
    # MultiClass Start Up H2O----
    h2o::h2o.init(max_mem_size = MaxMem,
                  nthreads = NThreads, 
                  enable_assertions = FALSE)
    
    # MultiClass Define data sets----
    datatrain    <- h2o::as.h2o(dataTrain)
    datavalidate <- h2o::as.h2o(dataTest)
    
    # MultiClass Grid Tune Search Criteria----
    search_criteria  <- list(
      strategy             = "RandomDiscrete",
      max_runtime_secs     = 3600 * 24 * 7,
      max_models           = MaxModelsInGrid,
      seed                 = 1234,
      stopping_rounds      = 10,
      stopping_metric      = eval_metric,
      stopping_tolerance   = 1e-3
    )
    
    # MultiClass Grid Parameters----
    hyper_params <- list(
      max_depth                        = c(6, 9, 12),
      balance_classes                  = c(TRUE, FALSE),
      sample_rate                      = c(0.5, 0.75, 1.0),
      col_sample_rate_per_tree         = c(0.5, 0.75, 1.0),
      col_sample_rate_change_per_level = c(0.9, 1.0, 1.1),
      min_rows                         = c(1, 5),
      nbins                            = c(10, 20, 30),
      nbins_cats                       = c(64, 256, 512),
      histogram_type                   = c("UniformAdaptive",
                                           "QuantilesGlobal",
                                           "RoundRobin")
    )
    
    # MultiClass Grid Train Model----
    grid <- h2o::h2o.grid(
      hyper_params         = hyper_params,
      search_criteria      = search_criteria,
      is_supervised        = TRUE,
      algorithm            = "randomForest",
      grid_id              = paste0(ModelID, "_Grid"),
      x                    = FeatureColNames,
      y                    = TargetColumnName,
      ntrees               = Trees,
      training_frame       = datatrain,
      validation_frame     = datavalidate,
      max_runtime_secs     = 3600 * 24 * 7,
      stopping_rounds      = 10,
      stopping_tolerance   = 1e-3,
      stopping_metric      = eval_metric,
      score_tree_interval  = 10,
      seed                 = 1234
    )
    
    # MultiClass Get Best Model----
    Grid_Out   <- h2o::h2o.getGrid(
      grid_id = paste0(ModelID, "_Grid"),
      sort_by = eval_metric,
      decreasing = Decreasing
    )
    
    # MultiClass Collect Best Grid Model----
    grid_model <- h2o::h2o.getModel(Grid_Out@model_ids[[1]])
  }
  
  # MultiClass Start Up H2O----
  if (!GridTune) {
    h2o::h2o.init(max_mem_size = MaxMem,
                  enable_assertions = FALSE)
    
    # MultiClass Define data sets----
    datatrain    <- h2o::as.h2o(dataTrain)
    if(!TrainOnFull) datavalidate <- h2o::as.h2o(dataTest)
  }
  
  # MultiClass Build Baseline Model----
  if(!TrainOnFull) {
    base_model <- h2o::h2o.randomForest(
      x                = FeatureColNames,
      y                = TargetColumnName,
      training_frame   = datatrain,
      validation_frame = datavalidate,
      model_id         = ModelID,
      ntrees           = Trees)  
  } else {
    base_model <- h2o::h2o.randomForest(
      x                = FeatureColNames,
      y                = TargetColumnName,
      training_frame   = datatrain,
      model_id         = ModelID,
      ntrees           = Trees)
  }
  
  # MultiClass Get Metrics----
  if (GridTune) {
    if (!is.null(TestData)) {
      datatest        <-  h2o::as.h2o(TestData)
      GridMetrics <- h2o::h2o.performance(model = base_model, newdata = datatest)
      BaseMetrics <- h2o::h2o.performance(model = base_model, newdata = datatest)
    } else {
      GridMetrics <- h2o::h2o.performance(model = base_model, newdata = datavalidate)
      BaseMetrics <- h2o::h2o.performance(model = base_model, newdata = datavalidate)
    }
  } else if(!TrainOnFull) {
    if (!is.null(TestData)) {
      datatest    <- h2o::as.h2o(TestData)
      BaseMetrics <- h2o::h2o.performance(model = base_model, newdata = datatest)
    } else {
      BaseMetrics <- h2o::h2o.performance(model = base_model, newdata = datavalidate)
    }
  } else {
    BaseMetrics <- h2o::h2o.performance(model = base_model, newdata = datatrain)
  }
  
  # MultiClass Evaluate Metrics----
  if (GridTune == TRUE & TrainOnFull == FALSE) {
    if (tolower(eval_metric) == "logloss") {
      BaseMetric <- BaseMetrics@metrics$logloss
      GridMetric <- GridMetrics@metrics$logloss
      if (GridMetric < BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        ConfusionMatrix <-
          data.table::as.data.table(GridMetrics@metrics$cm$table)
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetrics@metrics$logloss
        ConfusionMatrix <-
          data.table::as.data.table(BaseMetrics@metrics$cm$table)
      }
    } else if (tolower(eval_metric) == "r2") {
      BaseMetric <- BaseMetrics@metrics$r2
      GridMetric <- GridMetrics@metrics$r2
      if (GridMetric > BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        ConfusionMatrix <-
          data.table::as.data.table(GridMetrics@metrics$cm$table)
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetric
        ConfusionMatrix <-
          data.table::as.data.table(BaseMetrics@metrics$cm)
      }
    } else if (tolower(eval_metric) == "rmse") {
      BaseMetric <- BaseMetrics@metrics$logloss
      GridMetric <- GridMetrics@metrics$logloss
      if (GridMetric < BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        ConfusionMatrix <-
          data.table::as.data.table(GridMetrics@metrics$cm$table)
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetric
        ConfusionMatrix <-
          data.table::as.data.table(BaseMetrics@metrics$cm)
      }
    } else if (tolower(eval_metric) == "mse") {
      BaseMetric <- BaseMetrics@metrics$logloss
      GridMetric <- GridMetrics@metrics$logloss
      if (GridMetric < BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        ConfusionMatrix <-
          data.table::as.data.table(GridMetrics@metrics$cm$table)
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetric
        ConfusionMatrix <-
          data.table::as.data.table(BaseMetrics@metrics$cm$table)
      }
    }
  } else {
    if (tolower(eval_metric) == "logloss") {
      FinalModel <- base_model
      EvalMetric <- BaseMetrics@metrics$logloss
      ConfusionMatrix <- data.table::as.data.table(BaseMetrics@metrics$cm$table)
    } else if (tolower(eval_metric) == "r2") {
      FinalModel <- base_model
      EvalMetric <- BaseMetrics@metrics$r2
      ConfusionMatrix <- data.table::as.data.table(BaseMetrics@metrics$cm$table)
    } else if (tolower(eval_metric) == "rmse") {
      FinalModel <- base_model
      EvalMetric <- BaseMetrics@metrics$RMSE
      ConfusionMatrix <- data.table::as.data.table(BaseMetrics@metrics$cm$table)
    } else if (tolower(eval_metric) == "mse") {
      FinalModel <- base_model
      EvalMetric <- BaseMetrics@metrics$MSE
      ConfusionMatrix <- data.table::as.data.table(BaseMetrics@metrics$cm$table)
    }
  }
  
  # MultiClass Save Final Model----
  if (SaveModelObjects) {
    if (tolower(IfSaveModel) == "mojo") {
      SaveModel <- h2o::h2o.saveMojo(object = FinalModel, path = model_path, force = TRUE)
      h2o::h2o.download_mojo(
        model = FinalModel,
        path = model_path,
        get_genmodel_jar = TRUE,
        genmodel_path = model_path,
        genmodel_name = ModelID)
    } else {
      SaveModel <- h2o::h2o.saveModel(object = FinalModel, path = model_path, force = TRUE)
    }
  }
  
  # MultiClass Score Final Test Data----
  if (!is.null(TestData)) {
    Predict <- data.table::as.data.table(h2o::h2o.predict(object = FinalModel, newdata = datatest))
  } else if(!TrainOnFull) {
    Predict <- data.table::as.data.table(h2o::h2o.predict(object = FinalModel, newdata = datavalidate))
  } else {
    Predict <- data.table::as.data.table(h2o::h2o.predict(object = FinalModel, newdata = datatrain))
  }
  
  # MultiClass Variable Importance----
  VariableImportance <- data.table::as.data.table(h2o::h2o.varimp(object = FinalModel))
  
  # MultiClass Format Variable Importance Table----
  data.table::setnames(VariableImportance,
                       c("variable","relative_importance","scaled_importance","percentage"),
                       c("Variable","RelativeImportance","ScaledImportance","Percentage"))
  VariableImportance[, ':=' (
    RelativeImportance = round(RelativeImportance, 4),
    ScaledImportance = round(ScaledImportance, 4),
    Percentage = round(Percentage, 4))]
  
  # MultiClass Save Variable Importance----
  if (SaveModelObjects) {
    if(!is.null(metadata_path)) {
      data.table::fwrite(VariableImportance, file = paste0(metadata_path,"/",ModelID, "_VariableImportance.csv"))
    } else {
      data.table::fwrite(VariableImportance,file = paste0(model_path,"/",ModelID, "_VariableImportance.csv"))
    }
  }
  
  # MultiClass H2O Shutdown----
  if(H2OShutdown) {
    h2o::h2o.shutdown(prompt = FALSE)    
  }

  # MultiClass Create Validation Data----
  if (!is.null(TestData)) {
    ValidationData <- data.table::as.data.table(cbind(TestData, Predict))
    data.table::setnames(ValidationData, "predict", "Predict", skip_absent = TRUE)
  } else if(!TrainOnFull) {
    ValidationData <- data.table::as.data.table(cbind(dataTest, Predict))
    data.table::setnames(ValidationData, "predict", "Predict", skip_absent = TRUE)
  } else {
    ValidationData <- data.table::as.data.table(cbind(dataTrain, Predict))
    data.table::setnames(ValidationData, "predict", "Predict", skip_absent = TRUE)
  }
  
  # MultiClass Metrics Accuracy----
  if(TargetColumnName == "Target") {
    ValidationData[, eval(TargetColumnName) := as.character(get(TargetColumnName))]
    ValidationData[, Predict := as.character(Predict)]
    MetricAcc <- ValidationData[, mean(data.table::fifelse(get(TargetColumnName) == Predict, 1.0, 0.0), na.rm = TRUE)]
  } else {
    ValidationData[, eval(Target) := as.character(get(Target))]
    ValidationData[, Predict := as.character(Predict)]
    MetricAcc <- ValidationData[, mean(data.table::fifelse(get(Target) == Predict, 1.0, 0.0), na.rm = TRUE)]
  }
  
  # MultiClass Evaluation Metrics Table----
  EvaluationMetrics <- data.table::data.table(
    Metric = c("Accuracy", "MicroAUC", "temp"),
    Value = c(round(MetricAcc, 4),NA,round(EvalMetric, 4)))
  data.table::set(EvaluationMetrics, i = 3L, j = 1L, value = paste0(eval_metric))
  
  # MultiClass Save Validation Data to File----
  if (SaveModelObjects) {
    if(!is.null(metadata_path)) {
      data.table::fwrite(ValidationData, file = paste0(metadata_path, "/", ModelID, "_ValidationData.csv"))
    } else {
      data.table::fwrite(ValidationData, file = paste0(model_path, "/", ModelID, "_ValidationData.csv"))      
    }
  }
  
  # MultiClass Save ConfusionMatrix to File----
  if (SaveModelObjects) {
    if(!is.null(metadata_path)) {
      data.table::fwrite(ConfusionMatrix, file = paste0(metadata_path, "/", ModelID, "_EvaluationMetrics.csv"))
    } else {
      data.table::fwrite(ConfusionMatrix, file = paste0(model_path, "/", ModelID, "_EvaluationMetrics.csv"))
    }
  }
  
  # VI_Plot_Function
  VI_Plot <- function(VI_Data, ColorHigh = "darkblue", ColorLow = "white") {
    ggplot2::ggplot(VI_Data, ggplot2::aes(x = reorder(Variable, ScaledImportance), y = ScaledImportance, fill = ScaledImportance)) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::scale_fill_gradient2(
        mid = ColorLow,
        high = ColorHigh) +
      ChartTheme(
        Size = 12,
        AngleX = 0,
        LegendPosition = "right") +
      ggplot2::coord_flip() +
      ggplot2::labs(
        title = "Global Variable Importance") +
      ggplot2::xlab("Top Model Features") +
      ggplot2::ylab("Value")
  }
  
  # MultiClass Return Objects----
  if (ReturnModelObjects) {
    return(
      list(
        Model = FinalModel,
        ValidationData = ValidationData,
        ConfusionMatrix = ConfusionMatrix,
        EvaluationMetrics = EvaluationMetrics,
        VariableImportance = VariableImportance,
        VI_Plot = VI_Plot(VI_Data = VariableImportance),
        ColNames = Names
      )
    )
  }
}
