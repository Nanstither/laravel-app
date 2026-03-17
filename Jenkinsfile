pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '3meenosez/laravel-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        BUILD_NUMBER = "${env.BUILD_ID}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', 
                url: 'https://github.com/Nanstither/laravel-app.git'
                // credentialsId: 'your-git-credentials'
            }
        }

        // stage('Setup Environment') {
        //     steps {
        //         script {
        //             // Копируем production .env
        //             sh 'cp .env.production .env'
                    
        //             // Генерируем APP_KEY если нужно
        //             sh 'docker run --rm -v $(pwd):/app -w /app php:8.2-cli php artisan key:generate --force --no-interaction'
        //         }
        //     }
        // }

        stage('Build Docker Images') {
            steps {
                script {
                    // Собираем образ приложения
                    docker.build("${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}")
                }
            }
        }

        // stage('Run Tests') {
        //     steps {
        //         script {
        //             // Запускаем контейнер для тестов
        //             docker.image("${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}").inside('--network=host') {
        //                 // Устанавливаем зависимости
        //                 sh 'composer install --no-dev --optimize-autoloader'
                        
        //                 // Запускаем миграции и тесты
        //                 sh 'php artisan migrate --force'
        //                 sh 'php artisan test'
        //             }
        //         }
        //     }
        // }

        stage('Run Tests') {
            steps {
                script {
                    // Загрузите переменные из .env.production
                    def envVars = readFile('.env.production').readLines().collectEntries { line ->
                        if (line.trim() && !line.startsWith('#') && line.contains('=')) {
                            def parts = line.split('=', 2)
                            [(parts[0].trim()): parts[1].trim()]
                        } else {
                            [:]
                        }
                    }.findAll { it.value } // убрать пустые значения
                    
                    docker.image("${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}").inside(envVars.collect { k, v -> "-e ${k}=${v}" }.join(' ')) {
                        sh 'php artisan config:clear'
                        sh 'php artisan migrate --force'
                        sh 'php artisan test'
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${env.DOCKER_CREDENTIALS_ID}") {
                        docker.image("${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}").push()
                    }
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                script {
                    // 🔹 Останавливаем старые контейнеры
                    sh 'docker compose down --volumes --remove-orphans || true'
                    
                    // 🔹 Запускаем новые (без --build, образ уже собран и запушен!)
                    sh 'docker compose up -d'
                    
                    // 🔹 Выполняем только миграции (зависимости уже в образе!)
                    sh 'docker compose exec app php artisan migrate --force'
                    sh 'docker compose exec app php artisan optimize:clear'
                    sh 'docker compose exec app php artisan optimize'
                }
            }
        }
    }

    post {
        success {
            echo ' Laravel application deployed successfully!'
            echo ' Application URL: http://your-server-ip'
        }
        failure {
            echo ' Deployment failed!'
            // Можно добавить уведомления
        }
    }
}
