import time
import requests
import json
import os
import datetime
import threading
import logging
import glob

# 🚀 [사용자 설정] 시스템 환경 및 동작 설정

# 1. 센서/GPIO 설정
USE_PHYSICAL_SENSOR = True  # True: GPIO 센서 사용, False: 키보드 'o'/'c' 사용
DOOR_SENSOR_PIN = 17  # 마그네틱 센서가 연결된 GPIO 핀 번호 (BCM 모드 기준)

# 2. 카메라 촬영 설정
IMAGE_WIDTH = 1920  # 640 #1680         # 카메라 해상도
IMAGE_HEIGHT = 1080  # 640 #1050        # 카메라 해상도
CAPTURE_INTERVAL = 0.1  # 0.2   # 연속 촬영 간격 (초 단위)
CAMERA_STABILIZE_SLEEP = 0.5  # 0.0 #1.0  # 문 열림 직후 카메라 안정화 대기 시간 (초)

# 3. 데이터 전송 및 트리밍 설정
MAX_SEND_COUNT = 15  # 10     # 서버에 전송할 최대 프레임 수 (균등 간격 선별)
CUT_END = 2  # 문 닫힘 직전 노이즈 제거 프레임 수 (손/문 움직임)

# 🚨 config.py 정보
try:
    from config import SERVER_BASE_URL, ACCESS_TOKEN

    try:
        from config import USER_ID
    except ImportError:
        USER_ID = 1
except ImportError:
    print("❌ config.py 파일이 없거나 설정이 부족합니다.")
    exit(1)

# ========== 라이브러리 및 전역 변수 초기화 (설정값 사용) ==========

# 🚨 [라이브러리] Picamera2
try:
    from picamera2 import Picamera2
    from libcamera import Transform
except ImportError:
    print("❌ Picamera2 라이브러리가 없습니다. 'sudo apt install python3-libcamera' 등을 확인하세요.")
    exit(1)

# 🚨 [라이브러리] GPIOzero (센서 사용 시)
if USE_PHYSICAL_SENSOR:
    try:
        from gpiozero import Button
        from signal import pause
    except ImportError:
        print("❌ gpiozero 라이브러리가 없습니다. 'pip install gpiozero'를 실행하세요.")
        exit(1)

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# 전역 변수
GLOBAL_FRIDGE_ID = 1
GLOBAL_USER_ID = USER_ID
GLOBAL_SERVER_URL = ""
SHOULD_CAPTURE = False
CAPTURED_FILES = []
picam2 = None


# ====================================================================
# ========== 🛠️ RPi에서 판단할 임시 로직 (서버 데이터 사용으로 변경) ==========
def determine_layer():
    return 1  # 서버가 최종 판단하므로 임시값 전송


def determine_action_type():
    return 'inbound'  # 서버가 'analyzing' 플래그로 판단하므로 임시값 전송


# ====================================================================

# 🚨 [1] 서버 초기화 및 ID 획득 함수
def initialize_pi_settings():
    """서버에서 실제 사용자 및 냉장고 ID를 받아와 전역 변수를 갱신합니다."""
    global GLOBAL_FRIDGE_ID, GLOBAL_USER_ID, GLOBAL_SERVER_URL

    # 냉장고 리스트 API 경로 구성
    INIT_FRIDGE_LIST_URL = f"{SERVER_BASE_URL}/fridge/"

    headers = {
        'Authorization': f'Bearer {ACCESS_TOKEN.strip()}'
    }

    try:
        logging.info("🌐 서버에서 냉장고 ID 획득 시도 (GET /api/fridge/)...")
        response = requests.get(INIT_FRIDGE_LIST_URL, headers=headers, timeout=10)

        if response.status_code == 200:
            json_data = response.json()
            # DRF 응답 구조 대응 ('fridges' 키가 있거나, 리스트 자체가 반환되거나)
            fridge_list = json_data.get('fridges') if isinstance(json_data, dict) else json_data

            if not fridge_list or not isinstance(fridge_list, list) or len(fridge_list) == 0:
                logging.error("❌ 유효 토큰이지만, 연결된 냉장고가 없습니다.")
                return False

            first_fridge = fridge_list[0]

            # ID 획득 (fridge_id 또는 id)
            GLOBAL_FRIDGE_ID = first_fridge.get('fridge_id') or first_fridge.get('id')

            if not GLOBAL_FRIDGE_ID:
                logging.error("❌ 응답에 유효한 냉장고 ID 필드가 없습니다.")
                return False

            # GLOBAL_SERVER_URL 최종 업데이트
            GLOBAL_SERVER_URL = f"{SERVER_BASE_URL}/fridge/{GLOBAL_FRIDGE_ID}/"

            logging.info(f"✅ 초기화 성공: Fridge ID {GLOBAL_FRIDGE_ID} 설정됨.")
            return True
        else:
            logging.error(f"❌ 초기화 실패! 서버 응답: {response.status_code}")
            return False

    except Exception as e:
        logging.error(f"❌ 초기화 중 네트워크 오류: {e}")
        return False


