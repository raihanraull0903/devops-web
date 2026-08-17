# DevOps Web — CI/CD Automation

Project ini merupakan implementasi CI/CD pipeline untuk melakukan build, push, deployment, health check, dan automatic rollback aplikasi web berbasis Docker.

Pipeline menggunakan GitHub, Jenkins, Docker Hub, dan Ansible.

---

## 1. Architecture

Developer
│
│ git push
▼
GitHub Repository
│
│ GitHub Webhook
▼
Jenkins
│
├── Checkout
│
├── Test
│
├── Docker Build
│
├── Docker Push
│
├── Get Current Production Image
│
├── Deploy
│
└── Health Check
│
├── HTTP 200
│      │
│      ▼
│   SUCCESS
│
└── Health Check Failed
│
▼
Automatic Rollback
│
▼
Previous Image

---

## 2. Technologies

Technology | Function
Git | Version control
GitHub | Source code repository
Jenkins | CI/CD automation
Docker | Containerization
Docker Hub | Container image registry
Ansible | Server deployment automation
Nginx | Web server
Ubuntu | Server operating system

---

## 3. Project Structure

devops-project/
│
├── ansible/
│   ├── inventory.ini
│   ├── install-docker.yml
│   ├── get-current-image.yml
│   ├── deploy-web.yml
│   ├── health-check.yml
│   └── rollback-web.yml
│
└── devops-web/
├── .gitignore
├── Dockerfile
├── Jenkinsfile
├── README.md
├── index.html
└── style.css

---

## 4. CI/CD Pipeline

Pipeline dijalankan secara otomatis ketika terdapat perubahan pada repository GitHub.

### Pipeline Flow

Git Push
↓
GitHub Webhook
↓
Jenkins
↓
Checkout
↓
Test
↓
Docker Build
↓
Docker Push
↓
Get Current Production Image
↓
Deploy
↓
Health Check
↓
SUCCESS / ROLLBACK

---

## 5. Stage 1 — Checkout

Jenkins mengambil source code terbaru dari repository GitHub.

stage('Checkout') {
steps {
checkout scm
}
}

Source code yang digunakan berasal dari branch:

main

---

## 6. Stage 2 — Test

Jenkins melakukan pengecekan sederhana untuk memastikan file utama tersedia.

File yang diperiksa:

* index.html
* style.css
* Dockerfile

Jika salah satu file tidak tersedia, pipeline dihentikan.

---

## 7. Stage 3 — Docker Build

Jenkins membuat Docker image berdasarkan commit Git.

Format image:

raihan999/devops-web:

Contoh:

raihan999/devops-web:7e119df

Penggunaan Git commit SHA membuat setiap deployment memiliki identitas image yang unik.

---

## 8. Stage 4 — Docker Push

Image yang berhasil dibuat dikirim ke Docker Hub.

Contoh:

raihan999/devops-web:7e119df

Jenkins menggunakan credentials yang tersimpan di Jenkins Credential Manager untuk melakukan login ke Docker Hub.

---

## 9. Ansible Deployment

Ansible digunakan untuk melakukan deployment pada server production.

Target server:

app-server

Inventory:

ansible/inventory.ini

---

## 10. Get Current Production Image

File:

get-current-image.yml

Playbook ini mengambil image yang sedang digunakan oleh container production.

Command yang digunakan:

docker inspect devops-web --format '{{.Config.Image}}'

Contoh hasil:

CURRENT_IMAGE=raihan999/devops-web:eb813b3

Image tersebut disimpan oleh Jenkins sebagai:

PREVIOUS_IMAGE

Image ini diperlukan apabila deployment baru mengalami kegagalan.

---

## 11. Deployment

File:

deploy-web.yml

Deployment dilakukan menggunakan Docker image baru.

Contoh:

raihan999/devops-web:7e119df

Proses deployment:

Pull Image
↓
Stop Container Lama
↓
Remove Container
↓
Start Container Baru

Container production:

devops-web

Port:

80:80

---

## 12. Health Check

File:

health-check.yml

Health check memastikan container berjalan dan website memberikan HTTP status 200.

Pengecekan container:

devops-web

Pengecekan HTTP:

[http://127.0.0.1](http://127.0.0.1)

Deployment dianggap sehat apabila mendapatkan:

HTTP 200 OK

Contoh:

Website is healthy - HTTP 200

---

## 13. Automatic Rollback

File:

rollback-web.yml

Rollback dijalankan apabila health check deployment baru gagal.

Contoh kondisi:

Previous Image:
raihan999/devops-web:eb813b3

New Image:
raihan999/devops-web:fbf4099

Jika image baru menghasilkan:

HTTP 500

maka Jenkins menjalankan:

Health Check Failed
↓
Get Previous Image
↓
Rollback
↓
eb813b3

Container production kemudian kembali menggunakan image sebelumnya.

---

## 14. Rollback Test

Automatic rollback telah diuji menggunakan image yang sengaja dikonfigurasi untuk menghasilkan HTTP 500.

Hasil pengujian:

New Image
raihan999/devops-web:fbf4099
↓
HTTP 500
↓
Health Check FAILED
↓
Automatic Rollback
↓
raihan999/devops-web:eb813b3
↓
HTTP 200 OK

Hasil akhir:

Rollback berhasil.
Production kembali menggunakan image sebelumnya.

---

## 15. Production Verification

Production terakhir berhasil dijalankan menggunakan:

raihan999/devops-web:7e119df

Container:

devops-web

Port:

0.0.0.0:80 -> 80/tcp

Health check:

HTTP/1.1 200 OK

---

## 16. Dockerfile

Docker image menggunakan Nginx Alpine sebagai base image.

FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css

---

## 17. Deployment Result

Deployment berhasil apabila seluruh tahapan berikut berhasil:

* Checkout
* Test
* Docker Build
* Docker Push
* Get Current Production Image
* Deploy
* Health Check
* Production Running

Jika deployment gagal pada health check:

* Detect Failure
* Get Previous Image
* Rollback
* Restore Previous Production Version
* Pipeline marked as FAILED

Pipeline tetap diberi status FAILED ketika deployment baru gagal meskipun rollback berhasil. Hal ini dilakukan agar kegagalan deployment tetap tercatat di Jenkins.

---

## 18. Summary

Project ini menerapkan konsep dasar DevOps:

Version Control
↓
Continuous Integration
↓
Containerization
↓
Continuous Deployment
↓
Health Check
↓
Automatic Rollback

Tujuan utama project adalah membuat proses deployment aplikasi web menjadi otomatis, terkontrol, dan dapat melakukan recovery ketika deployment baru mengalami kegagalan.

