library(tidyverse)



design_matrix <- function(data) {
  "
  data (dataframe): Input data
  "
  
  # Get the unique IDs
  unique_ids <- unique(data$ID)
  num_ids <- length(unique_ids)
  
  # Initialize the design matrix
  X <- matrix(0, nrow = nrow(data), ncol = num_ids)
  
  # Populate design matrix with one-hot encoding
  for (i in 1:num_ids) {
    # Find the indices where ID matches unique ID
    indices <- which(data$ID == unique_ids[i])
    # Set corresponding elements to 1
    X[indices, i] <- 1
  }
  
  return(X)
}

dataIn <- function(path_to_data,index){
  
  "
  path_to_data (str): path to the directory where the input data is located
  index (str): either of either THI or AUC, specifying the environmental covariate to be included in the model
  "
  
  data <- read_csv(path_to_data) %>% 
    # Replace lab ID by an ID starting from zero
    group_by(Lab_ID) %>% 
    nest() %>% 
    rowid_to_column("ID") %>% 
    unnest(cols = data) %>% 
    filter(Group %in% c(1)) %>% 
    ungroup() 
  
  # For fitting the growth model
  df1 <- data %>% 
    select(ID, Window,Day ,Weight , BW0) %>% 
    group_by(Window) %>% 
    transmute(.,
              ID = ID, 
              time = Day,
              BWt = Weight - BW0, 
              BWto = BW0) %>% 
    drop_na(BWt) %>% 
    ungroup() %>% 
    dplyr::select(-Window)
  
  ## For fitting FI data
  df2 <- 
    data %>% 
    transmute(.,
              ID = ID, 
              ptime = Day, 
              fi = Total_Daily_DM_Intake, 
              THI = ifelse(THI>70,THI-70,0),
              AUC = AUC,
              BWto = BW0
    ) %>% 
    drop_na(fi, THI)
  
  # Define matrices
  X <- design_matrix(df1)
  Xs <- design_matrix(df2)
  
  dataModel <- list(
    # Sample size
    N = nrow(df1),
    N2 = nrow(df2), 
    # Matrices
    X = X,
    Xs = Xs, 
    # Population level effects
    K = length(unique(df1$ID)),
    fi = df2$fi,
    BWto = df2$BWto, 
    BW = df1$BWt, 
    time = df1$time,
    ptime = df2$ptime,
    # Here pass in the environmental covariate
    THIt = df2[[index]]
    
    
  )
  
}


## Derived quantities

summarise_posterior <- function(modelIn){
  
  "
  modelIn (stanfit object): Model fitted.
  "
  
  q500 <- rstan::extract(readRDS(modelPath), pars = "mu") %>% 
    as.data.frame() %>% 
    summarise_all(~mean(.)) %>% 
    mutate(q = "q500") %>% 
    pivot_longer(cols = contains("mu."))
  
  q975 <- rstan::extract(readRDS(modelPath), pars = "mu") %>% 
    as.data.frame() %>% 
    summarise_all(~quantile(., probs = 0.975)) %>% 
    mutate(q = "q975") %>% 
    pivot_longer(cols = contains("mu."))
  
  q025 <- rstan::extract(readRDS(modelPath), pars = "mu") %>% 
    as.data.frame() %>% 
    summarise_all(~quantile(., probs = 0.025)) %>% 
    mutate(q = "q025") %>% 
    pivot_longer(cols = contains("mu."))
  
  out <- rbind(q500, q975, q025)
}