# 🚨 [2] 카메라 초기화 함수
def init_camera():
    """카메라 초기화 및 예열 (호환성 패치 포함)"""
    global picam2
    try:
        picam2 = Picamera2()

        # 🚨 [로그 추가] 설정값 확인
        logging.info(f"DEBUG: Configured IMAGE_WIDTH: {IMAGE_WIDTH}, IMAGE_HEIGHT: {IMAGE_HEIGHT}")

        ROTATION_ANGLE = 0
        H_FLIP = False
        V_FLIP = False

        # 크기를 (HEIGHT, WIDTH)로 뒤집어 설정해야 90도 회전 후에도 해상도가 맞게 저장됩니다.
        config_args = {
            "main": {"size": (IMAGE_WIDTH, IMAGE_HEIGHT), "format": "RGB888"},
            # "transform": Transform(hflip=H_FLIP, vflip=V_FLIP, rotation=ROTATION_ANGLE)
        }

        # 🚨 [로그 추가] Transform이 적용될 최종 설정값 확인
        logging.info(
            f"DEBUG: Transform Setting - Size: ({IMAGE_HEIGHT}x{IMAGE_WIDTH}), Rotation: {ROTATION_ANGLE}, HFlip: {H_FLIP}, VFlip: {V_FLIP}")

        try:
            config = picam2.create_configuration(**config_args)
            logging.info("DEBUG: picam2.create_configuration Success.")
        except AttributeError:
            logging.warning("⚠️ 구버전 Picamera2 감지됨. 호환 모드로 진입합니다.")
            try:
                config = picam2.create_video_configuration(**config_args)
            except AttributeError:
                logging.warning("⚠️ 매우 오래된 버전입니다. 기본 설정으로 진행합니다.")
                config = picam2.make_configuration(**config_args)

        picam2.configure(config)
        logging.info("DEBUG: picam2.configure Success.")

        picam2.start()

        logging.info("📸 Picamera2 초기화 및 예열 완료 (Standby Mode)")

    except Exception as e:
        logging.error(f"❌ 카메라 초기화 실패: {e}")
        picam2 = None


def capture_single_image_fast():
    """Picamera2를 이용한 초고속 캡처"""
    global picam2
    if picam2 is None: return None

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
    filename = f"fridge_shot_{timestamp}.jpg"

    try:
        picam2.capture_file(filename)
        return filename
    except Exception as e:
        logging.error(f"캡처 실패: {e}")
        return None


def continuous_capture_loop():
    """고속 연속 캡처 루프"""
    global CAPTURED_FILES, SHOULD_CAPTURE
    CAPTURED_FILES = []

    logging.info(f"--- 📸 고속 연속 캡처 스레드 시작 (간격: {CAPTURE_INTERVAL}초)")

    while SHOULD_CAPTURE:
        start_time = time.time()

        file_path = capture_single_image_fast()
        if file_path:
            CAPTURED_FILES.append(file_path)

        elapsed = time.time() - start_time
        sleep_time = max(0, CAPTURE_INTERVAL - elapsed)
        time.sleep(sleep_time)

    logging.info(f"--- 📸 연속 캡처 스레드 종료. 총 {len(CAPTURED_FILES)}개 파일 저장.")


