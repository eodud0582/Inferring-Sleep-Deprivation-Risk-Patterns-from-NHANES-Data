
library(tidyverse)
library(scales)

select <- dplyr::select

library(haven)
setwd("/Users/jihoonchoi/Dropbox/PhD/R_personal")

# Define file names
file_names <- c("Demographic.xpt", "Diet.xpt", "Hospital.xpt", "Income.xpt", 
                "Diabetes.xpt", "Derma.xpt", "Blood.xpt", "Alcohol.xpt",
                "Biopro.xpt", "CBC.xpt")

# Define file path (set this to the correct folder where your files are located)
file_path <- "/Users/jihoonchoi/Dropbox/PhD/R_personal"  # Replace with your actual path

# Read all .xpt files into a list
datasets <- lapply(file_names, function(f) read_xpt(file.path(file_path, f)))

# Assign names to the list
names(datasets) <- gsub("\\.xpt", "", file_names)

summary(datasets$Diabetes)


# Select the specified variables from each dataset
selected_data <- list(
  
  Demographic = datasets$Demographic[, c("SEQN", "RIAGENDR", "RIDAGEYR", "DMDEDUC2")],
  
  Alcohol = datasets$Alcohol[, c("SEQN", "ALQ121", "ALQ130")],
  
  Blood = datasets$Blood[, c("SEQN", "BPQ020", "BPQ030", "BPQ050A", "BPQ080", "BPQ100D")],
  
  Derma = datasets$Derma[, c("SEQN", "DED120", "DED125")],
  
  Diabetes = datasets$Diabetes[, c("SEQN", "DIQ010", "DIQ050", "DIQ070")],  # Note: "diab_pill_for_lbp" lacks a specific variable name
  
  Diet = datasets$Diet[, c("SEQN", "DBQ700", "DBD895", "DBD900", "DBD905")], # Note: Check original data for separate columns for frozen_meal, RTE_meal
  
  Hospital = datasets$Hospital[, c("SEQN", "HUQ010", "HUQ090")],
  
  Income = datasets$Income[, c("SEQN", "INDFMMPI")],
  
  Bio = datasets$Biopro[, c("SEQN", "LBXSGTSI")], # proxy of alcohol consumption
  
  CBC = datasets$CBC[, c("SEQN", "LBXMCVSI")] # proxy of alcohol consumption
  
)

target <- read_csv("sleep_depriv_tab 1.csv")

target <- target %>% 
  rename(SEQN = respondent_id)

# Check the first few rows for each dataset
lapply(selected_data, head)

# Merge all datasets on SEQN (assuming SEQN is the unique identifier for each participant)
merged_data <- Reduce(function(x, y) full_join(x, y, by = "SEQN"), selected_data)

merged_data <- merged_data %>% 
  inner_join(target, by = "SEQN")

head(merged_data)



