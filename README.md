# Inferring Sleep Deprivation Risk Patterns from NHANES Data

### Identifying Key Drivers of Sleep Deprivation

## Project Overview

Sleep deprivation is a widespread yet underdiagnosed public health concern associated with chronic conditions such as diabetes, cardiovascular disease, and mental health disorders. Traditional diagnosis often relies on self-reported questionnaires, which lack broader physiological context.

This project leverages nationally representative data from the **National Health and Nutrition Examination Survey (NHANES)** (2017-2023 cycles) to develop predictive models for flagging sleep deprivation risk. By integrating demographic, behavioral, and clinical variables, we aim to identify key determinants of sleep health and provide a scalable screening tool for healthcare providers.

## Dataset

  * **Source**: [CDC National Health and Nutrition Examination Survey (NHANES)](https://www.cdc.gov/nchs/nhanes/)
  * **Cycles Used**: 2017-2020 (P\_*.XPT) and 2021-2023 (*.XPT)
  * **Sample Size**: \~18,000 individuals (Pooled)
  * **Data Categories**:
      * **Demographics**: Age, Gender, Race, Education, Income.
      * **Examination**: BMI, Blood Pressure, Body Measures.
      * **Laboratory**: Hormones, Cholesterol, Glucose, etc.
      * **Questionnaire**: Sleep Disorders, Depression (PHQ-9), Smoking, Alcohol, Physical Activity.

**Target Variable**:

  * **`is_sleep_deprived`**: Binary classification based on average daily sleep duration.
      * `1` (At Risk): \< 7 hours/day
      * `0` (Normal): ≥ 7 hours/day

## Project Workflow & Files

This repository is structured to follow a standard data science pipeline, from raw data ingestion to advanced modeling.

### 1\. Data Cleaning & Exploratory Data Analysis (EDA)

  * **File**: `01_data_eda_clean_dk.ipynb`
  * **Description**:
      * Ingests raw **SAS Transport Files (.XPT)** from 16 different NHANES modules (e.g., *Sleep Disorders, Kidney Conditions, Mental Health, Occupation*).
      * Merges datasets using `SEQN` (Respondent ID) as the unique key.
      * Performs extensive data cleaning: handling special codes (Refused/Don't Know), renaming cryptic column codes to meaningful names, and creating composite features (e.g., `PHQ-9` depression scores, `GLM` specific interaction terms).
      * **Output**: A consolidated raw dataset ready for preprocessing.

### 2\. Data Preparation & Feature Engineering

  * **File**: `02_data_preparation_dk.ipynb`
  * **Description**:
      * **Feature Selection**: Implements a dual-stage selection process to handle high dimensionality.
          * *Filter Method*: Variance Threshold, ANOVA F-test (Numerical), Chi-squared test (Categorical).
          * *Wrapper Method*: Recursive Feature Elimination (RFE) using XGBoost.
      * **Imputation**: Handles missing values using `IterativeImputer` (MICE-like approach) with XGBoost estimators to preserve data distribution.
      * **Feature Engineering**: Creates derived variables and interaction terms (e.g., `bedtime × gender`).
      * **Output**: Final processed training and testing datasets (`X_imputed.pkl`, `y.pkl`).

### 3\. Predictive Modeling & Evaluation

  * **File**: `03_modeling_dk.ipynb` (Python), `NHANES_nnet.ipynb` (Python) & `glm_model.Rmd` (R)
  * **Description**:
      * **Baseline**: Rule-based classifier using domain knowledge.
      * **Advanced Models**:
          * **XGBoost**: Tuned using Grid Search; handles class imbalance via scale weights.
          * **Neural Network (MLP)**: Captures non-linear complex interactions.
          * **Generalized Linear Models (GLM)**: Logistic Regression with BIC-based stepwise selection (implemented in R for interpretability).
          * **Stacking Ensemble**: Combines Random Forest, LightGBM, and SVM (Level 1) with Logistic Regression (Level 2).
      * **Evaluation**: Models are evaluated using **AUC-ROC**, **Sensitivity (Recall)**, and **F1-Score** using 5-fold Stratified Cross-Validation.

## Key Results

Our best-performing models demonstrated that routine health data could effectively flag sleep deprivation risks.

| Model | Test AUC | Test Sensitivity | Test F1 |
| :--- | :---: | :---: | :---: |
| **Stacking Ensemble** | **0.77** | **0.70** | **0.51** |
| XGBoost | 0.77 | 0.69 | 0.52 |
| GLM (BIC-Forward) | 0.76 | 0.70 | 0.51 |
| Naive Baseline | 0.65 | 0.44 | 0.41 |

**Key Findings**:

  * **Sleep Timing**: Bedtime is the strongest predictor. Going to sleep between **19:00 - 23:00** is significantly protective against sleep deprivation compared to very late or irregular schedules.
  * **Lifestyle Factors**: Smoking status and sedentary behavior are strong risk factors.
  * **Demographics**: Disparities exist across race/ethnicity groups, suggesting the need for targeted public health interventions.

## Installation & Usage

To reproduce the analysis, ensure you have Python 3.8+ and R installed.

### Python Dependencies

```bash
pip install numpy pandas scikit-learn xgboost lightgbm imbalanced-learn matplotlib seaborn
```

### R Dependencies (for GLM)

```r
install.packages(c("tidyverse", "caret", "glmnet", "pROC", "haven"))
```

### Running the Project

1.  **Data Cleaning**: Run `01_data_eda_clean_dk.ipynb` to download and merge NHANES data.
2.  **Preparation**: Run `02_data_preparation_dk.ipynb` to perform imputation and feature selection.
3.  **Modeling**:
      * Run `03_modeling_dk.ipynb` for Machine Learning models.
      * Run `glm_model.Rmd` for statistical GLM analysis.

## My Contribution

  * Data Cleaning, Preprocessing, ML Modeling (`01_data_eda_clean_dk.ipynb`, `02_data_preparation_dk.ipynb`, `03_modeling_dk.ipynb`)

---
## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/eodud0582/Inferring-Sleep-Deprivation-Risk-Patterns-from-NHANES-Data/blob/main/LICENSE) file for details.
