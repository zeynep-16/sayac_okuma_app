# Automatic Meter Reading Mobile Application

This project presents a **Flutter-based mobile application** for **automatic meter reading** using computer vision and deep learning techniques. The system captures meter images, detects the relevant region (ROI), and recognizes meter values with high accuracy.

## Features
- Automatic meter reading from images
- ROI-based image preprocessing
- OCR-based digit recognition
- Deep learning–based accuracy improvement
- Cloud integration for data storage and management

## Methodology
- **ROI-based image processing** is applied to isolate the meter region.
- Initial text recognition is performed using **OCR (Google ML Kit)**.
- A **CRNN (Convolutional Recurrent Neural Network)** model is trained to improve recognition accuracy on challenging images.
- Image preprocessing and model training are carried out using **OpenCV** and **Python**.
- **Firebase** is used for authentication, data storage, and real-time database services.

## Technologies Used
- **Mobile Development:** Flutter (Dart)
- **Backend / Cloud:** Firebase
- **OCR:** Google ML Kit
- **Deep Learning:** CRNN
- **Image Processing:** OpenCV
- **Model Training & Processing:** Python

## Use Cases
This application is suitable for:
- Electricity, water, and natural gas distribution companies
- Smart meter systems
- Automated billing workflows
- Reducing manual meter reading errors and labor costs

## Images of the application interface

<img width="709" height="318" alt="Ekran Resmi 2026-02-07 22 43 39" src="https://github.com/user-attachments/assets/05b731b9-c149-4813-859a-0695ad32ed28" />

<img width="833" height="311" alt="Ekran Resmi 2026-02-07 22 47 23" src="https://github.com/user-attachments/assets/c25df337-4537-439b-922b-e34586eb139d" />

<img width="781" height="228" alt="Ekran Resmi 2026-02-07 22 47 03" src="https://github.com/user-attachments/assets/bb3d4bb0-7d06-442d-b7b6-870206b7f6d2" />

<img width="699" height="234" alt="Ekran Resmi 2026-02-07 22 46 56" src="https://github.com/user-attachments/assets/4c3752ee-7512-4b3d-8d6f-3e87fc30584a" />

<img width="593" height="333" alt="Ekran Resmi 2026-02-07 22 46 41" src="https://github.com/user-attachments/assets/8b166276-7dca-4666-90c3-5b4d2de60927" />

<img width="689" height="266" alt="Ekran Resmi 2026-02-07 22 46 18" src="https://github.com/user-attachments/assets/884cc8a7-3d05-4365-87bc-351c63dbb179" />


