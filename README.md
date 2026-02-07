# 📱 Automatic Meter Reading Mobile Application

This project presents a **Flutter-based mobile application** for **automatic meter reading** using computer vision and deep learning techniques. The system captures meter images, detects the relevant region (ROI), and recognizes meter values with high accuracy.

## 🚀 Features
- Automatic meter reading from images
- ROI-based image preprocessing
- OCR-based digit recognition
- Deep learning–based accuracy improvement
- Cloud integration for data storage and management

## 🧠 Methodology
- **ROI-based image processing** is applied to isolate the meter region.
- Initial text recognition is performed using **OCR (Google ML Kit)**.
- A **CRNN (Convolutional Recurrent Neural Network)** model is trained to improve recognition accuracy on challenging images.
- Image preprocessing and model training are carried out using **OpenCV** and **Python**.
- **Firebase** is used for authentication, data storage, and real-time database services.

## 🛠 Technologies Used
- **Mobile Development:** Flutter (Dart)
- **Backend / Cloud:** Firebase
- **OCR:** Google ML Kit
- **Deep Learning:** CRNN
- **Image Processing:** OpenCV
- **Model Training & Processing:** Python

## 📌 Use Cases
This application is suitable for:
- Electricity, water, and natural gas distribution companies
- Smart meter systems
- Automated billing workflows
- Reducing manual meter reading errors and labor costs