# 🚨 [3] 데이터 전송 및 결과 출력 함수
def upload_sequence_to_server(file_list):
    if not file_list: return

    # 15장 선별 전송
    total_frames = len(file_list)
    selected_files = []

    if total_frames <= MAX_SEND_COUNT:
        selected_files = file_list
    else:
        indices = [int(i * (total_frames - 1) / (MAX_SEND_COUNT - 1)) for i in range(MAX_SEND_COUNT)]
        indices = sorted(list(set(indices)))
        selected_files = [file_list[i] for i in indices]

    logging.info(f"--- 📤 전송 준비: 총 {len(selected_files)}장 (전체 {total_frames}장 중 선별)")

    files = {}
    opened_files = []
    response = None

    start_time = time.time()

    try:
        for idx, f_path in enumerate(selected_files):
            f = open(f_path, 'rb')
            opened_files.append(f)
            files[f'image_{idx}'] = (os.path.basename(f_path), f, 'image/jpeg')

        data = {
            'user_id': str(GLOBAL_USER_ID),
            'layer': determine_layer(),
            'action_type': 'analyzing',
            # 해상도 인자 전달 (설정값 사용)
            'image_width': IMAGE_WIDTH,
            'image_height': IMAGE_HEIGHT
        }

        headers = {'Authorization': f'Bearer {ACCESS_TOKEN.strip()}'}

        # 타임아웃 (60초)
        response = requests.post(GLOBAL_SERVER_URL, data=data, files=files, headers=headers, timeout=200)

        end_time = time.time()
        latency = end_time - start_time

        if response.status_code in [200, 201, 404]:  # 404는 출고 시 재고 없음 응답일 수 있음
            logging.info(f"✅ 서버 전송 성공! (소요시간: {latency:.2f}초)")

            try:
                results = response.json()

                item = results.get('item_name', 'N/A')
                status_str = results.get('status', 'N/A').upper()
                layer_str = results.get('layer', 'N/A')
                yolo_conf = results.get('yolo_conf', 0.0)
                detail_log = results.get('detail_log', '서버에서 상세 정보 없음')  # detail_log 키 확인

                # 좌표 정보 안전하게 가져오기
                start_x = results.get('raw_start_x', 0.0)
                end_x = results.get('raw_end_x', 0.0)
                start_y = results.get('raw_start_y', 0.0)
                end_y = results.get('raw_end_y', 0.0)

                # 통합 로그 출력
                print("\n\n=============== 🧠 AI 분석 최종 결과 ===============")

                # 404 에러일 경우 응답 처리
                if response.status_code == 404:
                    print(f"| ⚠️ DB 오류: {results.get('message', '재고를 찾을 수 없어 출고 실패')}")

                print(f"| 📦 품목명: {item}")
                print(f"| 📈 상태: {status_str} | 층수: {layer_str}층")

                # 좌표 출력
                sx_str = f"{start_x:.0f}" if isinstance(start_x, (int, float)) else 'N/A'
                ex_str = f"{end_x:.0f}" if isinstance(end_x, (int, float)) else 'N/A'
                sy_str = f"{start_y:.0f}" if isinstance(start_y, (int, float)) else 'N/A'
                ey_str = f"{end_y:.0f}" if isinstance(end_y, (int, float)) else 'N/A'

                print(f"| ↔️ X 변화(왼쪽 1층-(+)-2층 오른쪽): {sx_str} → {ex_str} (층수)")
                print(f"| ↕️ Y 변화(위쪽(0) 입고 - 출고 아래쪽(+)): {sy_str} → {ey_str} (이동)")

                if isinstance(yolo_conf, (int, float)) and yolo_conf > 0.001:
                    print(f"| 💰 신뢰도: {yolo_conf:.2f} (Max Confidence)")

                # 상세 로그 출력
                print(f"| 🔍 판정 이유: {detail_log}")
                print(f"| ⏱️ 처리 시간: {latency:.2f}초")
                print("-----------------------------------------------------")

            except Exception as e:
                print(f"\n⚠️ 파싱 실패 (원인: {e})")
                print(f"RAW 응답: {response.text}")
        else:
            logging.error(f"❌ 전송 실패: {response.text}")

    except Exception as e:
        logging.error(f"❌ 전송 중 오류 발생: {e}")

    finally:
        for f in opened_files: f.close()
        logging.info(f"🗑️ 임시 파일 {len(file_list)}개 삭제.")
        for file_path in file_list:
            try:
                os.remove(file_path)
            except OSError as e:
                logging.error(f"❌ 파일 삭제 오류 {file_path}: {e}")