merged_data_clean <- merged_data %>%
  mutate(
    # Demographic
    gender = factor(
      case_when(
        RIAGENDR == 1 ~ "Male",
        RIAGENDR == 2 ~ "Female",
        TRUE ~ NA_character_
      ),
      levels = c("Male", "Female")
    ),
    age = case_when(
      RIDAGEYR >= 0 & RIDAGEYR <= 79 ~ RIDAGEYR,
      RIDAGEYR == 80 ~ 80,  # "80 or over"
      TRUE ~ NA_real_
    ),
    edu = factor(
      case_when(
        DMDEDUC2 == 1 ~ "<9th grade",
        DMDEDUC2 == 2 ~ "9–11th grade",
        DMDEDUC2 == 3 ~ "High school grad",
        DMDEDUC2 == 4 ~ "Some college/AA",
        DMDEDUC2 == 5 ~ "College grad+",
        TRUE ~ NA_character_
      ),
      levels = c("<9th grade", "9–11th grade", "High school grad",
                 "Some college/AA", "College grad+")
    ),
    
    # Alcohol
    alc_freq_12m = case_when(
      ALQ121 >= 0 & ALQ121 <= 10 ~ ALQ121,  # 0..10 valid
      TRUE ~ NA_real_
    ),
    avg_alc_day = case_when(
      ALQ130 >= 1 & ALQ130 <= 13 ~ ALQ130,   # 1..13 valid
      ALQ130 == 15 ~ 15,                    # 15 = "15 drinks or more"
      TRUE ~ NA_real_
    ),
    
    # HBP
    high_BP_diag_1 = factor(
      case_when(
        BPQ020 == 1 ~ "Yes",
        BPQ020 == 2 ~ "No",
        TRUE ~ NA_character_
      ),
      levels = c("No", "Yes")
    ),
    take_med_HBP = factor(
      case_when(
        BPQ050A == 1 ~ "Yes",
        BPQ050A == 2 ~ "No",
        TRUE ~ "No"
      ),
      levels = c("No", "Yes")
    ),
    high_chol = factor(
      case_when(
        BPQ080 == 1 ~ "Yes",
        BPQ080 == 2 ~ "No",
        TRUE ~ "No"
      ),
      levels = c("No", "Yes")
    ),
    high_chol_med = factor(
      case_when(
        BPQ100D == 1 ~ "Yes",
        BPQ100D == 2 ~ "No",
        TRUE ~ "No"
      ),
      levels = c("No", "Yes")
    ),
    
    # Derma
    min_outdoors_work_day = case_when(
      DED120 >= 0 & DED120 <= 480 ~ DED120,
      TRUE ~ NA_real_
    ),
    min_outdoors_not_work_day = case_when(
      DED125 >= 0 & DED125 <= 480 ~ DED125,
      TRUE ~ NA_real_
    ),
    
    # Diabetes
    diag_diab = factor(
      case_when(
        DIQ010 == 1 ~ "Yes",
        DIQ010 == 2 ~ "No",
        DIQ010 == 3 ~ "Borderline",
        TRUE ~ NA_character_
      ),
      levels = c("No", "Yes", "Borderline")
    ),
    insulin_take = factor(
      # Missing value indicates legitimate skip
      case_when(
        DIQ050 == 1 ~ "Yes",
        DIQ050 == 2 ~ "No",
        TRUE ~ "No"
      ),
      levels = c("No", "Yes")
    ),
    diab_pill_for_lbp = factor(
      # Missing value indicates legitimate skip
      case_when(
        DIQ070 == 1 ~ "Yes",
        DIQ070 == 2 ~ "No",
        TRUE ~ "No"
      ),
      levels = c("No", "Yes")
    ),
    
    # Diet
    health_diet = factor(
      case_when(
        DBQ700 == 1 ~ "Excellent",
        DBQ700 == 2 ~ "Very good",
        DBQ700 == 3 ~ "Good",
        DBQ700 == 4 ~ "Fair",
        DBQ700 == 5 ~ "Poor",
        TRUE ~ NA_character_
      ),
      levels = c("Excellent", "Very good", "Good", "Fair", "Poor")
    ),
    not_home_meal = case_when(
      DBD895 >= 0 & DBD895 <= 21 ~ DBD895,
      TRUE ~ NA_real_
    ),
    fast_food_meal = case_when(
      DBD900 >= 0 & DBD900 <= 21 ~ DBD900,
      TRUE ~ NA_real_
    ),
    frozen_meal = case_when(
      DBD905 >= 0 & DBD905 <= 21 ~ DBD905,
      TRUE ~ NA_real_
    ),
    
    # Hospital Util
    gen_health_cond = factor(
      case_when(
        HUQ010 == 1 ~ "Excellent",
        HUQ010 == 2 ~ "Very good",
        HUQ010 == 3 ~ "Good",
        HUQ010 == 4 ~ "Fair",
        HUQ010 == 5 ~ "Poor",
        TRUE ~ NA_character_
      ),
      levels = c("Excellent", "Very good", "Good", "Fair", "Poor")
    ),
    seen_mental_health_prof = factor(
      case_when(
        HUQ090 == 1 ~ "Yes",
        HUQ090 == 2 ~ "No",
        TRUE ~ NA_character_
      ),
      levels = c("No", "Yes")
    ),
    
    # Poverty
    family_pov_index = case_when(
      INDFMMPI >= 0 & INDFMMPI <= 5 ~ INDFMMPI,
      TRUE ~ NA_real_
    ),
    
    # Clinical Data (alcohol consumption proxy)
    GGT = case_when(
      LBXSGTSI >= 0 & LBXSGTSI <= 2500 ~ LBXSGTSI,
      TRUE ~ NA_real_
    ),
    
    MCV = case_when(
      LBXMCVSI >= 35 & LBXMCVSI <= 120 ~ LBXMCVSI,
      TRUE ~ NA_real_
    )
  )

