import torch
import cv2
import numpy as np

print("========================================")
print(f"✅ OpenCV 버전: {cv2.__version__}")
print(f"✅ PyTorch 버전: {torch.__version__}")
print("========================================")

if torch.cuda.is_available():
    print(f"🚀 GPU 인식 성공! 사용 가능한 그래픽카드: {torch.cuda.get_device_name(0)}")
else:
    print("⚠️ GPU를 찾을 수 없습니다. (CPU 모드로 동작합니다)")
print("========================================")


def test_homography():
    print("📸 45도 신용카드 기반 호모그래피 변환 기하학 연산 테스트")

    # 1. 테스트용 가상 검은색 이미지 생성 (실제 프로젝트 시 cv2.imread('test.jpg') 사용)
    test_img = np.zeros((800, 800, 3), dtype=np.uint8)
    # 가상의 이미지 위에 그릇 역할을 할 하얀 원 하나 그리기
    cv2.circle(test_img, (400, 400), 150, (255, 255, 255), -1)

    # 2. YOLOv26이 찾아냈다고 가정하는 카드의 왜곡된 4개 모서리 점 (픽셀 좌표)
    # 45도 측면 촬영으로 인해 찌그러진 사각형 형태
    src_pts = np.array([
        [250, 550],  # 좌상
        [420, 510],  # 우상
        [460, 620],  # 우하
        [280, 670]  # 좌하
    ], dtype=np.float32)

    # 3. 신용카드 실제 규격 (85.6mm x 53.98mm) 배율 설정
    scale = 10.0  # 1mm당 10픽셀 해상도로 투영
    dst_w = int(85.6 * scale)  # 856 px
    dst_h = int(53.98 * scale)  # 539 px

    dst_pts = np.array([
        [0, 0],
        [dst_w, 0],
        [dst_w, dst_h],
        [0, dst_h]
    ], dtype=np.float32)

    # 4. 투사 변환 행렬 H 도출
    H = cv2.getPerspectiveTransform(src_pts, dst_pts)
    print("\nCalculated Homography Matrix (H):")
    print(H)

    # 5. 이미지 워핑 적용 (왜곡 보정된 평면 이미지 획득)
    warped_res = cv2.warpPerspective(test_img, H, (dst_w, dst_h))
    print(f"\n📊 변환 완료된 Bird's-eye view 이미지 크기: {warped_res.shape[1]}x{warped_res.shape[0]}")
    print(f"📐 물리 스케일 기준 단차 수립 완료: 1픽셀 = {1.0 / scale} mm")

    # 로컬 디렉토리에 결과물 저장해서 확인할 수 있도록 설정
    # cv2.imwrite("warped_result.png", warped_res)


if __name__ == '__main__':
    test_homography()