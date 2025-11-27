# EC2 배포 프론트 설정

수정할 파일은 크게 4가지로 분류할 수 있습니다.

- Frontend/.env
- Frontend/android/local.properties
- Frontend/android/app/build.gradle.kts(github 업로드)
- Frontend/android/app/src/main/AndroidManifest.xml(github 업로드)

## 1. Frontend/.env
```env
HOST = 'domain_address/' or 'ec2_ip/'
KAKAO_APP_KEY = 'your_kakao_app_key' # 런타임용
```

## 2. Frontend/android/local.properties
```local.properties
...
KAKAO_APP_KEY = 'your_kakao_app_key' # 빌드용, 이 부분만 추가
```

## 3. Frontend/android/app/build.gradle.kts
```build.gradle.kts
// 상단에 패키지 import, defaultConfig 내에 카카오 앱 키 추가
import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        load(FileInputStream(file))
    }
}

...

    defaultConfig {
        applicationId = "com.example.Xnd"
        minSdk = 23 // 테스트 디버깅용 수정
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 이 부분 추가
        manifestPlaceholders["KAKAO_APP_KEY"] =
            localProperties.getProperty("KAKAO_APP_KEY")
    }

```

## 4. Frontend/android/app/src/main/AndroidManifest.xml
```AndroidManifest.xml
L21 : <data android:scheme="kakao${KAKAO_APP_KEY}" android:host="oauth"/>
```