write_csv(merged_data_clean, "cleaned_final(not_imputed).csv")


colSums(is.na(merged_data_clean))

# impute yearly/daily alcohol consumption based on GGT, MCV level (key indicator)
# Fit linear models to predict alcohol frequency and average alcohol consumption using GGT and MCV
model_alc_freq <- lm(alc_freq_12m ~ GGT + MCV, 
                     data = merged_data_clean, 
                     na.action = na.omit)
model_avg_alc_day <- lm(avg_alc_day ~ GGT + MCV, 
                        data = merged_data_clean, 
                        na.action = na.omit)

# Use the models to impute missing values
merged_data_imputed <- merged_data_clean %>%
  mutate(
    alc_freq_12m = if_else(is.na(alc_freq_12m),
                           # Predict and ensure the imputed value is between 0 and 10
                           pmin(pmax(round(predict(model_alc_freq, newdata = .)), 0), 10),
                           alc_freq_12m),
    avg_alc_day = if_else(is.na(avg_alc_day),
                          # Predict and ensure the imputed value is between 1 and 15 (15 = "15 or more")
                          pmin(pmax(round(predict(model_avg_alc_day, newdata = .)), 1), 15),
                          avg_alc_day)
  )

# Check a summary of the imputed variables
summary(merged_data_imputed$alc_freq_12m)
summary(merged_data_imputed$avg_alc_day)

summary(merged_data_clean$alc_freq_12m)
summary(merged_data_clean$avg_alc_day)


merged_data_final <- merged_data_imputed %>%
  select(
    SEQN,
    is_sleep_deprived,
    daily_sleep_duration,
    gender,
    age,
    edu,
    alc_freq_12m,
    avg_alc_day,
    high_BP_diag_1,
    take_med_HBP,
    high_chol,
    high_chol_med,
    min_outdoors_work_day,
    min_outdoors_not_work_day,
    diag_diab,
    insulin_take,
    diab_pill_for_lbp,
    health_diet,
    not_home_meal,
    fast_food_meal,
    frozen_meal,
    gen_health_cond,
    seen_mental_health_prof,
    family_pov_index,
    GGT,
    MCV
  )

write_csv(merged_data_final, "merged_imputed_final.csv")


colSums(is.na(merged_data_final))

str(merged_data_final)



dt1 <- merged_data_final %>% 
  mutate(is_sleep_deprived = as_factor(is_sleep_deprived)
  )

colSums(is.na(dt1))

str(dt1)

# export csv file
write_csv(dt1, "dt_NHANES.csv")

# export rds file
write_rds(dt1, "dt1_NHANES.rds")
dt1 <- read_rds("dt1_NHANES.rds")

#### 1) Basic Summaries ####
# Check missingness and overall summary
colSums(is.na(dt1))
summary(dt1)

#### 2) Distributions for Each Variable ####
numeric_vars <- dt1 %>% 
  select(where(is.numeric)) %>% 
  names()