def run_camera_and_upload():
    global SHOULD_CAPTURE

    print(f"🚀 서버 연결 주소: {GLOBAL_SERVER_URL}")
    print("--------------------------------------------------")

    if USE_PHYSICAL_SENSOR:
        print("📷 모드: Picamera2 (센서 연동 모드)")
        print("🚪 상태: 도어 센서(GPIO 17) 감시 중...")
        door_sensor = Button(DOOR_SENSOR_PIN, pull_up=True)
    else:
        print("📷 모드: Picamera2 (키보드 시뮬레이션 모드)")
        print("🚪 키보드: 'o' 열림 / 'c' 닫힘 / 'q' 종료")
    print("--------------------------------------------------")

    # 기존 파일 청소
    for f in glob.glob('fridge_shot_*.jpg'):
        os.remove(f)

    # 공통 동작 함수
    def action_open():
        global SHOULD_CAPTURE
        if not SHOULD_CAPTURE:
            print("\n🔔 문 열림! (촬영 시작)")
            time.sleep(CAMERA_STABILIZE_SLEEP)

            SHOULD_CAPTURE = True
            t = threading.Thread(target=continuous_capture_loop)
            t.start()

    # 2. 문 닫힘 감지 함수 (촬영 종료 & 전송)
    def action_close():

        global SHOULD_CAPTURE, CAPTURED_FILES

        if SHOULD_CAPTURE:
            print("✅ (센서) 문 닫힘! 촬영 종료.")

            SHOULD_CAPTURE = False
            time.sleep(1)  # 스레드 저장 대기

            # 문 닫힘 직전 프레임 (손/문) 삭제
            if len(CAPTURED_FILES) > CUT_END:
                print(f"✂️ 문 닫힘 직전 {CUT_END}장 삭제 (총 {len(CAPTURED_FILES)}장 -> {len(CAPTURED_FILES) - CUT_END}장)")
                CAPTURED_FILES = CAPTURED_FILES[:-CUT_END]

            # [추가] 0개 파일 전송 방지
            if len(CAPTURED_FILES) == 0:
                print("⚠️ 유효 파일이 없어 서버 전송을 건너뜁니다.")
            else:
                upload_sequence_to_server(CAPTURED_FILES)

            print("🚪 대기 중...")

    # 모드별 실행
    if USE_PHYSICAL_SENSOR:
        door_sensor.when_released = action_open
        door_sensor.when_pressed = action_close
        try:
            pause()
        except KeyboardInterrupt:
            pass
    else:
        while True:
            user_input = input("대기 중... (o/c/q): ").strip().lower()
            if user_input == 'o':
                action_open()
                while True:
                    close_input = input().strip().lower()
                    if close_input == 'c':
                        action_close()
                        break
                    elif close_input == 'q':
                        SHOULD_CAPTURE = False
                        return
            elif user_input == 'q':
                break


if __name__ == '__main__':
    if initialize_pi_settings():
        try:
            init_camera()
            if picam2:
                run_camera_and_upload()
        except KeyboardInterrupt:
            pass
        finally:
            if picam2:
                print("📸 카메라 자원 해제 중...")
                picam2.stop()
                picam2.close()
                print("✅ 종료")
