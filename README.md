# 📊 Malware Datasets Repository — Reduced & Balanced Versions

This repository contains **complete and reduced versions** of Android malware datasets, along with their respective **balancing strategies** (undersampling and oversampling).

The goal is to support experiments related to:

* Malware Detection
* Synthetic Data Generation
* Feature Selection
* Hyperparameter Optimization
* Dataset Reduction Impact Analysis

---

# 🗂️ Dataset Summary

| Dataset                         | Method      | Features (Full) | Features (Reduced) | Benigns / Malwares (Under) | Benigns / Malwares (Over) | Undersampling      | Oversampling      |
| ------------------------------- | ----------- | --------------- | ------------------ | -------------------------- | ------------------------- | ------------------ | ----------------- |
| mh100k                          | statistical | 24,833          | 93                 | 9,800                      | 92,175                    | EditedNearestNeighbours | RandomOverSampler |
| kronodroid_real_device          | statistical | 286             | 29                 | 36,755                     | 41,382                    | EditedNearestNeighbours | RandomOverSampler |
| kronodroid_emulator             | statistical | 286             | 25                 | 28,745                     | 35,246                    | RandomUnderSampler | SMOTE |
| drebin215                       | rfe         | 215             | 64                 | 5,555                      | 9,476                     | RandomUnderSampler | SMOTE |
| defensedroid_prs                | semidroid   | 2,877           | 144                | 5,975                      | 6,000                     | EditedNearestNeighbours | SMOTE |
| defensedroid_apicalls_katz      | rfe         | 6,002           | 300                | 5,222                      | 5,254                     | RandomUnderSampler | RandomOverSampler |
| defensedroid_apicalls_degree    | rfe         | 6,002           | 300                | 5,222                      | 5,254                     | RandomUnderSampler | RandomOverSampler |
| defensedroid_apicalls_closeness | rfe         | 4,274           | 213                | 5,222                      | 5,254                     | EditedNearestNeighbours | RandomOverSampler |
| android_permissions             | semidroid   | 151             | 57                 | 9,077                      | 17,787                    | RandomUnderSampler | ADASYN |
| androcrawl                      | statistical | 141             | 13                 | 10,170                     | 86,574                    | RandomUnderSampler | ADASYN |
| adroit                          | rfe         | 166             | 66                 | 3,418                      | 8,058                     | RandomUnderSampler | SMOTE |

---

# 🔬 Feature Selection Methods

The reduced datasets were generated using the following feature selection strategies:

* **Statistical** → Based on statistical relevance metrics
* **RFE** → Recursive Feature Elimination
* **SemiDroid** → Hybrid feature selection approach combining statistical and structural relevance

---

# ⚖️ Dataset Balancing

To mitigate class imbalance, the following techniques were applied:

## 🔻 Undersampling

* Method: `RandomUnderSampler`
* Goal: Reduce majority class size

## 🔺 Oversampling

* Method: `RandomOverSampler`
* Goal: Increase minority class representation

Balancing was applied after feature reduction to preserve dataset structure.

---

# 👥 Maintainers

| Name   |
| ------ |
| Lucas Ferreira  |
| Angelo Gaspar |
| Anna Luiza |

---

# 📌 Notes

* Feature counts refer to **input attributes only** (excluding class label).
* Balanced distributions vary depending on the dataset’s original imbalance ratio.
* Reduced datasets aim to preserve detection performance while minimizing dimensionality.

---

# 📖 Citation / Usage

If you use these datasets in academic work, please cite the corresponding research or repository.

---

# 📬 Contact

For questions or contributions, please contact the repository maintainers.
