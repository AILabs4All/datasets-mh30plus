# Description
This folder contains the balanced datasets used and create for the experiments of the paper, it's structure is divided in two sub-folders:(1)Oversampling/ and (2)Oversampling/; which contain datasets processed with their naming scheme methods.


# Overview

The specifications as well as the amount of benign and malign samples after and before are listed in the table.

| Dataset             | Original (B/M)            | Undersampling (B/M + technique)          | Oversampling (B/M + technique)      |
|---------------------|---------------------------|------------------------------------------|-------------------------------------|
| MH100k              | 92,134 / 9,800 (9.4:1)    | 9,800 / 9,800 (1:1, ENN + RandomUnder)   | 92,134 / 92,134 (1:1, RandomOver)   |
| KronoDroid Real     | 36,755 / 41,382 (1:1.1)   | 36,755 / 36,755 (1:1, ENN + RandomUnder) | 40,873 / 41,382 ($\sim$1:1, ADASYN) |
| KronoDroid Emulator | 35,246 / 28,745 (1.2:1)   | 28,745 / 28,745 (1:1, ENN + RandomUnder) | 35,246 / 35,246 (1:1, SMOTE)        |
| DREBIN-215          | 9,476 / 5,555 (1.7:1)     | 5,555 / 5,555 (1:1, ENN + RandomUnder)   | 9,476 / 9,476 (1:1, SMOTE)          |
| DefenseDroid PRS    | 5,975 / 6,000 ($\sim$1:1) | 4,827 / 4,827 (1:1, ENN + RandomUnder)   | 6,000 / 6,000 (1:1, RandomOver)     |
| DD API Katz         | 5,222 / 5,254 ($\sim$1:1) | 5,200 / 5,200 (1:1, ENN + RandomUnder)   | 5,254 / 5,254 (1:1, RandomOver)     |
| DD API Degree       | 5,222 / 5,254 ($\sim$1:1) | 5,200 / 5,200 (1:1, ENN + RandomUnder)   | 5,254 / 5,254 (1:1, RandomOver)     |
| DD API Closeness    | 5,222 / 5,254 ($\sim$1:1) | 5,200 / 5,200 (1:1, ENN + RandomUnder)   | 5,254 / 5,254 (1:1, RandomOver)     |
| Android Permissions | 9,077 / 17,787 (1:2)      | 7,379 / 7,379 (1:1, ENN + RandomUnder)   | 17,787 / 17,787 (1:1, SMOTE)        |
| AndroCrawl          | 86,574 / 10,170 (8.5:1)   | 10,170 / 10,170 (1:1, NearMiss)          | 86,574 / 86,574 (1:1, SMOTE)        |
| Adroit              | 8,058 / 3,418 (2.4:1)     | 3,418 / 3,418 (1:1, NearMiss)            | 8,058 / 8,058 (1:1, RandomOver)     |
