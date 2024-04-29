
data {
  int<lower=0> N; // observed data
  int<lower=0> N2; // simulated data
  
  
  int<lower = 1> K; //number of population level effects
  matrix[N,K] X; // design matrix
  matrix[N2,K] Xs; // design matrix for the simulated data
  
  vector[N] time; // observed time
  vector[N2] ptime; //predicted time
  
  vector<lower = 0>[N2] fi; // observed Feed Intake
  vector[N] BW; // observed BW
  vector[N2] BWto; // observed BW at time 0
  vector[N2] THIt; // daily observations of THI
  
}

parameters {
  real<lower=0> alpha; // First moment of the Gamma distribution for feed intake (fi)
  real<lower=0> sigma; // Second moment for the Normal distribution for body weight (BW)
  
  vector<lower=-0.0321, upper=1>[K] beta1; // effect of metabolic body weight on feed intake
  vector[K] beta2; // effect of environmental covariate on feed intake
  vector[K] eta1; //  effect of time on body weights (average daily gain)
}

transformed parameters {
  // Growth model
  vector[N] BWt; // Predicted BWt
  vector[N] nlp_eta1 = X * eta1; // Design matrix for the effect of time on body weights (average daily gain)

  for (n in 1:N){
    BWt[n] =  nlp_eta1[n] * time[n]; // Time series model for body weight
  }
  
  // simulate BW for every day
  // design matrix of length 70 * number of animals, columns is equal to the number of animals
  vector[N2] BWs;
  vector[N2] nlp2_eta1 = Xs * eta1;
  
  for (n in 1:N2){
    BWs[n] =  BWto[n] + nlp2_eta1[n] * ptime[n]; 
  }
  
  // Feed intake model
  vector[N2] mu; // Predicted Feed Intake
  vector[N2] nlp_beta1 = Xs * beta1; // Design matrix for predicted body weight
  vector[N2] nlp_beta2 = Xs * beta2; // Design matrix for environmental covariate (THI, AUC)
  
  for (n in 1:N2){ 
    mu[n] = nlp_beta1[n] * pow(BWs[n], 0.75) - nlp_beta2[n] * THIt[n];
  }
  
}

model {
  // Priors
  alpha ~ gamma(3,1); // First moment of the Gamma distribution for feed intake (fi)
  sigma ~ gamma(7,1); // Second moment for the Normal distribution for body weight (BW)

  beta1 ~ normal(0.12, 4); // effect of metabolic body weight on feed intake
  beta2 ~ gamma(2, 2 ./ 0.01); // effect of THI on feed intake (fi), mean effect is 0.01
  eta1 ~ normal(1.55,2); // effect of time on bodyweight (ADG)
  
  // Process models
  fi ~ gamma(alpha, alpha ./ exp(mu));
  BW ~ normal(BWt, sigma);
}

// Get the posterior predictive distribution
generated quantities {
  vector[N2] fi_tilde;
  for (n in 1:N2) {
    fi_tilde[n] = gamma_rng(alpha, alpha ./ exp(mu[n])); // Draw samples from posterior predictive
  }
}