# Continuous Predictors
# Create a correlation table for numeric predictors with daily_sleep_duration
cor_table <- dt1 %>%
  # Select all numeric columns
  select(where(is.numeric)) %>%
  # Remove target variables and predictors we want to exclude
  select(-c(SEQN, GGT, MCV)) %>%
  # Compute correlations with daily_sleep_duration using the complete cases
  summarise(across(everything(), ~ cor(dt1$daily_sleep_duration, ., use = "complete.obs"))) %>%
  # Convert from wide to long format
  pivot_longer(cols = everything(), names_to = "Predictor", values_to = "Correlation_with_daily_sleep") %>%
  mutate(Correlation_with_daily_sleep = round(Correlation_with_daily_sleep, 3))

# Print the correlation table
print(cor_table)

# Plot the correlations as a horizontal bar plot, ordering predictors by correlation value
cor_table <- cor_table %>%
  arrange(Correlation_with_daily_sleep) %>%
  mutate(Predictor = factor(Predictor, levels = Predictor))

ggplot(cor_table, aes(x = Predictor, y = Correlation_with_daily_sleep)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Correlation of Numeric Predictors with Daily Sleep Duration",
    x = "Predictor",
    y = "Correlation"
  )

# Remove the ID and the target (and any other numeric predictors you want to exclude)
predictor_vars <- setdiff(numeric_vars, c("SEQN", "daily_sleep_duration", "GGT", "MCV"))

# Run a bivariate logistic regression for each numeric predictor and extract coefficient and p-value
logistic_results <- lapply(predictor_vars, function(var) {
  # Build the formula
  form <- as.formula(paste("is_sleep_deprived ~", var))
  
  # Fit the logistic regression model
  model <- glm(form, data = dt1, family = binomial)
  
  # Get the summary and extract the coefficient (for the predictor only) and its p-value
  summ <- summary(model)
  coef_val <- summ$coefficients[2, "Estimate"]
  p_val <- summ$coefficients[2, "Pr(>|z|)"]
  
  # Return a data frame with the predictor name, coefficient, and p-value
  data.frame(Predictor = var,
             Coefficient = round(coef_val, 3),
             p_value = round(p_val, 3),
             stringsAsFactors = FALSE)
})

# Combine the results into a single data frame
logistic_results_df <- do.call(rbind, logistic_results)

# Print the summary table
print(logistic_results_df)

# Factor Predictors
# 1) Define factor predictors (excluding the target)
str(dt1)

# Get the names of all factor variables in dt1
factor_vars <- dt1 %>% 
  select(where(is.factor)) %>% 
  names()

# Remove the target variable from the list
factor_predictors <- setdiff(factor_vars, "is_sleep_deprived")

# Loop over each factor predictor
for (varname in factor_predictors) {
  
  # Filter out rows missing either the predictor or the target
  dt_no_na <- dt1 %>%
    filter(!is.na(.data[[varname]]), !is.na(is_sleep_deprived))
  
  # Create a table of counts by predictor level and sleep deprivation status
  counts <- dt_no_na %>%
    group_by(across(all_of(varname)), is_sleep_deprived) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(across(all_of(varname))) %>%
    mutate(percent = n / sum(n))
  
  # Generate the grouped bar plot with percentage labels above each bar
  p <- ggplot(dt_no_na, aes(x = .data[[varname]], fill = is_sleep_deprived)) +
    geom_bar(position = position_dodge(width = 0.9)) +
    geom_text(data = counts,
              aes(x = .data[[varname]], y = n, label = percent(percent, accuracy = 0.1)),
              position = position_dodge(width = 0.9),
              vjust = -0.5, size = 3) +
    labs(
      title = paste("Grouped Bar Chart of", varname, "vs. Sleep Deprivation (binary)"),
      x = varname,
      y = "Count"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}

