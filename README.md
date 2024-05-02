# STAT764 Feed Intake
 Repository published to reproduce analyses of STAT 764 final project.

 Authors: Matt Kinghorn and Nico Giordano.

The **models** directory contains .stan files with model 1 (feed intake predictor is metabolic body weight only) and model 2 (feed intake predictor is metabolic body weight and temperature humidity index).

The **code** folder contain scripts to reproduce the analysis:

- *Data Prep.Rmd.* Data wrangling and exploration. 

- *2. Model Fitting.Rmd.* Code to run Stan filed with for models 1 and 2.
   
- *5. Derive Quantities.Rmd.* Code to derive quantities from posterior distribtuions from stanfit object.
   
- *6.1 Plot Validation.Rmd.* Reproduce Figure 1.

- *6.2 Plot ADG and RFI.Rmd.* Reproduce Figure 2.

- *6.3 Plot RFI and BETA1.Rmd.* Reproduce Figure 3.

- *6.4 Plot BETA1 and ADG.Rmd*. Reproduce Figure 4.

- The *functions.R* file contains backend functions used in Rmd files. 
