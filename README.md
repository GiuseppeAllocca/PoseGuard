# 🎧 PoseGuard
> **Real-time Posture Correction with AirPods Motion Sensors**

PoseGuard is an iOS application designed to help users maintain healthy posture habits using the built-in motion sensors of Apple AirPods. Developed during the **Apple Foundation Program** in Naples.

## 🚀 Key Features
- **Real-time Tracking:** Uses `CoreMotion` to read Pitch, Roll, and Yaw data from AirPods Pro/Max.
- **Smart Alerts:** Local notifications warn when the monitor detects incorrect posture. Continuous background monitoring is not guaranteed and still requires device testing.
- **Privacy First:** Motion data is processed locally on the device; the onboarding completion preference is stored on device. A privacy manifest declares this UserDefaults use. The public privacy policy and the in-app policy link still need to be aligned before release.
- **Fixed Threshold:** The monitor compares AirPods pitch and roll against a fixed ±15° threshold. Personal calibration is not implemented.

## 🛠 Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Hardware Integration:** CoreMotion (AirPods Motion API)
- **Architecture:** MVVM

<p align="center">
  <img src="https://github.com/user-attachments/assets/b6658b22-2bb8-46d5-a20d-b7acf7da8f73" width="30%" />
  &nbsp; 
  <img src="https://github.com/user-attachments/assets/4eede344-9f14-47b1-9285-1dc6f7861b11" width="30%" />
  &nbsp; 
  <img src="https://github.com/user-attachments/assets/ec2c53ac-0f75-44e9-ad6e-14ada58e0cba" width="30%" />
</p>

## 👨‍💻 My Role

Co-created within a team of 4 developers. My key contributions included:
- Engineered the **gyroscope algorithm** to interpret raw motion data (calculating neck angles).
- Developed the posture monitoring and local alert logic.

---
*Developed with ❤️ in Naples, Italy.*
